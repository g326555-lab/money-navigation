import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/exchange_rate.dart';

/// Body of GET https://api.frankfurter.dev/v1/latest?base=THB&symbols=USD,JPY
/// captured on 14 Oct 2026.
const frankfurterBody =
    '{"amount":1.0,"base":"THB","date":"2026-10-14",'
    '"rates":{"JPY":4.7195,"USD":0.02978}}';

final fetched = DateTime.utc(2026, 10, 15, 3);

void main() {
  group('parseFrankfurterLatest: real API body', () {
    test('reads THB to USD with the publication date', () {
      final q = parseFrankfurterLatest(
        frankfurterBody,
        quote: 'USD',
        fetchedAt: fetched,
      );
      expect(q, isNotNull);
      expect(q!.base, 'THB');
      expect(q.quote, 'USD');
      expect(q.rate, 0.02978);
      expect(q.date, '2026-10-14');
      expect(q.fetchedAt, fetched);
    });

    test('reads another symbol from the same body (no USD hard-coding)', () {
      final q = parseFrankfurterLatest(
        frankfurterBody,
        quote: 'JPY',
        fetchedAt: fetched,
      );
      expect(q!.quote, 'JPY');
      expect(q.rate, 4.7195);
    });

    test('integer rate is accepted as a number', () {
      final q = parseFrankfurterLatest(
        '{"amount":1,"base":"THB","date":"2026-10-14","rates":{"USD":1}}',
        quote: 'USD',
        fetchedAt: fetched,
      );
      expect(q!.rate, 1.0);
    });
  });

  group('parseFrankfurterLatest: bad bodies give null, never a default', () {
    RateQuote? parse(String body) =>
        parseFrankfurterLatest(body, quote: 'USD', fetchedAt: fetched);

    test('"not json" gives null', () => expect(parse('not json'), isNull));
    test('empty body gives null', () => expect(parse(''), isNull));
    test('JSON array gives null', () => expect(parse('[]'), isNull));
    test('symbols missing USD gives null', () {
      expect(
        parse(
          '{"amount":1.0,"base":"THB","date":"2026-10-14",'
          '"rates":{"JPY":4.7195}}',
        ),
        isNull,
      );
    });
    test('missing base gives null', () {
      expect(
        parse('{"amount":1.0,"date":"2026-10-14","rates":{"USD":0.02978}}'),
        isNull,
      );
    });
    test('missing date gives null', () {
      expect(
        parse('{"amount":1.0,"base":"THB","rates":{"USD":0.02978}}'),
        isNull,
      );
    });
    test('missing rates gives null', () {
      expect(parse('{"amount":1.0,"base":"THB","date":"2026-10-14"}'), isNull);
    });
    test('zero rate gives null', () {
      expect(
        parse(
          '{"amount":1.0,"base":"THB","date":"2026-10-14",'
          '"rates":{"USD":0}}',
        ),
        isNull,
      );
    });
    test('negative rate gives null', () {
      expect(
        parse(
          '{"amount":1.0,"base":"THB","date":"2026-10-14",'
          '"rates":{"USD":-0.03}}',
        ),
        isNull,
      );
    });
    test('string rate gives null', () {
      expect(
        parse(
          '{"amount":1.0,"base":"THB","date":"2026-10-14",'
          '"rates":{"USD":"0.02978"}}',
        ),
        isNull,
      );
    });
  });

  group('rateNeedsRefresh: one fetch per 24 hours', () {
    final q = parseFrankfurterLatest(
      frankfurterBody,
      quote: 'USD',
      fetchedAt: fetched,
    )!;

    test('max age is 24 hours', () {
      expect(rateMaxAge, const Duration(hours: 24));
    });
    test('no cached rate needs a refresh', () {
      expect(rateNeedsRefresh(null, fetched), isTrue);
    });
    test('fresh rate does not', () {
      expect(rateNeedsRefresh(q, fetched), isFalse);
    });
    test('23h59m old does not', () {
      expect(
        rateNeedsRefresh(
          q,
          fetched.add(const Duration(hours: 23, minutes: 59)),
        ),
        isFalse,
      );
    });
    test('exactly 24h old does', () {
      expect(
        rateNeedsRefresh(q, fetched.add(const Duration(hours: 24))),
        isTrue,
      );
    });
  });

  group('convertFromBase', () {
    final q = parseFrankfurterLatest(
      frankfurterBody,
      quote: 'USD',
      fetchedAt: fetched,
    )!;

    test('286 THB kept is 8.51708 USD at the 14 Oct rate', () {
      expect(convertFromBase(286, q), closeTo(8.51708, 1e-6));
    });
    test('0 THB is 0 USD', () {
      expect(convertFromBase(0, q), 0);
    });
  });

  group('RateQuote JSON cache', () {
    final q = parseFrankfurterLatest(
      frankfurterBody,
      quote: 'USD',
      fetchedAt: fetched,
    )!;

    test('round trip preserves every field', () {
      final back = RateQuote.fromJson(q.toJson())!;
      expect(back.base, 'THB');
      expect(back.quote, 'USD');
      expect(back.rate, 0.02978);
      expect(back.date, '2026-10-14');
      expect(back.fetchedAt.isAtSameMomentAs(fetched), isTrue);
    });
    test('not a map gives null', () {
      expect(RateQuote.fromJson('x'), isNull);
      expect(RateQuote.fromJson(null), isNull);
    });
    test('zero or negative rate gives null', () {
      expect(RateQuote.fromJson(q.toJson()..['rate'] = 0), isNull);
      expect(RateQuote.fromJson(q.toJson()..['rate'] = -1), isNull);
    });
    test('missing field gives null', () {
      for (final key in ['base', 'quote', 'rate', 'date', 'fetchedAt']) {
        expect(
          RateQuote.fromJson(q.toJson()..remove(key)),
          isNull,
          reason: 'missing $key',
        );
      }
    });
  });
}
