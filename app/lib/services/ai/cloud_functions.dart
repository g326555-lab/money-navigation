import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Calls the project's Supabase Edge Functions (Vision, Places, Cloud TTS,
/// Gemini). Keys stay in Supabase secrets; the app only knows the project
/// URL and the public anon key, passed with
/// `--dart-define-from-file=env/supabase.json`.
class CloudFunctions {
  CloudFunctions({http.Client? client}) : _client = client ?? http.Client();

  static const _url = String.fromEnvironment('SUPABASE_URL');
  static const _anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  final http.Client _client;

  /// False in a build made without the env file; callers then skip cloud AI.
  static bool get configured => _url.isNotEmpty && _anonKey.isNotEmpty;

  /// Posts [body] to function [name]. Throws [CloudFunctionError] on any
  /// failure, including [timeout], so callers have one thing to catch.
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    if (!configured) throw const CloudFunctionError('not configured');
    final token = await _callerToken() ?? _anonKey;
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$_url/functions/v1/$name'),
            headers: {
              'Authorization': 'Bearer $token',
              'apikey': _anonKey,
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(timeout);
    } on TimeoutException {
      throw const CloudFunctionError('timeout');
    } catch (e) {
      throw CloudFunctionError('offline: $e');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(utf8.decode(res.bodyBytes));
    } on FormatException {
      throw CloudFunctionError('bad response ${res.statusCode}');
    }
    if (decoded is! Map<String, dynamic>) {
      throw CloudFunctionError('bad response ${res.statusCode}');
    }
    if (res.statusCode != 200) {
      throw CloudFunctionError('${res.statusCode}: ${decoded['error']}');
    }
    return decoded;
  }

  static Future<AuthResponse>? _guestSignIn;

  /// The functions only answer a signed-in caller (the public anon key
  /// proves nothing). A traveler without an account gets an anonymous
  /// Supabase session the first time the app calls the cloud; account
  /// screens treat that session as signed out.
  static Future<String?> _callerToken() async {
    try {
      final auth = Supabase.instance.client.auth;
      final session = auth.currentSession;
      if (session != null) return session.accessToken;
      final pending = _guestSignIn ??= auth.signInAnonymously();
      try {
        return (await pending).session?.accessToken;
      } finally {
        _guestSignIn = null;
      }
    } on Object {
      return null; // Supabase not started (tests) or offline: the call fails cleanly.
    }
  }
}

class CloudFunctionError implements Exception {
  const CloudFunctionError(this.reason);

  final String reason;

  @override
  String toString() => 'CloudFunctionError($reason)';
}
