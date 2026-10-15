import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/features/briefing/places_client.dart';

void main() {
  group('paymentFromJson', () {
    test('reads the three flags as Google gives them', () {
      final p = paymentFromJson({'cashOnly': null, 'cards': true, 'nfc': true});
      expect(p.cashOnly, isNull);
      expect(p.cards, isTrue);
      expect(p.nfc, isTrue);
    });

    test('cash only without any card flag stays cash only', () {
      final p = paymentFromJson({'cashOnly': true, 'cards': false});
      expect(p.cashOnly, isTrue);
      expect(p.cards, isFalse);
    });

    test('cash only next to takes cards is no evidence at all', () {
      final p = paymentFromJson({'cashOnly': true, 'cards': true});
      expect(p.known, isFalse);
      expect(p.cashOnly, isNull);
      expect(p.cards, isNull);
    });

    test('cash only next to contactless is no evidence at all', () {
      expect(paymentFromJson({'cashOnly': true, 'nfc': true}).known, isFalse);
    });

    test('anything that is not a map or a boolean stays unknown', () {
      expect(paymentFromJson(null).known, isFalse);
      expect(paymentFromJson('yes').known, isFalse);
      expect(paymentFromJson({'cards': 'true'}).known, isFalse);
    });
  });
}
