import 'package:supabase_flutter/supabase_flutter.dart';

import '../../rules/trip_ledger.dart';
import 'account_models.dart';
import 'auth_failure.dart';
import 'trip_record_mapper.dart';

/// Reads and writes the signed-in traveler's rows. Row level security limits
/// every query to the current user, so nothing here filters by user id for
/// safety; the filters only make the intent explicit.
class AccountRepository {
  AccountRepository([this._client]);

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  String get _uid {
    final id = _db.auth.currentUser?.id;
    if (id == null) {
      throw const AuthFlowException(AuthFailure.unknown, 'not signed in');
    }
    return id;
  }

  /// The profile row, created by the sign-up trigger. Null only if the
  /// trigger has not run yet (it runs in the same transaction, so never in
  /// practice).
  Future<Profile?> loadProfile() => _guard(() async {
    final row = await _db
        .from('profiles')
        .select()
        .eq('id', _uid)
        .maybeSingle();
    return Profile.fromRow(row);
  });

  Future<Profile> saveSetup(ProfileDraft draft, {required DateTime now}) =>
      _guard(() async {
        final profile = draft.toProfile(_uid, now: now);
        final row = await _db
            .from('profiles')
            .update(profile.toSetupRow())
            .eq('id', profile.id)
            .select()
            .single();
        return Profile.fromRow(row) ?? profile;
      });

  Future<List<TripSave>> loadSaves() => _guard(() async {
    final rows = await _db
        .from('trip_records')
        .select()
        .eq('user_id', _uid)
        .order('saved_at', ascending: false);
    return tripSavesFromRows(rows);
  });

  /// Adds or replaces one save; the app's id keeps a retry from duplicating.
  /// [context] records where and how it happened, for the assistant.
  Future<void> upsertSave(
    TripSave save, {
    Map<String, Object?> detail = const {},
    RecordContext? context,
  }) => _guard(() async {
    await _db
        .from('trip_records')
        .upsert(
          tripSaveToRow(save, detail: detail, context: context),
          onConflict: 'user_id,client_id',
        );
  });

  /// Logs the rounds of a haggle; [savedClientId] links them to the save
  /// they led to (upsert that save first). Re-sending a round replaces it.
  Future<void> upsertHaggleRounds(
    List<HaggleRound> rounds, {
    String? savedClientId,
  }) => _guard(() async {
    if (rounds.isEmpty) return;
    String? recordId;
    if (savedClientId != null) {
      final row = await _db
          .from('trip_records')
          .select('id')
          .eq('user_id', _uid)
          .eq('client_id', savedClientId)
          .maybeSingle();
      recordId = row?['id'] as String?;
    }
    await _db.from('haggle_rounds').upsert([
      for (final r in rounds) r.toRow(recordId: recordId),
    ], onConflict: 'user_id,haggle_id,round_no');
  });

  /// Uploads saves made before signing in, in one request.
  Future<void> upsertSaves(Iterable<TripSave> saves) => _guard(() async {
    final rows = [for (final s in saves) tripSaveToRow(s)];
    if (rows.isEmpty) return;
    await _db
        .from('trip_records')
        .upsert(rows, onConflict: 'user_id,client_id');
  });

  Future<void> removeSave(String clientId) => _guard(() async {
    await _db
        .from('trip_records')
        .delete()
        .eq('user_id', _uid)
        .eq('client_id', clientId);
  });

  /// `male`, `female` or `none` (PoliteEnding names).
  Future<String?> loadPoliteEnding() => _guard(() async {
    final row = await _db
        .from('settings')
        .select('polite_ending')
        .eq('user_id', _uid)
        .maybeSingle();
    final value = row?['polite_ending'];
    return value is String ? value : null;
  });

  Future<void> savePoliteEnding(String ending) => _guard(() async {
    await _db.from('settings').upsert({
      'user_id': _uid,
      'polite_ending': ending,
    });
  });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on AuthFlowException {
      rethrow;
    } on PostgrestException catch (e) {
      throw AuthFlowException(
        classifyAuthError(code: e.code, message: e.message),
        'postgrest ${e.code}',
      );
    } on Object catch (e) {
      throw AuthFlowException(
        classifyAuthError(message: e.toString()),
        e.runtimeType.toString(),
      );
    }
  }
}
