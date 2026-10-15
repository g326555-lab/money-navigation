import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../rules/day_cash.dart';
import '../../rules/nearby_traps.dart';
import '../../rules/pay_facts.dart';
import '../../rules/personal_context.dart';
import '../../services/ai/personal_memory.dart';
import '../assistant/card_profile_store.dart';
import 'calendar_source.dart';
import 'country_locator.dart';
import 'phone_location.dart';
import 'places_client.dart';

/// Where the briefing's place facts stand.
enum NearbyState { idle, loading, noLocation, done }

/// Gathers the morning briefing: today's calendar stops with Google Maps
/// payment facts, the cash estimate from the traveler's own records, and
/// traps near the phone. Everything is evaluated by lib/rules; this class
/// only fetches and caches.
class BriefingController extends ChangeNotifier {
  BriefingController({
    CalendarSource? calendar,
    PlacesClient? places,
    PhoneLocation? location,
    CountryLocator? countries,
    CardProfileStore? card,
    this._bundle,
  }) : calendar = calendar ?? CalendarSource(),
       places = places ?? PlacesClient(),
       location = location ?? PhoneLocation(),
       countries = countries ?? CountryLocator(),
       card = card ?? CardProfileStore();

  /// One briefing for the whole app.
  static final instance = BriefingController();

  final CalendarSource calendar;
  final PlacesClient places;
  final PhoneLocation location;
  final CountryLocator countries;
  final CardProfileStore card;
  final AssetBundle? _bundle;

  PayFacts? _facts;
  PayFacts? get facts => _facts;

  List<DayEvent> _events = const [];
  List<DayEvent> get events => _events;
  bool _eventsLoading = false;
  bool get eventsLoading => _eventsLoading;

  List<NearbyPlaceFact> _nearby = const [];
  NearbyState _nearbyState = NearbyState.idle;
  NearbyState get nearbyState => _nearbyState;

  /// The phone's country from its location, when known.
  String? _country;
  String? get country => _country;

  DateTime? _loadedDay;
  bool _started = false;

  /// Loads the facts file and the card facts once, then refreshes.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await Future.wait([_loadFacts(), card.load(), calendar.checkAccess()]);
    notifyListeners();
    unawaited(_loadAccountCard());
    await refresh();
  }

  /// The signed-in account's card facts, used where none were typed here.
  Future<void> _loadAccountCard() async {
    try {
      final memory = PersonalMemory();
      if (await memory.load()) card.useAccount(memory.profile);
    } on Object {
      // Signed out or accounts not configured: typed-in facts only.
    }
  }

  Future<void> _loadFacts() async {
    try {
      final text = await (_bundle ?? rootBundle).loadString(payFactsAsset);
      _facts = PayFacts.parse(text);
    } on Object {
      _facts = null;
    }
  }

  /// Re-reads today's events and the nearby places. Called on start and on
  /// pull to refresh; retries the facts file if it failed to load.
  Future<void> refresh({bool askLocation = false}) async {
    if (_facts == null) await _loadFacts();
    await Future.wait([_loadEvents(), _loadNearby(ask: askLocation)]);
  }

  /// Least time between two location reads when the app comes back.
  static const resumeThrottle = Duration(minutes: 2);
  DateTime? _nearbyAt;

  /// On coming back to the front: the location and country every time
  /// (throttled), so a landing is noticed the same day; the calendar only
  /// on a new day.
  Future<void> refreshIfStale() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final last = _nearbyAt;
    await Future.wait([
      if (_loadedDay != day) _loadEvents(),
      if (last == null || now.difference(last) >= resumeThrottle) _loadNearby(),
    ]);
  }

  Future<void> connectCalendar() async {
    final granted = await calendar.requestAccess();
    notifyListeners();
    if (granted) await _loadEvents();
  }

  Future<void> _loadEvents() async {
    final today = DateTime.now();
    _loadedDay = DateTime(today.year, today.month, today.day);
    if (calendar.access != CalendarAccess.granted) {
      _events = const [];
      notifyListeners();
      return;
    }
    _eventsLoading = true;
    notifyListeners();
    final now = DateTime.now();
    final raw = await calendar.eventsOn(now);
    _loadedDay = DateTime(now.year, now.month, now.day);
    // Show the stops at once, then add what Google Maps knows per place.
    _events = raw;
    notifyListeners();
    final near = location.position;
    final matched = await Future.wait([
      for (final e in raw)
        if (e.location == null || e.location!.trim().isEmpty)
          Future.value(e)
        else
          places
              .lookup(e.location!, near: near)
              .then((p) => p == null ? e : e.withPlace(p.payment, p.name)),
    ]);
    _events = matched;
    _eventsLoading = false;
    notifyListeners();
  }

  Future<void> _loadNearby({bool ask = false}) async {
    _nearbyAt = DateTime.now();
    // Keep showing what was found while it refreshes.
    if (_nearbyState != NearbyState.done) {
      _nearbyState = NearbyState.loading;
      notifyListeners();
    }
    final position = await location.read(ask: ask);
    if (position == null) {
      _nearbyState = NearbyState.noLocation;
      notifyListeners();
      return;
    }
    final results = await Future.wait([
      places.nearby(position),
      countries.countryAt(position),
    ]);
    _nearby = results[0] as List<NearbyPlaceFact>;
    _country = results[1] as String? ?? _country;
    _nearbyState = NearbyState.done;
    notifyListeners();
  }

  /// The cash plan for today from [history] (the ledger in view). A demo
  /// state is a prepared traveler somewhere else, so the phone's real
  /// calendar is left out of it.
  DayCashPlan? cashPlan(List<PastPurchase> history, {bool demo = false}) =>
      dayCash(
        history: history,
        events: demo ? const [] : _events,
        now: DateTime.now(),
      );

  /// Warnings around the phone for the country it is in. ATM warnings are
  /// about foreign cards, so they are left out where the traveler's own
  /// currency is the local one.
  List<TrapWarning> traps({
    required String? countryCode,
    required String homeCurrency,
    bool demo = false,
    int limit = 3,
  }) {
    // The phone's real surroundings do not belong to a demo traveler.
    if (demo) return const [];
    final facts = countryCode == null ? null : _facts?.country(countryCode);
    final foreign = facts != null && facts.currency != homeCurrency;
    return nearbyTraps(_nearby, foreign ? facts : null, limit: limit);
  }
}
