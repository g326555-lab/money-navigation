// The demo state's sample calendar: today's events of one prepared traveler,
// read from the demo file. Used in place of the phone's real calendar so a
// demo never shows (or reads) the owner's own schedule.

import 'dart:convert';

import 'day_cash.dart';
import 'trip_period.dart';

const demoCalendarAsset = 'assets/data/demo_personas.json';

/// Null when [json] is not a demo file. Otherwise the events of
/// [personaKey] on [now]'s local day, earliest first; empty when the
/// persona has none. Entries without a valid time or a place are skipped,
/// never repaired.
List<DayEvent>? demoCalendarEvents(
  String json,
  String personaKey,
  DateTime now,
) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded['personas'] is! List) return null;
  Map? persona;
  for (final p in decoded['personas'] as List) {
    if (p is Map && p['key'] == personaKey) persona = p;
  }
  final calendar = persona?['calendar'];
  if (calendar is! List) return const [];
  final events = <DayEvent>[];
  for (final e in calendar) {
    final event = e is Map ? _event(e, now) : null;
    if (event != null) events.add(event);
  }
  events.sort((a, b) => a.start.compareTo(b.start));
  return events;
}

final _time = RegExp(r'^(\d{1,2}):(\d{2})$');

DayEvent? _event(Map e, DateTime now) {
  final time = e['time'] is String
      ? _time.firstMatch(e['time'] as String)
      : null;
  final location = e['location'];
  if (time == null || location is! String || location.trim().isEmpty) {
    return null;
  }
  final hour = int.parse(time.group(1)!);
  final minute = int.parse(time.group(2)!);
  if (hour > 23 || minute > 59) return null;
  return DayEvent(
    title: e['title'] is String ? e['title'] as String : '',
    location: location.trim(),
    start: DateTime(now.year, now.month, now.day, hour, minute),
  );
}

/// The trip dates of [personaKey] around [now], from its 'trip' entry
/// (startDaysAgo, endDaysAhead). Null when the file or the entry is not
/// valid; never filled in.
TripPeriod? demoTripPeriod(String json, String personaKey, DateTime now) {
  final Object? decoded;
  try {
    decoded = jsonDecode(json);
  } on FormatException {
    return null;
  }
  if (decoded is! Map || decoded['personas'] is! List) return null;
  for (final p in decoded['personas'] as List) {
    if (p is! Map || p['key'] != personaKey) continue;
    final trip = p['trip'];
    if (trip is! Map) return null;
    final ago = trip['startDaysAgo'], ahead = trip['endDaysAhead'];
    if (ago is! int || ahead is! int || ago < 0 || ahead < 0) return null;
    return tripPeriodOrNull(
      DateTime(now.year, now.month, now.day - ago),
      DateTime(now.year, now.month, now.day + ahead),
    );
  }
  return null;
}
