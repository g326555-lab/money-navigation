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

  final SharedPreferencesAsync _prefs;
  List<ReceiptRecord> _records = const [];

  List<ReceiptRecord> get records => _records;

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
    if (json is! List) return;
    _records = _newestFirst([for (final e in json) ?ReceiptRecord.fromJson(e)]);
    notifyListeners();
  }

  /// Adds [record], or replaces the one with the same id (a correction).
  Future<void> save(ReceiptRecord record) async {
    await load();
    _records = _newestFirst([
      record,
      ..._records.where((r) => r.id != record.id),
    ]);
    notifyListeners();
    await _persist();
    _unsent.add(record.id);
    await _tryRemote((r) async {
      await r.upsert(record);
      _unsent.remove(record.id);
    });
  }

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

  bool contains(String id) => _records.any((r) => r.id == id);

  static List<ReceiptRecord> _newestFirst(List<ReceiptRecord> list) =>
      list..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}
