import 'package:flutter/material.dart';

import '../data/account_trip_remote.dart';
import '../data/settings_store.dart';
import '../features/auth/auth_gate.dart';
import '../services/auth/account_models.dart';
import '../services/auth/auth_controller.dart';
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
  final _auth = AuthController();

  /// The account whose records [_trip] is attached to, if any.
  bool _attached = false;

  /// The profile whose home currency was applied, once per sign-in, so a
  /// later change in Settings is not overwritten.
  String? _currencyFrom;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _trip.load();
    _settings.load().then((_) => _rates.ensure(_settings.homeCurrency));
    _rates.loadCurrencies();
    _auth.addListener(_onAuth);
    // Without accounts the controller settles at once; settle it before the
    // first build so it never notifies while the gate is being built.
    if (!_auth.accountsAvailable) _auth.start();
  }

  /// The app language: the account's once signed in, English otherwise
  /// until the demo switch (scene 4) owns it. The device language never
  /// decides.
  Locale _locale = const Locale('en');

  /// Signed in with a profile: records follow the account, and the
  /// traveler's own currency comes from the profile. Signed out: back to
  /// what is kept on the phone.
  void _onAuth() {
    final signedIn = _auth.isSignedIn;
    final locale = Locale(
      signedIn ? (_auth.profile?.language ?? AppLanguage.en).name : 'en',
    );
    if (locale != _locale) {
      // The gate may notify while it is being built; change after the frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _locale = locale);
      });
    }
    if (signedIn && !_attached) {
      _attached = true;
      _trip.attach(AccountTripRemote(_auth.repository));
    } else if (!signedIn && _attached) {
      _attached = false;
      _trip.detach();
    }
    final profile = _auth.profile;
    final currency = profile?.homeCurrency;
    if (!signedIn) {
      _currencyFrom = null;
    } else if (profile != null &&
        currency != null &&
        _currencyFrom != profile.id) {
      _currencyFrom = profile.id;
      if (currency != _settings.homeCurrency) {
        _settings.setHomeCurrency(currency);
        _rates.ensure(currency);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _auth
      ..removeListener(_onAuth)
      ..dispose();
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
        // AuthScope reaches every route, including pages pushed above the
        // gate (Settings, email sign-in).
        builder: (context, child) =>
            AuthScope(controller: _auth, child: child!),
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: _locale,
        home: AuthGate(controller: _auth, child: const AppShell()),
      ),
    );
  }
}
