import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../rules/cash_exchange.dart';
import '../services/ai/cloud_functions.dart';

/// Reads the 15-minute server cache of the publicly licensed ThaiRate feed.
/// It never calls ThaiRate from the phone, so device count cannot multiply
/// upstream API requests.
class CashExchangeRepository {
  CashExchangeRepository({
    SharedPreferencesAsync? preferences,
    CloudFunctions? functions,
    DateTime Function()? clock,
  }) : _preferences = preferences ?? SharedPreferencesAsync(),
       _functions = functions ?? CloudFunctions(),
       _clock = clock ?? DateTime.now;

  static const _cacheKey = 'cash_exchange_snapshot_v1';
  static const _timeout = Duration(seconds: 8);
  static const _reuseRemoteFor = Duration(minutes: 1);

  final SharedPreferencesAsync _preferences;
  final CloudFunctions _functions;
  final DateTime Function() _clock;
  Map<String, dynamic>? _memory;

  /// The latest server response with `stale` re-evaluated against the phone
  /// clock, the last saved copy when offline, or null when nothing was ever
  /// loaded. Never throws.
  Future<Map<String, dynamic>?> load({bool force = false}) async {
    final cached = _memory ?? await _readCache();
    if (cached != null) _memory = cached;
    if (!force && cached != null && _isRecent(cached, _reuseRemoteFor)) {
      return _withCurrentStaleFlag(cached);
    }
    final Map<String, dynamic> fresh;
    try {
      fresh = await _functions.call(
        'exchange-rates',
        const {},
        timeout: _timeout,
      );
    } on CloudFunctionError {
      return cached == null ? null : _withCurrentStaleFlag(cached);
    }
    _memory = fresh;
    try {
      await _preferences.setString(_cacheKey, jsonEncode(fresh));
    } on Exception {
      // A failed disk write only loses the offline copy, not this answer.
    }
    return _withCurrentStaleFlag(fresh);
  }

  Future<Map<String, dynamic>?> _readCache() async {
    try {
      return _decode(await _preferences.getString(_cacheKey));
    } on Exception {
      return null;
    }
  }

  Map<String, dynamic>? _decode(String? value) {
    if (value == null) return null;
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }

  DateTime? _refreshedAt(Map<String, dynamic> response) {
    final value = response['refreshedAt'];
    return value is String ? DateTime.tryParse(value) : null;
  }

  bool _isRecent(Map<String, dynamic> response, Duration duration) {
    final date = _refreshedAt(response);
    if (date == null) return false;
    final age = _clock().toUtc().difference(date.toUtc());
    return !age.isNegative && age < duration;
  }

  Map<String, dynamic> _withCurrentStaleFlag(Map<String, dynamic> response) {
    final data = response['data'];
    final generated = data is Map && data['generatedAt'] is String
        ? DateTime.tryParse(data['generatedAt'] as String)
        : null;
    final stale =
        response['stale'] == true ||
        generated == null ||
        !isExchangeTimeFresh(
          _refreshedAt(response),
          _clock(),
          exchangeRatesSnapshotFreshness,
        );
    return {...response, 'stale': stale};
  }
}
