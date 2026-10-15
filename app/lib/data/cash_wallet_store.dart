import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/cash_wallet.dart';

/// The traveler's cash ledger on this phone. Demo movements are kept apart
/// from real movements and are never uploaded as account records.
class CashWalletStore extends ChangeNotifier {
  CashWalletStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _key = 'cash_wallet_v1';
  static const _demoKey = 'cash_wallet_demo_v1';

  final SharedPreferencesAsync _prefs;
  List<CashMovement> _movements = const [];
  List<CashMovement> _demoSamples = const [];
  Map<String, List<CashMovement>> _demoLedgers = {};
  String? _demoShown;
  bool _loaded = false;
  Future<void>? _loading;

  bool get loaded => _loaded;
  bool get showingDemo => _demoShown != null;
  String? get demoKey => _demoShown;

  /// Newest first. While a demo state is shown, its own ledger (or its
  /// initial sample movements when nothing was changed in this session).
  List<CashMovement> get movements {
    final key = _demoShown;
    if (key == null) return _movements;
    final ledger = _demoLedgers[key];
    if (ledger != null && ledger.isNotEmpty) return ledger;
    return _demoSamples;
  }

  double? balance(String currency) => cashBalance(movements, currency);

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    _movements = _decode(await _prefs.getString(_key));
    _demoLedgers = _decodeLedgers(await _prefs.getString(_demoKey));
    _loaded = true;
    notifyListeners();
  }

  void showDemo(String? key, {List<CashMovement> sampleMovements = const []}) {
    if (key == null) {
      showReal();
      return;
    }
    final samples = _newestFirst(sampleMovements);
    if (_demoShown == key && _demoSamples.length == samples.length) return;
    _demoShown = key;
    _demoSamples = samples;
    notifyListeners();
  }

  void showReal() {
    if (_demoShown == null && _demoSamples.isEmpty) return;
    _demoShown = null;
    _demoSamples = const [];
    notifyListeners();
  }

  Future<void> resetDemo() async {
    await load();
    _demoLedgers = {};
    notifyListeners();
    await _prefs.remove(_demoKey);
  }

  /// Sets the amount the traveler currently has, recording the difference
  /// so earlier activity remains visible in the ledger.
  Future<void> setBalance({
    required double amount,
    required String currency,
    String? description,
    DateTime? at,
  }) async {
    await load();
    if (!amount.isFinite || amount < 0 || currency.length != 3) {
      throw ArgumentError(
        'A balance must be a non-negative amount and currency.',
      );
    }
    final now = at ?? DateTime.now();
    final current = balance(currency);
    final difference = amount - (current ?? 0);
    if (difference == 0 && current != null) return;
    await _append(
      CashMovement(
        id: 'cash-adjust-${now.microsecondsSinceEpoch}',
        kind: current == null
            ? CashMovementKind.openingBalance
            : CashMovementKind.adjustment,
        amount: difference,
        currency: currency.toUpperCase(),
        at: now,
        description:
            description ??
            (current == null ? 'Opening balance' : 'Balance correction'),
      ),
    );
  }

  Future<void> addCash({
    required double amount,
    required String currency,
    required String sourceId,
    required String description,
    DateTime? at,
  }) => _setLinkedMovement(
    sourceId: sourceId,
    amount: amount,
    currency: currency,
    kind: CashMovementKind.withdrawal,
    description: description,
    at: at,
  );

  /// Records proceeds from a completed cash exchange. The traveler confirms
  /// the actual counter payout before this changes the local-currency balance.
  Future<void> addExchangeCash({
    required double amount,
    required String currency,
    required String sourceId,
    required String description,
    DateTime? at,
  }) => _setLinkedMovement(
    sourceId: sourceId,
    amount: amount,
    currency: currency,
    kind: CashMovementKind.exchange,
    description: description,
    at: at,
  );

  /// Replaces a linked spend if its receipt was corrected, or removes it
  /// when the traveler changes its payment method away from cash.
  Future<void> setLinkedSpend({
    required String sourceId,
    required double? amount,
    required String currency,
    required String description,
    DateTime? at,
  }) async {
    await load();
    if (amount != null && (!amount.isFinite || amount <= 0)) {
      throw ArgumentError.value(amount, 'amount');
    }
    final updated = [
      for (final m in movements)
        if (m.sourceId != sourceId) m,
      if (amount != null)
        CashMovement(
          id: 'cash-spend-$sourceId',
          kind: CashMovementKind.cashSpend,
          amount: amount,
          currency: currency.toUpperCase(),
          at: at ?? DateTime.now(),
          description: description,
          sourceId: sourceId,
        ),
    ];
    await _replace(_newestFirst(updated));
  }

  /// Takes out the movements linked to [sourceId] when its record is
  /// removed, and returns them so an undo can put them back.
  Future<List<CashMovement>> removeLinked(String sourceId) async {
    await load();
    final removed = [
      for (final m in movements)
        if (m.sourceId == sourceId) m,
    ];
    if (removed.isEmpty) return const [];
    await _replace([
      for (final m in movements)
        if (m.sourceId != sourceId) m,
    ]);
    return removed;
  }

  /// Puts back movements taken out by [removeLinked].
  Future<void> restore(List<CashMovement> removed) async {
    await load();
    final ids = {for (final m in movements) m.id};
    final back = [
      for (final m in removed)
        if (!ids.contains(m.id)) m,
    ];
    if (back.isEmpty) return;
    await _replace(_newestFirst([...back, ...movements]));
  }

  Future<void> recordManualMovement({
    required double amount,
    required String currency,
    required bool spend,
    required String description,
    DateTime? at,
  }) async {
    await load();
    if (!amount.isFinite || amount <= 0) return;
    final now = at ?? DateTime.now();
    await _append(
      CashMovement(
        id: 'cash-manual-${now.microsecondsSinceEpoch}',
        kind: spend ? CashMovementKind.cashSpend : CashMovementKind.adjustment,
        amount: amount,
        currency: currency.toUpperCase(),
        at: now,
        description: description,
      ),
    );
  }

  Future<void> _setLinkedMovement({
    required String sourceId,
    required double amount,
    required String currency,
    required CashMovementKind kind,
    required String description,
    DateTime? at,
  }) async {
    await load();
    if (!amount.isFinite || amount <= 0) return;
    if (movements.any((m) => m.sourceId == sourceId)) return;
    await _append(
      CashMovement(
        id: 'cash-$sourceId',
        kind: kind,
        amount: amount,
        currency: currency.toUpperCase(),
        at: at ?? DateTime.now(),
        description: description,
        sourceId: sourceId,
      ),
    );
  }

  Future<void> _append(CashMovement movement) =>
      _replace(_newestFirst([movement, ...movements]));

  Future<void> _replace(List<CashMovement> next) async {
    if (_demoShown == null) {
      _movements = next;
      notifyListeners();
      await _prefs.setString(
        _key,
        jsonEncode([for (final m in next) m.toJson()]),
      );
      return;
    }
    _demoLedgers = {..._demoLedgers, _demoShown!: next};
    notifyListeners();
    await _prefs.setString(
      _demoKey,
      jsonEncode({
        for (final entry in _demoLedgers.entries)
          entry.key: [for (final m in entry.value) m.toJson()],
      }),
    );
  }
}

List<CashMovement> _decode(String? raw) {
  if (raw == null || raw.isEmpty) return const [];
  try {
    final value = jsonDecode(raw);
    if (value is! List) return const [];
    return _newestFirst([
      for (final entry in value) ?CashMovement.fromJson(entry),
    ]);
  } on FormatException {
    return const [];
  }
}

Map<String, List<CashMovement>> _decodeLedgers(String? raw) {
  if (raw == null || raw.isEmpty) return {};
  try {
    final value = jsonDecode(raw);
    if (value is! Map) return {};
    return {
      for (final entry in value.entries)
        if (entry.key is String &&
            entry.value is List &&
            (entry.value as List).isNotEmpty)
          entry.key as String: _newestFirst([
            for (final movement in entry.value as List)
              ?CashMovement.fromJson(movement),
          ]),
    };
  } on FormatException {
    return {};
  }
}

List<CashMovement> _newestFirst(List<CashMovement?> movements) => [
  for (final movement
      in movements.whereType<CashMovement>().toList()
        ..sort((a, b) => b.at.compareTo(a.at)))
    movement,
];
