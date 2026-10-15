import 'dart:io' show Platform;

import 'package:device_calendar_plus/device_calendar_plus.dart';
import 'package:flutter/services.dart';

import '../../rules/day_cash.dart';

enum CalendarAccess { unknown, granted, denied }

/// Today's events from the phone's calendar: title, place and start time
/// only. Nothing is written and nothing leaves the phone except a place's
/// name, sent to Google Maps to learn how it takes payment.
///
/// Android reads through the app's own read-only channel (READ_CALENDAR
/// only, android MainActivity); the calendar library's Android side would
/// require write access. iOS uses the library, which needs full access to
/// read on iOS 17+.
class CalendarSource {
  CalendarSource({bool? useChannel})
    : _useChannel = useChannel ?? Platform.isAndroid;

  static const _channel = MethodChannel('money_navigation/calendar');

  final bool _useChannel;
  CalendarAccess access = CalendarAccess.unknown;

  /// Checks without prompting.
  Future<void> checkAccess() async {
    try {
      final granted = _useChannel
          ? await _channel.invokeMethod<bool>('hasPermission') == true
          : await DeviceCalendar.instance.hasPermissions() ==
                CalendarPermissionStatus.granted;
      if (granted) {
        access = CalendarAccess.granted;
      } else if (access != CalendarAccess.denied) {
        access = CalendarAccess.unknown;
      }
    } on Object {
      access = CalendarAccess.unknown;
    }
  }

  /// Shows the system prompt once.
  Future<bool> requestAccess() async {
    try {
      final granted = _useChannel
          ? await _channel.invokeMethod<bool>('requestPermission') == true
          : await DeviceCalendar.instance.requestPermissions() ==
                CalendarPermissionStatus.granted;
      access = granted ? CalendarAccess.granted : CalendarAccess.denied;
    } on PlatformException catch (e) {
      // A request already open is not a refusal.
      if (e.code != 'IN_PROGRESS') access = CalendarAccess.denied;
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
      return _useChannel
          ? await _channelEvents(start, end)
          : await _libraryEvents(start, end);
    } on Object {
      return const [];
    }
  }

  Future<List<DayEvent>> _channelEvents(DateTime start, DateTime end) async {
    final rows = await _channel.invokeListMethod<Object?>('eventsOn', {
      'startMillis': start.millisecondsSinceEpoch,
      'endMillis': end.millisecondsSinceEpoch,
    });
    return [
      for (final r in rows ?? const <Object?>[])
        if (r is Map && r['allDay'] != true && r['begin'] is int)
          if (DateTime.fromMillisecondsSinceEpoch(r['begin'] as int)
              case final begin
              when !begin.isBefore(start) && begin.isBefore(end))
            DayEvent(
              title: r['title'] is String ? r['title'] as String : '',
              location:
                  r['location'] is String &&
                      (r['location'] as String).trim().isNotEmpty
                  ? r['location'] as String
                  : null,
              start: begin,
            ),
    ];
  }

  Future<List<DayEvent>> _libraryEvents(DateTime start, DateTime end) async {
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
  }
}
