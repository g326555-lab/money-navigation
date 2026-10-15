import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/app/app_shell.dart';
import 'package:money_navigation/shared/odometer.dart';

import 'harness.dart';

const startTitle = 'Scan the ATM screen before you press anything';

Finder heroNumber(String text) =>
    find.byWidgetPredicate((w) => w is Odometer && w.text == text);

void main() {
  setUpAll(warmMarketPrices);
  setUp(resetPreferences);

  /// Stores with the demo trip loaded: the ATM save from the real OCR text
  /// and the mango haggle (asked 150, paid 110).
  Future<Stores> demoTrip(Stores stores, {String? homeCurrency}) async {
    await stores.trip.load();
    await stores.trip.add(demoAtmSave());
    await stores.trip.add(demoMangoSave());
    await stores.settings.load();
    if (homeCurrency != null) {
      await stores.settings.setHomeCurrency(homeCurrency);
    }
    return stores;
  }

  testWidgets('an empty trip shows the dark start card and no About pill', (
    tester,
  ) async {
    final stores = Stores();
    await stores.trip.load();
    await stores.settings.setHomeCurrency('THB');
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester);

    expect(find.text('Kept on this trip'), findsOneWidget);
    expect(heroNumber('0'), findsOneWidget);
    expect(find.text('Before you withdraw'), findsOneWidget);
    expect(find.text(startTitle), findsOneWidget);
    expect(find.text('Open the scanner'), findsOneWidget);
    expect(find.textContaining('About'), findsNothing);
    expect(find.text('Recent saves'), findsNothing);
  });

  testWidgets('an empty trip with a home currency still shows no About pill', (
    tester,
  ) async {
    final stores = Stores();
    await stores.trip.load();
    await stores.settings.setHomeCurrency('KRW');
    await stores.rates.ensure('KRW');
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester);

    expect(find.text(startTitle), findsOneWidget);
    expect(find.textContaining('About'), findsNothing);
  });

  testWidgets('ATM and mango saves add up to 286 THB in the hero', (
    tester,
  ) async {
    final stores = await demoTrip(Stores(), homeCurrency: 'THB');
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester);

    expect(heroNumber('286'), findsOneWidget);
    expect(find.text(' THB'), findsOneWidget);
    expect(find.text(startTitle), findsNothing);
    expect(find.text('Recent saves'), findsOneWidget);
    expect(find.text('ATM conversion avoided'), findsOneWidget);
    // THB travelers need no conversion line.
    expect(find.textContaining('Frankfurter'), findsNothing);
    expect(find.textContaining('About'), findsNothing);
  });

  testWidgets(
    'with KRW home currency and a Frankfurter rate, shows About KRW and the source',
    (tester) async {
      final stores = await demoTrip(Stores(), homeCurrency: 'KRW');
      await stores.rates.ensure('KRW');
      await tester.pumpWidget(wrap(stores, const AppShell()));
      await pumpFrames(tester);

      expect(heroNumber('286'), findsOneWidget);
      // 285.75 THB x 39.81 = 11,375.71, whole won.
      expect(find.text('About 11,376 KRW'), findsOneWidget);
      final source = find.textContaining('Frankfurter');
      expect(source, findsOneWidget);
      final line = tester.widget<Text>(source).data!;
      expect(line, contains('1 THB = 39.81 KRW'));
      expect(line, contains('Oct 14'));
      expect(line, isNot(contains('offline')));
    },
  );

  testWidgets(
    'when the rate request fails, the line asks for a connection and no pill shows',
    (tester) async {
      final stores = await demoTrip(
        Stores(client: frankfurterClient(fail: true)),
        homeCurrency: 'KRW',
      );
      await stores.rates.ensure('KRW');
      await tester.pumpWidget(wrap(stores, const AppShell()));
      await pumpFrames(tester);

      expect(heroNumber('286'), findsOneWidget);
      expect(find.text('Today\'s KRW rate needs a connection'), findsOneWidget);
      expect(find.textContaining('About'), findsNothing);
      expect(find.textContaining('Frankfurter'), findsNothing);
      await drainTimers(tester);
    },
  );

  testWidgets('while the rate is loading, the line says so', (tester) async {
    final stores = await demoTrip(Stores(), homeCurrency: 'KRW');
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester, frames: 2);

    expect(find.text('Getting today\'s rate'), findsOneWidget);
    expect(find.textContaining('About'), findsNothing);
  });
}
