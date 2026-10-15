import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/thai_number.dart';

void main() {
  group('parseThaiNumberWords: tens', () {
    test('"สิบ" is 10', () => expect(parseThaiNumberWords('สิบ'), 10));
    test('"สิบเอ็ด" is 11', () => expect(parseThaiNumberWords('สิบเอ็ด'), 11));
    test('"ยี่สิบ" is 20', () => expect(parseThaiNumberWords('ยี่สิบ'), 20));
    test(
      '"ยี่สิบเอ็ด" is 21',
      () => expect(parseThaiNumberWords('ยี่สิบเอ็ด'), 21),
    );
    test('"ห้าสิบ" is 50', () => expect(parseThaiNumberWords('ห้าสิบ'), 50));
  });

  group('parseThaiNumberWords: hundreds, with and without leading one', () {
    test('"ร้อย" is 100', () => expect(parseThaiNumberWords('ร้อย'), 100));
    test(
      '"หนึ่งร้อย" is 100',
      () => expect(parseThaiNumberWords('หนึ่งร้อย'), 100),
    );
    test(
      '"ร้อยห้าสิบ" is 150 (demo price)',
      () => expect(parseThaiNumberWords('ร้อยห้าสิบ'), 150),
    );
    test(
      '"หนึ่งร้อยห้าสิบ" is 150',
      () => expect(parseThaiNumberWords('หนึ่งร้อยห้าสิบ'), 150),
    );
    test(
      '"สองร้อย" is 200',
      () => expect(parseThaiNumberWords('สองร้อย'), 200),
    );
    test(
      '"สองร้อยห้าสิบ" is 250',
      () => expect(parseThaiNumberWords('สองร้อยห้าสิบ'), 250),
    );
  });

  group('parseThaiNumberWords: thousands and ten thousands', () {
    test('"พัน" is 1000', () => expect(parseThaiNumberWords('พัน'), 1000));
    test(
      '"สามพันห้าร้อย" is 3500',
      () => expect(parseThaiNumberWords('สามพันห้าร้อย'), 3500),
    );
    test(
      '"หนึ่งพันสองร้อยห้าสิบ" is 1250',
      () => expect(parseThaiNumberWords('หนึ่งพันสองร้อยห้าสิบ'), 1250),
    );
    test(
      '"หมื่น" is 10000',
      () => expect(parseThaiNumberWords('หมื่น'), 10000),
    );
  });

  group(
    'parseThaiNumberWords: no number words returns null, never a guess',
    () {
      test('empty string', () => expect(parseThaiNumberWords(''), isNull));
      test('"ไม่แพง" (not expensive)', () {
        expect(parseThaiNumberWords('ไม่แพง'), isNull);
      });
      test('"มะม่วง" (item name only)', () {
        expect(parseThaiNumberWords('มะม่วง'), isNull);
      });
      test('Latin garbage', () => expect(parseThaiNumberWords('abc'), isNull));
      test(
        'punctuation only',
        () => expect(parseThaiNumberWords('?!.'), isNull),
      );
    },
  );

  group('findAmount: Arabic digits', () {
    test('"150" is 150', () => expect(findAmount('150'), 150));
    test('"1,200" is 1200', () => expect(findAmount('1,200'), 1200));
    test(
      '"80.50" is 80.5',
      () => expect(findAmount('80.50'), closeTo(80.5, 1e-9)),
    );
    test('"ราคา 1,200 บาท" is 1200', () {
      expect(findAmount('ราคา 1,200 บาท'), 1200);
    });
  });

  group('findAmount: Thai digits', () {
    test('"๑๕๐" is 150', () => expect(findAmount('๑๕๐'), 150));
    test('"มะม่วงกิโลละ ๑๕๐" is 150', () {
      expect(findAmount('มะม่วงกิโลละ ๑๕๐'), 150);
    });
  });

  group('findAmount: number words inside a sentence', () {
    test('"มะม่วงกิโลละร้อยห้าสิบ" is 150', () {
      expect(findAmount('มะม่วงกิโลละร้อยห้าสิบ'), 150);
    });
    test('"กิโลละร้อยห้าสิบบาท" is 150', () {
      expect(findAmount('กิโลละร้อยห้าสิบบาท'), 150);
    });
    test('"ห้าสิบบาท" is 50', () => expect(findAmount('ห้าสิบบาท'), 50));
  });

  group('findAmount: "ละ" (per) rule, else the last number', () {
    test('"มะม่วงกิโลละ 150" takes the number after ละ: 150', () {
      expect(findAmount('มะม่วงกิโลละ 150'), 150);
    });
    test('"มะม่วง 2 กิโล 250 บาท" takes the last number: 250, not 2', () {
      expect(findAmount('มะม่วง 2 กิโล 250 บาท'), 250);
    });
    test('"มะม่วงสองกิโลสองร้อยห้าสิบบาท" takes the last number: 250', () {
      expect(findAmount('มะม่วงสองกิโลสองร้อยห้าสิบบาท'), 250);
    });
  });

  group('findAmount: no amount returns null', () {
    test('empty string', () => expect(findAmount(''), isNull));
    test('"ไม่แพง"', () => expect(findAmount('ไม่แพง'), isNull));
    test('"มะม่วงกิโลละ" (price not said)', () {
      expect(findAmount('มะม่วงกิโลละ'), isNull);
    });
  });

  group(
    'parseThaiNumberWords: colloquial trailing digit after a multiplier',
    () {
      test(
        '"ร้อยห้า" is 150',
        () => expect(parseThaiNumberWords('ร้อยห้า'), 150),
      );
      test(
        '"สองร้อยห้า" is 250',
        () => expect(parseThaiNumberWords('สองร้อยห้า'), 250),
      );
      test(
        '"พันห้า" is 1500',
        () => expect(parseThaiNumberWords('พันห้า'), 1500),
      );
      test(
        '"พันสอง" is 1200',
        () => expect(parseThaiNumberWords('พันสอง'), 1200),
      );
      test(
        '"สองพันห้า" is 2500',
        () => expect(parseThaiNumberWords('สองพันห้า'), 2500),
      );
      test(
        '"หมื่นสอง" is 12000',
        () => expect(parseThaiNumberWords('หมื่นสอง'), 12000),
      );
    },
  );

  group(
    'parseThaiNumberWords: full forms are not changed by the short rule',
    () {
      test(
        '"ร้อยห้าสิบ" is still 150',
        () => expect(parseThaiNumberWords('ร้อยห้าสิบ'), 150),
      );
      test(
        '"พันห้าร้อย" is 1500 (multiplier after the digit)',
        () => expect(parseThaiNumberWords('พันห้าร้อย'), 1500),
      );
      test(
        '"ร้อยเอ็ด" is 101 (เอ็ด keeps its literal meaning)',
        () => expect(parseThaiNumberWords('ร้อยเอ็ด'), 101),
      );
    },
  );

  group('parseThaiNumberWords: "นึง" (colloquial one) after a multiplier', () {
    test(
      '"ร้อยนึง" is 100, not 110',
      () => expect(parseThaiNumberWords('ร้อยนึง'), 100),
    );
    test(
      '"พันนึง" is 1000, not 1100',
      () => expect(parseThaiNumberWords('พันนึง'), 1000),
    );
  });

  group('findAmount: colloquial forms in a sentence', () {
    test('"มะม่วงโลละร้อยห้า" is 150', () {
      expect(findAmount('มะม่วงโลละร้อยห้า'), 150);
    });
    test('"กิโลละร้อยนึง" is 100', () {
      expect(findAmount('กิโลละร้อยนึง'), 100);
    });
  });
}
