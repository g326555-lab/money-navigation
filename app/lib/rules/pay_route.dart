// "Fastest route" for money: which way of paying here adds the least on
// top of the price. Card, ATM cash and QR are compared only from facts we
// have (the traveler's card fee, sourced ATM fees, Google Maps payment
// options); a way we cannot price stays unpriced instead of guessed.

import 'pay_facts.dart';
import 'personal_context.dart';

enum PayMethod { card, cash, qr }

/// How a place takes payment, from Google Maps when known. Null means no
/// evidence either way.
class PlacePayment {
  const PlacePayment({this.cashOnly, this.cards, this.nfc});

  final bool? cashOnly;
  final bool? cards;
  final bool? nfc;

  static const unknown = PlacePayment();

  bool get known => cashOnly != null || cards != null || nfc != null;
}

enum Acceptance { yes, no, unknown }

/// One way to pay and what it adds.
class PayOption {
  const PayOption({
    required this.method,
    required this.accepted,
    required this.extraThb,
    required this.basis,
  });

  final PayMethod method;
  final Acceptance accepted;

  /// What this way adds on top of the price; null when it cannot be worked
  /// out from what we know.
  final double? extraThb;

  /// The facts used, e.g. 'cardFeePercent', 'foreignCardAtmFee'.
  final List<String> basis;
}

/// The comparison for one purchase.
class PayRoute {
  const PayRoute({
    required this.best,
    required this.sameCost,
    required this.forcedByPlace,
    required this.options,
    required this.breakEvenWithdrawalThb,
    required this.amountThb,
  });

  /// Null when nothing can be compared or the cheapest ways cost the same.
  final PayMethod? best;
  final bool sameCost;

  /// Cash wins only because the place takes nothing else.
  final bool forcedByPlace;

  /// Card, cash and QR, in that order.
  final List<PayOption> options;

  /// Withdrawal size above which ATM cash costs less than the card.
  final double? breakEvenWithdrawalThb;
  final double amountThb;

  PayOption option(PayMethod method) =>
      options.firstWhere((o) => o.method == method);
}

PayRoute payRoute({
  required double amountLocal,
  required double localToThb,
  required PlacePayment place,
  required TravelerProfile profile,
  CountryPayFacts? facts,
  double? withdrawalThb,
  double? homeToThb,
  double? qrFeePercent,
}) {
  if (amountLocal <= 0 || localToThb <= 0) {
    throw ArgumentError('amount and rate must be positive');
  }
  final amountThb = _round2(amountLocal * localToThb);
  final cashOnly = place.cashOnly == true;

  final cardFee = profile.cardFeePercent;
  final card = PayOption(
    method: PayMethod.card,
    accepted: cashOnly || place.cards == false
        ? Acceptance.no
        : place.cards == true
        ? Acceptance.yes
        : Acceptance.unknown,
    extraThb: cardFee == null ? null : _round2(amountThb * cardFee / 100),
    basis: ['cardFeePercent', if (place.known) 'placePayment'],
  );

  final fees = _AtmFees.of(profile, facts, localToThb, homeToThb);
  final withdrawal = withdrawalThb == null || withdrawalThb <= 0
      ? null
      : (amountThb > withdrawalThb ? amountThb : withdrawalThb);
  final perWithdrawal = withdrawal == null ? null : fees.total(withdrawal);
  final cash = PayOption(
    method: PayMethod.cash,
    accepted: Acceptance.yes,
    extraThb: perWithdrawal == null
        ? null
        : _round2(perWithdrawal * amountThb / withdrawal!),
    basis: [
      if (facts?.foreignCardAtmFee != null) 'foreignCardAtmFee',
      if (profile.atmFeePolicy != AtmFeePolicy.unknown) 'homeAtmFee',
      if (withdrawal != null) 'withdrawal',
    ],
  );

  final qr = PayOption(
    method: PayMethod.qr,
    accepted: Acceptance.unknown,
    extraThb: qrFeePercent == null
        ? null
        : _round2(amountThb * qrFeePercent / 100),
    basis: [if (qrFeePercent != null) 'qrFeePercent'],
  );

  final options = [card, cash, qr];
  PayMethod? best;
  var sameCost = false;
  if (cashOnly) {
    best = PayMethod.cash;
  } else {
    // The ways still in play. QR stays out unless a sourced fee prices it.
    final candidates = [
      for (final o in options)
        if (o.accepted != Acceptance.no &&
            (o.method != PayMethod.qr || o.extraThb != null))
          o,
    ];
    final priced = [
      for (final o in candidates)
        if (o.extraThb != null) o,
    ]..sort((a, b) => a.extraThb!.compareTo(b.extraThb!));
    // "Cheapest" needs every way in play priced: one priced way next to an
    // unpriced one is not a comparison.
    if (priced.length == candidates.length && priced.isNotEmpty) {
      if (priced.length >= 2 &&
          priced[1].extraThb! - priced[0].extraThb! <= sameCostThb) {
        sameCost = true;
      } else {
        best = priced.first.method;
      }
    }
  }

  return PayRoute(
    best: best,
    sameCost: sameCost,
    forcedByPlace: cashOnly,
    options: options,
    breakEvenWithdrawalThb: fees.breakEven(cardFee),
    amountThb: amountThb,
  );
}

/// ATM fees for one withdrawal, split into fixed baht and a percent.
class _AtmFees {
  const _AtmFees(this.fixedThb, this.percent);

  /// Null fixedThb means the fees cannot be worked out.
  final double? fixedThb;
  final double percent;

  static _AtmFees of(
    TravelerProfile profile,
    CountryPayFacts? facts,
    double localToThb,
    double? homeToThb,
  ) {
    if (profile.atmFeePolicy == AtmFeePolicy.refundsFees) {
      return const _AtmFees(0, 0);
    }
    final local = facts?.foreignCardAtmFee;
    if (local == null) return const _AtmFees(null, 0);
    var fixed = 0.0;
    var percent = 0.0;
    if (local.isPercent) {
      percent += local.value;
    } else if (local.currency == 'THB') {
      fixed += local.value;
    } else if (local.currency == facts!.currency) {
      fixed += local.value * localToThb;
    } else {
      return const _AtmFees(null, 0);
    }
    final value = profile.atmFeeValue;
    switch (profile.atmFeePolicy) {
      case AtmFeePolicy.chargesFixed when value != null && homeToThb != null:
        fixed += value * homeToThb;
      case AtmFeePolicy.chargesPercent when value != null:
        percent += value;
      case AtmFeePolicy.noFee:
        break;
      default:
        return const _AtmFees(null, 0);
    }
    return _AtmFees(fixed, percent);
  }

  double? total(double withdrawalThb) =>
      fixedThb == null ? null : fixedThb! + withdrawalThb * percent / 100;

  double? breakEven(double? cardFeePercent) {
    if (fixedThb == null || cardFeePercent == null || cardFeePercent <= 0) {
      return null;
    }
    if (fixedThb == 0 && percent == 0) return 0;
    final margin = (cardFeePercent - percent) / 100;
    if (margin <= 0) return null;
    return _round2(fixedThb! / margin);
  }
}

double _round2(double v) => (v * 100).round() / 100;
