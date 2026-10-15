import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Sign in with Apple replay protection: Apple receives the SHA-256 of a
/// fresh random nonce and puts it in the ID token; Supabase receives the raw
/// nonce and checks that the two match.
const _nonceCharset =
    '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-._';

String generateRawNonce({int length = 32, Random? random}) {
  final source = random ?? Random.secure();
  return List.generate(
    length,
    (_) => _nonceCharset[source.nextInt(_nonceCharset.length)],
  ).join();
}

String sha256Hex(String input) => sha256.convert(utf8.encode(input)).toString();
