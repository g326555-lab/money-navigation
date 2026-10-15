import 'package:supabase_flutter/supabase_flutter.dart';

import '../../rules/personal_context.dart';

/// The traveler's own history and card facts, read with their session so row
/// level security returns only their rows. Everything is evaluated on the
/// phone by `lib/rules/personal_context.dart`; only [cloudSummary] may be
/// handed to a cloud model.
class PersonalMemory {
  PersonalMemory([this._client]);

  final SupabaseClient? _client;
  SupabaseClient get _db => _client ?? Supabase.instance.client;

  /// Rows read per load; a trip has far fewer haggles than this.
  static const historyLimit = 200;

  List<PastPurchase> _history = const [];
  TravelerProfile _profile = const TravelerProfile();
  DateTime? _loadedAt;

  List<PastPurchase> get history => _history;
  TravelerProfile get profile => _profile;

  /// When the records were last read; null before the first [load].
  DateTime? get loadedAt => _loadedAt;

  /// Reads the signed-in traveler's finished haggles and card facts. Leaves
  /// the previous state in place and returns false when signed out or
  /// offline, so verdicts simply show no personal line.
  Future<bool> load() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      // Never keep someone else's records after sign-out.
      _history = const [];
      _profile = const TravelerProfile();
      _loadedAt = null;
      return false;
    }
    try {
      final rows = await _db
          .from('trip_records')
          .select(
            'item_key, asked_thb, paid_thb, place_name, saved_at, is_sample',
          )
          .eq('kind', 'haggle')
          .order('saved_at', ascending: false)
          .limit(historyLimit);
      final profileRow = await _db
          .from('profiles')
          .select('card_fee_percent, atm_fee_policy, atm_fee_value')
          .eq('id', user.id)
          .maybeSingle();
      _history = [for (final r in rows) ?purchaseFromRow(r)];
      _profile = profileFromRow(profileRow);
      _loadedAt = DateTime.now();
      return true;
    } on Object {
      return false;
    }
  }

  PriceMemory? priceOf(String itemKey, {String? placeName}) =>
      priceMemory(itemKey, _history, DateTime.now(), placeName: placeName);

  CounterFromHistory? counterFor(String itemKey, double askedThb) =>
      counterFromHistory(itemKey, askedThb, _history, DateTime.now());

  CashEstimate? morningEstimate() => morningCash(_history, DateTime.now());

  /// Item keys, prices to the baht, counts and day offsets only.
  Map<String, Object?> cloudSummary() =>
      cloudSafeSummary(_history, DateTime.now());
}

/// A finished haggle from a `trip_records` row, or null when it lacks an
/// item, a paid price or a time.
PastPurchase? purchaseFromRow(Map<String, dynamic> row) {
  final item = row['item_key'];
  final paid = _number(row['paid_thb']);
  final at = row['saved_at'] is String
      ? DateTime.tryParse(row['saved_at'] as String)?.toLocal()
      : null;
  if (item is! String || paid == null || at == null) return null;
  final asked = _number(row['asked_thb']);
  final place = row['place_name'];
  return PastPurchase(
    itemKey: item,
    paidThb: paid,
    askedThb: asked,
    placeName: place is String && place.isNotEmpty ? place : null,
    at: at,
    isSample: row['is_sample'] == true,
  );
}

/// Card facts from a `profiles` row; unknown when absent.
TravelerProfile profileFromRow(Map<String, dynamic>? row) {
  if (row == null) return const TravelerProfile();
  return TravelerProfile(
    cardFeePercent: _number(row['card_fee_percent']),
    atmFeePolicy: switch (row['atm_fee_policy']) {
      'charges_fixed' => AtmFeePolicy.chargesFixed,
      'charges_percent' => AtmFeePolicy.chargesPercent,
      'refunds_fees' => AtmFeePolicy.refundsFees,
      'no_fee' => AtmFeePolicy.noFee,
      _ => AtmFeePolicy.unknown,
    },
    atmFeeValue: _number(row['atm_fee_value']),
  );
}

/// PostgREST returns numeric columns as numbers or, for exact decimals, as
/// strings.
double? _number(Object? value) => switch (value) {
  final num n => n.toDouble(),
  final String s => double.tryParse(s),
  _ => null,
};
