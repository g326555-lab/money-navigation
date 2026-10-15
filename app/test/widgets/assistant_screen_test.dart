import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/features/assistant/assistant_screen.dart';
import 'package:money_navigation/features/assistant/card_profile_store.dart';
import 'package:money_navigation/features/briefing/arrival_alerts.dart';
import 'package:money_navigation/features/briefing/briefing_controller.dart';
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
      expect(find.text('+25.00 THB'), findsNothing);
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
      expect(find.text('+25.00 THB'), findsOneWidget);
      expect(find.text(needCard), findsNothing);
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
