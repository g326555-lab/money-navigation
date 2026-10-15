import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/demo_rates.dart';

/// The bundled fixed demo rate file. `flutter test` runs from app/.
String _assetJson() => File('assets/data/demo_rates.json').readAsStringSync();

void main() {
  group('parseDemoRates: bundled asset', () {
    test('reads the date of the fixed demo rates', () {
      final rates = parseDemoRates(_assetJson());
      expect(rates, isNotNull);
      expect(rates!.date, '2026-10-15');
    });

    test('THB to JPY is 4.6935, dated 2026-10-15', () {
      final q = parseDemoRates(_assetJson())!.quoteFor('THB', 'JPY');
      expect(q, isNotNull);
      expect(q!.base, 'THB');
      expect(q.quote, 'JPY');
      expect(q.rate, closeTo(4.6935, 1e-12));
      expect(q.date, '2026-10-15');
    });

    test('quotes lists every pair in the file', () {
      final quotes = parseDemoRates(_assetJson())!.quotes;
      expect(quotes, hasLength(1));
      expect(quotes.single.base, 'THB');
      expect(quotes.single.quote, 'JPY');
    });

    test('an unknown pair gives null', () {
      final rates = parseDemoRates(_assetJson())!;
      expect(rates.quoteFor('THB', 'USD'), isNull);
      expect(rates.quoteFor('USD', 'THB'), isNull);
    });

    test('the reverse direction is not invented', () {
      expect(parseDemoRates(_assetJson())!.quoteFor('JPY', 'THB'), isNull);
    });
  });

  group('parseDemoRates: bad input gives null, never a guess', () {
    String file(String rateJson) =>
        '{"source": "Fixed demo rate", "date": "2026-10-15", "rates": ['
        '{"base": "THB", "quote": "JPY"$rateJson}]}';

    test('malformed JSON', () {
      expect(parseDemoRates('{"date": "2026-10-15", "rates": ['), isNull);
    });

    test('empty string', () {
      expect(parseDemoRates(''), isNull);
    });

    test('missing rate', () {
      expect(parseDemoRates(file('')), isNull);
    });

    test('zero rate', () {
      expect(parseDemoRates(file(', "rate": 0')), isNull);
    });

    test('negative rate', () {
      expect(parseDemoRates(file(', "rate": -4.6935')), isNull);
    });

    test('non-finite rate (1e999 decodes to infinity)', () {
      expect(parseDemoRates(file(', "rate": 1e999')), isNull);
    });

    test('a valid file built the same way parses, so the cases above are '
        'rejected for the rate alone', () {
      final q = parseDemoRates(file(', "rate": 4.6935'))
          ?.quoteFor('THB', 'JPY');
      expect(q, isNotNull);
      expect(q!.rate, closeTo(4.6935, 1e-12));
    });
  });

  group('parseDemoRates: source', () {
    test('the bundled asset names its source', () {
      expect(parseDemoRates(_assetJson())!.source, 'Fixed demo rate');
    });

    test('a file without "source" gives null', () {
      expect(
        parseDemoRates(
          '{"date": "2026-10-15", "rates": ['
          '{"base": "THB", "quote": "JPY", "rate": 4.6935}]}',
        ),
        isNull,
      );
    });
  });
}
