import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/receipt_record.dart';

/// Where receipts live for a signed-in traveler. Calls may throw; the
/// store then keeps the phone's copy.
abstract interface class ReceiptRemote {
  Future<List<ReceiptRecord>> load();
  Future<void> upsert(ReceiptRecord record);
}

/// Bills the traveler checked and saved, kept on the device, newest first.
/// Verified records and the traveler's own corrections are stored the same
/// way; [ReceiptRecord.verified] keeps them apart.
class ReceiptStore extends ChangeNotifier {
  ReceiptStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  /// One store for the app. The bill screen and the assistant read it.
  static final shared = ReceiptStore();

  static const _key = 'receipts_v1';
  static const _demoKey = 'demo_receipts_v1';

  final SharedPreferencesAsync _prefs;
  List<ReceiptRecord> _records = const [];

  /// The traveler's receipts, or in the demo state the persona's ledger
  /// (its samples plus anything saved during the demo).
  List<ReceiptRecord> get records {
    final key = _demoShown;
    if (key == null) return _records;
    return _demoLedgers[key] ?? _demoSamples;
  }

  String? _demoShown;
  List<ReceiptRecord> _demoSamples = const [];

  /// Per persona: its samples plus what was saved while it was shown.
  /// Kept on the phone only, never sent to an account.
  Map<String, List<ReceiptRecord>> _demoLedgers = {};

  bool get showingDemo => _demoShown != null;

  /// Shows persona [key]'s receipts instead of the traveler's own.
  void showDemo(String key, List<ReceiptRecord> samples) {
    _demoShown = key;
    _demoSamples = _newestFirst([...samples]);
    notifyListeners();
  }

  /// Back to the traveler's own receipts.
  void showReal() {
    if (_demoShown == null) return;
    _demoShown = null;
    _demoSamples = const [];
    notifyListeners();
  }

  /// Forgets everything saved during demos.
  Future<void> resetDemo() async {
    await load();
    _demoLedgers = {};
    notifyListeners();
    await _prefs.remove(_demoKey);
  }

  Future<void>? _loading;

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    final raw = await _prefs.getString(_key);
    final Object? json;
    try {
      json = raw == null ? null : jsonDecode(raw);
    } on FormatException {
      return;
    }
    if (json is List) {
      _records = _newestFirst([
        for (final e in json) ?ReceiptRecord.fromJson(e),
      ]);
    }
    _demoLedgers = _decodeLedgers(await _prefs.getString(_demoKey));
    _unsent.addAll(await _prefs.getStringList(_unsentKey) ?? const []);
    notifyListeners();
  }

  static Map<String, List<ReceiptRecord>> _decodeLedgers(String? raw) {
    if (raw == null) return {};
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return {};
    }
    if (json is! Map) return {};
    return {
      for (final e in json.entries)
        if (e.key is String && e.value is List)
          e.key as String: _newestFirst([
            for (final r in e.value as List) ?ReceiptRecord.fromJson(r),
          ]),
    };
  }

  /// Adds [record], or replaces the one with the same id (a correction).
  Future<void> save(ReceiptRecord record) async {
    await load();
    final demo = _demoShown;
    if (demo != null) {
      // A demo save stays in the demo ledger, never in the real records
      // and never in the account.
      _demoLedgers = {
        ..._demoLedgers,
        demo: _newestFirst([
          record,
          ...records.where((r) => r.id != record.id),
        ]),
      };
      notifyListeners();
      await _prefs.setString(
        _demoKey,
        jsonEncode({
          for (final e in _demoLedgers.entries)
            e.key: [for (final r in e.value) r.toJson()],
        }),
      );
      return;
    }
    _records = _newestFirst([
      record,
      ..._records.where((r) => r.id != record.id),
    ]);
    notifyListeners();
    await _persist();
    _unsent.add(record.id);
    await _persistUnsent();
    // The account copy follows without holding up the caller.
    unawaited(
      _tryRemote((r) async {
        await r.upsert(record);
        _unsent.remove(record.id);
        await _persistUnsent();
      }),
    );
  }

  static const _unsentKey = 'receipts_unsent_v1';

  /// Ids not yet in the account, kept across restarts so a sign-out never
  /// drops a receipt that was saved offline.
  Future<void> _persistUnsent() =>
      _prefs.setStringList(_unsentKey, _unsent.toList());

  Future<void> _persist() => _prefs.setString(
    _key,
    jsonEncode([for (final r in _records) r.toJson()]),
  );

  ReceiptRemote? _remote;
  final Set<String> _unsent = {};

  /// Signed in: sends receipts saved on this phone, then shows the
  /// account's, which include them.
  Future<void> attach(ReceiptRemote remote) async {
    await load();
    _remote = remote;
    await _tryRemote((r) async {
      for (final record in _records) {
        await r.upsert(record);
      }
      _unsent.clear();
      await _persistUnsent();
      final account = await r.load();
      if (!identical(_remote, r)) return;
      _records = _newestFirst([...account]);
      notifyListeners();
      await _persist();
    });
  }

  /// Signed out: the account's receipts leave this phone, except ones that
  /// never reached it.
  Future<void> detach() async {
    if (_remote == null) return;
    _remote = null;
    _records = [
      for (final r in _records)
        if (_unsent.contains(r.id)) r,
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> _tryRemote(Future<void> Function(ReceiptRemote r) run) async {
    final remote = _remote;
    if (remote == null) return;
    try {
      await run(remote);
    } on Exception {
      // Offline or refused: kept on the phone and sent next time.
    }
  }

  bool contains(String id) => records.any((r) => r.id == id);

  static List<ReceiptRecord> _newestFirst(List<ReceiptRecord> list) =>
      list..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}
