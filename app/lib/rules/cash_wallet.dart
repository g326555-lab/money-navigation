/// A cash movement recorded by the traveler or linked to a confirmed action.
enum CashMovementKind {
  openingBalance,
  withdrawal,
  cashSpend,
  adjustment,
  exchange,
}

class CashMovement {
  const CashMovement({
    required this.id,
    required this.kind,
    required this.amount,
    required this.currency,
    required this.at,
    this.description,
    this.sourceId,
  });

  final String id;
  final CashMovementKind kind;

  /// Positive for money received, negative for an adjustment down.
  /// `cashSpend` is always stored as a positive amount and subtracted below.
  final double amount;
  final String currency;
  final DateTime at;
  final String? description;

  /// The receipt, ATM result, or haggle record this movement came from.
  final String? sourceId;

  double get signedAmount =>
      kind == CashMovementKind.cashSpend ? -amount : amount;

  Map<String, Object?> toJson() => {
    'id': id,
    'kind': kind.name,
    'amount': amount,
    'currency': currency,
    'at': at.toUtc().toIso8601String(),
    if (description != null) 'description': description,
    if (sourceId != null) 'sourceId': sourceId,
  };

  static CashMovement? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final kind = CashMovementKind.values.asNameMap()[value['kind']];
    final amount = value['amount'];
    final currency = value['currency'];
    final at = value['at'] is String
        ? DateTime.tryParse(value['at'] as String)
        : null;
    if (id is! String ||
        id.isEmpty ||
        kind == null ||
        amount is! num ||
        !amount.isFinite ||
        currency is! String ||
        currency.length != 3 ||
        at == null) {
      return null;
    }
    final parsedAmount = amount.toDouble();
    if ((parsedAmount < 0 && kind != CashMovementKind.adjustment) ||
        (kind == CashMovementKind.cashSpend && parsedAmount == 0)) {
      return null;
    }
    return CashMovement(
      id: id,
      kind: kind,
      amount: parsedAmount,
      currency: currency,
      at: at.toLocal(),
      description: value['description'] is String
          ? value['description'] as String
          : null,
      sourceId: value['sourceId'] is String
          ? value['sourceId'] as String
          : null,
    );
  }
}

double? cashBalance(Iterable<CashMovement> movements, String currency) {
  final matching = movements.where((m) => m.currency == currency);
  if (matching.isEmpty) return null;
  return matching.fold<double>(0, (balance, m) => balance + m.signedAmount);
}

/// The figure the wallet card shows: the recorded balance, or 0 before
/// anything is recorded. Display only; the ledger keeps "not set" as null.
double displayedCashBalance(double? recorded) => recorded ?? 0;
