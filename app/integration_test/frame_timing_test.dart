// Measures frame build and raster times over the animated moments of demo
// scenes 1-3 (success landing with coin burst, haggle verdict with price
// scale and card stack, Home with the living coin). Run in profile mode on
// a device: flutter drive --profile --driver=test_driver/integration_test.dart
// --target=integration_test/frame_timing_test.dart. The summary lands in
// build/integration_response_data.json and is printed as FRAME_TIMING.
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:money_navigation/services/rate_service.dart';

import '../test/rules/fixtures/atm_ocr_fixtures.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('demo path frame timing', (tester) async {
    final trip = TripStore();
    await trip.load();
    final settings = SettingsStore();
    await settings.load();
    final rates = RateService();

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

    Future<void> live(Duration d) => tester.runAsync(() => Future.delayed(d));

    final reading = parseAtmScreen(atmOcrBlockOrder)!;
    final verdict = evaluateAtm(reading);
    final items = await MarketPriceRepository().load();
    final mango = items.firstWhere((s) => s.item.key == 'mango');

    // Frame timings straight from the engine, so a plain profile run works
    // without the driver's timeline.
    final timings = <FrameTiming>[];
    void collect(List<FrameTiming> t) => timings.addAll(t);
    SchedulerBinding.instance.addTimingsCallback(collect);
    {
      await tester.pumpWidget(
        app(
          AtmResultScreen(
            state: ScanState(
              photoPath: 'timing',
              scannedAt: DateTime.now(),
              reading: reading,
              verdict: verdict,
            ),
          ),
        ),
      );
      await live(const Duration(seconds: 3));

      final haggle = HaggleController();
      await tester.pumpWidget(app(HaggleScreen(controller: haggle)));
      await live(const Duration(seconds: 1));
      await haggle.submitManual(mango, 150);
      await live(const Duration(seconds: 3));

      await tester.pumpWidget(app(const AppShell()));
      await live(const Duration(seconds: 3));
    }
    await live(const Duration(milliseconds: 500));
    SchedulerBinding.instance.removeTimingsCallback(collect);
    double ms(Duration d) => d.inMicroseconds / 1000;
    Map<String, double> stats(List<double> v) {
      final s = [...v]..sort();
      double at(double q) => s[((s.length - 1) * q).round()];
      return {
        'avg': s.reduce((a, b) => a + b) / s.length,
        'p90': at(0.9),
        'p99': at(0.99),
        'max': s.last,
      };
    }

    final build = [for (final t in timings) ms(t.buildDuration)];
    final raster = [for (final t in timings) ms(t.rasterDuration)];
    final size =
        binding.platformDispatcher.views.first.physicalSize /
        binding.platformDispatcher.views.first.devicePixelRatio;
    // ignore: avoid_print
    print(
      'FRAME_TIMING ${jsonEncode({'logicalSize': '${size.width.toStringAsFixed(1)}x${size.height.toStringAsFixed(1)}', 'frames': timings.length, 'over16ms': raster.where((r) => r > 16.7).length, 'build': stats(build), 'raster': stats(raster)})}',
    );
  });
}
