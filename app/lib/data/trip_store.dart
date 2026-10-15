import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/trip_ledger.dart';

/// Where saves live for a signed-in traveler (Supabase, row level security
/// per user). Every call may throw; the store then keeps the phone's copy.
abstract interface class TripRemote {
  Future<List<TripSave>> load();
  Future<void> upsert(TripSave save);
  Future<void> upsertAll(List<TripSave> saves);
  Future<void> remove(String id);
}

/// Results the traveler saved on this trip, kept on the device.
///
/// Stored as one JSON string in the platform preferences store
/// (DataStore on Android, NSUserDefaults on iOS) through
/// [SharedPreferencesAsync], which the plugin recommends for new code.
/// When signed in, every change also goes to the account ([attach]).
class TripStore extends ChangeNotifier {
  TripStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'trip_saves_v1';
  static const _demoKey = 'demo_trips_v1';

  final SharedPreferencesAsync _prefs;
  List<TripSave> _saves = const [];
  bool _loaded = false;

  /// Newest first. While a demo state is shown, its own ledger instead.
  List<TripSave> get saves {
    final key = _demoShown;
    if (key == null) return _saves;
    return _demoLedgers[key] ?? _demoSamples;
  }

  bool get loaded => _loaded;

  /// The demo state whose ledger [saves] shows, if any.
  String? _demoShown;
  List<TripSave> _demoSamples = const [];

  /// Each demo state's saves once something was saved or removed in it,
  /// kept apart from the traveler's own and never sent to the account.
  Map<String, List<TripSave>> _demoLedgers = {};

  bool get showingDemo => _demoShown != null;

  /// The most recent save made in this session, so Home can welcome it.
  TripSave? get lastAdded => _lastAdded;
  TripSave? _lastAdded;

  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _saves = newestFirst(decodeSaves(await _prefs.getString(_key)));
    _demoLedgers = _decodeLedgers(await _prefs.getString(_demoKey));
    _loaded = true;
    notifyListeners();
  }

  /// Shows the demo state [key]: what was saved in it before, or
  /// [samples] when nothing was. The traveler's own saves stay as they are.
  void showDemo(String key, List<TripSave> samples) {
    _demoShown = key;
    _demoSamples = samples;
    _lastAdded = null;
    notifyListeners();
  }

  /// Back to the traveler's own saves.
  void showReal() {
    if (_demoShown == null) return;
    _demoShown = null;
    _demoSamples = const [];
    _lastAdded = null;
    notifyListeners();
  }

  /// Forgets what was saved in every demo state, so each starts again from
  /// its samples.
  Future<void> resetDemo() async {
    await load();
    _demoLedgers = {};
    notifyListeners();
    await _prefs.remove(_demoKey);
  }

  Future<void> _changeDemo(List<TripSave> Function(List<TripSave>) change) {
    final key = _demoShown!;
    _demoLedgers = {..._demoLedgers, key: newestFirst(change(saves))};
    notifyListeners();
    return _prefs.setString(_demoKey, _encodeLedgers(_demoLedgers));
  }

  Future<void> add(TripSave save) async {
    if (_demoShown != null) {
      _lastAdded = save;
      return _changeDemo(
        (saves) => [save, ...saves.where((s) => s.id != save.id)],
      );
    }
    _saves = newestFirst([save, ..._saves.where((s) => s.id != save.id)]);
    _lastAdded = save;
    notifyListeners();
    await _prefs.setString(_key, encodeSaves(_saves));
    _unsent.add(save.id);
    await _tryRemote((r) async {
      await r.upsert(save);
      _unsent.remove(save.id);
    });
  }

  Future<void> remove(String id) async {
    if (_demoShown != null) {
      return _changeDemo((saves) => saves.where((s) => s.id != id).toList());
    }
    _saves = _saves.where((s) => s.id != id).toList();
    notifyListeners();
    await _prefs.setString(_key, encodeSaves(_saves));
    _unsent.remove(id);
    if (_remote == null) return;
    _unremoved.add(id);
    await _tryRemote((r) async {
      await r.remove(id);
      _unremoved.remove(id);
    });
  }

  /// Saves that have not reached the account yet, and removals that have
  /// not either. Sent again on the next sign-in; kept on sign-out.
  final Set<String> _unsent = {};
  final Set<String> _unremoved = {};

  TripRemote? _remote;

  /// Signed in: uploads what was saved on this phone (as a guest or while
  /// offline), then shows the account's records, which include them.
  Future<void> attach(TripRemote remote) async {
    await load();
    _remote = remote;
    await _tryRemote((r) async {
      for (final id in _unremoved.toList()) {
        await r.remove(id);
        _unremoved.remove(id);
      }
      if (_saves.isNotEmpty) await r.upsertAll(_saves);
      _unsent.clear();
      final account = await r.load();
      if (!identical(_remote, r)) return;
      _saves = newestFirst(account);
      notifyListeners();
      await _prefs.setString(_key, encodeSaves(_saves));
    });
  }

  /// Signed out: the account's records leave this phone, except saves that
  /// never reached it (made offline), which stay so nothing is lost.
  Future<void> detach() async {
    if (_remote == null) return;
    _remote = null;
    _saves = [
      for (final s in _saves)
        if (_unsent.contains(s.id)) s,
    ];
    notifyListeners();
    await _prefs.setString(_key, encodeSaves(_saves));
  }

  Future<void> _tryRemote(Future<void> Function(TripRemote r) run) async {
    final remote = _remote;
    if (remote == null) return;
    try {
      await run(remote);
    } on Exception {
      // Offline or refused: the phone keeps its copy and the next save or
      // sign-in sends it again.
    }
  }

  bool contains(String id) => saves.any((s) => s.id == id);

  /// A fresh id for a new save.
  static String newId(DateTime now) => now.microsecondsSinceEpoch.toString();
}

String _encodeLedgers(Map<String, List<TripSave>> ledgers) => jsonEncode({
  for (final e in ledgers.entries) e.key: [for (final s in e.value) s.toJson()],
});

Map<String, List<TripSave>> _decodeLedgers(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    return {};
  }
  if (decoded is! Map) return {};
  return {
    for (final e in decoded.entries)
      if (e.key is String && e.value is List)
        e.key as String: newestFirst([
          for (final entry in e.value as List) ?TripSave.fromJson(entry),
        ]),
  };
}
