import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/trip_ledger.dart';

/// Results the traveler saved on this trip, kept on the device.
///
/// Stored as one JSON string in the platform preferences store
/// (DataStore on Android, NSUserDefaults on iOS) through
/// [SharedPreferencesAsync], which the plugin recommends for new code.
class TripStore extends ChangeNotifier {
  TripStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'trip_saves_v1';

  final SharedPreferencesAsync _prefs;
  List<TripSave> _saves = const [];
  bool _loaded = false;

  /// Newest first.
  List<TripSave> get saves => _saves;
  bool get loaded => _loaded;

  /// The most recent save made in this session, so Home can welcome it.
  TripSave? get lastAdded => _lastAdded;
  TripSave? _lastAdded;

  Future<void> load() async {
    _saves = newestFirst(decodeSaves(await _prefs.getString(_key)));
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(TripSave save) async {
    _saves = newestFirst([save, ..._saves.where((s) => s.id != save.id)]);
    _lastAdded = save;
    notifyListeners();
    await _prefs.setString(_key, encodeSaves(_saves));
  }

  Future<void> remove(String id) async {
    _saves = _saves.where((s) => s.id != id).toList();
    notifyListeners();
    await _prefs.setString(_key, encodeSaves(_saves));
  }

  bool contains(String id) => _saves.any((s) => s.id == id);

  /// A fresh id for a new save.
  static String newId(DateTime now) => now.microsecondsSinceEpoch.toString();
}
