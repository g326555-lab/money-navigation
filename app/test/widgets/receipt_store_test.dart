import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/receipt_store.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

const receiptsKey = 'receipts_v1';

/// The demo restaurant bill: subtotal 225, discount 13, service 10 % = 21,
/// total 233, VAT 7 % 15.24 inside, 217.76 before VAT.
const demoBill = BillCheck(
  kind: BillKind.serviceCharge,
  total: 233,
  subtotal: 225,
  discount: 13,
  serviceCharge: 21,
  servicePercent: 10,
  vat: 15.24,
  vatPercent: 7,
  beforeVat: 217.76,
);

final morning = DateTime.utc(2026, 10, 15, 2);

ReceiptRecord demoRecord({String id = 'bill-1', DateTime? at}) =>
    ReceiptRecord.fromCheck(
      demoBill,
      id: id,
      savedAt: at ?? morning,
      merchantName: 'Baan Somtum',
      category: SpendCategory.food,
    );

ReceiptRecord typed({
  required String id,
  required DateTime at,
  double total = 100,
}) => ReceiptRecord(
  id: id,
  savedAt: at,
  totalThb: total,
  verified: false,
  userCorrected: true,
);

ReceiptStore freshStore() => ReceiptStore(prefs: SharedPreferencesAsync());

void main() {
  setUp(resetPreferences);

  group('load', () {
    test('nothing saved yet gives no records', () async {
      final store = freshStore();
      await store.load();
      expect(store.records, isEmpty);
    });

    test('unreadable stored text is ignored, not thrown', () async {
      await SharedPreferencesAsync().setString(receiptsKey, '{not json');
      final store = freshStore();
      await store.load();
      expect(store.records, isEmpty);
    });

    test('stored JSON that is not a list is ignored', () async {
      await SharedPreferencesAsync().setString(receiptsKey, '{"id":"x"}');
      final store = freshStore();
      await store.load();
      expect(store.records, isEmpty);
    });

    test('entries without id, time or positive total are dropped', () async {
      final good = demoRecord().toJson();
      await SharedPreferencesAsync().setString(
        receiptsKey,
        jsonEncode([
          good,
          {...good, 'id': ''},
          {...good, 'id': 'no-time', 'savedAt': null},
          {...good, 'id': 'zero', 'totalThb': 0},
          {...good, 'id': 'negative', 'totalThb': -5},
          'not a map',
        ]),
      );
      final store = freshStore();
      await store.load();
      expect([for (final r in store.records) r.id], ['bill-1']);
    });

    test('a stored correction marked verified loads as unverified', () async {
      await SharedPreferencesAsync().setString(
        receiptsKey,
        jsonEncode([
          {...demoRecord().toJson(), 'verified': true, 'userCorrected': true},
        ]),
      );
      final store = freshStore();
      await store.load();
      expect(store.records.single.verified, isFalse);
      expect(store.records.single.userCorrected, isTrue);
    });

    test('stored records come back newest first', () async {
      await SharedPreferencesAsync().setString(
        receiptsKey,
        jsonEncode([
          typed(id: 'old', at: morning).toJson(),
          typed(id: 'new', at: morning.add(const Duration(hours: 3))).toJson(),
          typed(id: 'mid', at: morning.add(const Duration(hours: 1))).toJson(),
        ]),
      );
      final store = freshStore();
      await store.load();
      expect([for (final r in store.records) r.id], ['new', 'mid', 'old']);
    });

    test('load reads storage once', () async {
      final store = freshStore();
      await store.load();
      await SharedPreferencesAsync().setString(
        receiptsKey,
        jsonEncode([demoRecord().toJson()]),
      );
      await store.load();
      expect(store.records, isEmpty);
    });
  });

  group('save', () {
    test('adds a record and notifies listeners', () async {
      final store = freshStore();
      var notified = 0;
      store.addListener(() => notified++);
      await store.save(demoRecord());
      expect(store.records, hasLength(1));
      expect(store.contains('bill-1'), isTrue);
      expect(store.contains('bill-2'), isFalse);
      expect(notified, greaterThanOrEqualTo(1));
    });

    test('keeps newest first whatever order bills are saved in', () async {
      final store = freshStore();
      await store.save(typed(id: 'mid', at: morning));
      await store.save(
        typed(id: 'old', at: morning.subtract(const Duration(days: 1))),
      );
      await store.save(
        typed(id: 'new', at: morning.add(const Duration(hours: 2))),
      );
      expect([for (final r in store.records) r.id], ['new', 'mid', 'old']);
    });

    test('a correction with the same id replaces the verified record', () async {
      final store = freshStore();
      final proven = demoRecord();
      await store.save(proven);
      await store.save(typed(id: 'other', at: morning));
      await store.save(proven.corrected(totalThb: 250, serviceIncluded: true));
      expect(store.records, hasLength(2));
      final fixed = store.records.firstWhere((r) => r.id == 'bill-1');
      expect(fixed.verified, isFalse);
      expect(fixed.userCorrected, isTrue);
      expect(fixed.totalThb, 250);
      expect(fixed.serviceIncluded, isTrue);
      // The proven service amount no longer matches the typed total.
      expect(fixed.serviceThb, isNull);
    });

    test('save before load keeps what was already stored', () async {
      await SharedPreferencesAsync().setString(
        receiptsKey,
        jsonEncode([typed(id: 'earlier', at: morning).toJson()]),
      );
      final store = freshStore();
      await store.save(
        demoRecord(at: morning.add(const Duration(minutes: 1))),
      );
      expect([for (final r in store.records) r.id], ['bill-1', 'earlier']);
    });
  });

  group('persistence', () {
    test('the demo bill survives a restart with every proven figure', () async {
      await freshStore().save(demoRecord());

      final raw = await SharedPreferencesAsync().getString(receiptsKey);
      expect(raw, isNotNull);
      expect(jsonDecode(raw!), isA<List>());

      final restarted = freshStore();
      await restarted.load();
      final r = restarted.records.single;
      expect(r.id, 'bill-1');
      expect(r.savedAt.isAtSameMomentAs(morning), isTrue);
      expect(r.verified, isTrue);
      expect(r.userCorrected, isFalse);
      expect(r.merchantName, 'Baan Somtum');
      expect(r.category, SpendCategory.food);
      expect(r.kind, BillKind.serviceCharge);
      expect(r.totalThb, 233);
      expect(r.subtotalThb, 225);
      expect(r.discountThb, 13);
      expect(r.serviceThb, 21);
      expect(r.servicePercent, 10);
      expect(r.serviceIncluded, isFalse);
      expect(r.vatThb, 15.24);
      expect(r.vatOnTop, isFalse);
    });

    test('a replaced record is stored once, as the correction', () async {
      final store = freshStore();
      await store.save(demoRecord());
      await store.save(demoRecord().corrected(totalThb: 240));
      final restarted = freshStore();
      await restarted.load();
      final r = restarted.records.single;
      expect(r.totalThb, 240);
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
    });
  });
}
