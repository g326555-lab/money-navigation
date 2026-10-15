import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/cash_wallet.dart';

void main() {
  final now = DateTime.utc(2026, 10, 16);

  test('cash balance tracks only the selected currency', () {
    final movements = [
      CashMovement(
        id: 'opening',
        kind: CashMovementKind.openingBalance,
        amount: 2000,
        currency: 'THB',
        at: now,
      ),
      CashMovement(
        id: 'atm',
        kind: CashMovementKind.withdrawal,
        amount: 1000,
        currency: 'THB',
        at: now,
      ),
      CashMovement(
        id: 'meal',
        kind: CashMovementKind.cashSpend,
        amount: 350,
        currency: 'THB',
        at: now,
      ),
      CashMovement(
        id: 'yen',
        kind: CashMovementKind.openingBalance,
        amount: 5000,
        currency: 'JPY',
        at: now,
      ),
    ];

    expect(cashBalance(movements, 'THB'), 2650);
    expect(cashBalance(movements, 'JPY'), 5000);
    expect(cashBalance(movements, 'USD'), isNull);
  });

  test('the card shows 0 before anything is recorded, never stores it', () {
    expect(cashBalance(const [], 'THB'), isNull);
    expect(displayedCashBalance(null), 0);
    expect(displayedCashBalance(1250), 1250);
    expect(displayedCashBalance(-40), -40);
  });

  test('movement JSON preserves ledger fields', () {
    final movement = CashMovement(
      id: 'spend',
      kind: CashMovementKind.cashSpend,
      amount: 99.5,
      currency: 'THB',
      at: now,
      description: 'Lunch',
      sourceId: 'receipt-1',
    );

    expect(
      CashMovement.fromJson(movement.toJson())?.toJson(),
      movement.toJson(),
    );
  });
}
