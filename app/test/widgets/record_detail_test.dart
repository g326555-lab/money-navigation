import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/features/home/cash_balance_card.dart';
import 'package:money_navigation/features/records/receipt_record_detail.dart';
import 'package:money_navigation/features/records/save_detail_screen.dart';
import 'package:money_navigation/rules/receipt_record.dart';

import 'harness.dart';

/// Amounts use a no-break space before the currency.
String thb(String amount) => '$amount THB';

Future<Stores> loaded() async {
  final stores = Stores();
  await Future.wait([
    stores.trip.load(),
    stores.settings.load(),
    stores.cashWallet.load(),
  ]);
  return stores;
}

void main() {
  setUp(resetPreferences);

  testWidgets('an ATM record shows what its screen said', (tester) async {
    setLogicalSize(tester, const Size(430, 2400));
    final stores = await tester.runAsync(loaded);
    final save = demoAtmSave();
    await tester.pumpWidget(
      wrap(stores!, SaveDetailScreen(save: save, itemName: '')),
    );
    await pumpFrames(tester);

    expect(find.text('+${thb('246')}'), findsOneWidget);
    expect(find.text(thb('4,000')), findsOneWidget);
    expect(find.text(thb('220')), findsOneWidget);
    expect(find.textContaining('30.86'), findsOneWidget);
    expect(find.text('144.71 USD'), findsOneWidget);
    expect(find.text(thb('4,220')), findsOneWidget);
    // Not linked to cash yet.
    expect(find.text('Cash on hand did not change'), findsOneWidget);

    await tester.runAsync(
      () => stores.cashWallet.addCash(
        amount: 4000,
        currency: 'THB',
        sourceId: save.id,
        description: 'ATM withdrawal',
        at: save.savedAt,
      ),
    );
    await pumpFrames(tester);
    expect(find.text('Added to cash on hand'), findsOneWidget);
    expect(find.text('+${thb('4,000')}'), findsOneWidget);
  });

  testWidgets('a haggle record shows asked, paid and what cash paid', (
    tester,
  ) async {
    setLogicalSize(tester, const Size(430, 2400));
    final stores = await tester.runAsync(loaded);
    final save = demoMangoSave();
    await tester.runAsync(
      () => stores!.cashWallet.setLinkedSpend(
        sourceId: save.id,
        amount: 110,
        currency: 'THB',
        description: 'Market purchase',
        at: save.savedAt,
      ),
    );
    await tester.pumpWidget(
      wrap(stores!, SaveDetailScreen(save: save, itemName: 'Mango')),
    );
    await pumpFrames(tester);
    expect(find.text('+${thb('40')}'), findsOneWidget);
    expect(find.text(thb('150')), findsOneWidget);
    expect(find.text(thb('110')), findsOneWidget);
    expect(find.text('Paid from cash on hand'), findsOneWidget);
    expect(find.text('−${thb('110')}'), findsOneWidget);
  });

  testWidgets('a receipt shows its photo and the figures read', (tester) async {
    setLogicalSize(tester, const Size(430, 2400));
    final stores = await tester.runAsync(loaded);
    final dir = await tester.runAsync(
      () => Directory.systemTemp.createTemp('receipt_photo'),
    );
    final photo = File('${dir!.path}/r.png');
    // A 1x1 PNG, enough for Image.file to have a real file.
    await tester.runAsync(
      () => photo.writeAsBytes(const [
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, //
        0x0D, 0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00,
        0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89,
        0x00, 0x00, 0x00, 0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63,
        0x00, 0x01, 0x00, 0x00, 0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4,
        0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60,
        0x82,
      ]),
    );
    final record = ReceiptRecord(
      id: 'bill-1',
      savedAt: DateTime(2026, 10, 16, 12),
      totalThb: 233,
      subtotalThb: 225,
      discountThb: 13,
      serviceThb: 21,
      servicePercent: 10,
      vatThb: 15.24,
      verified: true,
      merchantName: 'Som Tam Nua',
      photoPath: photo.path,
    );
    await tester.pumpWidget(wrap(stores!, ReceiptRecordDetail(record: record)));
    await pumpFrames(tester);
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('225.00 THB'), findsOneWidget);
    expect(find.text('−${'13.00 THB'}'), findsOneWidget);
    expect(find.text('21.00 THB'), findsOneWidget);
    expect(find.text('15.24 THB'), findsOneWidget);
    expect(find.text('233.00 THB'), findsOneWidget);
    expect(find.text(thb('233')), findsOneWidget);
  });

  testWidgets('a receipt without a photo says so', (tester) async {
    setLogicalSize(tester, const Size(430, 2400));
    final stores = await tester.runAsync(loaded);
    final record = ReceiptRecord(
      id: 'bill-2',
      savedAt: DateTime(2026, 10, 16, 12),
      totalThb: 89,
      verified: true,
      photoPath: '/no/such/file.jpg',
    );
    await tester.pumpWidget(wrap(stores!, ReceiptRecordDetail(record: record)));
    await pumpFrames(tester);
    expect(find.byType(Image), findsNothing);
    expect(
      find.text('The receipt details saved here do not include a photo.'),
      findsOneWidget,
    );
  });

  testWidgets('the cash card shows 0 THB before anything is recorded', (
    tester,
  ) async {
    final stores = await tester.runAsync(loaded);
    await tester.pumpWidget(
      wrap(
        stores!,
        Scaffold(
          body: ListenableBuilder(
            listenable: stores.cashWallet,
            builder: (_, _) => CashBalanceCard(
              wallet: stores.cashWallet,
              currency: 'THB',
              foreignCurrency: 'USD',
              onFindNearby: () {},
            ),
          ),
        ),
      ),
    );
    await pumpFrames(tester);
    expect(find.text('0'), findsOneWidget);
    expect(
      find.text('Add your cash balance to start tracking'),
      findsOneWidget,
    );
    expect(stores.cashWallet.balance('THB'), isNull);

    await tester.runAsync(
      () => stores.cashWallet.setBalance(amount: 1250, currency: 'THB'),
    );
    await pumpFrames(tester);
    expect(find.text('1,250'), findsOneWidget);
    expect(find.textContaining('Last:'), findsOneWidget);
  });
}
