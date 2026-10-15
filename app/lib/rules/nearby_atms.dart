import 'nearby_traps.dart';

/// One cash machine that can be pinned on the map and routed to.
class NearbyAtm {
  const NearbyAtm({
    required this.name,
    required this.lat,
    required this.lng,
    this.distanceM,
  });

  final String name;
  final double lat;
  final double lng;

  /// Straight-line metres from where the search was made; null when the
  /// search point is unknown.
  final double? distanceM;

  /// Stable across refreshes of the same search, for map selection.
  String get id => '$name|${lat.toStringAsFixed(5)}|${lng.toStringAsFixed(5)}';
}

/// The ATMs among [places] that have a usable position, nearest first,
/// each listed once. Places without coordinates cannot be shown on a map
/// or routed to, so they are left out rather than guessed.
List<NearbyAtm> nearbyAtms(List<NearbyPlaceFact> places, {int limit = 10}) {
  final seen = <String>{};
  final atms = <(int, NearbyAtm)>[];
  for (final (i, p) in places.indexed) {
    if (p.kind != PlaceKind.atm) continue;
    final lat = p.lat, lng = p.lng;
    if (!isMapPosition(lat, lng)) continue;
    final atm = NearbyAtm(
      name: p.name,
      lat: lat!,
      lng: lng!,
      distanceM: p.distanceM,
    );
    if (!seen.add(atm.id)) continue;
    atms.add((i, atm));
  }
  atms.sort((a, b) {
    final da = a.$2.distanceM, db = b.$2.distanceM;
    final byDistance = switch ((da, db)) {
      (null, null) => 0,
      (null, _) => 1,
      (_, null) => -1,
      (final x?, final y?) => x.compareTo(y),
    };
    // Equal distances keep Google's order.
    return byDistance != 0 ? byDistance : a.$1.compareTo(b.$1);
  });
  return [for (final (_, atm) in atms.take(limit < 0 ? 0 : limit)) atm];
}

/// A real latitude/longitude pair. (0, 0) is a missing fix, not a place in
/// the Gulf of Guinea.
bool isMapPosition(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat.isFinite &&
    lng.isFinite &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180 &&
    !(lat == 0 && lng == 0);

/// The warnings in [traps] that are about this machine.
List<TrapWarning> trapsAt(NearbyAtm atm, List<TrapWarning> traps) => [
  for (final t in traps)
    if ((t.kind == TrapKind.atmFee || t.kind == TrapKind.atmConversion) &&
        t.placeName == atm.name)
      t,
];
