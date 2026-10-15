import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/arrival_alert.dart';
import 'package:money_navigation/rules/pay_facts.dart';

// Built through the parser so the test does not depend on how PayFacts is
// constructed.
final PayFacts facts = PayFacts.parse(
  jsonEncode({
    'countries': [
      {
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
      },
      {'country': 'JP', 'currency': 'JPY', 'atmOffersConversion': false},
    ],
  }),
)!;

ArrivalAlert? alert(String home, String? current, String? last) => arrivalAlert(
  homeCurrency: home,
  currentCountry: current,
  lastAlertedCountry: last,
  facts: facts,
);

void main() {
  group('arrival in another country', () {
    test('THB home lands in JP: alert JPY / THB', () {
      final a = alert('THB', 'JP', null)!;
      expect(a.country, 'JP');
      expect(a.localCurrency, 'JPY');
      expect(a.homeCurrency, 'THB');
      expect(a.atmOffersConversion, isFalse);
    });

    test('USD home in TH: alert THB / USD with conversion offer', () {
      final a = alert('USD', 'TH', null)!;
      expect(a.country, 'TH');
      expect(a.localCurrency, 'THB');
      expect(a.homeCurrency, 'USD');
      expect(a.atmOffersConversion, isTrue);
    });

    test('lower-case current country is upper-cased in the alert', () {
      final a = alert('THB', 'jp', null)!;
      expect(a.country, 'JP');
      expect(a.localCurrency, 'JPY');
    });

    test('alerted for another country before: fires again here', () {
      expect(alert('THB', 'JP', 'KR'), isNotNull);
    });
  });

  group('no alert', () {
    test(
      'already alerted for JP',
      () => expect(alert('THB', 'JP', 'JP'), isNull),
    );
    test('case-insensitive: current jp, last JP', () {
      expect(alert('THB', 'jp', 'JP'), isNull);
    });
    test('case-insensitive: current JP, last jp', () {
      expect(alert('THB', 'JP', 'jp'), isNull);
    });
    test(
      'at home: TH with THB home',
      () => expect(alert('THB', 'TH', null), isNull),
    );
    test('unknown country ZZ', () => expect(alert('THB', 'ZZ', null), isNull));
    test('location unknown', () => expect(alert('THB', null, null), isNull));
    test('location unknown even with a stored country', () {
      expect(alert('THB', null, 'JP'), isNull);
    });
  });
}
