import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/account_receipt_remote.dart';
import '../data/account_trip_remote.dart';
import '../data/receipt_store.dart';
import '../data/settings_store.dart';
import '../features/auth/auth_gate.dart';
import '../services/auth/account_models.dart';
import '../services/auth/auth_controller.dart';
import '../data/trip_store.dart';
import '../l10n/app_localizations.dart';
import '../rules/demo_personas.dart';
import '../rules/demo_rates.dart';
import '../services/rate_service.dart';
import 'app_scope.dart';
import 'app_shell.dart';
import 'demo_switch.dart';
import '../features/scan/scan_screen.dart' show demoRatesAsset;
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
    _settings.addListener(_onSettings);
    // Records first, so a demo state restored from the last run shows its
    // own ledger at once instead of replacing the samples a moment later.
    (_trip.load(), _loadDemoFiles()).wait.then((r) async {
      await _settings.load(personas: r.$2);
      _demoSettled = true;
      _rates.ensure(_settings.homeCurrency);
    });
    _rates.loadCurrencies();
    _auth.addListener(_onAuth);
    // Without accounts the controller settles at once; settle it before the
    // first build so it never notifies while the gate is being built.
    if (!_auth.accountsAvailable) _auth.start();
  }

  /// The demo files: the two prepared states with their sample records,
  /// and the fixed rates. Null when a file cannot be read; the demo state
  /// is then simply not offered.
  DemoPersonas? _demoPersonas;
  DemoRates? _demoRates;

  Future<DemoPersonas?> _loadDemoFiles() async {
    Future<T?> read<T>(String asset, T? Function(String) parse) =>
        rootBundle.loadString(asset).then(parse, onError: (Object _) => null);
    final (personas, rates) = await (
      read(demoPersonasAsset, parseDemoPersonas),
      read(demoRatesAsset, parseDemoRates),
    ).wait;
    if (mounted) {
      setState(() {
        _demoPersonas = personas;
        _demoRates = rates;
      });
    }
    return personas;
  }

  /// The demo state on screen, so the records follow it exactly once.
  String? _demoShown;

  /// False until settings first loaded; tells a restored demo state from
  /// one switched to.
  bool _demoSettled = false;

  /// Demo state changes: the records follow the persona here; the language
  /// follows in [build]; the currency comes from [SettingsStore.homeCurrency].
  void _onSettings() {
    final persona = _settings.demoPersona;
    if (persona?.key == _demoShown) return;
    // A demo state that comes back with the app (not switched to now) starts
    // again from its samples, so dates like "2 days ago" stay true and a
    // rehearsal's saves never reach the stage.
    final restored = !_demoSettled && persona != null;
    _demoShown = persona?.key;
    final receipts = ReceiptStore.shared;
    if (persona == null) {
      _trip.showReal();
      receipts.showReal();
    } else {
      final now = DateTime.now();
      _trip.showDemo(persona.key, persona.samplesAt(now));
      receipts.showDemo(persona.key, persona.receiptsAt(now));
      if (restored) {
        _trip.resetDemo();
        receipts.resetDemo();
      }
    }
    _rates.ensure(_settings.homeCurrency);
    setState(() {});
  }

  /// The app language: the demo persona's in the demo state, otherwise the
  /// account's once signed in, English when signed out. The device
  /// language never decides.
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
      ReceiptStore.shared.attach(AccountReceiptRemote(_auth.repository));
    } else if (!signedIn && _attached) {
      _attached = false;
      _trip.detach();
      ReceiptStore.shared.detach();
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
    _settings.removeListener(_onSettings);
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
      receipts: ReceiptStore.shared,
      demoPersonas: _demoPersonas,
      demoRates: _demoRates,
      child: MaterialApp(
        // AuthScope reaches every route, including pages pushed above the
        // gate (Settings, email sign-in); the demo switch covers them all.
        builder: (context, child) => AuthScope(
          controller: _auth,
          child: DemoSwitch(child: child!),
        ),
        onGenerateTitle: (context) => AppLocalizations.of(context).appName,
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: switch (_settings.demoPersona) {
          final persona? => Locale(persona.language),
          null => _locale,
        },
        home: AuthGate(controller: _auth, child: const AppShell()),
      ),
    );
  }
}
