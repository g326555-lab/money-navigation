import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/features/assistant/assistant_screen.dart';
import 'package:money_navigation/features/assistant/card_profile_store.dart';
import 'package:money_navigation/features/briefing/arrival_alerts.dart';
import 'package:money_navigation/features/briefing/briefing_controller.dart';
import 'package:money_navigation/features/briefing/calendar_source.dart';
import 'package:money_navigation/features/briefing/country_locator.dart';
import 'package:money_navigation/features/briefing/phone_location.dart';
import 'package:money_navigation/features/briefing/places_client.dart';
import 'package:money_navigation/rules/day_cash.dart';
import 'package:money_navigation/rules/nearby_traps.dart';
import 'package:money_navigation/rules/pay_route.dart';
import 'package:geolocator/geolocator.dart';
import 'package:money_navigation/rules/demo_calendar.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/pay_facts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

const needCard = 'Add your card\'s foreign fee to compare';
const demoTrigger = 'Demo · Land in Japan';

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

const demoOff = 'Off in the demo state';

/// A calendar that granted access and has one stop today.
class FakeCalendar extends CalendarSource {
  FakeCalendar(this.events) {
    access = CalendarAccess.granted;
  }

  final List<DayEvent> events;

  @override
  Future<void> checkAccess() async => access = CalendarAccess.granted;

  @override
  Future<List<DayEvent>> eventsOn(DateTime day) async => events;
}

final phonePosition = Position(
  latitude: 35.6812,
  longitude: 139.7671,
  timestamp: DateTime.utc(2026, 10, 15, 9),
  accuracy: 10,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

class FakeLocation extends PhoneLocation {
  @override
  Future<Position?> read({bool ask = false}) async => position = phonePosition;
}

class FakeCountry extends CountryLocator {
  @override
  Future<String?> countryAt(Position position) async => 'JP';
}

/// An ATM and a cash-only market near Tokyo Station.
class FakePlaces extends PlacesClient {
  @override
  Future<List<NearbyPlaceFact>> nearby(Position position) async => const [
    NearbyPlaceFact(
      name: 'Seven Bank ATM',
      kind: PlaceKind.atm,
      payment: PlacePayment.unknown,
      distanceM: 120,
    ),
    NearbyPlaceFact(
      name: 'Ameyoko stall',
      kind: PlaceKind.market,
      payment: PlacePayment(cashOnly: true),
      distanceM: 300,
    ),
  ];

  @override
  Future<LookedUpPlace?> lookup(String location, {Position? near}) async =>
      null;
}

/// A briefing whose phone is in Tokyo with one calendar stop today.
BriefingController tokyoBriefing() => BriefingController(
  calendar: FakeCalendar([
    DayEvent(
      title: 'Lunch',
      location: 'Ameyoko, Ueno',
      start: DateTime.now().copyWith(hour: 12, minute: 0),
    ),
  ]),
  places: FakePlaces(),
  location: FakeLocation(),
  countries: FakeCountry(),
  card: CardProfileStore(prefs: SharedPreferencesAsync()),
);

/// The assistant's own list.
Finder assistantList() => find
    .descendant(
      of: find.byType(AssistantScreen),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> scrollTo(WidgetTester tester, Finder finder) =>
    tester.scrollUntilVisible(finder, 200, scrollable: assistantList());

Finder amountField() => find.descendant(
  of: find.byType(AssistantScreen),
  matching: find.byType(TextField),
);

/// Platform plugins are absent in tests and answer on a real event loop,
/// so let real time pass until the briefing has started and the nearby
/// lookup has finished (location unavailable).
Future<void> settle(WidgetTester tester, BriefingController briefing) async {
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
    // Load the facts file once in real async; rootBundle caches the future.
    await rootBundle.loadString(payFactsAsset);
    await rootBundle.loadString(demoCalendarAsset);
  });
  setUp(resetPreferences);

  /// Stores for a THB traveler (no demo) unless [demo] is set.
  Future<Stores> stores({String? demo}) async {
    final s = Stores();
    await s.trip.load();
    await s.settings.load(personas: personas);
    await s.settings.setHomeCurrency('THB');
    if (demo != null) await s.settings.setDemoPersona(personas.byKey(demo));
    return s;
  }

  Future<(BriefingController, CardProfileStore)> pumpAssistant(
    WidgetTester tester,
    Stores s,
  ) async {
    final card = CardProfileStore(prefs: SharedPreferencesAsync());
    final briefing = BriefingController(card: card);
    await tester.pumpWidget(
      // AppShell's Scaffold gives the amount field its Material.
      wrap(
        s,
        Scaffold(
          body: AssistantScreen(briefing: briefing, alerts: ArrivalAlerts()),
        ),
      ),
    );
    await settle(tester, briefing);
    return (briefing, card);
  }

  /// Like [pumpAssistant], then lets the demo calendar load (rootBundle
  /// answers outside fake async) and the controller finish.
  Future<void> pumpDemoAssistant(WidgetTester tester, Stores s) async {
    final (briefing, _) = await pumpAssistant(tester, s);
    for (
      var i = 0;
      i < 20 && briefing.cashPlan(const [], demo: true) == null;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await pumpFrames(tester, frames: 5);
    }
    await pumpFrames(tester, frames: 5);
  }

  testWidgets('shows the Assistant title', (tester) async {
    await pumpAssistant(tester, await stores());
    expect(find.text('Assistant'), findsOneWidget);
    expect(find.text('Cash for today'), findsOneWidget);
  });

  group('pay comparison', () {
    testWidgets('asks for an amount before anything is typed', (tester) async {
      await pumpAssistant(tester, await stores());
      await scrollTo(tester, amountField());
      expect(find.text('Type an amount to compare'), findsOneWidget);
    });

    testWidgets('with no card fee, 1000 THB asks for the card fee', (
      tester,
    ) async {
      await pumpAssistant(tester, await stores());
      await scrollTo(tester, amountField());
      await tester.enterText(amountField(), '1000');
      await pumpFrames(tester, frames: 3);

      expect(find.text(needCard), findsOneWidget);
      expect(find.text('+25 THB'), findsNothing);
    });

    testWidgets('card fee 2.5%, 1000 THB: the card adds 25.00 THB', (
      tester,
    ) async {
      final (_, card) = await pumpAssistant(tester, await stores());
      await card.setCardFee(2.5);
      await pumpFrames(tester, frames: 3);

      await scrollTo(tester, amountField());
      await tester.enterText(amountField(), '1000');
      await pumpFrames(tester, frames: 3);

      // 1000 THB x 2.5% = 25.00 THB.
      expect(find.text('+25 THB'), findsOneWidget);
      expect(find.text(needCard), findsNothing);
      // Cash is unpriced (no home bank policy), so no best way is named.
      expect(find.text('Pay by card'), findsNothing);
      // The card row no longer says the fee is missing.
      await scrollTo(tester, find.text('Foreign transaction fee'));
      expect(find.text('Not added yet'), findsNothing);
    });

    testWidgets('the card fee is kept on the phone for the next launch', (
      tester,
    ) async {
      final (_, card) = await pumpAssistant(tester, await stores());
      await card.setCardFee(2.5);
      await pumpFrames(tester, frames: 3);

      final next = CardProfileStore(prefs: SharedPreferencesAsync());
      await tester.runAsync(next.load);
      expect(next.profile.cardFeePercent, 2.5);
    });
  });

  group('BriefingController in a demo state', () {
    test(
      'traps: real surroundings give warnings, the demo state none',
      () async {
        final briefing = tokyoBriefing();
        await briefing.start();
        expect(briefing.nearbyState, NearbyState.done);
        expect(briefing.country, 'JP');

        final real = briefing.traps(countryCode: 'JP', homeCurrency: 'THB');
        expect(real, isNotEmpty);
        expect([
          for (final t in real) t.kind,
        ], containsAll([TrapKind.atmConversion, TrapKind.cashOnlyMarket]));
        expect(
          briefing.traps(countryCode: 'JP', homeCurrency: 'THB', demo: true),
          isEmpty,
        );
      },
    );

    test('cashPlan: the demo state leaves the phone calendar out', () async {
      final briefing = tokyoBriefing();
      await briefing.start();
      expect(briefing.events, hasLength(1));

      final real = briefing.cashPlan(const []);
      expect(real, isNotNull);
      expect(real!.stops, hasLength(1));
      // No records and no calendar: nothing to estimate from.
      expect(briefing.cashPlan(const [], demo: true), isNull);
    });
  });

  group('demo sample calendar in the controller', () {
    test('cashPlan: demo uses the sample stops, real ignores none', () async {
      final briefing = BriefingController(
        calendar: FakeCalendar([
          DayEvent(
            title: 'Lunch',
            location: 'Ameyoko, Ueno',
            start: DateTime.now().copyWith(hour: 12, minute: 0),
          ),
        ]),
        places: FakePlaces(),
        location: FakeLocation(),
        countries: FakeCountry(),
        card: CardProfileStore(prefs: SharedPreferencesAsync()),
      );
      await briefing.useDemo('visitorBangkok', currency: 'THB');
      final demo = briefing.cashPlan(const [], demo: true);
      expect(demo, isNotNull);
      expect(demo!.stops, hasLength(3));
      // The phone calendar was never read, so the real plan has no stops.
      final real = briefing.cashPlan(const [], demo: false);
      expect(real?.stops ?? const [], isEmpty);
    });
  });

  group('near you in a demo state', () {
    testWidgets('the Thai-in-Tokyo demo shows the sample calendar', (
      tester,
    ) async {
      await pumpDemoAssistant(tester, await stores(demo: 'thaiTokyo'));
      await scrollTo(tester, find.text('Sample calendar'));
      expect(find.text('Sample calendar'), findsOneWidget);
      expect(find.text('See money traps near you'), findsNothing);
      expect(find.text('Checking ATMs and markets nearby'), findsNothing);
      expect(find.text(demoOff), findsNothing);
    });

    testWidgets('the visitor in Bangkok demo lists the sample stops', (
      tester,
    ) async {
      await pumpDemoAssistant(tester, await stores(demo: 'visitorBangkok'));
      await scrollTo(tester, find.text('Terminal 21 Asok'));
      expect(find.text('Terminal 21 Asok'), findsOneWidget);
      expect(find.text('Jim Thompson House Museum'), findsOneWidget);
      expect(find.text('Sample calendar'), findsOneWidget);
      expect(find.text('Read today\'s calendar'), findsNothing);
    });

    testWidgets('outside the demo state nearby is not off', (tester) async {
      await pumpAssistant(tester, await stores());
      await scrollTo(tester, find.text('See money traps near you'));
      expect(find.text('See money traps near you'), findsOneWidget);
      expect(find.text(demoOff), findsNothing);
    });
  });

  group('arrival demo trigger', () {
    testWidgets('shows in the Thai-in-Tokyo demo state', (tester) async {
      final (briefing, _) = await pumpAssistant(
        tester,
        await stores(demo: 'thaiTokyo'),
      );
      expect(briefing.facts, isNotNull);
      await scrollTo(tester, find.text(demoTrigger));
      expect(find.text(demoTrigger), findsOneWidget);
    });

    testWidgets('is absent for the visitor in Bangkok demo', (tester) async {
      await pumpAssistant(tester, await stores(demo: 'visitorBangkok'));
      await scrollTo(tester, find.text('Arrival alert'));
      await tester.drag(assistantList(), const Offset(0, -2000));
      await pumpFrames(tester, frames: 3);
      expect(find.text(demoTrigger), findsNothing);
    });

    testWidgets('is absent outside the demo state', (tester) async {
      await pumpAssistant(tester, await stores());
      await scrollTo(tester, find.text('Arrival alert'));
      await tester.drag(assistantList(), const Offset(0, -2000));
      await pumpFrames(tester, frames: 3);
      expect(find.text(demoTrigger), findsNothing);
    });
  });
}
