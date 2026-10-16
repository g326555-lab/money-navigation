import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/app/app_shell.dart';
import 'package:money_navigation/features/assistant/card_profile_store.dart';
import 'package:money_navigation/features/briefing/arrival_alerts.dart';
import 'package:money_navigation/features/briefing/briefing_controller.dart';
import 'package:money_navigation/features/home/home_screen.dart';
import 'package:money_navigation/features/home/route_line.dart';
import 'package:money_navigation/rules/demo_calendar.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/pay_facts.dart';
import 'package:money_navigation/shared/odometer.dart';

import 'harness.dart';

Map<String, Object?> persona(
  String key,
  String language,
  String home,
  String local,
) => {
  'key': key,
  'language': language,
  'homeCurrency': home,
  'localCurrency': local,
  'samples': [
    {'kind': 'terminalDcc', 'daysAgo': 1, 'time': '18:05', 'keptThb': 86.4},
  ],
};

final personas = parseDemoPersonas(
  jsonEncode({
    'personas': [
      persona('visitorBangkok', 'en', 'USD', 'THB'),
      persona('thaiTokyo', 'th', 'THB', 'JPY'),
    ],
  }),
)!;

const startTitle = 'Scan the ATM screen before you press anything';

Finder heroNumber(String text) =>
    find.byWidgetPredicate((w) => w is Odometer && w.text == text);

/// Home's own list, so offstage tabs never match.
Finder homeList() => find
    .descendant(of: find.byType(HomeScreen), matching: find.byType(Scrollable))
    .first;

/// Scrolls Home's lazy list until [finder] is built and on screen.
Future<void> scrollHomeTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: homeList());

/// Text inside the route line only.
Finder inRoute(String text) =>
    find.descendant(of: find.byType(RouteLine), matching: find.text(text));

/// Amounts use a no-break space before the currency.
String kept(String amount) => '+$amount\u00A0THB';

/// Home on its own, with [briefing] and fresh alerts. No platform plugins
/// run in tests: calendar access stays unknown, location is unavailable.
Widget home(Stores stores, BriefingController briefing) => wrap(
  stores,
  HomeScreen(
    onScan: () {},
    onSeeAll: () {},
    onSettings: () {},
    onOpenAssistant: () {},
    briefing: briefing,
    alerts: ArrivalAlerts(),
  ),
);

/// The missing location plugin answers on a real event loop, outside fake
/// async, so let real time pass until the nearby lookup has finished.
Future<void> settleBriefing(
  WidgetTester tester,
  BriefingController briefing,
) async {
  for (var i = 0; i < 20; i++) {
    await pumpFrames(tester, frames: 5);
    final state = briefing.nearbyState;
    if (state != NearbyState.idle && state != NearbyState.loading) return;
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
  }
}

void main() {
  setUpAll(() async {
    await warmMarketPrices();
    // rootBundle caches the first load; doing it here, in real async, keeps
    // a later test from awaiting a load started inside another fake zone.
    await rootBundle.loadString(payFactsAsset);
    await rootBundle.loadString(demoCalendarAsset);
  });
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
    await scrollHomeTo(tester, find.text(startTitle));
    await scrollHomeTo(tester, find.text('Kept on this trip'));

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
    await scrollHomeTo(tester, find.text(startTitle));

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
    // The hero and the cash card each name their currency.
    expect(find.text(' THB'), findsNWidgets(2));
    expect(find.text(startTitle), findsNothing);
    // Recent saves sit below the briefing and nearby cards.
    await scrollHomeTo(tester, find.text('Recent saves'));
    expect(find.text('Recent saves'), findsOneWidget);
    await scrollHomeTo(tester, find.text('ATM conversion avoided'));
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

  group('route line', () {
    testWidgets('one stop per place with its kept amount, then Next stop', (
      tester,
    ) async {
      final stores = await demoTrip(Stores(), homeCurrency: 'THB');
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      expect(find.byType(RouteLine), findsOneWidget);
      // ATM save 245.75 THB and mango 40 THB, rounded to whole baht.
      expect(inRoute('ATM'), findsOneWidget);
      expect(inRoute(kept('246')), findsOneWidget);
      expect(inRoute('Market'), findsOneWidget);
      expect(inRoute(kept('40')), findsOneWidget);
      expect(inRoute('Next stop'), findsOneWidget);
      // Oldest first: the ATM stop is left of the market stop.
      expect(
        tester.getTopLeft(inRoute('ATM')).dx,
        lessThan(tester.getTopLeft(inRoute('Market')).dx),
      );
      expect(
        tester.getTopLeft(inRoute('Market')).dx,
        lessThan(tester.getTopLeft(inRoute('Next stop')).dx),
      );
    });

    testWidgets('a trip with no saves has no route line', (tester) async {
      final stores = Stores();
      await stores.trip.load();
      await stores.settings.setHomeCurrency('THB');
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      expect(find.byType(RouteLine), findsNothing);
      expect(find.text('Next stop'), findsNothing);
    });
  });

  group('briefing and nearby cards', () {
    testWidgets('without calendar access the briefing offers to read it', (
      tester,
    ) async {
      final stores = await demoTrip(Stores(), homeCurrency: 'THB');
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      await scrollHomeTo(tester, find.text('Today'));
      expect(find.text('Today'), findsOneWidget);
      await scrollHomeTo(tester, find.text('Read today\'s calendar'));
      expect(find.text('Read today\'s calendar'), findsOneWidget);
    });

    testWidgets('without a location the nearby card asks for it', (
      tester,
    ) async {
      final stores = await demoTrip(Stores(), homeCurrency: 'THB');
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      await scrollHomeTo(tester, find.text('See money traps near you'));
      expect(find.text('See money traps near you'), findsOneWidget);
      expect(find.text('Checking ATMs and markets nearby'), findsNothing);
    });

    testWidgets('a demo state hides the nearby card', (tester) async {
      final stores = Stores();
      await stores.trip.load();
      await stores.settings.load(personas: personas);
      await stores.settings.setDemoPersona(personas.byKey('thaiTokyo'));
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      // Scroll the whole list; none of the nearby card's states shows.
      await tester.drag(homeList(), const Offset(0, -3000));
      await pumpFrames(tester, frames: 5);
      expect(find.text('See money traps near you'), findsNothing);
      expect(find.text('Checking ATMs and markets nearby'), findsNothing);
      expect(find.text('Watch out nearby'), findsNothing);
      expect(find.text('Nothing to watch out for nearby'), findsNothing);
    });

    testWidgets('a demo state lists the sample stops, not a calendar prompt', (
      tester,
    ) async {
      final stores = Stores();
      await stores.trip.load();
      await stores.settings.load(personas: personas);
      await stores.settings.setDemoPersona(personas.byKey('visitorBangkok'));
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);
      for (
        var i = 0;
        i < 40 && find.text('Sample calendar').evaluate().isEmpty;
        i++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await pumpFrames(tester, frames: 5);
      }
      await pumpFrames(tester, frames: 5);

      expect(find.text('Sample calendar'), findsOneWidget);
      expect(find.text('Flight home'), findsOneWidget);
      expect(find.text('Lunch appointment'), findsOneWidget);
      expect(find.text('Read today\'s calendar'), findsNothing);
    });

    testWidgets('an empty trip still shows the briefing and nearby cards', (
      tester,
    ) async {
      final stores = Stores();
      await stores.trip.load();
      await stores.settings.setHomeCurrency('THB');
      final briefing = BriefingController(card: CardProfileStore());
      await tester.pumpWidget(home(stores, briefing));
      await settleBriefing(tester, briefing);

      await scrollHomeTo(tester, find.text('Read today\'s calendar'));
      expect(find.text('Read today\'s calendar'), findsOneWidget);
      await scrollHomeTo(tester, find.text('See money traps near you'));
      expect(find.text('See money traps near you'), findsOneWidget);
    });
  });
}
