import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../rules/demo_personas.dart';

/// How a spoken Thai request ends. Thai speakers soften requests with a
/// particle that depends on the speaker.
enum PoliteEnding { male, female, none }

/// The traveler's own choices, kept on the device.
class SettingsStore extends ChangeNotifier {
  SettingsStore({SharedPreferencesAsync? prefs})
    : _prefs = prefs ?? SharedPreferencesAsync();

  static const _currencyKey = 'home_currency_v1';
  static const _endingKey = 'polite_ending_v1';
  static const _demoKey = 'demo_persona_v1';

  final SharedPreferencesAsync _prefs;

  String _homeCurrency = deviceCurrency();
  PoliteEnding _ending = PoliteEnding.male;
  bool _currencyChosen = false;

  /// ISO 4217 code of the currency the traveler thinks in: the demo
  /// persona's while the demo state is on, otherwise the traveler's own.
  String get homeCurrency => _demoPersona?.homeCurrency ?? _homeCurrency;

  /// False while [homeCurrency] is only the guess from the phone's region.
  bool get currencyChosen => _currencyChosen;
  PoliteEnding get politeEnding => _ending;

  /// The demo state: one of the two prepared travelers from
  /// assets/data/demo_personas.json, with fixed exchange rates from
  /// assets/data/demo_rates.json so results never change on stage. Null in
  /// normal use.
  DemoPersona? get demoPersona => _demoPersona;
  DemoPersona? _demoPersona;
  bool get demoState => _demoPersona != null;

  Future<void> setDemoPersona(DemoPersona? persona) async {
    _demoPersona = persona;
    notifyListeners();
    if (persona == null) {
      await _prefs.remove(_demoKey);
    } else {
      await _prefs.setString(_demoKey, persona.key);
    }
  }

  /// [personas] lets a demo state chosen before the app closed come back.
  Future<void> load({DemoPersonas? personas}) async {
    final currency = await _prefs.getString(_currencyKey);
    if (currency != null && currency.length == 3) {
      _homeCurrency = currency;
      _currencyChosen = true;
    }
    final ending = PoliteEnding.values
        .asNameMap()[await _prefs.getString(_endingKey)];
    if (ending != null) _ending = ending;
    final demo = await _prefs.getString(_demoKey);
    _demoPersona = demo == null ? null : personas?.byKey(demo);
    notifyListeners();
  }

  Future<void> setHomeCurrency(String code) async {
    _homeCurrency = code;
    _currencyChosen = true;
    notifyListeners();
    await _prefs.setString(_currencyKey, code);
  }

  Future<void> setPoliteEnding(PoliteEnding ending) async {
    _ending = ending;
    notifyListeners();
    await _prefs.setString(_endingKey, ending.name);
  }

  /// The currency of the phone's region, from the locale data in intl
  /// (a Korean phone gives KRW, a US phone USD).
  static String deviceCurrency() {
    final locale = PlatformDispatcher.instance.locale;
    final tag = locale.countryCode == null
        ? locale.languageCode
        : '${locale.languageCode}_${locale.countryCode}';
    try {
      return NumberFormat.simpleCurrency(locale: tag).currencyName ?? 'USD';
    } on ArgumentError {
      return NumberFormat.simpleCurrency(locale: 'en_US').currencyName!;
    }
  }
}
