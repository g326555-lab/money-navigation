import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:money_navigation/app/app_scope.dart';
import 'package:money_navigation/app/theme.dart';
import 'package:money_navigation/data/market_price_repository.dart';
import 'package:money_navigation/data/settings_store.dart';
import 'package:money_navigation/data/trip_store.dart';
import 'package:money_navigation/l10n/app_localizations.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:money_navigation/services/rate_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import '../rules/fixtures/atm_ocr_fixtures.dart';

/// Body of GET https://api.frankfurter.dev/v1/latest?base=THB&symbols=KRW.
const frankfurterKrwBody =
    '{"amount":1.0,"base":"THB","date":"2026-10-14","rates":{"KRW":39.81}}';

final savedAt = DateTime.utc(2026, 10, 15, 9, 30);

/// The scene 1 save, built from the real OCR text of the ATM prop.
TripSave demoAtmSave({String id = 'atm-1', DateTime? at}) => saveFromAtm(
  evaluateAtm(parseAtmScreen(atmOcrBlockOrder)!),
  id: id,
  savedAt: at ?? savedAt,
)!;

/// The scene 2 save: mango asked 150, paid 110.
TripSave demoMangoSave({String id = 'mango-1', DateTime? at}) => saveFromHaggle(
  id: id,
  savedAt: at ?? savedAt.add(const Duration(minutes: 5)),
  itemKey: 'mango',
  askedThb: 150,
  paidThb: 110,
)!;

/// Fresh in-memory preferences; call in setUp before creating any store.
void resetPreferences() {
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
}

/// Loads the market price file once into the repository's static cache, in
/// a real async zone, so screens never wait on rootBundle inside fake async.
Future<void> warmMarketPrices() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await MarketPriceRepository().load();
}

http.Client frankfurterClient({bool fail = false, void Function()? onCall}) =>
    MockClient((request) async {
      onCall?.call();
      if (fail) throw http.ClientException('offline', request.url);
      if (request.url.path == '/v1/latest') {
        return http.Response(frankfurterKrwBody, 200);
      }
      return http.Response('{"KRW":"South Korean Won"}', 200);
    });

class Stores {
  Stores({http.Client? client})
    : trip = TripStore(),
      settings = SettingsStore(),
      rates = RateService(client: client ?? frankfurterClient());

  final TripStore trip;
  final SettingsStore settings;
  final RateService rates;
}

/// The screen wrapped the way MoneyNavigationApp wraps it.
Widget wrap(Stores stores, Widget home) => AppScope(
  trip: stores.trip,
  settings: stores.settings,
  rates: stores.rates,
  child: MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: buildAppTheme(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: home,
  ),
);

/// Pumps fixed frames. LivingCoin and AuraField repeat forever, so
/// pumpAndSettle would never return.
Future<void> pumpFrames(
  WidgetTester tester, {
  int frames = 30,
  Duration step = const Duration(milliseconds: 50),
}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(step);
  }
}

/// Lets timers such as rate retries and snackbars run out before teardown.
Future<void> drainTimers(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump(const Duration(seconds: 15));
  }
}

void setLogicalSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.reset);
}
