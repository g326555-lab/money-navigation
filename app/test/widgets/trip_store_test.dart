import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/trip_store.dart';
import 'package:money_navigation/rules/trip_ledger.dart';

import 'harness.dart';

void main() {
  setUp(resetPreferences);

  Future<TripStore> reloaded() async {
    final fresh = TripStore();
    await fresh.load();
    return fresh;
  }

  test('an empty device loads an empty, loaded trip', () async {
    final store = await reloaded();
    expect(store.loaded, isTrue);
    expect(store.saves, isEmpty);
  });

  test('added saves survive a fresh store instance, newest first', () async {
    final store = TripStore();
    await store.load();
    await store.add(demoAtmSave());
    await store.add(demoMangoSave());

    final fresh = await reloaded();
    expect(fresh.saves.map((s) => s.id), ['mango-1', 'atm-1']);
    expect(keptTotalThb(fresh.saves).round(), 286);
    final mango = fresh.saves.first;
    expect(mango.kind, SaveKind.haggle);
    expect(mango.itemKey, 'mango');
    expect(mango.askedThb, 150);
    expect(mango.paidThb, 110);
    expect(mango.keptThb, 40);
  });

  test('removed saves stay removed after reload', () async {
    final store = TripStore();
    await store.load();
    await store.add(demoAtmSave());
    await store.add(demoMangoSave());
    await store.remove('atm-1');

    expect(store.contains('atm-1'), isFalse);
    final fresh = await reloaded();
    expect(fresh.saves.map((s) => s.id), ['mango-1']);
  });

  test(
    'adding the same id twice keeps one save (undo re-adds safely)',
    () async {
      final store = TripStore();
      await store.load();
      await store.add(demoAtmSave());
      await store.add(demoAtmSave());

      expect(store.saves, hasLength(1));
      final fresh = await reloaded();
      expect(fresh.saves, hasLength(1));
      expect(fresh.saves.single.id, 'atm-1');
    },
  );

  test('add notifies listeners and records lastAdded', () async {
    final store = TripStore();
    await store.load();
    var notified = 0;
    store.addListener(() => notified++);
    final save = demoMangoSave();
    await store.add(save);
    expect(notified, 1);
    expect(store.lastAdded, same(save));
  });
}
