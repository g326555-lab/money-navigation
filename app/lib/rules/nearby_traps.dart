// "Speed camera warnings" around the traveler: the nearest ATM's fee for a
// foreign card and its conversion offer (from the sourced facts file), and
// markets Google Maps lists as cash only. No evidence, no warning.

import 'pay_facts.dart';
import 'pay_route.dart';

enum PlaceKind { atm, market, other }

/// A place near the traveler, from Google Maps.
class NearbyPlaceFact {
  const NearbyPlaceFact({
    required this.name,
    required this.kind,
    this.payment = PlacePayment.unknown,
    this.distanceM,
    this.lat,
    this.lng,
  });

  final String name;
  final PlaceKind kind;
  final PlacePayment payment;
  final double? distanceM;

  /// Where Google Maps puts the place, so it can be pinned and routed to.
  final double? lat;
  final double? lng;
}

enum TrapKind { atmFee, atmConversion, cashOnlyMarket }

/// One warning and where its fact came from.
class TrapWarning {
  const TrapWarning({
    required this.kind,
    required this.placeName,
    required this.distanceM,
    required this.source,
    this.fee,
    this.checked,
  });

  final TrapKind kind;
  final String placeName;
  final double? distanceM;

  /// [TrapKind.atmFee] only.
  final SourcedFee? fee;
  final String source;

  /// The day the fee's source was read; null for live Google Maps facts.
  final String? checked;
}

const googleMapsSource = 'Google Maps';

List<TrapWarning> nearbyTraps(
  List<NearbyPlaceFact> places,
  CountryPayFacts? facts, {
  int limit = 3,
}) {
  int byDistance(NearbyPlaceFact a, NearbyPlaceFact b) {
    final da = a.distanceM, db = b.distanceM;
    if (da == null && db == null) return 0;
    if (da == null) return 1;
    if (db == null) return -1;
    return da.compareTo(db);
  }

  final atms = [
    for (final p in places)
      if (p.kind == PlaceKind.atm) p,
  ];
  // List.sort is not stable; mergeSort-like stability via index.
  final atm = _nearest(atms, byDistance);
  final markets = [
    for (final p in places)
      if (p.kind == PlaceKind.market && p.payment.cashOnly == true) p,
  ];
  final sortedMarkets = _stableSorted(markets, byDistance);

  final fee = facts?.foreignCardAtmFee;
  final warnings = [
    if (atm != null && fee != null)
      TrapWarning(
        kind: TrapKind.atmFee,
        placeName: atm.name,
        distanceM: atm.distanceM,
        fee: fee,
        source: fee.source,
        checked: fee.checked,
      ),
    if (atm != null &&
        facts != null &&
        facts.atmOffersConversion &&
        facts.atmConversionSource != null)
      TrapWarning(
        kind: TrapKind.atmConversion,
        placeName: atm.name,
        distanceM: atm.distanceM,
        source: facts.atmConversionSource!,
        checked: facts.atmConversionChecked,
      ),
    for (final m in sortedMarkets)
      TrapWarning(
        kind: TrapKind.cashOnlyMarket,
        placeName: m.name,
        distanceM: m.distanceM,
        source: googleMapsSource,
      ),
  ];
  return warnings.take(limit < 0 ? 0 : limit).toList();
}

T? _nearest<T>(List<T> items, int Function(T, T) compare) {
  T? best;
  for (final item in items) {
    if (best == null || compare(item, best) < 0) best = item;
  }
  return best;
}

List<T> _stableSorted<T>(List<T> items, int Function(T, T) compare) {
  final indexed = [for (final (i, x) in items.indexed) (i, x)]
    ..sort((a, b) {
      final c = compare(a.$2, b.$2);
      return c != 0 ? c : a.$1.compareTo(b.$1);
    });
  return [for (final (_, x) in indexed) x];
}
