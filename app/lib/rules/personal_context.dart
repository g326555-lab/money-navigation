// The traveler's own records, turned into evidence for a verdict. Every
// personal statement the app makes comes from one of these functions and
// carries the records it used (count and dates), so nothing personal is
// ever invented. Pure Dart; runs on the phone before anything reaches the
// cloud.

/// One haggle the traveler actually finished.
class PastPurchase {
  const PastPurchase({
    required this.itemKey,
    required this.paidThb,
    this.askedThb,
    this.placeName,
    required this.at,
    this.isSample = false,
  });

  final String itemKey;
  final double paidThb;
  final double? askedThb;
  final String? placeName;
  final DateTime at;
  final bool isSample;
}

enum AtmFeePolicy { chargesFixed, chargesPercent, refundsFees, noFee, unknown }

/// What the traveler told us about their cards.
class TravelerProfile {
  const TravelerProfile({
    this.cardFeePercent,
    this.atmFeePolicy = AtmFeePolicy.unknown,
    this.atmFeeValue,
  });

  /// Foreign transaction fee of the card, in percent.
  final double? cardFeePercent;
  final AtmFeePolicy atmFeePolicy;

  /// [AtmFeePolicy.chargesFixed]: amount in the home currency;
  /// [AtmFeePolicy.chargesPercent]: percent of the withdrawal.
  final double? atmFeeValue;
}

/// What the traveler paid for an item before.
class PriceMemory {
  const PriceMemory({
    required this.itemKey,
    required this.lastPaidThb,
    required this.lastPlaceName,
    required this.daysAgo,
    required this.lastAskedThb,
    required this.lastDiscountPercent,
    required this.minPaidThb,
    required this.maxPaidThb,
    required this.recordsUsed,
    required this.samePlaceRecords,
    required this.sampleRecords,
    required this.dates,
  });

  final String itemKey;
  final double lastPaidThb;
  final String? lastPlaceName;

  /// Calendar days between the last purchase and now: 0 today, 1 yesterday.
  final int daysAgo;
  final double? lastAskedThb;

  /// How much below the asking price the last purchase was, whole percent.
  final double? lastDiscountPercent;
  final double minPaidThb;
  final double maxPaidThb;
  final int recordsUsed;
  final int samePlaceRecords;

  /// How many of the records used are demo samples (shown as such).
  final int sampleRecords;

  /// Dates of the records used, newest first.
  final List<DateTime> dates;
}

/// The traveler's earlier purchases of [itemKey] before [now], or null when
/// there are none.
PriceMemory? priceMemory(
  String itemKey,
  List<PastPurchase> history,
  DateTime now, {
  String? placeName,
  bool includeSamples = true,
}) {
  final used = _past(
    history,
    now,
    includeSamples: includeSamples,
  ).where((p) => p.itemKey == itemKey).toList();
  if (used.isEmpty) return null;
  final last = used.first;
  final paid = [for (final p in used) p.paidThb];
  final asked = last.askedThb;
  return PriceMemory(
    itemKey: itemKey,
    lastPaidThb: last.paidThb,
    lastPlaceName: last.placeName,
    daysAgo: _dayOf(now).difference(_dayOf(last.at)).inDays,
    lastAskedThb: asked,
    lastDiscountPercent: asked == null || asked <= 0
        ? null
        : ((asked - last.paidThb) / asked * 100).roundToDouble(),
    minPaidThb: paid.reduce((a, b) => a < b ? a : b),
    maxPaidThb: paid.reduce((a, b) => a > b ? a : b),
    recordsUsed: used.length,
    samePlaceRecords: placeName == null
        ? 0
        : used.where((p) => p.placeName == placeName).length,
    sampleRecords: used.where((p) => p.isSample).length,
    dates: [for (final p in used) p.at],
  );
}

/// A counter-offer learned from the traveler's own haggling.
class CounterFromHistory {
  const CounterFromHistory({
    required this.offerThb,
    required this.medianDiscountPercent,
    required this.recordsUsed,
    required this.sampleRecords,
    required this.dates,
  });

  final double offerThb;
  final double medianDiscountPercent;
  final int recordsUsed;
  final int sampleRecords;
  final List<DateTime> dates;
}

/// [askedThb] less the median discount the traveler got on [itemKey]
/// before, rounded down to 5 baht. Null without such a record or when the
/// traveler never got below the asking price.
CounterFromHistory? counterFromHistory(
  String itemKey,
  double askedThb,
  List<PastPurchase> history,
  DateTime now,
) {
  final used = _past(history, now)
      .where(
        (p) => p.itemKey == itemKey && p.askedThb != null && p.askedThb! > 0,
      )
      .toList();
  if (used.isEmpty || askedThb <= 0) return null;
  final discount = _median([
    for (final p in used) (p.askedThb! - p.paidThb) / p.askedThb!,
  ]);
  if (discount <= 0) return null;
  final offer = (askedThb * (1 - discount) / 5).floor() * 5.0;
  // Too small to say out loud as a counter-offer.
  if (offer <= 5) return null;
  return CounterFromHistory(
    offerThb: offer,
    medianDiscountPercent: (discount * 10000).round() / 100,
    recordsUsed: used.length,
    sampleRecords: used.where((p) => p.isSample).length,
    dates: [for (final p in used) p.at],
  );
}

enum PayWay { card, cash, same, unknown }

/// What paying one amount costs by card and by ATM cash.
class PayCost {
  const PayCost({
    required this.cardCostThb,
    required this.cashCostThb,
    required this.cheaper,
    required this.basis,
  });

  final double cardCostThb;

  /// Null when the home bank's ATM fee is unknown.
  final double? cashCostThb;
  final PayWay cheaper;

  /// Profile fields the comparison used.
  final List<String> basis;
}

/// Below this difference in baht the two ways cost the same.
const sameCostThb = 0.5;

/// Paying [amountThb] by card (the card's foreign fee) or with cash from an
/// ATM (this purchase's share of one [withdrawalThb] withdrawal's fees).
/// Null when the card fee is not known.
PayCost? cardOrCash(
  double amountThb,
  TravelerProfile profile, {
  required double localAtmFeeThb,
  required double withdrawalThb,
  double? homeToThb,
}) {
  final cardFee = profile.cardFeePercent;
  if (cardFee == null || amountThb <= 0 || withdrawalThb <= 0) return null;
  final card = _round2(amountThb * cardFee / 100);
  final basis = ['cardFeePercent', 'atmFeePolicy'];
  final value = profile.atmFeeValue;
  final double? feesPerWithdrawal = switch (profile.atmFeePolicy) {
    AtmFeePolicy.chargesFixed when value != null && homeToThb != null =>
      localAtmFeeThb + value * homeToThb,
    AtmFeePolicy.chargesPercent when value != null =>
      localAtmFeeThb + withdrawalThb * value / 100,
    AtmFeePolicy.refundsFees => 0,
    AtmFeePolicy.noFee => localAtmFeeThb,
    _ => null,
  };
  if (value != null &&
      (profile.atmFeePolicy == AtmFeePolicy.chargesFixed ||
          profile.atmFeePolicy == AtmFeePolicy.chargesPercent)) {
    basis.add('atmFeeValue');
  }
  if (feesPerWithdrawal == null) {
    return PayCost(
      cardCostThb: card,
      cashCostThb: null,
      cheaper: PayWay.unknown,
      basis: basis,
    );
  }
  final cash = _round2(feesPerWithdrawal * amountThb / withdrawalThb);
  final PayWay cheaper;
  if ((card - cash).abs() <= sameCostThb) {
    cheaper = PayWay.same;
  } else {
    cheaper = card < cash ? PayWay.card : PayWay.cash;
  }
  return PayCost(
    cardCostThb: card,
    cashCostThb: cash,
    cheaper: cheaper,
    basis: basis,
  );
}

/// An estimate of the cash a day needs, from the traveler's own past days.
class CashEstimate {
  const CashEstimate({
    required this.amountThb,
    required this.daysUsed,
    required this.sampleRecords,
    required this.days,
  });

  final double amountThb;
  final int daysUsed;

  /// Demo sample purchases among those the estimate used.
  final int sampleRecords;

  /// Always true: this is a pattern from past days, not a known amount.
  bool get isEstimate => true;
  final List<DateTime> days;
}

/// Days of history the morning estimate looks back over.
const cashEstimateDays = 7;

/// Median daily cash spend over the last [cashEstimateDays] earlier days
/// with purchases, rounded up to 100 baht. Needs at least two such days.
CashEstimate? morningCash(List<PastPurchase> history, DateTime now) {
  final today = _dayOf(now);
  final byDay = <DateTime, double>{};
  final samplesByDay = <DateTime, int>{};
  for (final p in _past(history, now)) {
    final day = _dayOf(p.at);
    if (!day.isBefore(today)) continue;
    byDay[day] = (byDay[day] ?? 0) + p.paidThb;
    if (p.isSample) samplesByDay[day] = (samplesByDay[day] ?? 0) + 1;
  }
  final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
  final recent = days.take(cashEstimateDays).toList();
  if (recent.length < 2) return null;
  final median = _median([for (final d in recent) byDay[d]!]);
  return CashEstimate(
    amountThb: (median / 100).ceil() * 100.0,
    daysUsed: recent.length,
    sampleRecords: recent.fold(0, (n, d) => n + (samplesByDay[d] ?? 0)),
    days: recent,
  );
}

/// Most purchases sent to the cloud AI.
const cloudSummaryLimit = 10;

/// The only personal data that may go to the cloud AI: item keys, prices
/// to the baht, counts and day offsets. No names, places or coordinates.
Map<String, Object?> cloudSafeSummary(
  List<PastPurchase> history,
  DateTime now,
) {
  final past = _past(history, now);
  return {
    'purchases': [
      for (final p in past.take(cloudSummaryLimit))
        {
          'item': p.itemKey,
          'paid': p.paidThb.round(),
          if (p.askedThb != null) 'asked': p.askedThb!.round(),
          'daysAgo': _dayOf(now).difference(_dayOf(p.at)).inDays,
        },
    ],
    'count': past.length,
  };
}

/// Valid purchases strictly before [now], newest first.
List<PastPurchase> _past(
  List<PastPurchase> history,
  DateTime now, {
  bool includeSamples = true,
}) => [
  for (final p in history)
    if (p.at.isBefore(now) && p.paidThb > 0 && (includeSamples || !p.isSample))
      p,
]..sort((a, b) => b.at.compareTo(a.at));

/// The calendar day of [t] in its own zone, as a UTC date so that day
/// counts across a daylight-saving change stay whole days.
DateTime _dayOf(DateTime t) => DateTime.utc(t.year, t.month, t.day);

double _round2(double v) => (v * 100).round() / 100;

double _median(List<double> values) {
  final sorted = [...values]..sort();
  final mid = sorted.length ~/ 2;
  return sorted.length.isOdd
      ? sorted[mid]
      : (sorted[mid - 1] + sorted[mid]) / 2;
}
