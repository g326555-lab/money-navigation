import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/trip_period.dart';

/// The trip dates the traveler entered, kept on this phone. Nothing is set
/// until the traveler says when the trip is; the calendar is then read for
/// those days only.
class TripPeriodStore extends ChangeNotifier {
  TripPeriodStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'trip_period_v1';

  final SharedPreferencesAsync _prefs;
  TripPeriod? _period;
  bool _loaded = false;
  Future<void>? _loading;

  TripPeriod? get period => _period;
  bool get loaded => _loaded;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      final raw = await _prefs.getString(_key);
      _period = raw == null ? null : TripPeriod.fromJson(jsonDecode(raw));
    } on Object {
      _period = null;
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> set(TripPeriod? period) async {
    await load();
    _period = period;
    notifyListeners();
    try {
      if (period == null) {
        await _prefs.remove(_key);
      } else {
        await _prefs.setString(_key, jsonEncode(period.toJson()));
      }
    } on Object {
      // Kept for this session; the next launch asks again.
    }
  }
}
