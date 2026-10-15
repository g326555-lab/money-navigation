import '../rules/receipt_record.dart';
import '../services/auth/account_repository.dart';
import 'receipt_store.dart';

/// [ReceiptRemote] backed by the signed-in account's receipts table.
class AccountReceiptRemote implements ReceiptRemote {
  const AccountReceiptRemote(this._repo);

  final AccountRepository _repo;

  @override
  Future<List<ReceiptRecord>> load() => _repo.loadReceipts();

  @override
  Future<void> upsert(ReceiptRecord record) => _repo.upsertReceipt(record);
}
