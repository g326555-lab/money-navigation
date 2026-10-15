import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:money_navigation/app/theme.dart';
import 'package:money_navigation/data/cash_exchange_repository.dart';
import 'package:money_navigation/data/cash_wallet_store.dart';
import 'package:money_navigation/features/briefing/phone_location.dart';
import 'package:money_navigation/features/home/cash_exchange_screen.dart';
import 'package:money_navigation/l10n/app_localizations.dart';
import 'package:money_navigation/services/ai/cloud_functions.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class FakeFunctions extends CloudFunctions {
  FakeFunctions(this.answer);

  final Map<String, dynamic>? Function() answer;

  @override
  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> body, {
    required Duration timeout,
  }) async {
    final value = answer();
    // What the app sees before the function is deployed or while offline.
    if (value == null) throw const CloudFunctionError('404: not found');
    return value;
  }
}

class FakeLocation extends PhoneLocation {
  FakeLocation(this.at, {this.fail = false});

  final Position? at;
  final bool fail;

  @override
  Future<Position?> read({bool ask = false}) async {
    if (fail) throw StateError('plugin crashed');
    return position = at;
  }
}

Position here(double lat, double lng) => Position(
  latitude: lat,
  longitude: lng,
  timestamp: DateTime.utc(2026, 10, 16, 4),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

/// A live-looking answer timed against the real clock, since the screen
/// evaluates freshness at DateTime.now().
Map<String, dynamic> liveAnswer() {
  final now = DateTime.now().toUtc();
  String ago(int minutes) =>
      now.subtract(Duration(minutes: minutes)).toIso8601String();
  return {
    'refreshedAt': ago(1),
    'stale': false,
    'data': {
      'generatedAt': ago(2),
      'sources': {
        'green': {'ok': true, 'fetchedAt': ago(5)},
      },
      'stores': [
        {
          'id': 'a',
          'brand': 'green',
          'name': 'Green A',
          'address': 'Silom',
          'lat': 13.0,
          'lng': 100.0,
        },
      ],
      'rates': {
        'a': {
          'USD': {
            'tiers': [
              {'denom': '100-50', 'buy': 33.5},
            ],
          },
        },
      },
    },
  };
}

Widget screen({
  required CloudFunctions functions,
  required PhoneLocation location,
}) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CashExchangeScreen(
    wallet: CashWalletStore(prefs: SharedPreferencesAsync()),
    walletCurrency: 'THB',
    foreignCurrency: 'USD',
    repository: CashExchangeRepository(
      preferences: SharedPreferencesAsync(),
      functions: functions,
    ),
    location: location,
  ),
);

void main() {
  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
  });

  testWidgets('undeployed or offline rates show the unavailable notice', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        functions: FakeFunctions(() => null),
        location: FakeLocation(here(13, 100)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Checking current published rates'), findsNothing);
    expect(
      find.text('Live exchange rates are unavailable right now'),
      findsOneWidget,
    );
    expect(find.textContaining('About'), findsNothing);
  });

  testWidgets('a throwing location plugin never leaves it on Checking', (
    tester,
  ) async {
    await tester.pumpWidget(
      screen(
        functions: FakeFunctions(liveAnswer),
        location: FakeLocation(null, fail: true),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Checking current published rates'), findsNothing);
    expect(
      find.text('Live exchange rates are unavailable right now'),
      findsOneWidget,
    );
  });

  testWidgets('payout reads once in THB and the record sheet starts empty', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1080, 4800);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      screen(
        functions: FakeFunctions(liveAnswer),
        location: FakeLocation(here(13, 100)),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('Enter an amount to compare nearby counters'),
      findsOneWidget,
    );
    await tester.enterText(find.byType(TextField), '0');
    await tester.pump();
    expect(find.textContaining('About'), findsNothing);

    await tester.enterText(find.byType(TextField), '100');
    await tester.pump();
    expect(find.text('About 3,350 THB'), findsOneWidget);
    expect(find.textContaining('THB THB'), findsNothing);
    expect(find.textContaining('THB THB'), findsNothing);
    expect(find.text('33.50 THB per 1 USD'), findsOneWidget);
    expect(find.text('0.0 km away'), findsOneWidget);

    await tester.tap(find.text('Add received cash to balance'));
    await tester.pumpAndSettle();
    expect(find.text('Confirm the counter payout'), findsOneWidget);
    final sheetField = find.byType(TextField).last;
    expect(tester.widget<TextField>(sheetField).controller!.text, isEmpty);
    expect(
      find.descendant(of: sheetField, matching: find.text('3,350')),
      findsOneWidget,
    );
    await tester.tap(find.text('Add actual amount'));
    await tester.pumpAndSettle();
    // Still open: nothing typed means nothing recorded.
    expect(find.text('Confirm the counter payout'), findsOneWidget);

    await tester.enterText(sheetField, '3,300');
    await tester.pump();
    await tester.tap(find.text('Add actual amount'));
    await tester.pumpAndSettle();
    expect(find.text('Exchange added to Cash on hand'), findsOneWidget);
  });
}
