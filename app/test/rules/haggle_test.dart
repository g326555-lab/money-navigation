import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/haggle.dart';

import 'fixtures/market_items_fixture.dart';

HeardPrice _heard(String text, [List<MarketItem> items = allFixtureItems]) {
  final heard = parseHeardPrice(text, items);
  expect(heard, isNotNull, reason: 'expected an amount in "$text"');
  return heard!;
}

void main() {
  group('Demo scene 2: "มะม่วงกิโลละ 150" against mango 60-80 per kg', () {
    test('parses item mango, amount 150, unit perKg', () {
      final heard = _heard('มะม่วงกิโลละ 150', mangoOnly);
      expect(heard.item?.key, 'mango');
      expect(heard.amount, 150);
      expect(heard.unit, PriceUnit.perKg);
    });

    test('verdict high, over by 70, counter-offer 80', () {
      final heard = _heard('มะม่วงกิโลละ 150', mangoOnly);
      final verdict = judgePrice(heard, mangoFixture);
      expect(verdict, isNotNull);
      expect(verdict!.verdict, PriceVerdict.high);
      expect(verdict.overBy, 70);
      expect(verdict.counterOffer, 80);
    });

    test('same result when the price is spoken in words', () {
      final heard = _heard('มะม่วงกิโลละร้อยห้าสิบบาท', mangoOnly);
      expect(heard.amount, 150);
      final verdict = judgePrice(heard, mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.high);
      expect(verdict.overBy, 70);
      expect(verdict.counterOffer, 80);
    });
  });

  group('judgePrice: fair and low', () {
    test('"มะม่วงกิโลละ 70" is fair, overBy 0, no counter-offer', () {
      final verdict = judgePrice(_heard('มะม่วงกิโลละ 70'), mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.fair);
      expect(verdict.overBy, 0);
      expect(verdict.counterOffer, isNull);
    });

    test('"มะม่วงกิโลละ 40" is low, overBy 0, no counter-offer', () {
      final verdict = judgePrice(_heard('มะม่วงกิโลละ 40'), mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.low);
      expect(verdict.overBy, 0);
      expect(verdict.counterOffer, isNull);
    });
  });

  group('judgePrice: range boundaries are inclusive', () {
    test('amount equal to high (80) is fair', () {
      const heard = HeardPrice(
        amount: 80,
        item: mangoFixture,
        unit: PriceUnit.perKg,
      );
      final verdict = judgePrice(heard, mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.fair);
      expect(verdict.counterOffer, isNull);
    });

    test('amount equal to low (60) is fair', () {
      const heard = HeardPrice(
        amount: 60,
        item: mangoFixture,
        unit: PriceUnit.perKg,
      );
      expect(judgePrice(heard, mangoFixture)!.verdict, PriceVerdict.fair);
    });

    test('80.50 is high, overBy 0.5, counter-offer 80', () {
      const heard = HeardPrice(
        amount: 80.5,
        item: mangoFixture,
        unit: PriceUnit.perKg,
      );
      final verdict = judgePrice(heard, mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.high);
      expect(verdict.overBy, closeTo(0.5, 1e-9));
      expect(verdict.counterOffer, 80);
    });

    test('59 is low', () {
      const heard = HeardPrice(
        amount: 59,
        item: mangoFixture,
        unit: PriceUnit.perKg,
      );
      expect(judgePrice(heard, mangoFixture)!.verdict, PriceVerdict.low);
    });
  });

  group('judgePrice: counter-offer rounding (down to a multiple of 5)', () {
    test('high 80 stays 80', () {
      const heard = HeardPrice(
        amount: 100,
        item: mangoFixture,
        unit: PriceUnit.perKg,
      );
      expect(judgePrice(heard, mangoFixture)!.counterOffer, 80);
    });

    test('high 83 rounds down to 80, overBy uses the unrounded high', () {
      const heard = HeardPrice(
        amount: 100,
        item: oddHighFixture,
        unit: PriceUnit.perKg,
      );
      final verdict = judgePrice(heard, oddHighFixture)!;
      expect(verdict.verdict, PriceVerdict.high);
      expect(verdict.overBy, 17);
      expect(verdict.counterOffer, 80);
    });

    test(
      'counter-offer is never above the asked amount (asked 84, high 83)',
      () {
        const heard = HeardPrice(
          amount: 84,
          item: oddHighFixture,
          unit: PriceUnit.perKg,
        );
        final verdict = judgePrice(heard, oddHighFixture)!;
        expect(verdict.counterOffer, 80);
        expect(verdict.counterOffer!, lessThanOrEqualTo(heard.amount));
      },
    );
  });

  group('judgePrice: unit mismatch cannot be compared', () {
    test('"มะม่วงลูกละ 150" heard per piece, mango is per kg: null', () {
      final heard = _heard('มะม่วงลูกละ 150');
      expect(heard.item?.key, 'mango');
      expect(heard.unit, PriceUnit.each);
      expect(judgePrice(heard, mangoFixture), isNull);
    });

    test('"มะพร้าวกิโลละ 50" heard per kg, coconut is each: null', () {
      final heard = _heard('มะพร้าวกิโลละ 50');
      expect(heard.unit, PriceUnit.perKg);
      expect(judgePrice(heard, coconutFixture), isNull);
    });

    test('unit not said ("มะม่วง 150"): compared in the item unit, high', () {
      final heard = _heard('มะม่วง 150');
      expect(heard.unit, isNull);
      final verdict = judgePrice(heard, mangoFixture)!;
      expect(verdict.verdict, PriceVerdict.high);
      expect(verdict.overBy, 70);
      expect(verdict.counterOffer, 80);
    });
  });

  group('Second item (coconut 40-60 each): nothing is mango-specific', () {
    test('"มะพร้าวลูกละ 80" is coconut, each, high, over 20, counter 60', () {
      final heard = _heard('มะพร้าวลูกละ 80');
      expect(heard.item?.key, 'coconut');
      expect(heard.unit, PriceUnit.each);
      final verdict = judgePrice(heard, coconutFixture)!;
      expect(verdict.verdict, PriceVerdict.high);
      expect(verdict.overBy, 20);
      expect(verdict.counterOffer, 60);
    });

    test('"มะพร้าวลูกละ 50" is fair', () {
      final verdict = judgePrice(_heard('มะพร้าวลูกละ 50'), coconutFixture)!;
      expect(verdict.verdict, PriceVerdict.fair);
      expect(verdict.counterOffer, isNull);
    });

    test('"มะพร้าวลูกละ 30" is low', () {
      final verdict = judgePrice(_heard('มะพร้าวลูกละ 30'), coconutFixture)!;
      expect(verdict.verdict, PriceVerdict.low);
    });
  });

  group('parseHeardPrice: item matching', () {
    test('unknown item "ทุเรียนกิโลละ 150" with only mango: item null', () {
      final heard = _heard('ทุเรียนกิโลละ 150', mangoOnly);
      expect(heard.item, isNull);
      expect(heard.amount, 150);
      expect(heard.unit, PriceUnit.perKg);
    });

    test('longest keyword wins: "ข้าวผัดจานละ 60" is fried rice, not rice', () {
      final heard = _heard('ข้าวผัดจานละ 60');
      expect(heard.item?.key, 'fried_rice');
      expect(heard.unit, PriceUnit.perPlate);
    });

    test('longest keyword wins regardless of list order', () {
      final heard = _heard('ข้าวผัดจานละ 60', const [
        friedRiceFixture,
        riceFixture,
      ]);
      expect(heard.item?.key, 'fried_rice');
      final reversed = _heard('ข้าวผัดจานละ 60', const [
        riceFixture,
        friedRiceFixture,
      ]);
      expect(reversed.item?.key, 'fried_rice');
    });

    test('shorter keyword still matches alone: "ข้าวกิโลละ 40" is rice', () {
      expect(_heard('ข้าวกิโลละ 40').item?.key, 'rice');
    });

    test('empty item list: item null, amount still parsed', () {
      final heard = _heard('มะม่วงกิโลละ 150', const []);
      expect(heard.item, isNull);
      expect(heard.amount, 150);
    });
  });

  group('parseHeardPrice: unit words', () {
    test('"กิโล" is perKg', () {
      expect(_heard('มะม่วงกิโลละ 150').unit, PriceUnit.perKg);
    });
    test('"โล" is perKg', () {
      expect(_heard('มะม่วงโลละ 150').unit, PriceUnit.perKg);
    });
    test('"กก." is perKg', () {
      expect(_heard('มะม่วง กก.ละ 150').unit, PriceUnit.perKg);
    });
    for (final word in ['ลูก', 'อัน', 'ชิ้น', 'ตัว', 'ผืน']) {
      test('"$word" is each', () {
        expect(_heard('$wordละ 100').unit, PriceUnit.each);
      });
    }
    test('"จาน" is perPlate', () {
      expect(_heard('จานละ 60').unit, PriceUnit.perPlate);
    });
    test('"ชั่วโมง" is perHour', () {
      expect(_heard('ชั่วโมงละ 300').unit, PriceUnit.perHour);
    });
    test('"ชม." is perHour', () {
      expect(_heard('ชม.ละ 300').unit, PriceUnit.perHour);
    });
    test('"เที่ยว" is perRide', () {
      expect(_heard('เที่ยวละ 100').unit, PriceUnit.perRide);
    });
    test('no unit word: unit null', () {
      expect(_heard('ห้าสิบบาท').unit, isNull);
    });
    test('"มะม่วง 2 กิโล 250 บาท": unit perKg, amount 250', () {
      final heard = _heard('มะม่วง 2 กิโล 250 บาท');
      expect(heard.unit, PriceUnit.perKg);
      expect(heard.amount, 250);
    });
  });

  group('parseHeardPrice: no amount returns null', () {
    test('empty string', () {
      expect(parseHeardPrice('', allFixtureItems), isNull);
    });
    test('"ไม่แพง"', () {
      expect(parseHeardPrice('ไม่แพง', allFixtureItems), isNull);
    });
    test('item and unit but no price: "มะม่วงกิโลละ"', () {
      expect(parseHeardPrice('มะม่วงกิโลละ', allFixtureItems), isNull);
    });
  });

  group('parseHeardPrice: added unit words', () {
    test('"น้ำปั่นแก้วละ 50": "แก้ว" (drink) is each', () {
      final heard = _heard('น้ำปั่นแก้วละ 50');
      expect(heard.unit, PriceUnit.each);
      expect(heard.amount, 50);
    });

    test('"ข้าวเหนียวมะม่วงกล่องละ 120": "กล่อง" is perPlate, item is '
        'mango sticky rice, not mango', () {
      final heard = _heard('ข้าวเหนียวมะม่วงกล่องละ 120', const [
        mangoFixture,
        mangoStickyRiceFixture,
      ]);
      expect(heard.unit, PriceUnit.perPlate);
      expect(heard.amount, 120);
      expect(heard.item?.key, 'mango_sticky_rice');
    });
  });

  group('parseHeardPrice: "โลละ" short form', () {
    test('"มะม่วงโลละ 150" is mango, perKg, 150', () {
      final heard = _heard('มะม่วงโลละ 150', mangoOnly);
      expect(heard.item?.key, 'mango');
      expect(heard.unit, PriceUnit.perKg);
      expect(heard.amount, 150);
    });
  });
}
