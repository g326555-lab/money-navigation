import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/pay_facts.dart';

/// The real bundled facts file, read from disk (tests run from app/).
PayFacts realFacts() {
  final text = File(payFactsAsset).readAsStringSync();
  final facts = PayFacts.parse(text);
  expect(facts, isNotNull, reason: '$payFactsAsset must parse');
  return facts!;
}

bool isIsoDate(String? s) =>
    s != null &&
    RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(s) &&
    DateTime.tryParse(s) != null;

void main() {
  late PayFacts facts;
  setUpAll(() => facts = realFacts());

  group('TH', () {
    test('foreign card ATM fee is 250 THB, sourced and dated', () {
      final fee = facts.country('TH')!.foreignCardAtmFee!;
      expect(fee.value, 250);
      expect(fee.currency, 'THB');
      expect(fee.isPercent, isFalse);
      expect(fee.source, 'Kasikorn Bank fee list');
      expect(fee.appliesTo, 'Kasikorn K-ATM, Visa');
      expect(isIsoDate(fee.checked), isTrue, reason: fee.checked);
    });

    test('ATMs offer conversion, with a source and checked date', () {
      final th = facts.country('TH')!;
      expect(th.currency, 'THB');
      expect(th.atmOffersConversion, isTrue);
      expect(th.atmConversionSource, isNotNull);
      expect(th.atmConversionSource!.trim(), isNotEmpty);
      expect(isIsoDate(th.atmConversionChecked), isTrue);
    });
  });

  group('JP', () {
    test('no foreign card ATM fee is listed (none was found)', () {
      expect(facts.country('JP')!.foreignCardAtmFee, isNull);
    });

    test('ATMs offer conversion, with a source', () {
      final jp = facts.country('JP')!;
      expect(jp.atmOffersConversion, isTrue);
      expect(jp.atmConversionSource, isNotNull);
      expect(jp.atmConversionSource!.trim(), isNotEmpty);
      expect(isIsoDate(jp.atmConversionChecked), isTrue);
    });

    test('currencyOf JP is JPY', () {
      expect(facts.currencyOf('JP'), 'JPY');
    });
  });

  test('every claimed conversion offer names a source', () {
    for (final c in facts.countries.values) {
      if (c.atmOffersConversion) {
        expect(c.atmConversionSource, isNotNull, reason: c.country);
      }
    }
  });

  test('every country has a 3-letter currency', () {
    expect(facts.countries, isNotEmpty);
    for (final c in facts.countries.values) {
      expect(c.currency, matches(RegExp(r'^[A-Z]{3}$')), reason: c.country);
    }
  });
}
