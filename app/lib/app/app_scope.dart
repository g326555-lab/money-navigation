import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';
import '../data/trip_store.dart';
import '../rules/demo_personas.dart';
import '../rules/demo_rates.dart';
import '../services/rate_service.dart';

/// App-wide stores, created once in [MoneyNavigationApp].
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.trip,
    required this.settings,
    required this.rates,
    this.demoPersonas,
    this.demoRates,
    required super.child,
  });

  final TripStore trip;
  final SettingsStore settings;
  final RateService rates;

  /// The demo files, once read; used only in the demo state.
  final DemoPersonas? demoPersonas;
  final DemoRates? demoRates;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      trip != oldWidget.trip ||
      settings != oldWidget.settings ||
      rates != oldWidget.rates ||
      demoPersonas != oldWidget.demoPersonas ||
      demoRates != oldWidget.demoRates;
}
