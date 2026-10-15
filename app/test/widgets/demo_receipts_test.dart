import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/receipt_store.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

const receiptsKey = 'receipts_v1';
const demoReceiptsKey = 'demo_receipts_v1';

final now = DateTime(2026, 10, 15, 16, 0);

DemoPersonas personas() =>
    parseDemoPersonas(File(demoPersonasAsset).readAsStringSync())!;

ReceiptStore freshStore() => ReceiptStore(prefs: SharedPreferencesAsync());

/// What app.dart's _onSettings does when a demo persona is switched on.
void switchOn(ReceiptStore store, DemoPersona persona) =>
    store.showDemo(persona.key, persona.receiptsAt(now));

ReceiptRecord own(String id, {double total = 120}) => ReceiptRecord(
  id: id,
  savedAt: now.subtract(const Duration(hours: 3)),
  totalThb: total,
  verified: false,
  userCorrected: true,
  merchantName: 'Corner shop',
);

Future<Object?> stored(String key) async {
  final raw = await SharedPreferencesAsync().getString(key);
  return raw == null ? null : jsonDecode(raw);
}

void main() {
  setUp(resetPreferences);

  test('switching the visitor on shows its 5 sample receipts', () async {
    final store = freshStore();
    await store.load();
    final visitor = personas().byKey('visitorBangkok')!;
    switchOn(store, visitor);

    expect(store.showingDemo, isTrue);
    expect(store.records, hasLength(5));
    expect(store.records.every((r) => r.isSample && r.verified), isTrue);
    expect(
      store.records.map((r) => r.id),
      unorderedEquals(visitor.receiptsAt(now).map((r) => r.id)),
    );
    expect(
      store.records.map((r) => r.merchantName),
      containsAll(['Thai restaurant', '7-Eleven', 'MBK Center food court']),
    );
  });

  test('the Thai persona has no sample receipts', () async {
    final store = freshStore();
    await store.load();
    switchOn(store, personas().byKey('thaiTokyo')!);
    expect(store.showingDemo, isTrue);
    expect(store.records, isEmpty);
  });

  test('showReal gives back the real receipts untouched', () async {
    final store = freshStore();
    await store.load();
    await store.save(own('mine-1'));
    await store.save(own('mine-2', total: 80));
    final before = [for (final r in store.records) jsonEncode(r.toJson())];

    switchOn(store, personas().byKey('visitorBangkok')!);
    expect(store.records.any((r) => r.id.startsWith('mine-')), isFalse);
    store.showReal();

    expect(store.showingDemo, isFalse);
    expect([for (final r in store.records) jsonEncode(r.toJson())], before);
    expect(store.records.any((r) => r.isSample), isFalse);
  });

  test(
    'a receipt saved during the demo goes to the demo ledger only',
    () async {
      final store = freshStore();
      await store.load();
      await store.save(own('mine-1'));
      final visitor = personas().byKey('visitorBangkok')!;
      switchOn(store, visitor);

      await store.save(own('demo-save'));
      expect(store.records, hasLength(6));
      expect(store.contains('demo-save'), isTrue);

      // The real records, here and on the phone, never see it.
      final real = (await stored(receiptsKey))! as List;
      expect(real.map((e) => (e as Map)['id']), ['mine-1']);
      final demo = (await stored(demoReceiptsKey))! as Map;
      expect(
        (demo[visitor.key] as List).map((e) => (e as Map)['id']),
        contains('demo-save'),
      );

      store.showReal();
      expect(store.records.map((r) => r.id), ['mine-1']);

      // Back in the demo the save is still in its ledger, with the samples.
      switchOn(store, visitor);
      expect(store.contains('demo-save'), isTrue);
      expect(store.records.where((r) => r.isSample), hasLength(5));

      // A later app start reads the real list without it.
      final reopened = freshStore();
      await reopened.load();
      expect(reopened.records.map((r) => r.id), ['mine-1']);

      // Resetting the demo forgets it and leaves the samples.
      await store.resetDemo();
      switchOn(store, visitor);
      expect(store.contains('demo-save'), isFalse);
      expect(store.records, hasLength(5));
      expect(await stored(demoReceiptsKey), isNull);
      store.showReal();
      expect(store.records.map((r) => r.id), ['mine-1']);
    },
  );
}
