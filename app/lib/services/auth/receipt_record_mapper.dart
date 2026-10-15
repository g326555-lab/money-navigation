/// Converts saved receipts between the app ([ReceiptRecord]) and rows of
/// `public.receipts` (migration 20261015190000_receipts.sql). Pure Dart.
library;

import '../../rules/receipt_record.dart';

/// App field -> column. `user_id` is left to the database default.
const _columns = {
  'id': 'client_id',
  'savedAt': 'saved_at',
  'totalThb': 'total_thb',
  'verified': 'verified',
  'merchantName': 'merchant_name',
  'placeName': 'place_name',
  'lat': 'place_lat',
  'lng': 'place_lng',
  'kind': 'kind',
  'subtotalThb': 'subtotal_thb',
  'discountThb': 'discount_thb',
  'serviceThb': 'service_thb',
  'servicePercent': 'service_percent',
  'serviceIncluded': 'service_included',
  'vatThb': 'vat_thb',
  'vatOnTop': 'vat_on_top',
  'itemCount': 'item_count',
  'category': 'category',
  'userCorrected': 'user_corrected',
  'isSample': 'is_sample',
};

/// Number columns that PostgREST may return as strings (`numeric`).
const _numberFields = {
  'totalThb',
  'lat',
  'lng',
  'subtotalThb',
  'discountThb',
  'serviceThb',
  'servicePercent',
  'vatThb',
};

/// The row to upsert for [record]. Every column is present (absent values
/// as null), so a bulk upsert sends one shape and a re-save clears a field
/// the traveler removed.
Map<String, Object?> receiptToRow(ReceiptRecord record) {
  final json = record.toJson();
  return {
    for (final MapEntry(key: field, value: column) in _columns.entries)
      column: json[field],
  };
}

/// Null when [row] cannot be read as a receipt.
ReceiptRecord? receiptFromRow(Object? row) {
  if (row is! Map) return null;
  final json = <String, Object?>{};
  for (final MapEntry(key: field, value: column) in _columns.entries) {
    final value = row[column];
    if (value == null) continue;
    json[field] = _numberFields.contains(field) && value is String
        ? double.tryParse(value.trim())
        : value;
  }
  return ReceiptRecord.fromJson(json);
}

/// Every readable receipt in [rows], newest first.
List<ReceiptRecord> receiptsFromRows(Object? rows) {
  if (rows is! List) return const [];
  return [for (final r in rows) ?receiptFromRow(r)]
    ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
}
