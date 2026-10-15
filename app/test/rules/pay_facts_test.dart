import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/pay_facts.dart';

Map<String, Object?> thEntry() => {
  'country': 'TH',
  'currency': 'THB',
  'atmOffersConversion': true,
  'foreignCardAtmFee': {
    'value': 220,
    'currency': 'THB',
    'isPercent': false,
    'source': 'Bangkok Bank fee schedule',
    'checked': '2026-10-15',
  },
};

Map<String, Object?> jpEntry() => {
  'country': 'JP',
  'currency': 'JPY',
  'atmOffersConversion': false,
  'foreignCardAtmFee': {
    'value': 110,
    'currency': 'JPY',
    'isPercent': false,
    'source': 'Seven Bank fee schedule',
    'checked': '2026-10-14',
  },
};

String file(List<Object?> countries) => jsonEncode({'countries': countries});

void main() {
  test('asset path is the bundled facts file', () {
    expect(payFactsAsset, 'assets/data/pay_facts.json');
  });

  group('parse: valid file', () {
    late PayFacts facts;
    setUp(() => facts = PayFacts.parse(file([thEntry(), jpEntry()]))!);

    test('both countries are read', () {
      expect(facts.countries.keys, containsAll(['TH', 'JP']));
      expect(facts.countries.length, 2);
    });

    test('TH: local ATM fee 220 THB with its source and date', () {
      final th = facts.country('TH')!;
      expect(th.country, 'TH');
      expect(th.currency, 'THB');
      expect(th.atmOffersConversion, isTrue);
      final fee = th.foreignCardAtmFee!;
      expect(fee.value, 220);
      expect(fee.currency, 'THB');
      expect(fee.isPercent, isFalse);
      expect(fee.source, 'Bangkok Bank fee schedule');
      expect(fee.checked, '2026-10-15');
    });

    test('JP: local ATM fee 110 JPY, no conversion offer', () {
      final jp = facts.country('JP')!;
      expect(jp.currency, 'JPY');
      expect(jp.atmOffersConversion, isFalse);
      expect(jp.foreignCardAtmFee!.value, 110);
      expect(jp.foreignCardAtmFee!.currency, 'JPY');
      expect(jp.foreignCardAtmFee!.source, 'Seven Bank fee schedule');
    });

    test('percent fee keeps isPercent', () {
      final entry = thEntry();
      entry['foreignCardAtmFee'] = {
        'value': 1.5,
        'currency': 'THB',
        'isPercent': true,
        'source': 'Example fee schedule',
        'checked': '2026-10-01',
      };
      final fee = PayFacts.parse(file([entry]))!
          .country('TH')!
          .foreignCardAtmFee!;
      expect(fee.value, 1.5);
      expect(fee.isPercent, isTrue);
    });
  });

  group('lookup', () {
    final facts = PayFacts.parse(file([thEntry(), jpEntry()]))!;

    test('unknown country is null', () {
      expect(facts.country('ZZ'), isNull);
      expect(facts.currencyOf('ZZ'), isNull);
    });

    test('lower-case lookup works', () {
      expect(facts.country('th')!.currency, 'THB');
      expect(facts.country('Jp')!.currency, 'JPY');
    });

    test('currencyOf maps country to its local currency', () {
      expect(facts.currencyOf('JP'), 'JPY');
      expect(facts.currencyOf('TH'), 'THB');
      expect(facts.currencyOf('jp'), 'JPY');
    });
  });

  group('parse: malformed entries are skipped, not fatal', () {
    test('entry missing currency is skipped, others kept', () {
      final broken = jpEntry()..remove('currency');
      final facts = PayFacts.parse(file([thEntry(), broken]))!;
      expect(facts.country('JP'), isNull);
      expect(facts.currencyOf('JP'), isNull);
      expect(facts.country('TH'), isNotNull);
    });

    test('entry missing country code is skipped', () {
      final broken = jpEntry()..remove('country');
      final facts = PayFacts.parse(file([thEntry(), broken]))!;
      expect(facts.countries.length, 1);
      expect(facts.country('TH'), isNotNull);
    });

    test('non-object entry is skipped', () {
      final facts = PayFacts.parse(file([42, 'JP', null, thEntry()]))!;
      expect(facts.countries.length, 1);
      expect(facts.country('TH'), isNotNull);
    });

    test('fee missing source is dropped: fee null, country kept', () {
      final entry = thEntry();
      (entry['foreignCardAtmFee'] as Map).remove('source');
      final th = PayFacts.parse(file([entry]))!.country('TH')!;
      expect(th.foreignCardAtmFee, isNull);
      expect(th.currency, 'THB');
      expect(th.atmOffersConversion, isTrue);
    });

    test('fee with an empty source is dropped', () {
      final entry = thEntry();
      (entry['foreignCardAtmFee'] as Map)['source'] = '';
      final th = PayFacts.parse(file([entry]))!.country('TH')!;
      expect(th.foreignCardAtmFee, isNull);
    });

    test('fee with a non-numeric value is dropped, never guessed', () {
      final entry = thEntry();
      (entry['foreignCardAtmFee'] as Map)['value'] = 'about 220';
      final th = PayFacts.parse(file([entry]))!.country('TH')!;
      expect(th.foreignCardAtmFee, isNull);
    });

    test('country without a fee keeps a null fee', () {
      final entry = thEntry()..remove('foreignCardAtmFee');
      final th = PayFacts.parse(file([entry]))!.country('TH')!;
      expect(th.foreignCardAtmFee, isNull);
    });

    test('empty country list parses to no countries', () {
      final facts = PayFacts.parse(file([]))!;
      expect(facts.countries, isEmpty);
      expect(facts.country('TH'), isNull);
    });
  });

  group('parse: ATM conversion source', () {
    Map<String, Object?> withConversion({
      Object? source = 'Portail Asie, Withdraw money in Thailand',
      Object? checked = '2026-10-15',
    }) {
      final entry = thEntry();
      if (source != null) entry['atmConversionSource'] = source;
      if (checked != null) entry['atmConversionChecked'] = checked;
      return entry;
    }

    CountryPayFacts th(Map<String, Object?> entry) =>
        PayFacts.parse(file([entry]))!.country('TH')!;

    test('source and checked date are read', () {
      final facts = th(withConversion());
      expect(
        facts.atmConversionSource,
        'Portail Asie, Withdraw money in Thailand',
      );
      expect(facts.atmConversionChecked, '2026-10-15');
      expect(facts.atmOffersConversion, isTrue);
    });

    test('no source: both null, the offer flag is kept', () {
      final facts = th(thEntry());
      expect(facts.atmConversionSource, isNull);
      expect(facts.atmConversionChecked, isNull);
      expect(facts.atmOffersConversion, isTrue);
    });

    test('a checked date without a source is dropped', () {
      final facts = th(withConversion(source: null));
      expect(facts.atmConversionSource, isNull);
      expect(facts.atmConversionChecked, isNull);
    });

    test('an empty or blank source counts as none', () {
      expect(th(withConversion(source: '')).atmConversionSource, isNull);
      expect(th(withConversion(source: '   ')).atmConversionSource, isNull);
      expect(th(withConversion(source: '   ')).atmConversionChecked, isNull);
    });

    test('a non-string source counts as none', () {
      final facts = th(withConversion(source: 42));
      expect(facts.atmConversionSource, isNull);
      expect(facts.atmConversionChecked, isNull);
    });

    test('source without a checked date keeps the source only', () {
      final facts = th(withConversion(checked: null));
      expect(
        facts.atmConversionSource,
        'Portail Asie, Withdraw money in Thailand',
      );
      expect(facts.atmConversionChecked, isNull);
    });

    test('a non-string checked date is dropped', () {
      final facts = th(withConversion(checked: 20261015));
      expect(facts.atmConversionSource, isNotNull);
      expect(facts.atmConversionChecked, isNull);
    });

    test('constructor defaults leave both null', () {
      const facts = CountryPayFacts(country: 'TH', currency: 'THB');
      expect(facts.atmConversionSource, isNull);
      expect(facts.atmConversionChecked, isNull);
      expect(facts.atmOffersConversion, isFalse);
    });
  });

  group('parse: malformed top level is null', () {
    test('non-JSON', () => expect(PayFacts.parse('not json {'), isNull));
    test('empty string', () => expect(PayFacts.parse(''), isNull));
    test('top level is a list', () {
      expect(PayFacts.parse(jsonEncode([thEntry()])), isNull);
    });
    test('countries is not a list', () {
      expect(PayFacts.parse(jsonEncode({'countries': thEntry()})), isNull);
    });
    test('countries key missing', () {
      expect(PayFacts.parse(jsonEncode({'other': []})), isNull);
    });
  });
}
