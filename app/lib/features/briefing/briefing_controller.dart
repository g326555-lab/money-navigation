import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../rules/day_cash.dart';
import '../../rules/demo_calendar.dart';
import '../../rules/facts_cache.dart';
import '../../rules/nearby_traps.dart';
import '../../rules/pay_facts.dart';
import '../../rules/personal_context.dart';
import '../../rules/trip_period.dart';
import '../../data/trip_period_store.dart';
import '../../services/ai/personal_memory.dart';
import '../assistant/card_profile_store.dart';
import 'calendar_source.dart';
import 'country_locator.dart';
import 'facts_repository.dart';
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
    FactsRepository? live,
    TripPeriodStore? trip,
    this._bundle,
  }) : calendar = calendar ?? CalendarSource(),
       trip = trip ?? TripPeriodStore(),
       places = places ?? PlacesClient(),
       location = location ?? PhoneLocation(),
       countries = countries ?? CountryLocator(),
       card = card ?? CardProfileStore(),
       live = live ?? FactsRepository() {
    this.live.addListener(notifyListeners);
    this.trip.addListener(notifyListeners);
  }

  /// One briefing for the whole app.
  static final instance = BriefingController();

  final CalendarSource calendar;
  final PlacesClient places;
  final PhoneLocation location;
  final CountryLocator countries;
  final CardProfileStore card;

  /// The trip dates the traveler entered.
  final TripPeriodStore trip;

  /// The day whose stops are shown; null follows [defaultTripDay].
  DateTime? _day;

  /// The trip in view: the demo traveler's in the demo state.
  TripPeriod? tripPeriod({bool demo = false}) =>
      demo ? _demoPeriod : trip.period;

  /// The day whose calendar stops are shown.
  DateTime dayShown({bool demo = false}) =>
      _day ?? defaultTripDay(tripPeriod(demo: demo), DateTime.now());

  /// Shows [day]'s stops (a day of the trip).
  Future<void> showDay(DateTime day) async {
    _day = DateTime(day.year, day.month, day.day);
    notifyListeners();
    await _loadEvents(force: true);
  }

  /// Saves the trip dates and shows the trip's current day.
  Future<void> setTripPeriod(TripPeriod? period) async {
    _day = null;
    await trip.set(period);
    await _loadEvents(force: true);
  }

  /// Facts the server re-checked today, laid over the bundled file.
  final FactsRepository live;
  final AssetBundle? _bundle;

  PayFacts? _facts;

  /// The bundled facts with today's checked values laid over them.
  PayFacts? get facts {
    final bundled = _facts;
    return bundled == null ? null : applyLiveFacts(bundled, live.facts);
  }

  /// The bundled file as shipped: the demo state's fixed facts.
  PayFacts? get bundledFacts => _facts;

  List<DayEvent> _events = const [];
  List<DayEvent> get events => _events;
  bool _eventsLoading = false;
  bool get eventsLoading => _eventsLoading;

  List<NearbyPlaceFact> _nearby = const [];
  NearbyState _nearbyState = NearbyState.idle;
  NearbyState get nearbyState => _nearbyState;

  /// Where the last real nearby search was made.
  ({double lat, double lng})? _nearbyOrigin;

  /// The phone's country from its location, when known.
  String? _country;
  String? get country => _country;

  DateTime? _loadedDay;
  bool _started = false;

  /// Loads the facts file and the card facts once, then refreshes.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await Future.wait([
      _loadFacts(),
      card.load(),
      trip.load(),
      calendar.checkAccess(),
    ]);
    unawaited(live.load());
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
    if (_demoActive) return;
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
    if (_demoActive) return;
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final last = _nearbyAt;
    await Future.wait([
      live.load(),
      if (_loadedDay != day) _loadEvents(),
      if (last == null || now.difference(last) >= resumeThrottle) _loadNearby(),
    ]);
  }

  /// Asks for calendar access; true when it was granted.
  Future<bool> connectCalendar() async {
    if (_demoActive) return false;
    final granted = await calendar.requestAccess();
    notifyListeners();
    if (granted) await _loadEvents();
    return granted;
  }

  Future<void> _loadEvents({bool force = false}) async {
    if (_demoActive) {
      if (force) notifyListeners();
      return;
    }
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
    final day = dayShown();
    final raw = await calendar.eventsOn(day);
    // A later choice of day replaced this read.
    if (day != dayShown()) return;
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
    if (_demoActive) return;
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
    _nearbyOrigin = (lat: position.latitude, lng: position.longitude);
    _country = results[1] as String? ?? _country;
    _nearbyState = NearbyState.done;
    notifyListeners();
  }

  // The demo state's own calendar and surroundings. The phone's real
  // calendar and location are never read for it.
  String? _demoKey;
  List<DayEvent> _demoEvents = const [];
  List<NearbyPlaceFact> _demoNearby = const [];
  TripPeriod? _demoPeriod;
  ({double lat, double lng})? _demoOrigin;
  String? _demoCountry;
  NearbyState _demoNearbyState = NearbyState.idle;
  NearbyState get demoNearbyState => _demoNearbyState;
  String? get demoKey => _demoKey;

  /// While true the phone's real calendar, location and country are never
  /// read. Screens set it on every build, before anything loads.
  bool _demoActive = false;
  bool get demoActive => _demoActive;

  void markDemo(bool on) {
    if (on == _demoActive) return;
    _demoActive = on;
    _day = null;
    // Back from the demo: load the real state once.
    if (!on) Future.microtask(refresh);
  }

  /// Bumped on every switch so a load that finished late is dropped.
  int _demoGeneration = 0;

  /// Switches the sample calendar to [personaKey]'s (null leaves the demo).
  /// The same pipeline as the real one: place lookup, then payment facts,
  /// then what is nearby the first stop.
  Future<void> useDemo(String? personaKey, {required String? currency}) async {
    if (personaKey == _demoKey) return;
    _demoKey = personaKey;
    final generation = ++_demoGeneration;
    bool stale() => generation != _demoGeneration;
    _demoEvents = const [];
    _demoNearby = const [];
    _demoPeriod = null;
    _day = null;
    _demoOrigin = null;
    _demoCountry = null;
    _demoNearbyState = NearbyState.idle;
    notifyListeners();
    if (personaKey == null) return;
    try {
      final text = await (_bundle ?? rootBundle).loadString(demoCalendarAsset);
      final raw =
          demoCalendarEvents(text, personaKey, DateTime.now()) ?? const [];
      if (stale()) return;
      _demoEvents = raw;
      _demoPeriod = demoTripPeriod(text, personaKey, DateTime.now());
      _demoNearbyState = NearbyState.loading;
      notifyListeners();
      // No real position: the lookup is not biased towards the phone.
      final looked = await Future.wait([
        for (final e in raw) places.lookup(e.location!),
      ]);
      if (stale()) return;
      _demoEvents = [
        for (final (i, e) in raw.indexed)
          looked[i] == null
              ? e
              : e.withPlace(looked[i]!.payment, looked[i]!.name),
      ];
      final first = looked.firstWhere(
        (p) => p?.lat != null && p?.lng != null,
        orElse: () => null,
      );
      if (first != null) {
        final nearby = await places.nearbyAt(first.lat!, first.lng!);
        if (stale()) return;
        _demoNearby = nearby;
        _demoOrigin = (lat: first.lat!, lng: first.lng!);
      }
      for (final c in _facts?.countries.values ?? const <CountryPayFacts>[]) {
        if (c.currency == currency) _demoCountry = c.country;
      }
    } on Object {
      // Whatever loaded stays; the rest is simply not shown.
    } finally {
      if (!stale()) {
        _demoNearbyState = NearbyState.done;
        notifyListeners();
      }
    }
  }

  /// The cash plan for today from [history] (the ledger in view). A demo
  /// state is a prepared traveler somewhere else, so the phone's real
  /// calendar is left out of it.
  DayCashPlan? cashPlan(List<PastPurchase> history, {bool demo = false}) =>
      dayCash(
        history: history,
        // The sample calendar only has today's events.
        events: demo
            ? (_isToday(dayShown(demo: true)) ? _demoEvents : const [])
            : _events,
        now: DateTime.now(),
      );

  static bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day == DateTime(now.year, now.month, now.day);
  }

  /// What the last nearby search found: around the phone, or around the
  /// demo traveler's first stop in the demo state.
  List<NearbyPlaceFact> nearbyPlaces({bool demo = false}) =>
      demo ? _demoNearby : _nearby;

  /// Where that search was made; null before one has finished.
  ({double lat, double lng})? nearbyOrigin({bool demo = false}) =>
      demo ? _demoOrigin : _nearbyOrigin;

  NearbyState nearbyStateFor({bool demo = false}) =>
      demo ? _demoNearbyState : _nearbyState;

  /// Warnings around the phone for the country it is in. ATM warnings are
  /// about foreign cards, so they are left out where the traveler's own
  /// currency is the local one.
  List<TrapWarning> traps({
    required String? countryCode,
    required String homeCurrency,
    bool demo = false,
    int limit = 3,
  }) {
    if (demo) {
      // A demo traveler is where the sample calendar is, not where the phone is.
      final sample = _demoCountry == null
          ? null
          : bundledFacts?.country(_demoCountry!);
      final foreign = sample != null && sample.currency != homeCurrency;
      return nearbyTraps(_demoNearby, foreign ? sample : null, limit: limit);
    }
    final facts = countryCode == null ? null : this.facts?.country(countryCode);
    final foreign = facts != null && facts.currency != homeCurrency;
    return nearbyTraps(_nearby, foreign ? facts : null, limit: limit);
  }
}
