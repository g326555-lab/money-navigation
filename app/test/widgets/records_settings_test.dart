import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/settings_store.dart';
import 'package:money_navigation/data/trip_store.dart';
import 'package:money_navigation/features/records/records_screen.dart';
import 'package:money_navigation/features/settings/settings_screen.dart';

import 'harness.dart';

void main() {
  setUpAll(warmMarketPrices);
  setUp(resetPreferences);

  group('Records', () {
    Future<Stores> twoSaves() async {
      final stores = Stores();
      await stores.trip.load();
      await stores.trip.add(demoAtmSave());
      await stores.trip.add(demoMangoSave());
      return stores;
    }

    testWidgets('swiping a row left removes it and offers Undo', (
      tester,
    ) async {
      final stores = await twoSaves();
      await tester.pumpWidget(
        wrap(stores, const Scaffold(body: RecordsScreen())),
      );
      await pumpFrames(tester, frames: 5);

      final atmRow = find.text('ATM conversion avoided');
      expect(atmRow, findsOneWidget);
      await tester.drag(atmRow, const Offset(-600, 0));
      await pumpFrames(tester, frames: 20);

      expect(atmRow, findsNothing);
      expect(stores.trip.contains('atm-1'), isFalse);
      expect(stores.trip.saves, hasLength(1));
      expect(find.text('Removed from this trip'), findsOneWidget);
      expect(find.widgetWithText(SnackBarAction, 'Undo'), findsOneWidget);

      // The removal is persisted, not only in memory.
      final persisted = TripStore();
      await persisted.load();
      expect(persisted.contains('atm-1'), isFalse);
      await drainTimers(tester);
    });

    testWidgets('tapping Undo restores the removed save', (tester) async {
      final stores = await twoSaves();
      await tester.pumpWidget(
        wrap(stores, const Scaffold(body: RecordsScreen())),
      );
      await pumpFrames(tester, frames: 5);

      await tester.drag(
        find.text('ATM conversion avoided'),
        const Offset(-600, 0),
      );
      await pumpFrames(tester, frames: 20);
      await tester.tap(find.text('Undo'));
      await pumpFrames(tester, frames: 10);

      expect(stores.trip.contains('atm-1'), isTrue);
      expect(stores.trip.saves.map((s) => s.id), ['mango-1', 'atm-1']);
      expect(find.text('ATM conversion avoided'), findsOneWidget);

      final persisted = TripStore();
      await persisted.load();
      expect(persisted.saves, hasLength(2));
      await drainTimers(tester);
    });

    testWidgets('swiping right does nothing', (tester) async {
      final stores = await twoSaves();
      await tester.pumpWidget(
        wrap(stores, const Scaffold(body: RecordsScreen())),
      );
      await pumpFrames(tester, frames: 5);
      await tester.drag(
        find.text('ATM conversion avoided'),
        const Offset(600, 0),
      );
      await pumpFrames(tester, frames: 20);
      expect(stores.trip.saves, hasLength(2));
    });
  });

  group('Settings', () {
    testWidgets('choosing "End with kha" persists PoliteEnding.female', (
      tester,
    ) async {
      final stores = Stores();
      await stores.settings.load();
      expect(stores.settings.politeEnding, PoliteEnding.male);

      await tester.pumpWidget(wrap(stores, const SettingsScreen()));
      await pumpFrames(tester, frames: 5);
      expect(find.text('End with khrap'), findsOneWidget);
      expect(find.text('No ending'), findsOneWidget);

      await tester.tap(find.text('End with kha'));
      await pumpFrames(tester, frames: 10);

      expect(stores.settings.politeEnding, PoliteEnding.female);
      final fresh = SettingsStore();
      await fresh.load();
      expect(fresh.politeEnding, PoliteEnding.female);
    });

    testWidgets('choosing "No ending" persists PoliteEnding.none', (
      tester,
    ) async {
      final stores = Stores();
      await stores.settings.load();
      await tester.pumpWidget(wrap(stores, const SettingsScreen()));
      await pumpFrames(tester, frames: 5);

      await tester.tap(find.text('No ending'));
      await pumpFrames(tester, frames: 10);

      final fresh = SettingsStore();
      await fresh.load();
      expect(fresh.politeEnding, PoliteEnding.none);
    });
  });
}
