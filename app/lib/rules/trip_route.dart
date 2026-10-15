// The route line on Home: the trip's saves as stops, oldest first. Saves
// made at the same place on the same day, one after another, are one stop.

import 'trip_ledger.dart';

class RouteStop {
  const RouteStop({
    required this.placeName,
    required this.kind,
    required this.keptThb,
    required this.at,
    required this.saves,
    required this.isSample,
  });

  final String? placeName;

  /// The kind of the stop's biggest save.
  final SaveKind kind;
  final double keptThb;

  /// When the stop's first save was made.
  final DateTime at;
  final int saves;
  final bool isSample;
}

/// Stops shown on Home at most; the most recent are kept.
const routeMaxStops = 4;

List<RouteStop> tripRoute(
  List<TripSave> saves, {
  int maxStops = routeMaxStops,
}) {
  final ordered = [...saves]..sort((a, b) => a.savedAt.compareTo(b.savedAt));
  final groups = <List<TripSave>>[];
  for (final save in ordered) {
    final last = groups.isEmpty ? null : groups.last.last;
    if (last != null && _samePlace(last, save)) {
      groups.last.add(save);
    } else {
      groups.add([save]);
    }
  }
  final stops = [
    for (final g in groups)
      RouteStop(
        placeName: g.first.placeName,
        kind: g.reduce((a, b) => b.keptThb > a.keptThb ? b : a).kind,
        keptThb: g.fold(0, (s, x) => s + x.keptThb),
        at: g.first.savedAt,
        saves: g.length,
        isSample: g.every((x) => x.isSample),
      ),
  ];
  if (maxStops <= 0) return const [];
  return stops.length <= maxStops
      ? stops
      : stops.sublist(stops.length - maxStops);
}

bool _samePlace(TripSave a, TripSave b) {
  final pa = a.placeName?.trim().toLowerCase();
  final pb = b.placeName?.trim().toLowerCase();
  if (pa == null || pb == null || pa.isEmpty || pa != pb) return false;
  final la = a.savedAt.toLocal(), lb = b.savedAt.toLocal();
  return la.year == lb.year && la.month == lb.month && la.day == lb.day;
}
