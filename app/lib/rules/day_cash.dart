// "Route preview": how much cash today needs, from the traveler's own past
// days and today's calendar stops. A stop counts as cash-only only when
// Google Maps says so; a number appears only when past spending backs it.

import 'pay_route.dart';
import 'personal_context.dart';

/// One calendar event: title, place and time only.
class DayEvent {
  const DayEvent({
    required this.title,
    required this.location,
    required this.start,
    this.payment = PlacePayment.unknown,
    this.matchedPlace,
  });

  final String title;
  final String? location;
  final DateTime start;

  /// How the event's place takes payment, when Google Maps knows.
  final PlacePayment payment;

  /// The place Google Maps matched for [location], when any.
  final String? matchedPlace;

  DayEvent withPlace(PlacePayment payment, String? matchedPlace) => DayEvent(
    title: title,
    location: location,
    start: start,
    payment: payment,
    matchedPlace: matchedPlace,
  );
}

/// A stop of today and what the traveler spent there before.
class StopCash {
  const StopCash({
    required this.event,
    required this.lastSpentThb,
    required this.lastVisit,
    required this.lastFromSamples,
  });

  final DayEvent event;

  /// Total paid on the last earlier day at this place.
  final double? lastSpentThb;
  final DateTime? lastVisit;

  /// Every purchase behind [lastSpentThb] is a demo sample.
  final bool lastFromSamples;

  bool get cashOnly => event.payment.cashOnly == true;
  bool get cardsAccepted => event.payment.cards == true && !cashOnly;
}

/// The morning briefing's cash line.
class DayCashPlan {
  const DayCashPlan({
    required this.amountThb,
    required this.pattern,
    required this.stops,
    required this.stopsFloorThb,
  });

  /// About this much; rounded up to 100. Null when nothing backs a number.
  final double? amountThb;
  final CashEstimate? pattern;
  final List<StopCash> stops;

  /// What the cash-only stops cost last time, rounded up to 100.
  final double? stopsFloorThb;

  bool get isEstimate => true;
  int get cashOnlyStops => stops.where((s) => s.cashOnly).length;
}

/// Shortest name that may match a longer one by containment.
const placeMatchMinLength = 6;

DayCashPlan? dayCash({
  required List<PastPurchase> history,
  required List<DayEvent> events,
  required DateTime now,
}) {
  final today = DateTime(now.year, now.month, now.day);
  bool isToday(DateTime t) =>
      t.year == today.year && t.month == today.month && t.day == today.day;
  final todays = [
    for (final e in events)
      if (isToday(e.start) && (e.location?.trim().isNotEmpty ?? false)) e,
  ]..sort((a, b) => a.start.compareTo(b.start));

  final earlier = [
    for (final p in history)
      if (p.at.isBefore(today)) p,
  ];
  final stops = [for (final e in todays) _stop(e, earlier)];

  final pattern = morningCash(history, now);
  final floorSum = stops
      .where((s) => s.cashOnly && s.lastSpentThb != null)
      .fold<double?>(null, (sum, s) => (sum ?? 0) + s.lastSpentThb!);
  final floor = floorSum == null ? null : (floorSum / 100).ceil() * 100.0;

  if (stops.isEmpty && pattern == null) return null;
  final candidates = [?pattern?.amountThb, ?floor];
  return DayCashPlan(
    amountThb: candidates.isEmpty
        ? null
        : candidates.reduce((a, b) => a > b ? a : b),
    pattern: pattern,
    stops: stops,
    stopsFloorThb: floor,
  );
}

StopCash _stop(DayEvent event, List<PastPurchase> earlier) {
  final names = {
    _norm(event.location!),
    if (event.matchedPlace != null) _norm(event.matchedPlace!),
  }..remove('');
  final matching = [
    for (final p in earlier)
      if (p.placeName != null &&
          names.any((n) => _same(n, _norm(p.placeName!))))
        p,
  ];
  if (matching.isEmpty) {
    return StopCash(
      event: event,
      lastSpentThb: null,
      lastVisit: null,
      lastFromSamples: false,
    );
  }
  DateTime day(DateTime t) => DateTime(t.year, t.month, t.day);
  final last = matching
      .map((p) => day(p.at))
      .reduce((a, b) => a.isAfter(b) ? a : b);
  final thatDay = [
    for (final p in matching)
      if (day(p.at) == last) p,
  ];
  return StopCash(
    event: event,
    lastSpentThb: thatDay.fold<double>(0, (s, p) => s + p.paidThb),
    lastVisit: last,
    lastFromSamples: thatDay.every((p) => p.isSample),
  );
}

String _norm(String s) => s.trim().toLowerCase();

bool _same(String a, String b) {
  if (a.isEmpty || b.isEmpty) return false;
  if (a == b) return true;
  final (short, long) = a.length <= b.length ? (a, b) : (b, a);
  return short.length >= placeMatchMinLength && long.contains(short);
}
