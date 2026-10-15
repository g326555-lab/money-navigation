// Captures the main screens with real calculations on sample inputs, for
// design reviews (before/after comparisons). Run with flutter drive and
// test_driver/integration_test.dart; images land in CAPTURE_DIR.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:money_navigation/app/app_scope.dart';
import 'package:money_navigation/app/app_shell.dart';
import 'package:money_navigation/app/theme.dart';
import 'package:money_navigation/data/market_price_repository.dart';
import 'package:money_navigation/data/settings_store.dart';
import 'package:money_navigation/data/trip_store.dart';
import 'package:money_navigation/features/scan/atm_result_screen.dart';
import 'package:money_navigation/features/scan/scan_controller.dart';
import 'package:money_navigation/features/speak/haggle_controller.dart';
import 'package:money_navigation/features/speak/haggle_screen.dart';
import 'package:money_navigation/l10n/app_localizations.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:money_navigation/services/rate_service.dart';

import '../test/rules/fixtures/atm_ocr_fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> shot(WidgetTester tester, String name) async {
    // The coin floats and the success light drifts forever, so settle by
    // time rather than waiting for every animation to stop.
    for (var i = 0; i < 25; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    if (Platform.isAndroid) await binding.convertFlutterSurfaceToImage();
    await tester.pump(const Duration(milliseconds: 100));
    await binding.takeScreenshot(name);
  }

  testWidgets('capture main screens', (tester) async {
    final trip = TripStore();
    await trip.load();
    for (final s in trip.saves.toList()) {
      await trip.remove(s.id);
    }
    final settings = SettingsStore();
    await settings.load();
    final rates = RateService();
    await rates.ensure(settings.homeCurrency);
    await rates.loadCurrencies();

    Widget app(Widget home) => AppScope(
      trip: trip,
      settings: settings,
      rates: rates,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: home,
      ),
    );

    await tester.pumpWidget(app(const AppShell()));
    await shot(tester, '1-home-empty');

    final reading = parseAtmScreen(atmOcrBlockOrder)!;
    final verdict = evaluateAtm(reading);
    final scannedAt = DateTime.now();
    await tester.pumpWidget(
      app(
        AtmResultScreen(
          state: ScanState(
            photoPath: 'capture',
            scannedAt: scannedAt,
            reading: reading,
            verdict: verdict,
          ),
        ),
      ),
    );
    await shot(tester, '2-atm-result');

    await trip.add(
      saveFromAtm(verdict, id: 'atm-capture', savedAt: scannedAt)!,
    );
    final items = await MarketPriceRepository().load();
    final mango = items.firstWhere((s) => s.item.key == 'mango');
    final haggle = HaggleController();
    await tester.pumpWidget(app(HaggleScreen(controller: haggle)));
    await tester.pump(const Duration(seconds: 1));
    await haggle.submitManual(mango, 150);
    await shot(tester, '3-haggle-verdict');

    // The two sheets on the haggle screen: keying a price in, and what was
    // really paid before saving.
    await tester.tap(find.text('Enter price').first);
    await shot(tester, '3b-haggle-enter-price');
    await tester.tap(find.text('Mango').last);
    await tester.enterText(find.byType(TextField), '150');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await shot(tester, '3c-haggle-entered');
    await tester.tap(find.text('Save to trip'));
    await shot(tester, '3d-haggle-paid-sheet');
    Navigator.of(tester.element(find.byType(TextField))).pop();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    await trip.add(
      saveFromHaggle(
        id: 'haggle-capture',
        savedAt: DateTime.now(),
        itemKey: mango.item.key,
        askedThb: 150,
        paidThb: mango.item.high,
      )!,
    );
    await tester.pumpWidget(app(const AppShell()));
    await shot(tester, '4-home-saved');

    await tester.tap(find.byIcon(Icons.tune_rounded));
    await shot(tester, '5-settings');
    Navigator.of(tester.element(find.text('Settings').first)).pop();
    await shot(tester, '5b-home-back');

    await tester.tap(find.text('Records'));
    await shot(tester, '6-records');
  });
}
