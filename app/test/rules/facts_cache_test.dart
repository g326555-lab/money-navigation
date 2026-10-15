import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/facts_cache.dart';
import 'package:money_navigation/rules/pay_facts.dart';

const visaKey = 'th.atm_fee.kasikorn.visa';
const kasikornPdf =
    'https://www.kasikornbank.com/en/personal/Digital-banking/Documents/fee.pdf';

/// A row as the `facts` table returns it.
Map<String, Object?> row({
  String key = visaKey,
  Object? value = 250,
  String unit = 'THB',
  Object? sourceUrl = kasikornPdf,
  String? quote = 'Visa 250 Baht/transaction',
  String checkedAt = '2026-10-15T09:00:00',
  String? fetchedAt = '2026-10-15T09:00:00',
  String status = 'updated',
  String? note,
}) => {
  'key': key,
  'value': value,
  'unit': unit,
  'source_url': sourceUrl,
  'quoted_text': quote,
  'checked_at': checkedAt,
  'fetched_at': fetchedAt,
  'status': status,
  'note': note,
};

LiveFact fact({
  String key = visaKey,
  Object? value = 250,
  String checkedAt = '2026-10-15T09:00:00',
  String status = 'updated',
  String? note,
}) => LiveFact.fromRow(
  row(key: key, value: value, checkedAt: checkedAt, status: status, note: note),
)!;

const bundledJson = '''
{
  "countries": [
    {
      "country": "TH",
      "currency": "THB",
      "atmOffersConversion": true,
      "atmConversionSource": "Portail Asie, Withdraw money in Thailand",
      "atmConversionChecked": "2026-09-01",
      "foreignCardAtmFee": {
        "value": 220,
        "currency": "THB",
        "isPercent": false,
        "source": "Kasikorn Bank fee schedule",
        "checked": "2026-09-01",
        "appliesTo": "Kasikorn K-ATM, Visa"
      }
    },
    {
      "country": "JP",
      "currency": "JPY",
      "foreignCardAtmFee": {
        "value": 110,
        "currency": "JPY",
        "isPercent": false,
        "source": "Seven Bank fee schedule",
        "checked": "2026-09-01"
      }
    }
  ]
}
''';

PayFacts bundled() => PayFacts.parse(bundledJson)!;

/// Builds a snapshot through the public codec. Contract for the cache
/// layout: `{"savedAt": ISO-8601, "facts": [LiveFact.toJson(), ...]}`.
FactsSnapshot snapshot(List<LiveFact> facts, DateTime savedAt) =>
    FactsSnapshot.decode(
      jsonEncode({
        'savedAt': savedAt.toIso8601String(),
        'facts': [for (final f in facts) f.toJson()],
      }),
    )!;

void main() {
  test('cache lives for 24 hours', () {
    expect(factsMaxAge, const Duration(hours: 24));
  });

  group('LiveFact.fromRow', () {
    test('reads a full row', () {
      final f = LiveFact.fromRow(row(note: null))!;
      expect(f.key, visaKey);
      expect(f.value, 250);
      expect(f.unit, 'THB');
      expect(f.sourceUrl, kasikornPdf);
      expect(f.quote, 'Visa 250 Baht/transaction');
      expect(f.checkedAt, DateTime.parse('2026-10-15T09:00:00'));
      expect(f.fetchedAt, DateTime.parse('2026-10-15T09:00:00'));
      expect(f.status, 'updated');
      expect(f.note, isNull);
    });

    test('numeric column delivered as a string "250" reads as 250', () {
      expect(LiveFact.fromRow(row(value: '250'))!.value, 250);
    });

    test('decimal string "1250.50" reads as 1250.5', () {
      expect(LiveFact.fromRow(row(value: '1250.50'))!.value, 1250.5);
    });

    test('missing source_url -> null (no number without a source)', () {
      expect(LiveFact.fromRow(row()..remove('source_url')), isNull);
    });

    test('blank source_url -> null', () {
      expect(LiveFact.fromRow(row(sourceUrl: '  ')), isNull);
    });

    test('null value -> null, never a guessed number', () {
      expect(LiveFact.fromRow(row(value: null)), isNull);
    });

    test('non-numeric value string -> null', () {
      expect(LiveFact.fromRow(row(value: 'about 250')), isNull);
    });

    test('missing key -> null', () {
      expect(LiveFact.fromRow(row()..remove('key')), isNull);
    });

    test('unparseable checked_at -> null', () {
      expect(LiveFact.fromRow(row(checkedAt: 'yesterday')), isNull);
    });

    test('kept row keeps its failure note', () {
      final f = LiveFact.fromRow(
        row(status: 'kept', note: 'quote_not_in_page'),
      )!;
      expect(f.status, 'kept');
      expect(f.note, 'quote_not_in_page');
    });

    test('null fetched_at is allowed', () {
      expect(LiveFact.fromRow(row(fetchedAt: null))!.fetchedAt, isNull);
    });

    test('toJson round-trips through fromRow', () {
      final f = fact(status: 'kept', note: 'out_of_range');
      final back = LiveFact.fromRow(f.toJson())!;
      expect(back.key, f.key);
      expect(back.value, f.value);
      expect(back.unit, f.unit);
      expect(back.sourceUrl, f.sourceUrl);
      expect(back.quote, f.quote);
      expect(back.checkedAt, f.checkedAt);
      expect(back.fetchedAt, f.fetchedAt);
      expect(back.status, f.status);
      expect(back.note, f.note);
    });
  });

  group('FactsSnapshot staleness', () {
    final saved = DateTime(2026, 10, 15, 9);

    test('stale at exactly 24 h', () {
      final s = snapshot([fact()], saved);
      expect(s.isStale(saved.add(const Duration(hours: 24))), isTrue);
    });

    test('not stale at 23 h 59 m', () {
      final s = snapshot([fact()], saved);
      expect(
        s.isStale(saved.add(const Duration(hours: 23, minutes: 59))),
        isFalse,
      );
    });

    test('fresh right after saving', () {
      expect(snapshot([fact()], saved).isStale(saved), isFalse);
    });
  });

  group('FactsSnapshot encode / decode', () {
    test('round-trips facts and savedAt', () {
      final saved = DateTime(2026, 10, 15, 9, 30);
      final s = snapshot([
        fact(),
        fact(key: 'market.mango.lotuss', value: 89),
      ], saved);
      final back = FactsSnapshot.decode(s.encode())!;
      expect(back.savedAt, saved);
      expect(back.facts.map((f) => f.key), [visaKey, 'market.mango.lotuss']);
      expect(back.facts.map((f) => f.value), [250, 89]);
      expect(back.facts.first.sourceUrl, kasikornPdf);
      expect(back.facts.first.quote, 'Visa 250 Baht/transaction');
    });

    test('garbage -> null', () {
      expect(FactsSnapshot.decode('not json {'), isNull);
    });

    test('valid JSON of the wrong shape -> null', () {
      expect(FactsSnapshot.decode('[1, 2, 3]'), isNull);
      expect(FactsSnapshot.decode('{"facts": 7}'), isNull);
    });

    test('empty string -> null', () {
      expect(FactsSnapshot.decode(''), isNull);
    });
  });

  group('FactsSnapshot.summary', () {
    final today = DateTime(2026, 10, 15, 12);

    test('counts by status for today only', () {
      final s = snapshot([
        fact(key: 'a', status: 'updated'),
        fact(key: 'b', status: 'unchanged', checkedAt: '2026-10-15T00:30:00'),
        fact(key: 'c', status: 'unchanged', checkedAt: '2026-10-15T23:30:00'),
        fact(key: 'd', status: 'kept', note: 'quote_not_in_page'),
        fact(key: 'e', status: 'updated', checkedAt: '2026-10-14T23:59:00'),
        fact(key: 'f', status: 'kept', checkedAt: '2026-10-16T00:01:00'),
      ], today);
      final sum = s.summary(today);
      expect(sum.checked, 4);
      expect(sum.updated, 1);
      expect(sum.unchanged, 2);
      expect(sum.kept, 1);
    });

    test('nothing checked that day -> all zero', () {
      final s = snapshot([fact()], today);
      final sum = s.summary(DateTime(2026, 10, 20));
      expect(sum.checked, 0);
      expect(sum.updated, 0);
      expect(sum.unchanged, 0);
      expect(sum.kept, 0);
    });
  });

  group('applyLiveFacts', () {
    test('empty list leaves the bundled facts untouched', () {
      final b = bundled();
      final out = applyLiveFacts(b, const []);
      final fee = out.country('TH')!.foreignCardAtmFee!;
      expect(fee.value, 220);
      expect(fee.checked, '2026-09-01');
      expect(fee.source, 'Kasikorn Bank fee schedule');
    });

    test('updated Visa fee replaces value and checked date only', () {
      final out = applyLiveFacts(bundled(), [
        fact(value: 250, checkedAt: '2026-10-15T09:00:00'),
      ]);
      final th = out.country('TH')!;
      final fee = th.foreignCardAtmFee!;
      expect(fee.value, 250);
      expect(fee.checked, '2026-10-15');
      expect(fee.source, 'Kasikorn Bank fee schedule');
      expect(fee.appliesTo, 'Kasikorn K-ATM, Visa');
      expect(fee.currency, 'THB');
      expect(fee.isPercent, isFalse);
      expect(th.currency, 'THB');
      expect(th.atmOffersConversion, isTrue);
      expect(
        th.atmConversionSource,
        'Portail Asie, Withdraw money in Thailand',
      );
    });

    test('unchanged status still refreshes the checked date', () {
      final out = applyLiveFacts(bundled(), [
        fact(value: 220, status: 'unchanged'),
      ]);
      final fee = out.country('TH')!.foreignCardAtmFee!;
      expect(fee.value, 220);
      expect(fee.checked, '2026-10-15');
    });

    test('kept status does not move the checked date forward', () {
      final out = applyLiveFacts(bundled(), [
        fact(value: 220, status: 'kept', note: 'quote_not_in_page'),
      ]);
      final fee = out.country('TH')!.foreignCardAtmFee!;
      expect(fee.value, 220);
      expect(fee.checked, '2026-09-01');
    });

    test('unknown keys are ignored', () {
      final out = applyLiveFacts(bundled(), [
        fact(key: 'th.atm_fee.someotherbank.visa', value: 999),
        fact(key: 'market.mango.lotuss', value: 89),
      ]);
      final fee = out.country('TH')!.foreignCardAtmFee!;
      expect(fee.value, 220);
      expect(fee.checked, '2026-09-01');
    });

    test('zero value is ignored', () {
      final out = applyLiveFacts(bundled(), [fact(value: 0)]);
      expect(out.country('TH')!.foreignCardAtmFee!.value, 220);
      expect(out.country('TH')!.foreignCardAtmFee!.checked, '2026-09-01');
    });

    test('negative value is ignored', () {
      final out = applyLiveFacts(bundled(), [fact(value: -250)]);
      expect(out.country('TH')!.foreignCardAtmFee!.value, 220);
    });

    test('other countries are not touched', () {
      final out = applyLiveFacts(bundled(), [fact(value: 250)]);
      final jp = out.country('JP')!.foreignCardAtmFee!;
      expect(jp.value, 110);
      expect(jp.currency, 'JPY');
      expect(jp.checked, '2026-09-01');
    });

    test('the bundled object itself is not mutated', () {
      final b = bundled();
      applyLiveFacts(b, [fact(value: 250)]);
      expect(b.country('TH')!.foreignCardAtmFee!.value, 220);
      expect(b.country('TH')!.foreignCardAtmFee!.checked, '2026-09-01');
    });

    test('bundled file without TH is returned unchanged', () {
      final jpOnly = PayFacts.parse(
        '{"countries": [{"country": "JP", "currency": "JPY"}]}',
      )!;
      final out = applyLiveFacts(jpOnly, [fact(value: 250)]);
      expect(out.country('TH'), isNull);
      expect(out.country('JP'), isNotNull);
    });
  });
}
