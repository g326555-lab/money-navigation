import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/cash_wallet_store.dart';
import 'package:money_navigation/rules/cash_wallet.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

final now = DateTime(2026, 10, 16, 11, 0);

CashWalletStore freshStore() =>
    CashWalletStore(prefs: SharedPreferencesAsync());

void main() {
  setUp(resetPreferences);

  test('nothing recorded is "not set", not zero', () async {
    final store = freshStore();
    await store.load();
    expect(store.balance('THB'), isNull);
    expect(displayedCashBalance(store.balance('THB')), 0);
  });

  test('opening balance, ATM, cash spend and a correction add up', () async {
    final store = freshStore();
    await store.setBalance(amount: 1000, currency: 'THB', at: now);
    await store.addCash(
      amount: 4000,
      currency: 'THB',
      sourceId: 'atm-1',
      description: 'ATM withdrawal',
      at: now.add(const Duration(minutes: 1)),
    );
    await store.setLinkedSpend(
      sourceId: 'haggle-1',
      amount: 110,
      currency: 'THB',
      description: 'Market purchase',
      at: now.add(const Duration(minutes: 2)),
    );
    expect(store.balance('THB'), 4890);
    // Correcting to what is really in the wallet keeps the history.
    await store.setBalance(
      amount: 4800,
      currency: 'THB',
      at: now.add(const Duration(minutes: 3)),
    );
    expect(store.balance('THB'), 4800);
    expect(store.movements.first.kind, CashMovementKind.adjustment);
    expect(store.movements.first.amount, -90);

    // A reopened app reads the same ledger.
    final reopened = freshStore();
    await reopened.load();
    expect(reopened.balance('THB'), 4800);
  });

  test('one ATM scan adds its cash once', () async {
    final store = freshStore();
    for (var i = 0; i < 2; i++) {
      await store.addCash(
        amount: 4000,
        currency: 'THB',
        sourceId: 'atm-1',
        description: 'ATM withdrawal',
        at: now,
      );
    }
    expect(store.balance('THB'), 4000);
  });

  test('a corrected receipt replaces its spend; card removes it', () async {
    final store = freshStore();
    await store.setBalance(amount: 1000, currency: 'THB', at: now);
    Future<void> spend(double? amount) => store.setLinkedSpend(
      sourceId: 'bill-1',
      amount: amount,
      currency: 'THB',
      description: 'Receipt payment',
      at: now,
    );
    await spend(233);
    expect(store.balance('THB'), 767);
    await spend(250);
    expect(store.balance('THB'), 750);
    await spend(null);
    expect(store.balance('THB'), 1000);
  });

  test('removing a record takes its cash out; undo puts it back', () async {
    final store = freshStore();
    await store.addCash(
      amount: 4000,
      currency: 'THB',
      sourceId: 'atm-1',
      description: 'ATM withdrawal',
      at: now,
    );
    final removed = await store.removeLinked('atm-1');
    expect(removed, hasLength(1));
    expect(store.balance('THB'), isNull);
    await store.restore(removed);
    await store.restore(removed);
    expect(store.balance('THB'), 4000);
    expect(await store.removeLinked('unknown'), isEmpty);
  });

  test('demo cash never touches the real wallet', () async {
    final personas = parseDemoPersonas(
      File(demoPersonasAsset).readAsStringSync(),
    )!;
    final visitor = personas.byKey('visitorBangkok')!;
    final store = freshStore();
    await store.setBalance(amount: 300, currency: 'THB', at: now);

    store.showDemo(visitor.key, sampleMovements: visitor.cashMovementsAt(now));
    expect(store.balance('THB'), 49044);
    await store.setLinkedSpend(
      sourceId: 'demo-haggle',
      amount: 110,
      currency: 'THB',
      description: 'Market purchase',
      at: now,
    );
    expect(store.balance('THB'), 48934);

    store.showReal();
    expect(store.balance('THB'), 300);
    final reopened = freshStore();
    await reopened.load();
    expect(reopened.balance('THB'), 300);

    // Back in the demo its own change is still there, until a reset.
    store.showDemo(visitor.key, sampleMovements: visitor.cashMovementsAt(now));
    expect(store.balance('THB'), 48934);
    await store.resetDemo();
    expect(store.balance('THB'), 49044);
  });

  test('negative or non-finite amounts are refused', () async {
    final store = freshStore();
    expect(
      () => store.setBalance(amount: -1, currency: 'THB'),
      throwsArgumentError,
    );
    expect(
      () => store.setLinkedSpend(
        sourceId: 'x',
        amount: double.nan,
        currency: 'THB',
        description: 'x',
      ),
      throwsArgumentError,
    );
    await store.recordManualMovement(
      amount: 0,
      currency: 'THB',
      spend: true,
      description: 'x',
    );
    expect(store.balance('THB'), isNull);
  });
}
