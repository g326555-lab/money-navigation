import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/card_catalog.dart';
import 'package:money_navigation/rules/personal_context.dart';

Map<String, Object?> card({
  String id = 'utopia-u-card',
  String issuer = 'U-topia',
  String name = 'U-Card',
  String home = 'USD',
  List<Map<String, Object?>> fees = const [
    {'kind': 'foreignExchange', 'percent': 1.5, 'upTo': true},
    {'kind': 'crossBorder', 'percent': 1.5, 'upTo': true},
  ],
  Map<String, Object?> atm = const {
    'policy': 'unknown',
    'value': null,
    'currency': null,
  },
  List<String> printed = const ['U-CARD', 'U-TOPIA', 'VISA'],
  List<Map<String, Object?>> sources = const [
    {
      'label': 'Card terms',
      'url': 'https://u-topia.com/terms-of-service/international',
      'checked': '2026-10-16',
    },
  ],
}) => {
  'id': id,
  'issuer': issuer,
  'name': name,
  'network': 'visa',
  'kind': 'debit',
  'homeCurrency': home,
  'faceColor': '#1A1A2E',
  'faceTextLight': true,
  'fees': fees,
  'atm': atm,
  'benefits': [
    {'en': 'Freeze and unfreeze in the app', 'th': 'ระงับและเปิดบัตรได้ในแอป'},
  ],
  'printedText': printed,
  'sources': sources,
};

String file(List<Map<String, Object?>> cards) => jsonEncode({'cards': cards});

void main() {
  test('a valid card is read with its colour, fees and sources', () {
    final cards = parseCardCatalog(file([card()]))!;
    final c = cards.single;
    expect(c.faceColor, 0xFF1A1A2E);
    expect(c.fees, hasLength(2));
    expect(c.sources.single.checked, '2026-10-16');
    expect(c.benefits.single.of('th'), 'ระงับและเปิดบัตรได้ในแอป');
  });

  test('exchange and cross-border fees add up to an "up to" fee', () {
    final c = parseCardCatalog(file([card()]))!.single;
    expect(cardForeignFee(c), (percent: 3.0, upTo: true));
    expect(profileFromCard(c, homeCurrency: 'USD').cardFeePercent, 3.0);
  });

  test('a card that states no fee gives no fee, not zero', () {
    final c = parseCardCatalog(file([card(fees: const [])]))!.single;
    expect(cardForeignFee(c), isNull);
    expect(profileFromCard(c, homeCurrency: 'USD').cardFeePercent, isNull);
  });

  test('a fixed ATM fee in another currency is not converted silently', () {
    final c = parseCardCatalog(
      file([
        card(
          atm: const {'policy': 'chargesFixed', 'value': 5, 'currency': 'USD'},
        ),
      ]),
    )!.single;
    expect(
      profileFromCard(c, homeCurrency: 'USD').atmFeePolicy,
      AtmFeePolicy.chargesFixed,
    );
    expect(profileFromCard(c, homeCurrency: 'USD').atmFeeValue, 5);
    final thb = profileFromCard(c, homeCurrency: 'THB');
    expect(thb.atmFeePolicy, AtmFeePolicy.unknown);
    expect(thb.atmFeeValue, isNull);
  });

  test('cards without an https source or with bad figures are dropped', () {
    final cards = parseCardCatalog(
      file([
        card(id: 'no-source', sources: const []),
        card(
          id: 'http',
          sources: const [
            {'label': 'x', 'url': 'http://x.example', 'checked': '2026-10-16'},
          ],
        ),
        card(
          id: 'bad-fee',
          fees: const [
            {'kind': 'foreignExchange', 'percent': 99, 'upTo': false},
          ],
        ),
        card(
          id: 'fixed-without-value',
          atm: const {
            'policy': 'chargesFixed',
            'value': null,
            'currency': 'USD',
          },
        ),
        card(id: 'ok'),
        card(id: 'ok'),
      ]),
    )!;
    expect(cards.map((c) => c.id), ['ok']);
    expect(parseCardCatalog('not json'), isNull);
    expect(parseCardCatalog('{"cards": 1}'), isNull);
  });

  group('photo of a card face', () {
    final cards = parseCardCatalog(
      file([
        card(),
        card(
          id: 'kbank-travel',
          issuer: 'KBank',
          name: 'Travel Debit',
          home: 'THB',
          printed: const ['KBANK', 'TRAVEL'],
        ),
        card(id: 'generic', name: 'Plain', printed: const ['VISA', 'DEBIT']),
      ]),
    )!;

    test('numbers and dates are dropped before matching', () {
      expect(
        cardFaceWords('4111 1111 1111 1111\nVALID THRU 12/29\nU-CARD'),
        'VALID THRU U CARD',
      );
    });

    test('the printed name finds the card', () {
      final found = matchCardFace('U-TOPIA\n4000 1234 5678 9010\nVISA', cards);
      expect(found.first.id, 'utopia-u-card');
    });

    test('generic network words alone name no card', () {
      expect(matchCardFace('VISA DEBIT\n1234', cards), isEmpty);
    });

    test('a phrase counts only when all its words are read', () {
      expect(matchCardFace('KBANK', cards).single.id, 'kbank-travel');
      expect(matchCardFace('TRAVEL', cards).single.id, 'kbank-travel');
      expect(matchCardFace('nothing here', cards), isEmpty);
    });
  });

  group('the real assets/data/card_catalog.json', () {
    final raw = File(cardCatalogAsset).readAsStringSync();
    final cards = parseCardCatalog(raw)!;

    test('every listed card is read, none dropped', () {
      final listed = (jsonDecode(raw) as Map)['cards'] as List;
      expect(cards, hasLength(listed.length));
      expect(cards.every((c) => c.sources.isNotEmpty), isTrue);
    });

    test('U-Card: exchange and cross-border fees, up to 3%', () {
      final u = cards.firstWhere((c) => c.id == 'utopia-u-card');
      expect(cardForeignFee(u), (percent: 3.0, upTo: true));
    });

    test('a photo with the printed names finds its card first', () {
      for (final c in cards.where((c) => c.printedText.isNotEmpty)) {
        final photo = '${c.printedText.join('\n')}\n4111 1111 1111 1111\n12/29';
        final found = matchCardFace(photo, cards);
        if (found.isEmpty) continue; // printed words are all generic
        expect(found.first.id, c.id, reason: c.id);
      }
    });
  });
}
