import '../rules/trip_ledger.dart';
import '../services/auth/account_repository.dart';
import '../services/auth/trip_record_mapper.dart';
import 'trip_store.dart';

/// [TripRemote] backed by the signed-in account's trip_records table.
class AccountTripRemote implements TripRemote {
  const AccountTripRemote(this._repo);

  final AccountRepository _repo;

  @override
  Future<List<TripSave>> load() => _repo.loadSaves();

  @override
  Future<void> upsert(TripSave save) => _repo.upsertSave(
    save,
    // Where a haggle happened, so later verdicts can recall it.
    context: save.placeName == null
        ? null
        : RecordContext(placeName: save.placeName),
  );

  @override
  Future<void> upsertAll(List<TripSave> saves) => _repo.upsertSaves(saves);

  @override
  Future<void> remove(String id) => _repo.removeSave(id);
}
