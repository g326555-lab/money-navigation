import 'package:flutter/widgets.dart';

import '../data/settings_store.dart';
import '../data/trip_store.dart';
import '../services/rate_service.dart';

/// App-wide stores, created once in [MoneyNavigationApp].
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.trip,
    required this.settings,
    required this.rates,
    required super.child,
  });

  final TripStore trip;
  final SettingsStore settings;
  final RateService rates;

  static AppScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!;

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      trip != oldWidget.trip ||
      settings != oldWidget.settings ||
      rates != oldWidget.rates;
}
