import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/trip_store.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

/// An account that records every call it gets.
class FakeRemote implements TripRemote {
  FakeRemote([List<TripSave> account = const []]) : account = [...account];

  final List<TripSave> account;
  final upserted = <String>[];
  final removed = <String>[];

  @override
  Future<List<TripSave>> load() async => [...account];

  @override
  Future<void> upsert(TripSave save) async {
    upserted.add(save.id);
    account
      ..removeWhere((s) => s.id == save.id)
      ..add(save);
  }

  @override
  Future<void> upsertAll(List<TripSave> saves) async {
    for (final s in saves) {
      await upsert(s);
    }
  }

  @override
  Future<void> remove(String id) async {
    removed.add(id);
    account.removeWhere((s) => s.id == id);
  }
}

const visitorKey = 'visitorBangkok';
const thaiKey = 'thaiTokyo';

TripSave sample(String key, int i, {double kept = 10}) => TripSave(
  id: 'demo-$key-$i',
  kind: SaveKind.haggle,
  keptThb: kept,
  savedAt: DateTime(2026, 10, 13, 10 + i),
  itemKey: 'mango',
  askedThb: 100 + kept,
  paidThb: 100,
  isSample: true,
);

final visitorSamples = [sample(visitorKey, 0), sample(visitorKey, 1)];
final thaiSamples = [
  TripSave(
    id: 'demo-$thaiKey-0',
    kind: SaveKind.terminalDcc,
    keptThb: 86.4,
    savedAt: DateTime(2026, 10, 14, 18, 5),
    isSample: true,
  ),
];

Iterable<String> ids(Iterable<TripSave> saves) => saves.map((s) => s.id);

void main() {
  setUp(resetPreferences);

  Future<TripStore> loadedStore() async {
    final store = TripStore();
    await store.load();
    return store;
  }

  /// A store with one real save on the phone.
  Future<TripStore> storeWithRealSave() async {
    final store = await loadedStore();
    await store.add(demoMangoSave());
    return store;
  }

  Future<String?> storedReal() =>
      SharedPreferencesAsync().getString('trip_saves_v1');
  Future<String?> storedDemo() =>
      SharedPreferencesAsync().getString('demo_trips_v1');

  test('starts on the real saves', () async {
    final store = await storeWithRealSave();
    expect(store.showingDemo, isFalse);
    expect(ids(store.saves), ['mango-1']);
  });

  test('showDemo shows the samples and notifies', () async {
    final store = await storeWithRealSave();
    var notified = 0;
    store.addListener(() => notified++);
    store.showDemo(visitorKey, visitorSamples);
    expect(store.showingDemo, isTrue);
    expect(ids(store.saves), unorderedEquals(ids(visitorSamples)));
    expect(store.saves.every((s) => s.isSample), isTrue);
    expect(notified, greaterThanOrEqualTo(1));
  });

  test('showReal restores the real saves and notifies', () async {
    final store = await storeWithRealSave();
    store.showDemo(visitorKey, visitorSamples);
    var notified = 0;
    store.addListener(() => notified++);
    store.showReal();
    expect(store.showingDemo, isFalse);
    expect(ids(store.saves), ['mango-1']);
    expect(notified, greaterThanOrEqualTo(1));
  });

  test('add in demo goes to the demo ledger only, never the remote', () async {
    final store = await storeWithRealSave();
    final remote = FakeRemote();
    await store.attach(remote);
    final upsertsBefore = remote.upserted.length;

    store.showDemo(visitorKey, visitorSamples);
    await store.add(demoAtmSave(id: 'demo-added'));
    expect(
      ids(store.saves),
      unorderedEquals([...ids(visitorSamples), 'demo-added']),
    );
    expect(remote.upserted.length, upsertsBefore);
    expect(remote.account.map((s) => s.id), isNot(contains('demo-added')));
    expect(await storedReal(), isNot(contains('demo-added')));
    expect(await storedDemo(), contains('demo-added'));

    store.showReal();
    expect(ids(store.saves), ['mango-1']);
  });

  test('remove in demo changes the demo ledger only', () async {
    final store = await storeWithRealSave();
    final remote = FakeRemote();
    await store.attach(remote);

    store.showDemo(visitorKey, visitorSamples);
    await store.remove('demo-$visitorKey-0');
    expect(ids(store.saves), ['demo-$visitorKey-1']);
    // Removing an id that only exists among the real saves leaves them be.
    await store.remove('mango-1');
    expect(remote.removed, isEmpty);
    expect(remote.account.map((s) => s.id), contains('mango-1'));

    store.showReal();
    expect(ids(store.saves), ['mango-1']);
    expect(await storedReal(), contains('mango-1'));
  });

  test(
    'real saves are untouched on a fresh instance after demo adds',
    () async {
      final store = await storeWithRealSave();
      store.showDemo(visitorKey, visitorSamples);
      await store.add(demoAtmSave(id: 'demo-added'));

      final fresh = await loadedStore();
      expect(ids(fresh.saves), ['mango-1']);
    },
  );

  test('each persona keeps its own ledger across swaps', () async {
    final store = await storeWithRealSave();
    store.showDemo(visitorKey, visitorSamples);
    await store.add(demoAtmSave(id: 'visitor-added'));

    store.showDemo(thaiKey, thaiSamples);
    expect(ids(store.saves), unorderedEquals(ids(thaiSamples)));
    await store.add(demoAtmSave(id: 'thai-added'));

    store.showDemo(visitorKey, visitorSamples);
    expect(
      ids(store.saves),
      unorderedEquals([...ids(visitorSamples), 'visitor-added']),
    );

    store.showReal();
    store.showDemo(thaiKey, thaiSamples);
    expect(
      ids(store.saves),
      unorderedEquals([...ids(thaiSamples), 'thai-added']),
    );
  });

  test('demo ledgers persist: a new store shows the stored ledger', () async {
    final store = await storeWithRealSave();
    store.showDemo(visitorKey, visitorSamples);
    await store.add(demoAtmSave(id: 'visitor-added'));
    await store.remove('demo-$visitorKey-0');

    final stored = jsonDecode((await storedDemo())!);
    expect(stored, isA<Map>());
    expect((stored as Map).keys, contains(visitorKey));

    final fresh = await loadedStore();
    fresh.showDemo(visitorKey, visitorSamples);
    expect(
      ids(fresh.saves),
      unorderedEquals(['demo-$visitorKey-1', 'visitor-added']),
    );
    // Persona without a stored ledger still starts from its samples.
    fresh.showDemo(thaiKey, thaiSamples);
    expect(ids(fresh.saves), unorderedEquals(ids(thaiSamples)));
  });

  test('resetDemo forgets every demo ledger', () async {
    final store = await storeWithRealSave();
    store.showDemo(visitorKey, visitorSamples);
    await store.add(demoAtmSave(id: 'visitor-added'));
    store.showDemo(thaiKey, thaiSamples);
    await store.remove('demo-$thaiKey-0');

    await store.resetDemo();
    store.showDemo(visitorKey, visitorSamples);
    expect(ids(store.saves), unorderedEquals(ids(visitorSamples)));
    store.showDemo(thaiKey, thaiSamples);
    expect(ids(store.saves), unorderedEquals(ids(thaiSamples)));

    final fresh = await loadedStore();
    fresh.showDemo(visitorKey, visitorSamples);
    expect(ids(fresh.saves), unorderedEquals(ids(visitorSamples)));
    fresh.showReal();
    expect(ids(fresh.saves), ['mango-1']);
  });

  test(
    'showDemo before load completes shows the stored ledger once loaded',
    () async {
      final first = await storeWithRealSave();
      first.showDemo(visitorKey, visitorSamples);
      await first.add(demoAtmSave(id: 'visitor-added'));

      final store = TripStore();
      final loading = store.load();
      store.showDemo(visitorKey, visitorSamples);
      await loading;
      expect(store.showingDemo, isTrue);
      expect(
        ids(store.saves),
        unorderedEquals([...ids(visitorSamples), 'visitor-added']),
      );
      store.showReal();
      expect(ids(store.saves), ['mango-1']);
    },
  );

  test('showDemo before load is even called works once loaded', () async {
    await storeWithRealSave();
    final store = TripStore();
    store.showDemo(thaiKey, thaiSamples);
    await store.load();
    expect(store.showingDemo, isTrue);
    expect(ids(store.saves), unorderedEquals(ids(thaiSamples)));
    store.showReal();
    expect(ids(store.saves), ['mango-1']);
  });

  test(
    'attach while demo shown keeps the demo view; real saves sync',
    () async {
      final store = await storeWithRealSave();
      store.showDemo(visitorKey, visitorSamples);
      await store.add(demoAtmSave(id: 'visitor-added'));

      final remote = FakeRemote([demoAtmSave(id: 'account-atm')]);
      await store.attach(remote);

      expect(store.showingDemo, isTrue);
      expect(
        ids(store.saves),
        unorderedEquals([...ids(visitorSamples), 'visitor-added']),
      );
      // Only the real phone save went up; no sample, no demo add.
      expect(remote.upserted, ['mango-1']);

      store.showReal();
      expect(ids(store.saves), unorderedEquals(['account-atm', 'mango-1']));
    },
  );

  test('detach while demo shown keeps the demo view', () async {
    final store = await storeWithRealSave();
    await store.attach(FakeRemote([demoAtmSave(id: 'account-atm')]));
    store.showDemo(visitorKey, visitorSamples);

    await store.detach();
    expect(store.showingDemo, isTrue);
    expect(ids(store.saves), unorderedEquals(ids(visitorSamples)));

    store.showReal();
    // Everything had reached the account, so nothing stays on the phone.
    expect(store.saves, isEmpty);
  });
}
