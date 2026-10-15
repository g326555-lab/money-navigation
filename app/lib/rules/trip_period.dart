/// The traveler's trip as calendar dates, first and last day included.
class TripPeriod {
  TripPeriod({required DateTime start, required DateTime end})
    : start = _date(start),
      end = _date(end),
      assert(!_date(end).isBefore(_date(start)));

  final DateTime start;
  final DateTime end;

  /// Every day of the trip, first to last.
  List<DateTime> get days => [
    for (
      var d = start;
      !d.isAfter(end);
      d = DateTime(d.year, d.month, d.day + 1)
    )
      d,
  ];

  int get length => days.length;

  /// 1 for the first day; null when [day] is outside the trip.
  int? dayNumber(DateTime day) {
    final d = _date(day);
    if (d.isBefore(start) || d.isAfter(end)) return null;
    return days.indexOf(d) + 1;
  }

  bool contains(DateTime day) => dayNumber(day) != null;

  Map<String, Object?> toJson() => {'start': _iso(start), 'end': _iso(end)};

  /// Null when [json] is not a valid period, never a repaired one.
  static TripPeriod? fromJson(Object? json) {
    if (json is! Map) return null;
    final start = json['start'] is String
        ? DateTime.tryParse(json['start'] as String)
        : null;
    final end = json['end'] is String
        ? DateTime.tryParse(json['end'] as String)
        : null;
    return start == null || end == null ? null : tripPeriodOrNull(start, end);
  }

  @override
  bool operator ==(Object other) =>
      other is TripPeriod && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);
}

/// The longest trip the app plans for, in days.
const maxTripDays = 90;

/// A period from [start] to [end], or null when the end is before the
/// start or the trip is longer than [maxTripDays].
TripPeriod? tripPeriodOrNull(DateTime start, DateTime end) {
  final s = _date(start), e = _date(end);
  if (e.isBefore(s)) return null;
  final period = TripPeriod(start: s, end: e);
  return period.length > maxTripDays ? null : period;
}

/// The day the briefing shows by default: today inside the trip, the first
/// day before it starts, the last day after it ended.
DateTime defaultTripDay(TripPeriod? period, DateTime now) {
  final today = _date(now);
  if (period == null || period.contains(today)) return today;
  return today.isBefore(period.start) ? period.start : period.end;
}

DateTime _date(DateTime d) => DateTime(d.year, d.month, d.day);

String _iso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';
