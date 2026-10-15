import 'package:flutter/widgets.dart';

import '../data/receipt_store.dart';
import '../data/settings_store.dart';
import '../data/trip_store.dart';
import '../data/cash_wallet_store.dart';
import '../rules/demo_personas.dart';
import '../rules/demo_rates.dart';
import '../services/rate_service.dart';

/// App-wide stores, created once in [MoneyNavigationApp].
class AppScope extends InheritedWidget {
  AppScope({
    super.key,
    required this.trip,
    required this.settings,
    required this.rates,
    CashWalletStore? cashWallet,
    ReceiptStore? receipts,
    this.demoPersonas,
    this.demoRates,
    required super.child,
  }) : cashWallet = cashWallet ?? CashWalletStore(),
       receipts = receipts ?? ReceiptStore.shared;

  final TripStore trip;
  final SettingsStore settings;
  final RateService rates;
  final CashWalletStore cashWallet;

  /// Checked receipts, synced with the account like trip saves.
  final ReceiptStore receipts;

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
      cashWallet != oldWidget.cashWallet ||
      receipts != oldWidget.receipts ||
      demoPersonas != oldWidget.demoPersonas ||
      demoRates != oldWidget.demoRates;
}
