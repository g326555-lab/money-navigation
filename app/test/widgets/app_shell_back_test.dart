import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/app/app_shell.dart';
import 'package:money_navigation/features/assistant/assistant_screen.dart';
import 'package:money_navigation/features/home/home_screen.dart';
import 'package:money_navigation/features/records/records_screen.dart';

import 'harness.dart';

/// Which tab of the IndexedStack is showing.
int shownTab(WidgetTester tester) =>
    tester.widget<IndexedStack>(find.byType(IndexedStack).first).index ?? 0;

void main() {
  setUpAll(warmMarketPrices);
  setUp(resetPreferences);

  Future<void> pumpShell(WidgetTester tester) async {
    setLogicalSize(tester, const Size(466.5, 737.2));
    final stores = Stores();
    await stores.trip.load();
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester);
  }

  /// The system back button, as Android sends it.
  Future<bool> systemBack(WidgetTester tester) async {
    final handled = await tester.binding.handlePopRoute();
    await pumpFrames(tester, frames: 10);
    return handled;
  }

  testWidgets('back from a tab returns to the tab before it, then Home', (
    tester,
  ) async {
    await pumpShell(tester);
    expect(find.byType(HomeScreen), findsOneWidget);

    await tester.tap(find.text('Assistant').last);
    await pumpFrames(tester, frames: 10);
    expect(shownTab(tester), 1);
    await tester.tap(find.text('Records').last);
    await pumpFrames(tester, frames: 10);
    expect(shownTab(tester), 2);

    // Handled inside the app: it does not close.
    expect(await systemBack(tester), isTrue);
    expect(shownTab(tester), 1);
    expect(await systemBack(tester), isTrue);
    expect(shownTab(tester), 0);
    expect(find.byType(HomeScreen), findsOneWidget);
    // The other tabs keep their state offstage.
    expect(find.byType(AssistantScreen, skipOffstage: false), findsOneWidget);
    expect(find.byType(RecordsScreen, skipOffstage: false), findsOneWidget);
    await drainTimers(tester);
  });

  testWidgets('back on Home with nothing behind it leaves the app', (
    tester,
  ) async {
    await pumpShell(tester);
    // Not handled by the app: the platform closes it.
    expect(await systemBack(tester), isFalse);
    await drainTimers(tester);
  });
}
