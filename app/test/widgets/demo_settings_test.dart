import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/data/settings_store.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'harness.dart';

Map<String, Object?> persona(
  String key,
  String language,
  String home,
  String local,
) => {
  'key': key,
  'language': language,
  'homeCurrency': home,
  'localCurrency': local,
  'samples': [
    {'kind': 'terminalDcc', 'daysAgo': 1, 'time': '18:05', 'keptThb': 86.4},
  ],
};

final personas = parseDemoPersonas(
  jsonEncode({
    'personas': [
      persona('visitorBangkok', 'en', 'USD', 'THB'),
      persona('thaiTokyo', 'th', 'THB', 'JPY'),
    ],
  }),
)!;

final visitor = personas.byKey('visitorBangkok')!;
final thai = personas.byKey('thaiTokyo')!;

const personaPref = 'demo_persona_v1';
const currencyPref = 'home_currency_v1';

void main() {
  setUp(resetPreferences);

  Future<SettingsStore> loaded({DemoPersonas? with_}) async {
    final s = SettingsStore();
    await s.load(personas: with_);
    return s;
  }

  test('no demo by default', () async {
    final s = await loaded(with_: personas);
    expect(s.demoPersona, isNull);
    expect(s.demoState, isFalse);
  });

  test('setDemoPersona turns demo on, persists the key, notifies', () async {
    final s = await loaded(with_: personas);
    var notified = 0;
    s.addListener(() => notified++);
    await s.setDemoPersona(visitor);
    expect(s.demoPersona!.key, 'visitorBangkok');
    expect(s.demoState, isTrue);
    expect(notified, greaterThanOrEqualTo(1));
    expect(
      await SharedPreferencesAsync().getString(personaPref),
      'visitorBangkok',
    );

    await s.setDemoPersona(thai);
    expect(s.demoPersona!.key, 'thaiTokyo');
    expect(await SharedPreferencesAsync().getString(personaPref), 'thaiTokyo');
  });

  test('setDemoPersona(null) turns demo off and removes the key', () async {
    final s = await loaded(with_: personas);
    await s.setDemoPersona(visitor);
    await s.setDemoPersona(null);
    expect(s.demoPersona, isNull);
    expect(s.demoState, isFalse);
    expect(await SharedPreferencesAsync().getString(personaPref), isNull);

    final fresh = await loaded(with_: personas);
    expect(fresh.demoPersona, isNull);
  });

  test('load(personas:) restores the stored persona', () async {
    final s = await loaded(with_: personas);
    await s.setDemoPersona(thai);

    final fresh = await loaded(with_: personas);
    expect(fresh.demoPersona!.key, 'thaiTokyo');
    expect(fresh.demoState, isTrue);
    expect(fresh.homeCurrency, 'THB');
  });

  test('load without personas does not restore a demo', () async {
    await SharedPreferencesAsync().setString(personaPref, 'thaiTokyo');
    final s = await loaded();
    expect(s.demoPersona, isNull);
    expect(s.demoState, isFalse);
  });

  test('unknown stored key gives no demo', () async {
    await SharedPreferencesAsync().setString(personaPref, 'marsColony');
    await SharedPreferencesAsync().setString(currencyPref, 'KRW');
    final s = await loaded(with_: personas);
    expect(s.demoPersona, isNull);
    expect(s.demoState, isFalse);
    expect(s.homeCurrency, 'KRW');
  });

  test(
    'demo overrides homeCurrency; own choice returns after demo off',
    () async {
      final s = await loaded(with_: personas);
      await s.setHomeCurrency('KRW');

      await s.setDemoPersona(visitor);
      expect(s.homeCurrency, 'USD');
      await s.setDemoPersona(thai);
      expect(s.homeCurrency, 'THB');

      await s.setDemoPersona(null);
      expect(s.homeCurrency, 'KRW');
      expect(s.currencyChosen, isTrue);
      expect(await SharedPreferencesAsync().getString(currencyPref), 'KRW');
    },
  );

  test(
    'restored demo overrides the stored own currency, which survives',
    () async {
      final s = await loaded(with_: personas);
      await s.setHomeCurrency('KRW');
      await s.setDemoPersona(visitor);

      final fresh = await loaded(with_: personas);
      expect(fresh.homeCurrency, 'USD');
      await fresh.setDemoPersona(null);
      expect(fresh.homeCurrency, 'KRW');
    },
  );

  test('setHomeCurrency during demo stores the own choice', () async {
    final s = await loaded(with_: personas);
    await s.setHomeCurrency('KRW');
    await s.setDemoPersona(visitor);

    await s.setHomeCurrency('JPY');
    expect(s.homeCurrency, 'USD');
    expect(s.currencyChosen, isTrue);
    expect(await SharedPreferencesAsync().getString(currencyPref), 'JPY');

    await s.setDemoPersona(null);
    expect(s.homeCurrency, 'JPY');

    final fresh = await loaded(with_: personas);
    expect(fresh.homeCurrency, 'JPY');
  });
}
