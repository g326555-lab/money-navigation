import 'personal_context.dart';

/// A counter-offer for an item without a sourced price range: the
/// traveler's own median discount on this item, else on any item they
/// haggled. Null without such a record. Never a made-up percentage.
CounterFromHistory? counterForNewItem(
  String itemKey,
  double askedThb,
  List<PastPurchase> history,
  DateTime now,
) {
  final own = counterFromHistory(itemKey, askedThb, history, now);
  if (own != null) return own;
  const any = 'any';
  return counterFromHistory(any, askedThb, [
    for (final p in history)
      PastPurchase(
        itemKey: any,
        paidThb: p.paidThb,
        askedThb: p.askedThb,
        at: p.at,
        isSample: p.isSample,
      ),
  ], now);
}
