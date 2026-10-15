import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../rules/facts_cache.dart';

/// The facts the server re-checks every day (facts-refresh), kept on the
/// phone for [factsMaxAge]. Opening the app after that asks again in the
/// background; offline the last copy stays, and with none the bundled file
/// is used as it is.
class FactsRepository extends ChangeNotifier {
  FactsRepository({SharedPreferencesAsync? prefs, http.Client? client})
    : _prefs = prefs ?? SharedPreferencesAsync(),
      _client = client ?? http.Client();

  static const _cacheKey = 'assist.factsSnapshot';
  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  static const timeout = Duration(seconds: 6);

  final SharedPreferencesAsync _prefs;
  final http.Client _client;

  FactsSnapshot? _snapshot;
  FactsSnapshot? get snapshot => _snapshot;

  /// The last fetch failed; [snapshot] is an older copy or null.
  bool _offline = false;
  bool get offline => _offline;

  List<LiveFact> get facts => _snapshot?.facts ?? const [];

  /// Reads the phone's copy, then refreshes it when older than a day.
  Future<void> load({DateTime? now}) async {
    try {
      final raw = await _prefs.getString(_cacheKey);
      _snapshot = raw == null ? null : FactsSnapshot.decode(raw);
    } on Object {
      _snapshot = null;
    }
    notifyListeners();
    final at = now ?? DateTime.now();
    if (_snapshot == null || _snapshot!.isStale(at)) await refresh(now: at);
  }

  /// Asks the server for the current facts.
  Future<void> refresh({DateTime? now}) async {
    if (_url.isEmpty || _anonKey.isEmpty) return;
    try {
      final res = await _client
          .get(
            Uri.parse('$_url/rest/v1/facts?select=*'),
            headers: {'apikey': _anonKey, 'Authorization': 'Bearer $_anonKey'},
          )
          .timeout(timeout);
      if (res.statusCode != 200) throw StateError('${res.statusCode}');
      final rows = jsonDecode(utf8.decode(res.bodyBytes));
      if (rows is! List) throw const FormatException('not a list');
      final snapshot = FactsSnapshot(
        facts: [
          for (final r in rows)
            if (r is Map) ?LiveFact.fromRow(Map<String, Object?>.from(r)),
        ],
        savedAt: now ?? DateTime.now(),
      );
      _snapshot = snapshot;
      _offline = false;
      try {
        await _prefs.setString(_cacheKey, snapshot.encode());
      } on Object {
        // Kept for this session.
      }
    } on Object {
      _offline = true;
    }
    notifyListeners();
  }
}
