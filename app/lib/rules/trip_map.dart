import 'receipt_record.dart';
import 'trip_ledger.dart';

/// What a pin on the trip map stands for.
enum PinKind { receipt, haggle, atm, terminal }

/// One saved record that has a place on the map.
class MapPin {
  const MapPin({
    required this.id,
    required this.kind,
    required this.lat,
    required this.lng,
    required this.at,
    this.title,
    this.amountThb,
    this.keptThb,
    this.verified = true,
    this.isSample = false,
  });

  final String id;
  final PinKind kind;
  final double lat;
  final double lng;

  /// Local time of the record.
  final DateTime at;

  /// Shop or place name, when known.
  final String? title;

  /// What was paid: a receipt's total, a haggle's agreed price.
  final double? amountThb;

  /// Money kept (trip saves only).
  final double? keptThb;

  /// Receipts proven by arithmetic; false for the traveler's corrections.
  final bool verified;
  final bool isSample;
}

bool _located(double? lat, double? lng) =>
    lat != null &&
    lng != null &&
    lat >= -90 &&
    lat <= 90 &&
    lng >= -180 &&
    lng <= 180 &&
    // (0, 0) is a missing fix, not a place in the Gulf of Guinea.
    !(lat == 0 && lng == 0);

/// Every record that has a location; the rest are left off the map.
List<MapPin> pinsFrom({
  required List<ReceiptRecord> receipts,
  required List<TripSave> saves,
}) => [
  for (final r in receipts)
    if (_located(r.lat, r.lng))
      MapPin(
        id: r.id,
        kind: PinKind.receipt,
        lat: r.lat!,
        lng: r.lng!,
        at: r.savedAt.toLocal(),
        title: r.merchantName ?? r.placeName,
        amountThb: r.totalThb,
        verified: r.verified,
        isSample: r.isSample,
      ),
  for (final s in saves)
    if (_located(s.placeLat, s.placeLng))
      MapPin(
        id: s.id,
        kind: switch (s.kind) {
          SaveKind.haggle => PinKind.haggle,
          SaveKind.atmConversion => PinKind.atm,
          SaveKind.terminalDcc => PinKind.terminal,
        },
        lat: s.placeLat!,
        lng: s.placeLng!,
        at: s.savedAt.toLocal(),
        title: s.placeName,
        amountThb: s.paidThb,
        keptThb: s.keptThb,
        isSample: s.isSample,
      ),
];

/// Pins by local calendar day, newest day first, newest pin first in a day.
List<({DateTime day, List<MapPin> pins})> pinsByDay(List<MapPin> pins) {
  final days = <DateTime, List<MapPin>>{};
  for (final p in pins) {
    final local = p.at.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    (days[day] ??= []).add(p);
  }
  final keys = days.keys.toList()..sort((a, b) => b.compareTo(a));
  return [
    for (final day in keys)
      (day: day, pins: days[day]!..sort((a, b) => b.at.compareTo(a.at))),
  ];
}

/// Smallest span a framed map shows, in degrees, so one pin still frames
/// its neighbourhood.
const pinMinSpan = 0.01;

/// The box around [pins], padded by [padFraction] of its span on each side.
({double south, double west, double north, double east})? pinBounds(
  List<MapPin> pins, {
  double padFraction = 0.15,
}) {
  if (pins.isEmpty) return null;
  var south = pins.first.lat, north = south;
  var west = pins.first.lng, east = west;
  for (final p in pins) {
    if (p.lat < south) south = p.lat;
    if (p.lat > north) north = p.lat;
    if (p.lng < west) west = p.lng;
    if (p.lng > east) east = p.lng;
  }
  double grow(double lo, double hi) {
    final span = hi - lo;
    return span < pinMinSpan ? (pinMinSpan - span) / 2 : 0;
  }

  final dLat = grow(south, north);
  final dLng = grow(west, east);
  south -= dLat;
  north += dLat;
  west -= dLng;
  east += dLng;
  final padLat = (north - south) * padFraction;
  final padLng = (east - west) * padFraction;
  return (
    south: (south - padLat).clamp(-90.0, 90.0),
    west: (west - padLng).clamp(-180.0, 180.0),
    north: (north + padLat).clamp(-90.0, 90.0),
    east: (east + padLng).clamp(-180.0, 180.0),
  );
}

/// Pins closer than this (in degrees, about 100 m) count as one place.
const samePlaceDegrees = 0.001;

/// How many distinct places [pins] stand for: two records at the same
/// market are one place, not two.
int placeCount(List<MapPin> pins) => {
  for (final p in pins)
    ((p.lat / samePlaceDegrees).round(), (p.lng / samePlaceDegrees).round()),
}.length;

/// Money kept on the pins of one day; receipts keep nothing.
double keptOnDay(List<MapPin> pins) =>
    pins.fold(0, (sum, p) => sum + (p.keptThb ?? 0));
