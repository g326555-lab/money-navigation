import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/exchange_rate.dart';
import 'package:money_navigation/rules/personal_context.dart';
import 'package:money_navigation/rules/trip_ledger.dart';

/// The exact demo values printed on the ATM prop (CLAUDE.md "Demo data").
const demoReading = AtmScreenReading(
  withdrawalThb: 4000,
  accessFeeThb: 220,
  thbPerUsd: 30.86,
  markupPercent: 5.50,
  chargedThb: 4220,
  chargedUsd: 144.71,
);

/// Body of GET https://api.frankfurter.dev/v1/latest?base=THB&symbols=USD,JPY
/// captured on 14 Oct 2026.
const frankfurterBody =
    '{"amount":1.0,"base":"THB","date":"2026-10-14",'
    '"rates":{"JPY":4.7195,"USD":0.02978}}';

final t0 = DateTime.utc(2026, 10, 15, 9, 30);

TripSave mangoSave({String id = 'mango-1', DateTime? at}) => saveFromHaggle(
  id: id,
  savedAt: at ?? t0,
  itemKey: 'mango',
  askedThb: 150,
  paidThb: 110,
)!;

TripSave atmSave({String id = 'atm-1', DateTime? at}) =>
    saveFromAtm(evaluateAtm(demoReading), id: id, savedAt: at ?? t0)!;

void main() {
  group('saveFromAtm: demo ATM (scene 1 result)', () {
    final verdict = evaluateAtm(demoReading);

    test('keeps exactly the verdict extra cost, about 246 THB', () {
      final s = saveFromAtm(verdict, id: 'atm-1', savedAt: t0)!;
      expect(s.keptThb, verdict.extraCostThb);
      expect(s.keptThb.round(), 246);
      expect(s.keptThb, closeTo(245.75, 0.01));
    });

    test('records kind, id and time, no haggle fields', () {
      final s = saveFromAtm(verdict, id: 'atm-1', savedAt: t0)!;
      expect(s.kind, SaveKind.atmConversion);
      expect(s.id, 'atm-1');
      expect(s.savedAt, t0);
      expect(s.itemKey, isNull);
      expect(s.askedThb, isNull);
      expect(s.paidThb, isNull);
    });

    test('no saving (extra cost zero) gives null', () {
      const v = AtmVerdict(
        recommended: AtmChoice.acceptConversion,
        extraCostUsd: 0,
        extraCostThb: 0,
      );
      expect(saveFromAtm(v, id: 'x', savedAt: t0), isNull);
    });

    test('negative extra cost gives null', () {
      const v = AtmVerdict(
        recommended: AtmChoice.acceptConversion,
        extraCostUsd: -1,
        extraCostThb: -30.86,
      );
      expect(saveFromAtm(v, id: 'x', savedAt: t0), isNull);
    });
  });

  group('haggle savings (scene 2 result)', () {
    test('mango asked 150, paid 110 keeps 40 THB', () {
      expect(haggleKeptThb(askedThb: 150, paidThb: 110), 40);
      final s = mangoSave();
      expect(s.kind, SaveKind.haggle);
      expect(s.keptThb, 40);
      expect(s.itemKey, 'mango');
      expect(s.askedThb, 150);
      expect(s.paidThb, 110);
      expect(s.savedAt, t0);
    });

    test('paid equal to asked keeps 0 but is still a valid save', () {
      final s = saveFromHaggle(
        id: 'h',
        savedAt: t0,
        itemKey: 'mango',
        askedThb: 150,
        paidThb: 150,
      );
      expect(s, isNotNull);
      expect(s!.keptThb, 0);
    });

    test('paid above asked gives null', () {
      expect(
        saveFromHaggle(
          id: 'h',
          savedAt: t0,
          itemKey: 'mango',
          askedThb: 150,
          paidThb: 160,
        ),
        isNull,
      );
    });

    test('paid zero or negative gives null', () {
      for (final paid in [0.0, -10.0]) {
        expect(
          saveFromHaggle(
            id: 'h',
            savedAt: t0,
            itemKey: 'mango',
            askedThb: 150,
            paidThb: paid,
          ),
          isNull,
        );
      }
    });

    test('haggleKeptThb never goes below 0', () {
      expect(haggleKeptThb(askedThb: 100, paidThb: 120), 0);
    });
  });

  group('totals: "Kept on this trip" on home', () {
    test('empty trip keeps 0', () {
      expect(keptTotalThb(const []), 0);
      expect(keptByKind(const []), isEmpty);
    });

    test('ATM plus mango is about 286 THB', () {
      final total = keptTotalThb([atmSave(), mangoSave()]);
      expect(total, closeTo(evaluateAtm(demoReading).extraCostThb + 40, 1e-9));
      expect(total.round(), 286);
    });

    test('total in USD with the 14 Oct Frankfurter rate', () {
      final rate = parseFrankfurterLatest(
        frankfurterBody,
        quote: 'USD',
        fetchedAt: t0,
      )!;
      // The whole-baht total shown on home, converted.
      expect(convertFromBase(286, rate), closeTo(8.51708, 1e-6));
      // The unrounded total gives the same displayed cents.
      final total = keptTotalThb([atmSave(), mangoSave()]);
      expect(convertFromBase(total, rate).toStringAsFixed(2), '8.51');
    });

    test('keptByKind splits by kind and lists only kinds that occur', () {
      final byKind = keptByKind([
        atmSave(),
        mangoSave(id: 'a'),
        mangoSave(id: 'b'),
      ]);
      expect(byKind.keys.toSet(), {SaveKind.atmConversion, SaveKind.haggle});
      expect(byKind[SaveKind.haggle], 80);
      expect(
        byKind[SaveKind.atmConversion],
        evaluateAtm(demoReading).extraCostThb,
      );
      expect(keptByKind([mangoSave()]).keys, [SaveKind.haggle]);
    });
  });

  group('newestFirst', () {
    test('sorts by savedAt descending and leaves the input untouched', () {
      final a = mangoSave(id: 'a', at: t0);
      final b = mangoSave(id: 'b', at: t0.add(const Duration(hours: 2)));
      final c = atmSave(id: 'c', at: t0.add(const Duration(hours: 1)));
      final input = [a, b, c];
      expect(newestFirst(input).map((s) => s.id), ['b', 'c', 'a']);
      expect(input.map((s) => s.id), ['a', 'b', 'c']);
    });
  });

  group('persistence: encode and decode', () {
    test('round trip preserves every field of both kinds', () {
      final local = DateTime(2026, 10, 15, 16, 30, 5);
      final saves = [atmSave(at: local), mangoSave(at: t0)];
      final back = decodeSaves(encodeSaves(saves));
      expect(back, hasLength(2));
      for (var i = 0; i < 2; i++) {
        expect(back[i].id, saves[i].id);
        expect(back[i].kind, saves[i].kind);
        expect(back[i].keptThb, saves[i].keptThb);
        expect(back[i].savedAt.isAtSameMomentAs(saves[i].savedAt), isTrue);
        expect(back[i].itemKey, saves[i].itemKey);
        expect(back[i].askedThb, saves[i].askedThb);
        expect(back[i].paidThb, saves[i].paidThb);
      }
    });

    test('toJson writes kind as enum name and savedAt as ISO-8601 UTC', () {
      final j = mangoSave(at: DateTime.utc(2026, 10, 15, 9, 30)).toJson();
      expect(j['kind'], 'haggle');
      expect(j['savedAt'], isA<String>());
      final parsed = DateTime.parse(j['savedAt']! as String);
      expect(parsed.isUtc, isTrue);
      expect(parsed, DateTime.utc(2026, 10, 15, 9, 30));
    });

    test('null, empty and garbage decode to an empty list', () {
      for (final raw in [null, '', 'not json', '{}', '42', '[1,2]']) {
        expect(decodeSaves(raw), isEmpty, reason: 'raw=$raw');
      }
    });

    test('one malformed entry among two valid keeps the two', () {
      final list = jsonDecode(encodeSaves([atmSave(), mangoSave()])) as List;
      list.insert(1, {'id': 'bad', 'kind': 'haggle'}); // keptThb missing
      final back = decodeSaves(jsonEncode(list));
      expect(back.map((s) => s.id), ['atm-1', 'mango-1']);
    });
  });

  group('TripSave.fromJson rejects malformed input', () {
    Map<String, Object?> valid() => mangoSave().toJson();

    test('valid map parses', () {
      expect(TripSave.fromJson(valid()), isNotNull);
    });
    test('not a map gives null', () {
      expect(TripSave.fromJson('x'), isNull);
      expect(TripSave.fromJson(null), isNull);
      expect(TripSave.fromJson(const [1]), isNull);
    });
    test('unknown kind gives null', () {
      expect(TripSave.fromJson(valid()..['kind'] = 'lottery'), isNull);
    });
    test('missing id gives null', () {
      expect(TripSave.fromJson(valid()..remove('id')), isNull);
    });
    test('missing keptThb gives null', () {
      expect(TripSave.fromJson(valid()..remove('keptThb')), isNull);
    });
    test('negative keptThb gives null', () {
      expect(TripSave.fromJson(valid()..['keptThb'] = -1), isNull);
    });
    test('NaN keptThb gives null', () {
      expect(TripSave.fromJson(valid()..['keptThb'] = double.nan), isNull);
    });
    test('bad date gives null', () {
      expect(TripSave.fromJson(valid()..['savedAt'] = 'yesterday'), isNull);
    });
  });

  group('TripSave.isSample', () {
    TripSave sample({bool isSample = true}) => TripSave(
      id: 'demo-visitorBangkok-0',
      kind: SaveKind.haggle,
      keptThb: 40,
      savedAt: t0,
      itemKey: 'mango',
      askedThb: 140,
      paidThb: 100,
      isSample: isSample,
    );

    test('defaults to false', () {
      expect(mangoSave().isSample, isFalse);
      expect(atmSave().isSample, isFalse);
    });

    test('toJson writes isSample only when true', () {
      expect(sample().toJson()['isSample'], true);
      expect(sample(isSample: false).toJson().containsKey('isSample'), isFalse);
      expect(mangoSave().toJson().containsKey('isSample'), isFalse);
    });

    test('round trip keeps isSample true and false', () {
      final back = decodeSaves(encodeSaves([sample(), mangoSave(id: 'own-1')]));
      expect(back.map((s) => s.id), ['demo-visitorBangkok-0', 'own-1']);
      expect(back[0].isSample, isTrue);
      expect(back[1].isSample, isFalse);
    });

    test('missing or non-bool isSample reads as false', () {
      final base = sample().toJson();
      expect(TripSave.fromJson(base..remove('isSample'))!.isSample, isFalse);
      for (final v in ['true', 1, null, const <Object>[]]) {
        final j = sample().toJson()..['isSample'] = v;
        final s = TripSave.fromJson(j);
        expect(s, isNotNull, reason: 'isSample=$v');
        expect(s!.isSample, isFalse, reason: 'isSample=$v');
      }
    });
  });

  group('pastPurchasesFromSaves', () {
    final at = DateTime(2026, 10, 13, 11, 5);
    final sampleHaggle = TripSave(
      id: 'demo-visitorBangkok-2',
      kind: SaveKind.haggle,
      keptThb: 60,
      savedAt: at,
      itemKey: 'mango',
      askedThb: 150,
      paidThb: 90,
      placeName: 'Chatuchak Weekend Market',
      isSample: true,
    );
    final ownHaggle = mangoSave(id: 'own-mango', at: t0);
    final skipped = [
      atmSave(),
      TripSave(
        id: 'dcc-1',
        kind: SaveKind.terminalDcc,
        keptThb: 86.4,
        savedAt: t0,
        placeName: 'Convenience store, Shinjuku',
      ),
      TripSave(
        id: 'no-item',
        kind: SaveKind.haggle,
        keptThb: 10,
        savedAt: t0,
        askedThb: 60,
        paidThb: 50,
      ),
      TripSave(
        id: 'no-paid',
        kind: SaveKind.haggle,
        keptThb: 0,
        savedAt: t0,
        itemKey: 'coconut',
        askedThb: 60,
      ),
      TripSave(
        id: 'paid-zero',
        kind: SaveKind.haggle,
        keptThb: 60,
        savedAt: t0,
        itemKey: 'coconut',
        askedThb: 60,
        paidThb: 0,
      ),
    ];

    test('keeps only haggles with itemKey and paidThb > 0', () {
      final out = pastPurchasesFromSaves([...skipped, sampleHaggle, ownHaggle]);
      expect(out, hasLength(2));
      expect(out.map((p) => p.paidThb), unorderedEquals(<double>[90, 110]));
    });

    test('nothing usable gives an empty list', () {
      expect(pastPurchasesFromSaves(skipped), isEmpty);
      expect(pastPurchasesFromSaves(const []), isEmpty);
    });

    test('copies itemKey, paid, asked, place, at and isSample', () {
      final out = pastPurchasesFromSaves([sampleHaggle, ownHaggle]);
      final sample = out.singleWhere((p) => p.isSample);
      expect(sample.itemKey, 'mango');
      expect(sample.paidThb, 90);
      expect(sample.askedThb, 150);
      expect(sample.placeName, 'Chatuchak Weekend Market');
      expect(sample.at.isAtSameMomentAs(at), isTrue);
      final own = out.singleWhere((p) => !p.isSample);
      expect(own.itemKey, 'mango');
      expect(own.paidThb, 110);
      expect(own.askedThb, 150);
      expect(own.placeName, isNull);
      expect(own.at.isAtSameMomentAs(t0), isTrue);
    });

    test('result feeds priceMemory with the sample counted', () {
      final history = pastPurchasesFromSaves([sampleHaggle]);
      final m = priceMemory('mango', history, DateTime(2026, 10, 15, 16))!;
      expect(m.recordsUsed, 1);
      expect(m.sampleRecords, 1);
      expect(m.lastPlaceName, 'Chatuchak Weekend Market');
    });
  });
}
