import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/personal_context.dart';

// Fixture from the real sample account (test.visitor). All local DateTime.
final DateTime oct13 = DateTime(2026, 10, 13, 15);
final DateTime oct15Morning = DateTime(2026, 10, 15, 11);
final DateTime now = DateTime(2026, 10, 15, 18);

final PastPurchase mango1 = PastPurchase(
  itemKey: 'mango',
  askedThb: 130,
  paidThb: 90,
  placeName: 'Chatuchak',
  at: oct13,
);
final PastPurchase mango2 = PastPurchase(
  itemKey: 'mango',
  askedThb: 150,
  paidThb: 110,
  placeName: 'Chatuchak',
  at: oct15Morning,
);
final List<PastPurchase> history = [mango1, mango2];

const TravelerProfile profile = TravelerProfile(
  cardFeePercent: 3,
  atmFeePolicy: AtmFeePolicy.chargesFixed,
  atmFeeValue: 5,
);
const double homeToThb = 32.6;
const double localAtmFee = 220;
const double withdrawal = 4000;

PastPurchase buy(
  String item,
  double paid,
  DateTime at, {
  double? asked,
  String? place,
  bool sample = false,
}) => PastPurchase(
  itemKey: item,
  paidThb: paid,
  askedThb: asked,
  placeName: place,
  at: at,
  isSample: sample,
);

void main() {
  group('priceMemory: sample account mango', () {
    late PriceMemory m;
    setUp(() => m = priceMemory('mango', history, now)!);

    test('last paid is the most recent purchase, 110', () {
      expect(m.itemKey, 'mango');
      expect(m.lastPaidThb, 110);
    });
    test('last place is Chatuchak', () => expect(m.lastPlaceName, 'Chatuchak'));
    test('bought earlier today is daysAgo 0', () => expect(m.daysAgo, 0));
    test('last asked is 150', () => expect(m.lastAskedThb, 150));
    test('last discount 40/150 = 26.67 rounds to 27', () {
      expect(m.lastDiscountPercent, 27);
    });
    test('min 90, max 110', () {
      expect(m.minPaidThb, 90);
      expect(m.maxPaidThb, 110);
    });
    test('uses 2 records, dates newest first', () {
      expect(m.recordsUsed, 2);
      expect(m.dates, [oct15Morning, oct13]);
    });
    test('samePlaceRecords is 0 when no placeName is given', () {
      expect(m.samePlaceRecords, 0);
    });
  });

  group('priceMemory: place, day boundary and filtering', () {
    test('placeName Chatuchak counts 2 same-place records', () {
      final m = priceMemory('mango', history, now, placeName: 'Chatuchak')!;
      expect(m.samePlaceRecords, 2);
      expect(m.recordsUsed, 2);
    });

    test('placeName elsewhere counts 0 same-place records', () {
      final m = priceMemory('mango', history, now, placeName: 'Or Tor Kor')!;
      expect(m.samePlaceRecords, 0);
      expect(m.recordsUsed, 2);
    });

    test('next morning 09:00 is daysAgo 1 (calendar days, not 24h)', () {
      final m = priceMemory('mango', history, DateTime(2026, 10, 16, 9))!;
      expect(m.daysAgo, 1);
    });

    test('late night to early morning is still daysAgo 1', () {
      final h = [buy('mango', 100, DateTime(2026, 10, 14, 23, 30))];
      final m = priceMemory('mango', h, DateTime(2026, 10, 15, 0, 30))!;
      expect(m.daysAgo, 1);
    });

    test('two days earlier is daysAgo 2', () {
      final m = priceMemory('mango', [mango1], now)!;
      expect(m.daysAgo, 2);
    });

    test('unknown item returns null', () {
      expect(priceMemory('durian', history, now), isNull);
    });

    test('empty history returns null', () {
      expect(priceMemory('mango', const [], now), isNull);
    });

    test('purchases after now are ignored', () {
      final h = [
        ...history,
        buy('mango', 50, DateTime(2026, 10, 16, 10), asked: 60),
      ];
      final m = priceMemory('mango', h, now)!;
      expect(m.lastPaidThb, 110);
      expect(m.minPaidThb, 90);
      expect(m.recordsUsed, 2);
    });

    test('only future purchases returns null', () {
      final h = [buy('mango', 50, DateTime(2026, 10, 16, 10))];
      expect(priceMemory('mango', h, now), isNull);
    });

    test('other items are ignored', () {
      final h = [...history, buy('coconut', 40, DateTime(2026, 10, 15, 12))];
      final m = priceMemory('mango', h, now)!;
      expect(m.recordsUsed, 2);
      expect(m.maxPaidThb, 110);
    });

    test('includeSamples false with all-sample data returns null', () {
      final h = [
        buy('mango', 90, oct13, asked: 130, sample: true),
        buy('mango', 110, oct15Morning, asked: 150, sample: true),
      ];
      expect(priceMemory('mango', h, now, includeSamples: false), isNull);
    });

    test('includeSamples defaults to true', () {
      final h = [buy('mango', 90, oct13, asked: 130, sample: true)];
      expect(priceMemory('mango', h, now)!.recordsUsed, 1);
    });

    test('includeSamples false keeps real records only', () {
      final h = [
        mango1,
        buy('mango', 110, oct15Morning, asked: 150, sample: true),
      ];
      final m = priceMemory('mango', h, now, includeSamples: false)!;
      expect(m.recordsUsed, 1);
      expect(m.lastPaidThb, 90);
      expect(m.dates, [oct13]);
    });

    test('no asked price gives null discount, not a guess', () {
      final m = priceMemory('mango', [buy('mango', 100, oct13)], now)!;
      expect(m.lastAskedThb, isNull);
      expect(m.lastDiscountPercent, isNull);
    });

    test('asked 0 gives null discount (no division by zero)', () {
      final m = priceMemory('mango', [
        buy('mango', 100, oct13, asked: 0),
      ], now)!;
      expect(m.lastDiscountPercent, isNull);
    });

    test('paid 0 or negative is invalid and ignored', () {
      final h = [
        ...history,
        buy('mango', 0, DateTime(2026, 10, 15, 12)),
        buy('mango', -20, DateTime(2026, 10, 15, 13)),
      ];
      final m = priceMemory('mango', h, now)!;
      expect(m.lastPaidThb, 110);
      expect(m.minPaidThb, 90);
      expect(m.recordsUsed, 2);
    });

    test('only invalid paid records returns null', () {
      expect(priceMemory('mango', [buy('mango', 0, oct13)], now), isNull);
    });
  });

  group('counterFromHistory: offer from the traveler\'s own discounts', () {
    test('sample mango asked 150 gives 105 from 2 records', () {
      final c = counterFromHistory('mango', 150, history, now)!;
      // Discounts 30.77 % and 26.67 % -> median 28.72 % -> 106.92 -> 105.
      expect(c.offerThb, 105);
      expect(c.medianDiscountPercent, closeTo(28.72, 0.01));
      expect(c.recordsUsed, 2);
      expect(c.dates, [oct15Morning, oct13]);
    });

    test('offer is rounded down to a multiple of 5', () {
      final c = counterFromHistory('mango', 150, history, now)!;
      expect(c.offerThb % 5, 0);
    });

    test('single record is enough', () {
      final c = counterFromHistory('mango', 100, [mango1], now)!;
      // 40/130 = 30.77 % -> 69.23 -> 65.
      expect(c.offerThb, 65);
      expect(c.recordsUsed, 1);
    });

    test('records without asked price are not used', () {
      final h = [...history, buy('mango', 60, DateTime(2026, 10, 14, 10))];
      expect(counterFromHistory('mango', 150, h, now)!.recordsUsed, 2);
    });

    test('records with asked 0 are not used', () {
      final h = [
        ...history,
        buy('mango', 60, DateTime(2026, 10, 14, 10), asked: 0),
      ];
      expect(counterFromHistory('mango', 150, h, now)!.recordsUsed, 2);
    });

    test('no records with asked price returns null', () {
      expect(
        counterFromHistory('mango', 150, [buy('mango', 90, oct13)], now),
        isNull,
      );
    });

    test('empty history returns null', () {
      expect(counterFromHistory('mango', 150, const [], now), isNull);
    });

    test('other item returns null', () {
      expect(counterFromHistory('durian', 300, history, now), isNull);
    });

    test('median discount 0 (paid what was asked) returns null', () {
      final h = [buy('mango', 100, oct13, asked: 100)];
      expect(counterFromHistory('mango', 150, h, now), isNull);
    });

    test('future purchases are ignored', () {
      final h = [
        mango1,
        buy('mango', 50, DateTime(2026, 10, 16, 10), asked: 150),
      ];
      expect(counterFromHistory('mango', 100, h, now)!.recordsUsed, 1);
    });

    test('paid 0 or negative is ignored', () {
      final h = [
        ...history,
        buy('mango', 0, DateTime(2026, 10, 14, 10), asked: 150),
      ];
      expect(counterFromHistory('mango', 150, h, now)!.offerThb, 105);
    });
  });

  group('cardOrCash: card fee vs share of an ATM withdrawal', () {
    test('sample profile: card 30.00, cash 95.75, card cheaper', () {
      final p = cardOrCash(
        1000,
        profile,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
        homeToThb: homeToThb,
      )!;
      expect(p.cardCostThb, closeTo(30.00, 1e-9));
      // (220 + 5 * 32.6) * 1000 / 4000 = 95.75
      expect(p.cashCostThb, closeTo(95.75, 1e-9));
      expect(p.cheaper, PayWay.card);
    });

    test('basis names the profile fields used', () {
      final p = cardOrCash(
        1000,
        profile,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
        homeToThb: homeToThb,
      )!;
      expect(
        p.basis,
        containsAll(<String>['cardFeePercent', 'atmFeePolicy', 'atmFeeValue']),
      );
    });

    test('unknown ATM policy: cash null, cheaper unknown', () {
      const prof = TravelerProfile(cardFeePercent: 3);
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
        homeToThb: homeToThb,
      )!;
      expect(p.cardCostThb, closeTo(30.00, 1e-9));
      expect(p.cashCostThb, isNull);
      expect(p.cheaper, PayWay.unknown);
    });

    test('refundsFees: cash 0 (local fee refunded too), cash cheaper', () {
      const prof = TravelerProfile(
        cardFeePercent: 3,
        atmFeePolicy: AtmFeePolicy.refundsFees,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
      )!;
      expect(p.cashCostThb, 0);
      expect(p.cheaper, PayWay.cash);
    });

    test('noFee: local ATM fee still applies, 220 * 1000/4000 = 55', () {
      const prof = TravelerProfile(
        cardFeePercent: 3,
        atmFeePolicy: AtmFeePolicy.noFee,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
      )!;
      expect(p.cashCostThb, closeTo(55.00, 1e-9));
      expect(p.cheaper, PayWay.card);
    });

    test('chargesPercent 1 %: (220 + 40) * 1000/4000 = 65', () {
      const prof = TravelerProfile(
        cardFeePercent: 3,
        atmFeePolicy: AtmFeePolicy.chargesPercent,
        atmFeeValue: 1,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
      )!;
      expect(p.cashCostThb, closeTo(65.00, 1e-9));
    });

    test('costs within 0.5 THB are reported as same', () {
      // Card 5.5 % of 1000 = 55, cash (noFee) = 55.
      const prof = TravelerProfile(
        cardFeePercent: 5.5,
        atmFeePolicy: AtmFeePolicy.noFee,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
      )!;
      expect(p.cheaper, PayWay.same);
    });

    test('costs within 0.4 THB still same; cash 55, card 55.4', () {
      const prof = TravelerProfile(
        cardFeePercent: 5.54,
        atmFeePolicy: AtmFeePolicy.noFee,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
      )!;
      expect(p.cardCostThb, closeTo(55.40, 1e-9));
      expect(p.cheaper, PayWay.same);
    });

    test('cash cheaper when card fee is high', () {
      const prof = TravelerProfile(
        cardFeePercent: 12,
        atmFeePolicy: AtmFeePolicy.chargesFixed,
        atmFeeValue: 5,
      );
      final p = cardOrCash(
        1000,
        prof,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
        homeToThb: homeToThb,
      )!;
      expect(p.cardCostThb, closeTo(120.00, 1e-9));
      expect(p.cheaper, PayWay.cash);
    });

    test('costs are rounded to 2 decimals', () {
      // 3 % of 333.33 = 9.9999 -> 10.00
      final p = cardOrCash(
        333.33,
        profile,
        localAtmFeeThb: localAtmFee,
        withdrawalThb: withdrawal,
        homeToThb: homeToThb,
      )!;
      expect(p.cardCostThb, 10.00);
      // 383 * 333.33 / 4000 = 31.9163... -> 31.92
      expect(p.cashCostThb, 31.92);
    });

    test('cardFeePercent null returns null', () {
      const prof = TravelerProfile(atmFeePolicy: AtmFeePolicy.noFee);
      expect(
        cardOrCash(
          1000,
          prof,
          localAtmFeeThb: localAtmFee,
          withdrawalThb: withdrawal,
        ),
        isNull,
      );
    });
  });

  group('morningCash: estimate from the traveler\'s own daily spend', () {
    final List<PastPurchase> days = [
      buy('mango', 90, DateTime(2026, 10, 13, 15)),
      buy('noodles', 200, DateTime(2026, 10, 14, 12)),
      buy('water', 50, DateTime(2026, 10, 14, 19)),
    ];

    test('totals 90 and 250 -> median 170 -> rounded up to 200', () {
      final c = morningCash(days, now)!;
      expect(c.amountThb, 200);
      expect(c.daysUsed, 2);
      expect(c.isEstimate, isTrue);
      expect(c.days.length, 2);
    });

    test('same-day purchases are excluded', () {
      final h = [...days, buy('massage', 500, DateTime(2026, 10, 15, 9))];
      final c = morningCash(h, now)!;
      expect(c.amountThb, 200);
      expect(c.daysUsed, 2);
    });

    test('one past day only returns null', () {
      expect(morningCash([days.first], now), isNull);
    });

    test('one past day plus today returns null', () {
      final h = [days.first, buy('massage', 500, DateTime(2026, 10, 15, 9))];
      expect(morningCash(h, now), isNull);
    });

    test('empty history returns null', () {
      expect(morningCash(const [], now), isNull);
    });

    test('odd count uses the middle total: 90, 250, 410 -> 250 -> 300', () {
      final h = [...days, buy('dinner', 410, DateTime(2026, 10, 12, 20))];
      final c = morningCash(h, now)!;
      expect(c.amountThb, 300);
      expect(c.daysUsed, 3);
    });

    test('exact hundreds stay as they are', () {
      final h = [
        buy('a', 200, DateTime(2026, 10, 13, 10)),
        buy('b', 200, DateTime(2026, 10, 14, 10)),
      ];
      expect(morningCash(h, now)!.amountThb, 200);
    });

    test('only the last 7 days with purchases are used', () {
      final h = <PastPurchase>[
        // Two old expensive days that must be dropped.
        buy('hotel', 5000, DateTime(2026, 10, 1, 10)),
        buy('hotel', 5000, DateTime(2026, 10, 2, 10)),
        // Seven recent days of 100 each.
        for (var d = 8; d <= 14; d++)
          buy('food', 100, DateTime(2026, 10, d, 12)),
      ];
      final c = morningCash(h, now)!;
      expect(c.daysUsed, 7);
      expect(c.amountThb, 100);
    });

    test('days with gaps still count as purchase days', () {
      final h = [
        buy('a', 90, DateTime(2026, 10, 5, 10)),
        buy('b', 250, DateTime(2026, 10, 11, 10)),
      ];
      final c = morningCash(h, now)!;
      expect(c.daysUsed, 2);
      expect(c.amountThb, 200);
    });

    test('paid 0 or negative is ignored', () {
      final h = [...days, buy('refund', -1000, DateTime(2026, 10, 14, 20))];
      expect(morningCash(h, now)!.amountThb, 200);
    });

    test('day with only invalid purchases does not count as a day', () {
      final h = [days.first, buy('x', 0, DateTime(2026, 10, 14, 10))];
      expect(morningCash(h, now), isNull);
    });
  });

  group('cloudSafeSummary: what may leave the device', () {
    test('never contains a place name', () {
      final s = cloudSafeSummary(history, now);
      expect(jsonEncode(s).contains('Chatuchak'), isFalse);
    });

    test('count matches and purchases are newest first', () {
      final s = cloudSafeSummary(history, now);
      expect(s['count'], 2);
      final list = s['purchases']! as List;
      expect(list.length, 2);
      final first = list[0] as Map;
      final second = list[1] as Map;
      expect(first['item'], 'mango');
      expect(first['paid'], 110);
      expect(first['asked'], 150);
      expect(first['daysAgo'], 0);
      expect(second['paid'], 90);
      expect(second['asked'], 130);
      expect(second['daysAgo'], 2);
    });

    test('prices are rounded to the nearest baht', () {
      final h = [buy('mango', 89.6, oct13, asked: 129.4, place: 'Chatuchak')];
      final p = (cloudSafeSummary(h, now)['purchases']! as List).single as Map;
      expect(p['paid'], 90);
      expect(p['asked'], 129);
    });

    test('only allowed keys per purchase', () {
      final s = cloudSafeSummary(history, now);
      for (final p in s['purchases']! as List) {
        expect(
          (p as Map).keys.toSet().difference({
            'item',
            'paid',
            'asked',
            'daysAgo',
          }),
          isEmpty,
        );
      }
    });

    test('at most 10 purchases, count is the total', () {
      final h = [
        for (var i = 0; i < 14; i++)
          buy(
            'mango',
            100 + i.toDouble(),
            DateTime(2026, 10, 1 + i, 12),
            place: 'Chatuchak',
          ),
      ];
      final s = cloudSafeSummary(h, now);
      final list = s['purchases']! as List;
      expect(list.length, 10);
      expect(s['count'], 14);
      expect((list.first as Map)['paid'], 113);
      expect(jsonEncode(s).contains('Chatuchak'), isFalse);
    });

    test('empty history gives count 0 and no purchases', () {
      final s = cloudSafeSummary(const [], now);
      expect(s['count'], 0);
      expect(s['purchases'], isEmpty);
    });
  });
}
