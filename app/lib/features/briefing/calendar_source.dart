import 'package:device_calendar_plus/device_calendar_plus.dart';

import '../../rules/day_cash.dart';

enum CalendarAccess { unknown, granted, denied }

/// Today's events from the phone's calendar: title, place and start time
/// only. Nothing is written and nothing leaves the phone except a place's
/// name, sent to Google Maps to learn how it takes payment.
class CalendarSource {
  CalendarAccess access = CalendarAccess.unknown;

  /// Checks without prompting.
  Future<void> checkAccess() async {
    try {
      final status = await DeviceCalendar.instance.hasPermissions();
      access = status == CalendarPermissionStatus.granted
          ? CalendarAccess.granted
          : access == CalendarAccess.denied
          ? CalendarAccess.denied
          : CalendarAccess.unknown;
    } on Object {
      access = CalendarAccess.unknown;
    }
  }

  /// Shows the system prompt (full access: iOS cannot read with less).
  Future<bool> requestAccess() async {
    try {
      final status = await DeviceCalendar.instance.requestPermissions();
      access = status == CalendarPermissionStatus.granted
          ? CalendarAccess.granted
          : CalendarAccess.denied;
    } on Object {
      access = CalendarAccess.denied;
    }
    return access == CalendarAccess.granted;
  }

  /// Events that start on [day]'s date; all-day events are left out (they
  /// have no time to place on the route).
  Future<List<DayEvent>> eventsOn(DateTime day) async {
    if (access != CalendarAccess.granted) return const [];
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    try {
      final events = await DeviceCalendar.instance.listEvents(start, end);
      return [
        for (final e in events)
          if (!e.isAllDay)
            DayEvent(
              title: e.title,
              location: e.location,
              start: e.startDate.toLocal(),
            ),
      ];
    } on Object {
      return const [];
    }
  }
}
