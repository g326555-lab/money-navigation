import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/receipt_store.dart';
import 'package:money_navigation/features/scan/bill_screen.dart';
import 'package:money_navigation/l10n/app_localizations.dart';
import 'package:money_navigation/rules/bill_check.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:money_navigation/services/ai/bill_reader.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

/// The English copy, read from the generated strings so wording tweaks
/// (no-break spaces against widows) do not break the behaviour checks.
final en = lookupAppLocalizations(const Locale('en'));
final yourRecord = en.billYourRecord;
final saveLabel = en.billSave;
final savedLabel = en.billSaved;
final editLabel = en.billEdit;
final enterLabel = en.billEnterIt;
final useLabel = en.billUseCorrection;
final correctionNote = en.billCorrectedNote;

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

/// Answers every photo with [reading]; never touches the network.
class FakeBillReader extends BillReader {
  FakeBillReader(this.reading);

  final BillReading reading;
  int calls = 0;

  @override
  Future<BillReading> read(Uint8List jpeg) async {
    calls++;
    return reading;
  }
}

BillReading verified(String merchant) =>
    BillReading(check: demoBill, traces: const [], merchantName: merchant);

BillReading unproven(String? merchant) =>
    BillReading.failed(BillFailure.doesNotAddUp, merchantName: merchant);

late String photoPath;

/// Records in the shared store for [merchant] (the store is shared by
/// every test in this file, so each test uses its own shop name).
List<ReceiptRecord> recordsAt(String merchant) => [
  for (final r in ReceiptStore.shared.records)
    if (r.merchantName == merchant) r,
];

Future<void> openBill(
  WidgetTester tester,
  BillReading reading, {
  ({double latitude, double longitude})? at,
}) async {
  setLogicalSize(tester, const Size(430, 2400));
  await tester.pumpWidget(
    wrap(
      Stores(),
      BillScreen(
        reader: FakeBillReader(reading),
        initialPhotoPath: photoPath,
        location: at == null ? null : () async => at,
      ),
    ),
  );
  // The photo is read from disk with real IO, outside fake time.
  for (
    var i = 0;
    i < 50 && find.text(en.billReading).evaluate().isNotEmpty;
    i++
  ) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
  await pumpFrames(tester);
}

/// Lets futures that belong to the real zone (the shared store) finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// Seeds the shared store outside fake time.
Future<void> seed(WidgetTester tester, ReceiptRecord record) async {
  await tester.runAsync(() => ReceiptStore.shared.save(record));
}

Future<void> tapText(WidgetTester tester, String text) async {
  final target = find.text(text).last;
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await settle(tester);
  await pumpFrames(tester, frames: 20);
}

Future<void> tapSave(WidgetTester tester) async {
  await tapText(tester, saveLabel);
  await tapText(tester, en.cashPaymentCard);
  for (var i = 0; i < 20 && find.text(savedLabel).evaluate().isEmpty; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();
  }
}

Finder inSheet(Finder f) =>
    find.descendant(of: find.byType(BottomSheet), matching: f);

Future<void> tapInSheet(WidgetTester tester, String text) async {
  final target = inSheet(find.text(text));
  await tester.ensureVisible(target);
  await tester.pump();
  await tester.tap(target);
  await pumpFrames(tester, frames: 6);
}

Finder sheetField(int index) => inSheet(find.byType(TextField)).at(index);

String fieldText(WidgetTester tester, int index) =>
    tester.widget<TextField>(sheetField(index)).controller!.text;

String thb(String amount) => '$amount THB';

void main() {
  setUpAll(() async {
    resetPreferences();
    const pathProvider = MethodChannel('plugins.flutter.io/path_provider');
    final supportDir = await Directory.systemTemp.createTemp(
      'bill_app_support',
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          pathProvider,
          (_) => Future<String>.value(supportDir.path),
        );
    await warmMarketPrices();
    // ReceiptStore.shared memoises its first load. Started inside one
    // test's fake zone, that future would never resolve in the next test,
    // so it is started here in the real zone.
    await ReceiptStore.shared.load();
    final dir = await Directory.systemTemp.createTemp('bill_receipts_test');
    photoPath = '${dir.path}/bill.jpg';
    await File(photoPath).writeAsBytes(List<int>.filled(64, 0xFF));
  });

  group('verified bill', () {
    testWidgets('shows the shop and saves the proven record', (tester) async {
      const shop = 'Baan Somtum Siam';
      await openBill(tester, verified(shop));

      expect(find.text(yourRecord), findsOneWidget);
      expect(find.text(shop), findsOneWidget);
      expect(find.text(saveLabel), findsOneWidget);
      expect(find.text(correctionNote), findsNothing);
      expect(find.textContaining('You saved'), findsNothing);
      expect(recordsAt(shop), isEmpty);

      await tapSave(tester);

      expect(find.text(savedLabel), findsOneWidget);
      expect(find.text(saveLabel), findsNothing);
      final r = recordsAt(shop).single;
      expect(r.verified, isTrue);
      expect(r.userCorrected, isFalse);
      expect(r.totalThb, 233);
      expect(r.subtotalThb, 225);
      expect(r.photoPath, isNotNull);
      expect(File(r.photoPath!).existsSync(), isTrue);
      expect(r.discountThb, 13);
      expect(r.serviceThb, 21);
      expect(r.servicePercent, 10);
      expect(r.vatThb, 15.24);
      expect(r.vatOnTop, isFalse);
      expect(r.kind, BillKind.serviceCharge);

      // Saved to disk under receipts_v1, not only in memory.
      final raw = await tester.runAsync(
        () => SharedPreferencesAsync().getString('receipts_v1'),
      );
      expect(raw, contains(shop));

      // The record just saved is not memory of an earlier visit.
      expect(find.textContaining('You saved'), findsNothing);

      // A second tap does not store a duplicate.
      await tapText(tester, savedLabel);
      expect(recordsAt(shop), hasLength(1));
    });

    testWidgets('an unread shop name says so', (tester) async {
      await openBill(tester, const BillReading(check: demoBill, traces: []));
      expect(find.text(yourRecord), findsOneWidget);
      expect(find.text(en.billShopUnknown), findsOneWidget);
    });
  });

  group('correction', () {
    testWidgets('the sheet opens with what was read', (tester) async {
      const shop = 'Krua Apsorn Test';
      await openBill(tester, verified(shop));
      await tapText(tester, editLabel);

      expect(find.text(en.billEditTitle), findsOneWidget);
      expect(fieldText(tester, 0), shop);
      expect(fieldText(tester, 1), '233.00');
      // Service was added on top at 10 %, so the percent field is shown.
      expect(inSheet(find.byType(TextField)), findsNWidgets(3));
      expect(fieldText(tester, 2), '10');
    });

    testWidgets('replaces the record with an unverified correction', (
      tester,
    ) async {
      const shop = 'Som Tam Nua Test';
      await openBill(tester, verified(shop));
      await tapSave(tester);
      final proven = recordsAt(shop).single;
      expect(proven.verified, isTrue);

      await tapText(tester, editLabel);
      await tester.enterText(sheetField(1), '250');
      await tapInSheet(tester, en.billServiceIncludedChoice);
      await tapInSheet(tester, en.billVatOnTopChip);
      await tapInSheet(tester, useLabel);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(correctionNote), findsOneWidget);
      expect(find.text(thb('250.00')), findsOneWidget);
      // The correction is not saved until the traveler saves it.
      expect(find.text(saveLabel), findsOneWidget);
      expect(recordsAt(shop).single.verified, isTrue);

      await tapSave(tester);
      expect(find.text(savedLabel), findsOneWidget);
      final r = recordsAt(shop).single;
      expect(r.id, proven.id);
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
      expect(r.totalThb, 250);
      expect(r.serviceIncluded, isTrue);
      expect(r.servicePercent, isNull);
      expect(r.serviceThb, isNull);
      expect(r.vatOnTop, isTrue);
      expect(r.vatThb, isNull);
    });

    testWidgets('a renamed shop and a new service percent are kept', (
      tester,
    ) async {
      const shop = 'Jay Fai Test';
      const renamed = 'Jay Fai Pratu Phi';
      await openBill(tester, verified(shop));
      await tapText(tester, editLabel);
      await tester.enterText(sheetField(0), renamed);
      await tester.enterText(sheetField(2), '12');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);

      expect(find.text(renamed), findsOneWidget);
      await tapSave(tester);
      final r = recordsAt(renamed).single;
      expect(r.servicePercent, 12);
      expect(r.serviceIncluded, isFalse);
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
    });

    testWidgets('no service charge clears the percent', (tester) async {
      const shop = 'Thip Samai Test';
      await openBill(tester, verified(shop));
      await tapText(tester, editLabel);
      await tapInSheet(tester, en.billServiceNone);
      expect(inSheet(find.byType(TextField)), findsNWidgets(2));
      await tapInSheet(tester, useLabel);
      await tapSave(tester);
      final r = recordsAt(shop).single;
      expect(r.servicePercent, isNull);
      expect(r.serviceIncluded, isFalse);
      expect(r.totalThb, 233);
    });

    testWidgets('invalid figures keep the sheet open', (tester) async {
      const shop = 'Invalid Figures Test';
      await openBill(tester, verified(shop));
      await tapText(tester, editLabel);

      await tester.enterText(sheetField(1), '');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.enterText(sheetField(1), '233');
      await tester.enterText(sheetField(2), '100');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.enterText(sheetField(2), '');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.enterText(sheetField(2), '10');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);
      expect(find.byType(BottomSheet), findsNothing);
      expect(recordsAt(shop), isEmpty);
    });
  });

  group('bill that does not add up', () {
    testWidgets('offers to enter it and stores an unverified record', (
      tester,
    ) async {
      const shop = 'Unproven Noodles';
      await openBill(tester, unproven(shop));

      expect(find.text(en.billNoMatchTitle), findsOneWidget);
      expect(find.text(enterLabel), findsOneWidget);
      expect(find.text(yourRecord), findsNothing);
      // Nothing to save before the traveler enters a figure.
      await tapText(tester, saveLabel);
      expect(recordsAt(shop), isEmpty);

      await tapText(tester, enterLabel);
      expect(fieldText(tester, 0), shop);
      expect(fieldText(tester, 1), isEmpty);
      // No total yet: the button does nothing.
      await tapInSheet(tester, useLabel);
      expect(find.byType(BottomSheet), findsOneWidget);

      await tester.enterText(sheetField(1), '180');
      await pumpFrames(tester, frames: 4);
      await tapInSheet(tester, useLabel);

      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text(yourRecord), findsOneWidget);
      expect(find.text(shop), findsOneWidget);
      expect(find.text(thb('180.00')), findsOneWidget);
      expect(find.text(correctionNote), findsOneWidget);
      expect(find.text(editLabel), findsOneWidget);

      await tapSave(tester);
      expect(find.text(savedLabel), findsOneWidget);
      final r = recordsAt(shop).single;
      expect(r.verified, isFalse);
      expect(r.userCorrected, isTrue);
      expect(r.totalThb, 180);
      expect(r.kind, isNull);
    });

    testWidgets('other failures offer no manual entry', (tester) async {
      await openBill(tester, const BillReading.failed(BillFailure.offline));
      expect(find.text(en.billOfflineTitle), findsOneWidget);
      expect(find.text(enterLabel), findsNothing);
      expect(find.text(saveLabel), findsNothing);
    });
  });

  group('merchant memory', () {
    ReceiptRecord earlierAt(
      String shop, {
      required String id,
      int daysAgo = 1,
      double? lat,
      double? lng,
    }) => ReceiptRecord.fromCheck(
      demoBill,
      id: id,
      savedAt: DateTime.now().subtract(Duration(days: daysAgo)),
      merchantName: shop,
      lat: lat,
      lng: lng,
    );

    testWidgets(
      'an unlocated corrected bill of the same name is another branch',
      (tester) async {
        const shop = 'Memory Kitchen';
        await seed(
          tester,
          earlierAt(
            shop,
            id: 'memory-earlier',
          ).corrected(totalThb: 400, servicePercent: 10),
        );

        // Same shop printed in capitals still matches the name.
        await openBill(tester, verified('MEMORY KITCHEN'));

        expect(
          find.text(en.billBrandMemory(en.billBrandServiceAdded, 1)),
          findsOneWidget,
        );
        expect(
          find.text(en.billMemoryNoteBranch(en.billNoteServiceAdded('10'), 1)),
          findsOneWidget,
        );
        // A name alone is never counted as a visit to this shop.
        expect(find.textContaining('You saved'), findsNothing);
      },
    );

    testWidgets('a verified bill of the same name gives a habit, no note', (
      tester,
    ) async {
      const shop = 'Proven Diner';
      await seed(tester, earlierAt(shop, id: 'proven-earlier', daysAgo: 2));
      await openBill(tester, verified(shop));
      expect(
        find.text(en.billBrandMemory(en.billBrandServiceAdded, 1)),
        findsOneWidget,
      );
      expect(find.textContaining('noted'), findsNothing);
      expect(find.textContaining('You saved'), findsNothing);
    });

    testWidgets('branches that disagree give no habit line', (tester) async {
      const shop = 'Mixed Chain';
      await seed(tester, earlierAt(shop, id: 'mixed-1', daysAgo: 2));
      await seed(
        tester,
        ReceiptRecord(
          id: 'mixed-2',
          savedAt: DateTime.now().subtract(const Duration(days: 1)),
          totalThb: 120,
          verified: true,
          merchantName: shop,
        ),
      );
      await openBill(tester, verified(shop));
      expect(find.textContaining('branch'), findsNothing);
      expect(find.textContaining('You saved'), findsNothing);
    });

    testWidgets('another shop brings no memory', (tester) async {
      await seed(tester, earlierAt('Somewhere Else Entirely', id: 'elsewhere'));
      await openBill(tester, verified('Brand New Place'));
      expect(find.textContaining('You saved'), findsNothing);
      expect(find.textContaining('branch'), findsNothing);
      expect(find.textContaining('noted'), findsNothing);
    });

    testWidgets('an included-service correction reads as such', (tester) async {
      const shop = 'Included Service Bistro';
      await seed(
        tester,
        earlierAt(
          shop,
          id: 'included-earlier',
        ).corrected(serviceIncluded: true),
      );
      await openBill(tester, verified(shop));
      expect(
        find.text(en.billBrandMemory(en.billNoteServiceIncluded, 1)),
        findsOneWidget,
      );
      expect(
        find.text(en.billMemoryNoteBranch(en.billNoteServiceIncluded, 1)),
        findsOneWidget,
      );
    });

    testWidgets('a located earlier bill at this shop counts as a visit', (
      tester,
    ) async {
      const shop = 'Located Kitchen';
      await seed(
        tester,
        earlierAt(
          shop,
          id: 'located-earlier',
          lat: 13.7466,
          lng: 100.5393,
        ).corrected(totalThb: 400, servicePercent: 10),
      );
      await openBill(
        tester,
        verified(shop),
        at: (latitude: 13.7466, longitude: 100.5393),
      );
      expect(find.text(en.billMemoryVisits(1, thb('400.00'))), findsOneWidget);
      expect(
        find.text(en.billMemoryNote(en.billNoteServiceAdded('10'), 1)),
        findsOneWidget,
      );
    });
  });
}
