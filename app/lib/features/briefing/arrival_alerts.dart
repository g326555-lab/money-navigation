import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../rules/arrival_alert.dart';
import '../../rules/pay_facts.dart';

/// The words of one arrival alert, in the app's language.
typedef ArrivalWords = ({String title, String body, String channel});

/// Shows the arrival warning as a local notification, once per country the
/// phone arrives in. The demo trigger shows the same notification for a
/// prepared country and leaves the stored arrival alone.
class ArrivalAlerts extends ChangeNotifier {
  ArrivalAlerts({
    FlutterLocalNotificationsPlugin? plugin,
    SharedPreferencesAsync? prefs,
  }) : _plugin = plugin ?? FlutterLocalNotificationsPlugin(),
       _prefs = prefs ?? SharedPreferencesAsync();

  static final instance = ArrivalAlerts();

  static const _lastKey = 'assist.lastArrivalCountry';
  static const _channelId = 'arrival';
  static const _notificationId = 7001;

  final FlutterLocalNotificationsPlugin _plugin;
  final SharedPreferencesAsync _prefs;
  bool _ready = false;

  /// Null until asked; false when the system refused notifications.
  bool? permitted;

  /// The last alert shown, real or demo, for the in-app card.
  ArrivalAlert? lastShown;
  bool lastWasDemo = false;

  Future<void> _init() async {
    if (_ready) return;
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    _ready = true;
  }

  /// Asks for permission to notify (Android 13+, iOS).
  Future<bool> requestPermission() async {
    try {
      await _init();
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      permitted =
          await android?.requestNotificationsPermission() ??
          await ios?.requestPermissions(alert: true, sound: true) ??
          false;
    } on Object {
      permitted = false;
    }
    notifyListeners();
    return permitted!;
  }

  /// Alerts when the phone has arrived in a new country (real location).
  Future<ArrivalAlert?> checkArrival({
    required String homeCurrency,
    required String? country,
    required PayFacts facts,
    required ArrivalWords Function(ArrivalAlert) words,
  }) async {
    String? last;
    try {
      last = await _prefs.getString(_lastKey);
    } on Object {
      last = null;
    }
    final alert = arrivalAlert(
      homeCurrency: homeCurrency,
      currentCountry: country,
      lastAlertedCountry: last,
      facts: facts,
    );
    if (alert == null) {
      // Back home: the next trip abroad alerts again.
      if (country != null &&
          facts.currencyOf(country) == homeCurrency.toUpperCase()) {
        await _forget();
      }
      return null;
    }
    await _show(alert, words(alert), demo: false);
    try {
      await _prefs.setString(_lastKey, alert.country);
    } on Object {
      // Shown once this session; may show again on the next launch.
    }
    return alert;
  }

  /// Demo state only: the alert for arriving in [country], on request.
  Future<ArrivalAlert?> demoArrival({
    required String homeCurrency,
    required String country,
    required PayFacts facts,
    required ArrivalWords Function(ArrivalAlert) words,
  }) async {
    final alert = arrivalAlert(
      homeCurrency: homeCurrency,
      currentCountry: country,
      lastAlertedCountry: null,
      facts: facts,
    );
    if (alert == null) return null;
    await _show(alert, words(alert), demo: true);
    return alert;
  }

  Future<void> _show(
    ArrivalAlert alert,
    ArrivalWords words, {
    required bool demo,
  }) async {
    lastShown = alert;
    lastWasDemo = demo;
    notifyListeners();
    try {
      await _init();
      await _plugin.show(
        id: _notificationId,
        title: words.title,
        body: words.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            words.channel,
            importance: Importance.high,
            priority: Priority.high,
            styleInformation: BigTextStyleInformation(words.body),
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBanner: true,
            presentSound: true,
          ),
        ),
      );
    } on Object {
      // The in-app card still shows [lastShown].
    }
  }

  Future<void> _forget() async {
    try {
      await _prefs.remove(_lastKey);
    } on Object {
      // Nothing stored.
    }
  }
}
