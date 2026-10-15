import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/haggle.dart';
import 'package:money_navigation/rules/new_item.dart';

const _heardLatte = 'ลาเต้วานิลลาแก้วละ 120';

NewItem? _accept({
  String nameTh = 'ลาเต้วานิลลา',
  String nameEn = 'Vanilla latte',
  String unit = 'each',
  String category = 'drink',
  List<String> transcripts = const [_heardLatte],
  PriceUnit? heardUnit,
}) =>
    acceptNewItem(
      nameTh: nameTh,
      nameEn: nameEn,
      unit: unit,
      category: category,
      transcripts: transcripts,
      heardUnit: heardUnit,
    );

void main() {
  group('Owner scene: "vanilla latte" spoken in Thai becomes an item', () {
    test('accepted with exact fields and key new:ลาเต้วานิลลา', () {
      final item = _accept();
      expect(item, isNotNull);
      expect(item!.nameTh, 'ลาเต้วานิลลา');
      expect(item.nameEn, 'Vanilla latte');
      expect(item.unit, PriceUnit.each);
      expect(item.category, ItemCategory.drink);
      expect(item.key, 'new:ลาเต้วานิลลา');
    });

    test('accepted when heardUnit matches the proposed unit', () {
      expect(_accept(heardUnit: PriceUnit.each)?.unit, PriceUnit.each);
    });

    test('spaced transcript still contains the name', () {
      final item = _accept(transcripts: const ['ลาเต้ วานิลลา แก้ว ละ 120']);
      expect(item, isNotNull);
      expect(item!.key, 'new:ลาเต้วานิลลา');
    });

    test('spaced proposed name is matched and keyed without spaces', () {
      final item = _accept(nameTh: 'ลาเต้ วานิลลา');
      expect(item, isNotNull);
      expect(item!.key, 'new:ลาเต้วานิลลา');
    });

    test('second alternative containing the name is enough', () {
      final item = _accept(transcripts: const [
        'ลาเต้แก้วละ 120',
        _heardLatte,
      ]);
      expect(item, isNotNull);
    });
  });

  group('Never invents a name that was not heard', () {
    test('name absent from every transcript -> null', () {
      expect(_accept(nameTh: 'คาปูชิโน่', nameEn: 'Cappuccino'), isNull);
    });

    test('empty transcripts -> null', () {
      expect(_accept(transcripts: const []), isNull);
    });

    test('blank transcripts -> null', () {
      expect(_accept(transcripts: const ['', '   ']), isNull);
    });
  });

  group('nameTh shape', () {
    test('one-letter name -> null even when heard', () {
      expect(_accept(nameTh: 'ล'), isNull);
    });

    test('empty name -> null', () {
      expect(_accept(nameTh: ''), isNull);
    });

    test('name without any Thai letter -> null', () {
      expect(
        _accept(nameTh: 'latte', transcripts: const ['latte แก้วละ 120']),
        isNull,
      );
    });

    test('name longer than 40 characters -> null', () {
      final long = 'ก' * 41;
      expect(_accept(nameTh: long, transcripts: [long]), isNull);
    });

    test('name of exactly 40 characters is accepted', () {
      final edge = 'ก' * 40;
      expect(_accept(nameTh: edge, transcripts: [edge]), isNotNull);
    });
  });

  group('nameTh must not carry price or unit words', () {
    test('"แก้วละ" (ends with ละ) -> null', () {
      expect(_accept(nameTh: 'แก้วละ'), isNull);
    });

    test('name that ends with ละ after the item -> null', () {
      expect(_accept(nameTh: 'ลาเต้วานิลลาแก้วละ'), isNull);
    });

    test('"120บาท" -> null', () {
      expect(
        _accept(nameTh: '120บาท', transcripts: const ['ลาเต้ 120 บาท']),
        isNull,
      );
    });

    test('name containing บาท without digits -> null', () {
      expect(
        _accept(nameTh: 'ลาเต้บาท', transcripts: const ['ลาเต้บาท']),
        isNull,
      );
    });

    test('"ลาเต้120" (digits) -> null even when heard', () {
      expect(
        _accept(nameTh: 'ลาเต้120', transcripts: const ['ลาเต้ 120']),
        isNull,
      );
    });

    test('Thai digits in the name -> null', () {
      expect(
        _accept(nameTh: 'ลาเต้๑๒๐', transcripts: const ['ลาเต้๑๒๐']),
        isNull,
      );
    });
  });

  group('nameEn shape', () {
    test('digits -> null', () {
      expect(_accept(nameEn: 'Latte 120'), isNull);
    });

    test('Thai letters -> null', () {
      expect(_accept(nameEn: 'ลาเต้'), isNull);
    });

    test('empty -> null', () {
      expect(_accept(nameEn: ''), isNull);
    });

    test('over 40 characters -> null', () {
      expect(_accept(nameEn: 'a' * 41), isNull);
    });

    test('hyphen and apostrophe are allowed', () {
      expect(_accept(nameEn: "Grandma's iced-latte"), isNotNull);
    });
  });

  group('unit and category', () {
    test('perKg proposed while heard unit is each -> null', () {
      expect(_accept(unit: 'perKg', heardUnit: PriceUnit.each), isNull);
    });

    test('no heard unit accepts any known unit', () {
      expect(_accept(unit: 'perKg')?.unit, PriceUnit.perKg);
      expect(_accept(unit: 'perRide')?.unit, PriceUnit.perRide);
    });

    test('unknown unit string -> null', () {
      expect(_accept(unit: 'perCup'), isNull);
      expect(_accept(unit: ''), isNull);
    });

    test('unknown category falls back to other', () {
      expect(_accept(category: 'coffee')?.category, ItemCategory.other);
    });

    test('every known category maps to its enum', () {
      for (final c in ItemCategory.values) {
        expect(_accept(category: c.name)?.category, c);
      }
    });
  });
}
