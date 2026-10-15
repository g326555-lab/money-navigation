import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/services/auth/nonce.dart';

final _allowed = RegExp(r'^[0-9A-Za-z\-._]*$');

void main() {
  group('generateRawNonce', () {
    test('default length is 32', () {
      expect(generateRawNonce().length, 32);
    });

    test('honors a custom length exactly', () {
      expect(generateRawNonce(length: 1).length, 1);
      expect(generateRawNonce(length: 64).length, 64);
    });

    test('uses only 0-9 A-Z a-z - . _', () {
      final r = Random(7);
      for (var i = 0; i < 50; i++) {
        expect(generateRawNonce(length: 64, random: r), matches(_allowed));
      }
    });

    test('a seeded Random is deterministic', () {
      expect(
        generateRawNonce(random: Random(42)),
        generateRawNonce(random: Random(42)),
      );
    });

    test('two secure nonces differ', () {
      expect(
        generateRawNonce(random: Random.secure()),
        isNot(generateRawNonce(random: Random.secure())),
      );
    });

    test('default (no random given) also differs between calls', () {
      expect(generateRawNonce(), isNot(generateRawNonce()));
    });
  });

  group('sha256Hex', () {
    test('known vector: abc', () {
      expect(
        sha256Hex('abc'),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });

    test('known vector: empty string', () {
      expect(
        sha256Hex(''),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });

    test('known vector: 448-bit message', () {
      expect(
        sha256Hex('abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq'),
        '248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1',
      );
    });

    test('is 64 lowercase hex characters for a generated nonce', () {
      expect(
        sha256Hex(generateRawNonce(random: Random(1))),
        matches(RegExp(r'^[0-9a-f]{64}$')),
      );
    });
  });
}
