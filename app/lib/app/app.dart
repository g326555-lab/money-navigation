import 'package:flutter/material.dart';

import '../data/settings_store.dart';
import '../data/trip_store.dart';
import '../l10n/app_localizations.dart';
import '../services/rate_service.dart';
import 'app_scope.dart';
import 'app_shell.dart';
import 'theme.dart';

class MoneyNavigationApp extends StatefulWidget {
  const MoneyNavigationApp({super.key});

  @override
  State<MoneyNavigationApp> createState() => _MoneyNavigationAppState();
}

class _MoneyNavigationAppState extends State<MoneyNavigationApp>
    with WidgetsBindingObserver {
  final _trip = TripStore();
  final _settings = SettingsStore();
  final _rates = RateService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trip.load();
    _settings.load().then((_) => _rates.ensure(_settings.homeCurrency));
    _rates.loadCurrencies();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A trip lasts days; refresh the rate when the app comes back, so it is
  /// never more than a day old while there is a connection.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _rates.ensure(_settings.homeCurrency);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      trip: _trip,
      settings: _settings,
      rates: _rates,
      child: MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        // Part A is English. The demo switch (scene 4) will own the locale;
        // until then the device language must not turn the app Thai.
        locale: const Locale('en'),
        home: const AppShell(),
      ),
    );
  }
}
