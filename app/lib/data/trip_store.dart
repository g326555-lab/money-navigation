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

  final SharedPreferencesAsync _prefs;
  List<TripSave> _saves = const [];
  bool _loaded = false;

  /// Newest first.
  List<TripSave> get saves => _saves;
  bool get loaded => _loaded;

  /// The most recent save made in this session, so Home can welcome it.
  TripSave? get lastAdded => _lastAdded;
  TripSave? _lastAdded;

  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _saves = newestFirst(decodeSaves(await _prefs.getString(_key)));
    _loaded = true;
    notifyListeners();
  }

  Future<void> add(TripSave save) async {
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

  bool contains(String id) => _saves.any((s) => s.id == id);

  /// A fresh id for a new save.
  static String newId(DateTime now) => now.microsecondsSinceEpoch.toString();
}
