// Item matcher: picks the market item from Thai speech transcripts.
//
// Expected sound-alike confidences below were worked out by hand from the
// rule (consonant skeleton, sound-alike groups, same-length window, edit
// similarity x 0.8, threshold 0.6). Skeletons used:
//   มะม่วง MMวG   ผัดไทย PDTย   ทักทาย TกTย   ผัด PD   มันลง MNRG
// ทักทาย vs ผัดไทย: 2 edits in 4 -> 0.5 x 0.8 = 0.4, below 0.6, so a
// sound-alike match cannot rescue it and the expected result is null.

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/services/ai/item_matcher.dart';

import 'fixtures/market_items_fixture.dart';

void main() {
  test('threshold is 0.6', () => expect(itemMatchThreshold, 0.6));

  group('matchItem: exact keyword', () {
    test('"มะม่วงกิโลละ 150" is mango, 1.0, keyword', () {
      final m = matchItem(['มะม่วงกิโลละ 150'], matcherItems)!;
      expect(m.item.key, 'mango');
      expect(m.confidence, 1.0);
      expect(m.reason, MatchReason.keyword);
    });

    test('"ผัดไทยจานละ 60" is pad thai, 1.0, keyword', () {
      final m = matchItem(['ผัดไทยจานละ 60'], matcherItems)!;
      expect(m.item.key, 'pad_thai');
      expect(m.confidence, 1.0);
      expect(m.reason, MatchReason.keyword);
    });

    test('longest keyword wins: ข้าวเหนียวมะม่วง beats มะม่วง', () {
      final m = matchItem(['ข้าวเหนียวมะม่วงกล่องละ 120'], matcherItems)!;
      expect(m.item.key, 'mango_sticky_rice');
      expect(m.reason, MatchReason.keyword);
    });

    test('longest keyword wins regardless of list order', () {
      final m = matchItem(
        ['ข้าวเหนียวมะม่วงกล่องละ 120'],
        const [mangoStickyRiceFixture, mangoFixture],
      )!;
      expect(m.item.key, 'mango_sticky_rice');
    });
  });

  group('matchItem: logged mishearings with heardAs aliases', () {
    for (final heard in ['มันหมุน', 'น้ำมัน', 'งั้นมึง']) {
      test('"$heardกิโลละ 150" is mango, 0.9, heardAs', () {
        final m = matchItem(
          ['$heardกิโลละ 150'],
          matcherItems,
          heardAs: loggedHeardAs,
        )!;
        expect(m.item.key, 'mango');
        expect(m.confidence, closeTo(0.9, 1e-9));
        expect(m.reason, MatchReason.heardAs);
      });
    }

    test('"ทักทายจานละ 60" is pad thai, 0.9, heardAs', () {
      final m = matchItem(
        ['ทักทายจานละ 60'],
        matcherItems,
        heardAs: loggedHeardAs,
      )!;
      expect(m.item.key, 'pad_thai');
      expect(m.confidence, closeTo(0.9, 1e-9));
      expect(m.reason, MatchReason.heardAs);
    });

    test('a keyword beats an alias in the same transcript', () {
      final m = matchItem(
        ['มันหมุน ผัดไทยจานละ 60'],
        matcherItems,
        heardAs: loggedHeardAs,
      )!;
      expect(m.item.key, 'pad_thai');
      expect(m.reason, MatchReason.keyword);
    });
  });

  group('matchItem: logged mishearings that are NOT aliases give null', () {
    // Sound-alike scores (hand-computed): องค์ 0.0, มัน 0.2, มันลง 0.4,
    // ผัด 0.4. All below 0.6. Guessing would be worse than asking again.
    for (final heard in [
      'องค์กิโลละ 150',
      'มันกิโลละ 150',
      'มันลงกิโลละ 150',
    ]) {
      test('"$heard" is null', () {
        expect(
          matchItem([heard], matcherItems, heardAs: loggedHeardAs),
          isNull,
        );
      });
    }
    test('"ผัดจานละ 60" is null', () {
      expect(
        matchItem(['ผัดจานละ 60'], matcherItems, heardAs: loggedHeardAs),
        isNull,
      );
    });
  });

  group('matchItem: sound-alike without aliases', () {
    test(
      '"ทักทายจานละ 60" with unit perPlate is null (skeleton score 0.4)',
      () {
        expect(
          matchItem(['ทักทายจานละ 60'], matcherItems, unit: PriceUnit.perPlate),
          isNull,
        );
      },
    );

    test('"มะมวงกิโลละ 150" (tone mark lost) is mango, 0.8, soundAlike', () {
      final m = matchItem(['มะมวงกิโลละ 150'], matcherItems)!;
      expect(m.item.key, 'mango');
      expect(m.confidence, closeTo(0.8, 1e-9));
      expect(m.reason, MatchReason.soundAlike);
    });

    test('"พัดไทยจานละ 60" (พ for ผ, same group) is pad thai, 0.8, '
        'soundAlike', () {
      final m = matchItem(['พัดไทยจานละ 60'], matcherItems)!;
      expect(m.item.key, 'pad_thai');
      expect(m.confidence, closeTo(0.8, 1e-9));
      expect(m.reason, MatchReason.soundAlike);
    });
  });

  group('matchItem: no match gives null', () {
    test('durian (not in the list) "ทุเรียนกิโลละ 150" is null', () {
      expect(matchItem(['ทุเรียนกิโลละ 150'], matcherItems), isNull);
    });
    test('"สวัสดี" is null', () {
      expect(matchItem(['สวัสดี'], matcherItems), isNull);
    });
    test('no alternatives is null', () {
      expect(matchItem(const [], matcherItems), isNull);
    });
    test('empty strings are null', () {
      expect(matchItem(['', ''], matcherItems), isNull);
    });
    test('empty item list is null', () {
      expect(matchItem(['มะม่วงกิโลละ 150'], const []), isNull);
    });
  });

  group('matchItem: every alternative is scored', () {
    test('second alternative with the keyword wins over an empty first', () {
      final m = matchItem(['สวัสดี', 'มะม่วงกิโลละ 150'], matcherItems)!;
      expect(m.item.key, 'mango');
      expect(m.confidence, 1.0);
      expect(m.reason, MatchReason.keyword);
    });

    test('a later keyword (1.0) beats an earlier alias (0.9)', () {
      final m = matchItem(
        ['ทักทายจานละ 60', 'มะม่วงกิโลละ 150'],
        matcherItems,
        heardAs: loggedHeardAs,
      )!;
      expect(m.item.key, 'mango');
      expect(m.reason, MatchReason.keyword);
    });
  });

  group('matchItem: unit filter', () {
    test('unit perPlate excludes mango: "มะม่วงกิโลละ 150" is null', () {
      expect(
        matchItem(['มะม่วงกิโลละ 150'], matcherItems, unit: PriceUnit.perPlate),
        isNull,
      );
    });

    test('unit perPlate excludes a mango alias too', () {
      expect(
        matchItem(
          ['มันหมุน'],
          matcherItems,
          heardAs: loggedHeardAs,
          unit: PriceUnit.perPlate,
        ),
        isNull,
      );
    });

    test('unit perKg excludes sticky rice, so mango is matched', () {
      final m = matchItem(
        ['ข้าวเหนียวมะม่วงกิโลละ 120'],
        matcherItems,
        unit: PriceUnit.perKg,
      )!;
      expect(m.item.key, 'mango');
      expect(m.reason, MatchReason.keyword);
    });

    test('unit perPlate keeps pad thai', () {
      final m = matchItem(
        ['ผัดไทยจานละ 60'],
        matcherItems,
        unit: PriceUnit.perPlate,
      )!;
      expect(m.item.key, 'pad_thai');
    });
  });

  group('matchItem: ties keep the earlier item', () {
    const mangoCopy = MarketItem(
      key: 'mango_copy',
      nameEn: 'Mango copy',
      nameTh: 'มะม่วง',
      keywordsTh: ['มะม่วง'],
      unit: PriceUnit.perKg,
      low: 60,
      high: 80,
    );
    test('mango first wins', () {
      final m = matchItem(['มะม่วง'], const [mangoFixture, mangoCopy])!;
      expect(m.item.key, 'mango');
    });
    test('copy first wins', () {
      final m = matchItem(['มะม่วง'], const [mangoCopy, mangoFixture])!;
      expect(m.item.key, 'mango_copy');
    });
  });
}
