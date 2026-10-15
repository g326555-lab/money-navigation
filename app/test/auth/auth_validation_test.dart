import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/services/auth/auth_validation.dart';

void main() {
  group('checkEmail', () {
    test('accepts a plain address', () {
      expect(checkEmail('name@example.com'), isNull);
    });

    test('accepts surrounding whitespace (trimmed)', () {
      expect(checkEmail(' name@example.com '), isNull);
      expect(checkEmail('\tname@example.com\n'), isNull);
    });

    test('accepts subdomains, plus tags and mixed case', () {
      expect(checkEmail('first.last+trip@mail.example.co.uk'), isNull);
      expect(checkEmail('Name@Example.COM'), isNull);
    });

    test('empty and whitespace-only are empty, not malformed', () {
      expect(checkEmail(''), EmailProblem.empty);
      expect(checkEmail('   '), EmailProblem.empty);
    });

    test('domain without a dot is malformed', () {
      expect(checkEmail('a@b'), EmailProblem.malformed);
    });

    test('more than one @ is malformed', () {
      expect(checkEmail('a@@b.com'), EmailProblem.malformed);
      expect(checkEmail('a@b@c.com'), EmailProblem.malformed);
    });

    test('inner spaces are malformed', () {
      expect(checkEmail('a b@c.com'), EmailProblem.malformed);
      expect(checkEmail('name@exam ple.com'), EmailProblem.malformed);
    });

    test('missing local part or missing @ is malformed', () {
      expect(checkEmail('@example.com'), EmailProblem.malformed);
      expect(checkEmail('name.example.com'), EmailProblem.malformed);
    });

    test('TLD must be at least two letters', () {
      expect(checkEmail('name@example.c'), EmailProblem.malformed);
      expect(checkEmail('name@example.c0'), EmailProblem.malformed);
      expect(checkEmail('name@example.'), EmailProblem.malformed);
    });
  });

  group('normalizeEmail', () {
    test('trims and lowercases', () {
      expect(normalizeEmail('  Name@Example.COM '), 'name@example.com');
    });

    test('leaves an already normal address unchanged', () {
      expect(normalizeEmail('name@example.com'), 'name@example.com');
    });
  });

  group('checkPassword', () {
    test('minimum length is 8', () {
      expect(minPasswordLength, 8);
    });

    test('empty is empty', () {
      expect(checkPassword(''), PasswordProblem.empty);
    });

    test('7 characters is too short, 8 is fine', () {
      expect(checkPassword('abcdefg'), PasswordProblem.tooShort);
      expect(checkPassword('abcdefgh'), isNull);
      expect(checkPassword('a much longer passphrase'), isNull);
    });

    test('does not trim: spaces count toward the length', () {
      expect(checkPassword(' '), PasswordProblem.tooShort);
      expect(checkPassword('        '), isNull);
      expect(checkPassword(' abcdef '), isNull);
      expect(checkPassword(' abcde '), PasswordProblem.tooShort);
    });
  });
}
