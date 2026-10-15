import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

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
    final http.Response res;
    try {
      res = await _client
          .post(
            Uri.parse('$_url/functions/v1/$name'),
            headers: {
              'Authorization': 'Bearer $_anonKey',
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
}

class CloudFunctionError implements Exception {
  const CloudFunctionError(this.reason);

  final String reason;

  @override
  String toString() => 'CloudFunctionError($reason)';
}
