import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:money_navigation/services/auth/trip_record_mapper.dart';

/// The demo ATM prop values (same as test/rules/trip_ledger_test.dart).
const demoReading = AtmScreenReading(
  withdrawalThb: 4000,
  accessFeeThb: 220,
  thbPerUsd: 30.86,
  markupPercent: 5.50,
  chargedThb: 4220,
  chargedUsd: 144.71,
);

final t0 = DateTime.utc(2026, 10, 15, 9, 30);

TripSave atmSave() =>
    saveFromAtm(evaluateAtm(demoReading), id: 'atm-1', savedAt: t0)!;

TripSave mangoSave() => saveFromHaggle(
  id: 'mango-1',
  savedAt: t0.add(const Duration(minutes: 5)),
  itemKey: 'mango',
  askedThb: 150,
  paidThb: 110,
)!;

Map<String, Object?> mangoRow() => {
  'client_id': 'mango-1',
  'kind': 'haggle',
  'kept_thb': 40,
  'saved_at': '2026-10-15T09:35:00+00:00',
  'item_key': 'mango',
  'asked_thb': 150,
  'paid_thb': 110,
  'detail': <String, Object?>{},
};

void expectSameSave(TripSave actual, TripSave expected) {
  expect(actual.id, expected.id);
  expect(actual.kind, expected.kind);
  expect(actual.keptThb, expected.keptThb);
  expect(actual.savedAt.isAtSameMomentAs(expected.savedAt), isTrue);
  expect(actual.itemKey, expected.itemKey);
  expect(actual.askedThb, expected.askedThb);
  expect(actual.paidThb, expected.paidThb);
}

void main() {
  group('tripSaveToRow', () {
    test('demo ATM save maps to an insert row with no user_id', () {
      final row = tripSaveToRow(atmSave());
      expect(row['client_id'], 'atm-1');
      expect(row['kind'], 'atmConversion');
      expect(row['kept_thb'], closeTo(245.75, 0.01));
      expect(row['saved_at'], '2026-10-15T09:30:00.000Z');
      expect(row['item_key'], isNull);
      expect(row['asked_thb'], isNull);
      expect(row['paid_thb'], isNull);
      expect(row['detail'], <String, Object?>{});
      expect(row.containsKey('user_id'), isFalse);
      expect(row.containsKey('id'), isFalse);
    });

    test('haggle save carries item, asked and paid', () {
      final row = tripSaveToRow(mangoSave());
      expect(row['client_id'], 'mango-1');
      expect(row['kind'], 'haggle');
      expect(row['kept_thb'], 40);
      expect(row['item_key'], 'mango');
      expect(row['asked_thb'], 150);
      expect(row['paid_thb'], 110);
    });

    test('passes detail through', () {
      final row = tripSaveToRow(atmSave(), detail: {'markupPercent': 5.5});
      expect(row['detail'], {'markupPercent': 5.5});
    });

    test('a local saved time is written as UTC', () {
      final local = DateTime(2026, 10, 15, 16, 30);
      final s = TripSave(
        id: 'x',
        kind: SaveKind.haggle,
        keptThb: 1,
        savedAt: local,
      );
      expect(tripSaveToRow(s)['saved_at'], local.toUtc().toIso8601String());
    });
  });

  group('round trip', () {
    test('demo ATM save (about 246 THB) survives unchanged', () {
      final s = atmSave();
      expect(s.keptThb.round(), 246);
      expectSameSave(tripSaveFromRow(tripSaveToRow(s))!, s);
    });

    test('mango haggle save (150 asked, 110 paid, 40 kept) survives', () {
      final s = mangoSave();
      expect(s.keptThb, 40);
      expectSameSave(tripSaveFromRow(tripSaveToRow(s))!, s);
    });
  });

  group('tripSaveFromRow', () {
    test('reads a PostgREST row with int numerics and offset time', () {
      final s = tripSaveFromRow(mangoRow())!;
      expectSameSave(s, mangoSave());
    });

    test('accepts numerics as double or numeric strings', () {
      final asDouble = tripSaveFromRow(
        mangoRow()
          ..['kept_thb'] = 40.0
          ..['asked_thb'] = 150.0
          ..['paid_thb'] = 110.0,
      )!;
      expect(asDouble.keptThb, 40);
      final asString = tripSaveFromRow(
        mangoRow()
          ..['kept_thb'] = '40.00'
          ..['asked_thb'] = '150'
          ..['paid_thb'] = '110.50',
      )!;
      expect(asString.keptThb, 40);
      expect(asString.askedThb, 150);
      expect(asString.paidThb, 110.5);
      final atm = tripSaveFromRow(
        tripSaveToRow(atmSave())..['kept_thb'] = '245.75',
      )!;
      expect(atm.keptThb, 245.75);
    });

    test('ignores extra columns such as id, user_id, created_at', () {
      final s = tripSaveFromRow(
        mangoRow()
          ..['id'] = 'b6a0e7c4-uuid'
          ..['user_id'] = 'user-1'
          ..['created_at'] = '2026-10-15T09:36:00+00:00',
      )!;
      expect(s.id, 'mango-1');
    });

    test('null optional columns stay null', () {
      final s = tripSaveFromRow(
        mangoRow()
          ..['item_key'] = null
          ..['asked_thb'] = null
          ..['paid_thb'] = null,
      )!;
      expect(s.itemKey, isNull);
      expect(s.askedThb, isNull);
      expect(s.paidThb, isNull);
    });

    test('zero kept is allowed', () {
      expect(tripSaveFromRow(mangoRow()..['kept_thb'] = 0)!.keptThb, 0);
    });

    test('malformed rows give null', () {
      expect(tripSaveFromRow(null), isNull);
      expect(tripSaveFromRow('row'), isNull);
      expect(tripSaveFromRow([mangoRow()]), isNull);
      expect(tripSaveFromRow(mangoRow()..remove('client_id')), isNull);
      expect(tripSaveFromRow(mangoRow()..['client_id'] = ''), isNull);
      expect(tripSaveFromRow(mangoRow()..['client_id'] = 7), isNull);
      expect(tripSaveFromRow(mangoRow()..['kind'] = 'lottery'), isNull);
      expect(tripSaveFromRow(mangoRow()..remove('kind')), isNull);
      expect(tripSaveFromRow(mangoRow()..['kept_thb'] = -1), isNull);
      expect(tripSaveFromRow(mangoRow()..['kept_thb'] = '-0.5'), isNull);
      expect(tripSaveFromRow(mangoRow()..['kept_thb'] = 'forty'), isNull);
      expect(tripSaveFromRow(mangoRow()..remove('kept_thb')), isNull);
      expect(tripSaveFromRow(mangoRow()..['saved_at'] = 'today'), isNull);
      expect(tripSaveFromRow(mangoRow()..remove('saved_at')), isNull);
    });
  });

  group('tripSavesFromRows', () {
    test('skips bad rows and sorts newest first', () {
      final rows = [
        tripSaveToRow(atmSave()),
        {'kind': 'haggle'},
        null,
        mangoRow(),
        mangoRow()..['kind'] = 'lottery',
      ];
      final saves = tripSavesFromRows(rows);
      expect(saves.map((s) => s.id), ['mango-1', 'atm-1']);
    });

    test('non-list or empty input gives an empty list', () {
      expect(tripSavesFromRows(null), isEmpty);
      expect(tripSavesFromRows('[]'), isEmpty);
      expect(tripSavesFromRows({'client_id': 'x'}), isEmpty);
      expect(tripSavesFromRows(const []), isEmpty);
    });
  });
}
