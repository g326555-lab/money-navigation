import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/app/app_shell.dart';
import 'package:money_navigation/core/spacing.dart';
import 'package:money_navigation/features/settings/settings_screen.dart';
import 'package:money_navigation/shared/odometer.dart';
import 'package:money_navigation/shared/surface.dart';

import 'harness.dart';

/// Logical sizes: Fold cover screen, a typical iPhone, the unfolded Fold in
/// landscape and in portrait.
const sizes = [
  Size(466.5, 737.2),
  Size(390, 844),
  Size(932.6, 704),
  Size(704, 932.6),
];

void main() {
  setUpAll(warmMarketPrices);
  setUp(resetPreferences);

  Future<Stores> demoStores() async {
    final stores = Stores();
    await stores.trip.load();
    // Four saves, so Home shows "See all" and Records a longer list.
    await stores.trip.add(demoAtmSave());
    await stores.trip.add(demoMangoSave());
    await stores.trip.add(
      demoMangoSave(id: 'mango-2', at: savedAt.add(const Duration(hours: 1))),
    );
    await stores.trip.add(
      demoAtmSave(id: 'atm-2', at: savedAt.add(const Duration(hours: 2))),
    );
    await stores.settings.setHomeCurrency('KRW');
    await stores.rates.ensure('KRW');
    return stores;
  }

  String label(Size s) => '${s.width}x${s.height}';

  for (final size in sizes) {
    testWidgets('Home and Records render without overflow at ${label(size)}', (
      tester,
    ) async {
      setLogicalSize(tester, size);
      final stores = await demoStores();
      await tester.pumpWidget(wrap(stores, const AppShell()));
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('See all'), findsOneWidget);

      await tester.tap(find.text('Records').last);
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
      expect(find.text('Remove'), findsNothing);
    });

    testWidgets('Empty Home renders without overflow at ${label(size)}', (
      tester,
    ) async {
      setLogicalSize(tester, size);
      final stores = Stores();
      await stores.trip.load();
      await stores.settings.setHomeCurrency('KRW');
      await stores.rates.ensure('KRW');
      await tester.pumpWidget(wrap(stores, const AppShell()));
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Settings renders without overflow at ${label(size)}', (
      tester,
    ) async {
      setLogicalSize(tester, size);
      final stores = await demoStores();
      await tester.pumpWidget(wrap(stores, const SettingsScreen()));
      await pumpFrames(tester);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('at 932.6 wide the hero card stays within contentMaxWidth', (
    tester,
  ) async {
    setLogicalSize(tester, const Size(932.6, 704));
    final stores = await demoStores();
    await tester.pumpWidget(wrap(stores, const AppShell()));
    await pumpFrames(tester);

    final hero = find.ancestor(
      of: find.byType(Odometer),
      matching: find.byType(Surface),
    );
    expect(hero, findsOneWidget);
    final width = tester.getSize(hero).width;
    expect(width, lessThanOrEqualTo(AppSizes.contentMaxWidth));
    // Centered on the wide screen, not stuck to the left edge.
    final left = tester.getTopLeft(hero).dx;
    final right = 932.6 - tester.getTopRight(hero).dx;
    expect((left - right).abs(), lessThan(1));
  });
}
