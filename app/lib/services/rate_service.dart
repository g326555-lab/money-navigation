import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/exchange_rate.dart';

/// Daily exchange rates from Frankfurter (European Central Bank reference
/// rates, free, no key). The last good rate is cached on the device and shown
/// with its date when the network is down.
class RateService extends ChangeNotifier {
  RateService({SharedPreferencesAsync? prefs, http.Client? client})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      _client = client ?? http.Client();

  static const host = 'api.frankfurter.dev';
  static const base = 'THB';
  static const _timeout = Duration(seconds: 6);
  static const _rateKey = 'rate_v1_';
  static const _currenciesKey = 'currencies_v1';

  final SharedPreferencesAsync _prefs;
  final http.Client _client;

  final Map<String, RateQuote> _quotes = {};
  final Set<String> _failed = {};
  Map<String, String> _currencies = const {};

  /// The latest known rate from THB to [quote], fresh or cached.
  RateQuote? quoteFor(String quote) => _quotes[quote];

  /// True when the last refresh for [quote] failed; a cached rate may
  /// still be shown, marked as the last known one.
  bool refreshFailed(String quote) => _failed.contains(quote);

  /// True when the last refresh for [quote] failed and nothing is cached.
  bool unavailable(String quote) =>
      _failed.contains(quote) && !_quotes.containsKey(quote);

  /// ISO code to English name, as Frankfurter lists them. Empty until loaded.
  Map<String, String> get currencies => _currencies;

  /// Loads the cached rate for [quote] and refreshes it when it is a day old.
  Future<void> ensure(String quote) async {
    if (quote == base) return;
    final cached =
        _quotes[quote] ??
        RateQuote.fromJson(_decode(await _prefs.getString('$_rateKey$quote')));
    if (cached != null && cached.quote == quote) {
      _quotes[quote] = cached;
      notifyListeners();
    }
    if (!rateNeedsRefresh(_quotes[quote], DateTime.now())) return;
    final fresh = await _fetchLatest(quote);
    if (fresh == null) {
      _failed.add(quote);
      _scheduleRetry(quote);
    } else {
      _retries.remove(quote);
      _failed.remove(quote);
      _quotes[quote] = fresh;
      await _prefs.setString('$_rateKey$quote', jsonEncode(fresh.toJson()));
    }
    notifyListeners();
  }

  /// A failed refresh tries again after [retryDelays], then waits for the
  /// next app resume. One pending retry per currency.
  static const retryDelays = [
    Duration(seconds: 5),
    Duration(seconds: 20),
    Duration(seconds: 60),
  ];
  final Map<String, int> _retries = {};
  final Set<String> _retryPending = {};

  void _scheduleRetry(String quote) {
    final attempt = _retries[quote] ?? 0;
    if (attempt >= retryDelays.length || !_retryPending.add(quote)) return;
    _retries[quote] = attempt + 1;
    Future<void>.delayed(retryDelays[attempt], () {
      _retryPending.remove(quote);
      ensure(quote);
    });
  }

  /// Loads the list of currencies the rate source supports.
  Future<void> loadCurrencies() async {
    final cached = _decode(await _prefs.getString(_currenciesKey));
    if (cached is Map) _setCurrencies(cached);
    try {
      final res = await _client
          .get(Uri.https(host, '/v1/currencies'))
          .timeout(_timeout);
      if (res.statusCode != 200) return;
      final json = _decode(res.body);
      if (json is! Map) return;
      _setCurrencies(json);
      await _prefs.setString(_currenciesKey, res.body);
    } on Exception {
      // Keep the cached list; the picker says when it is offline.
    }
  }

  void _setCurrencies(Map<dynamic, dynamic> json) {
    _currencies = {
      for (final e in json.entries)
        if (e.key is String && e.value is String && e.key != base)
          e.key as String: e.value as String,
    };
    notifyListeners();
  }

  Future<RateQuote?> _fetchLatest(String quote) async {
    try {
      final res = await _client
          .get(Uri.https(host, '/v1/latest', {'base': base, 'symbols': quote}))
          .timeout(_timeout);
      if (res.statusCode != 200) return null;
      return parseFrankfurterLatest(
        res.body,
        quote: quote,
        fetchedAt: DateTime.now(),
      );
    } on Exception {
      return null;
    }
  }

  static Object? _decode(String? raw) {
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }
}
