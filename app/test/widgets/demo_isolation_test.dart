import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:money_navigation/features/assistant/card_profile_store.dart';
import 'package:money_navigation/features/briefing/briefing_controller.dart';
import 'package:money_navigation/features/briefing/calendar_source.dart';
import 'package:money_navigation/features/briefing/country_locator.dart';
import 'package:money_navigation/features/briefing/phone_location.dart';
import 'package:money_navigation/features/briefing/places_client.dart';
import 'package:money_navigation/rules/day_cash.dart';
import 'package:money_navigation/rules/demo_calendar.dart';
import 'package:money_navigation/rules/nearby_traps.dart';
import 'package:money_navigation/rules/pay_facts.dart';
import 'package:money_navigation/rules/pay_route.dart';

import 'harness.dart';

/// Counts every read of the phone's real calendar, position and country.
class CountingCalendar extends CalendarSource {
  CountingCalendar() {
    access = CalendarAccess.granted;
  }
  int reads = 0;

  @override
  Future<void> checkAccess() async => access = CalendarAccess.granted;

  @override
  Future<List<DayEvent>> eventsOn(DateTime day) async {
    reads++;
    return [DayEvent(title: 'Real', location: 'Real place', start: day)];
  }
}

class CountingLocation extends PhoneLocation {
  int reads = 0;

  @override
  Future<Position?> read({bool ask = false}) async {
    reads++;
    return null;
  }
}

class CountingCountry extends CountryLocator {
  int reads = 0;

  @override
  Future<String?> countryAt(Position position) async {
    reads++;
    return 'JP';
  }
}

class QuietPlaces extends PlacesClient {
  final lookups = <String>[];
  var usedNear = false;

  @override
  Future<LookedUpPlace?> lookup(String location, {Position? near}) async {
    lookups.add(location);
    if (near != null) usedNear = true;
    return LookedUpPlace(
      name: location,
      payment: PlacePayment.unknown,
      lat: 35.6,
      lng: 139.7,
    );
  }

  @override
  Future<List<NearbyPlaceFact>> nearbyAt(
    double lat,
    double lng,
  ) async => const [
    NearbyPlaceFact(name: 'Seven Bank ATM', kind: PlaceKind.atm, distanceM: 90),
  ];
}

void main() {
  setUp(resetPreferences);
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await rootBundle.loadString(payFactsAsset);
    await rootBundle.loadString(demoCalendarAsset);
  });

  Future<
    ({
      BriefingController c,
      CountingCalendar cal,
      CountingLocation loc,
      CountingCountry country,
      QuietPlaces places,
    })
  >
  make() async {
    final cal = CountingCalendar();
    final loc = CountingLocation();
    final country = CountingCountry();
    final places = QuietPlaces();
    final c = BriefingController(
      calendar: cal,
      location: loc,
      countries: country,
      places: places,
      card: CardProfileStore(),
    );
    return (c: c, cal: cal, loc: loc, country: country, places: places);
  }

  test('in a demo state nothing real is read, however it is asked', () async {
    final m = await make();
    m.c.markDemo(true);
    await m.c.start();
    await m.c.refresh(askLocation: true);
    await m.c.refreshIfStale();
    await m.c.connectCalendar();
    await m.c.useDemo('thaiTokyo', currency: 'JPY');
    expect(m.cal.reads, 0);
    expect(m.loc.reads, 0);
    expect(m.country.reads, 0);
    expect(m.places.usedNear, isFalse);
    expect(m.places.lookups, isNotEmpty);
  });

  test(
    'the sample calendar feeds the cash plan and the nearby warnings',
    () async {
      final m = await make();
      m.c.markDemo(true);
      await m.c.start();
      await m.c.useDemo('thaiTokyo', currency: 'JPY');
      final plan = m.c.cashPlan(const [], demo: true);
      expect(plan, isNotNull);
      expect(plan!.stops, hasLength(3));
      final traps = m.c.traps(
        countryCode: null,
        homeCurrency: 'THB',
        demo: true,
      );
      expect(traps.map((t) => t.kind), isNotEmpty);
    },
  );

  test('leaving the demo loads the real state once', () async {
    final m = await make();
    m.c.markDemo(true);
    await m.c.start();
    await m.c.useDemo('visitorBangkok', currency: 'THB');
    expect(m.cal.reads, 0);
    m.c.markDemo(false);
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(m.cal.reads, greaterThan(0));
  });

  test(
    'a persona switched away mid-load does not overwrite the new one',
    () async {
      final m = await make();
      m.c.markDemo(true);
      await m.c.start();
      final first = m.c.useDemo('visitorBangkok', currency: 'THB');
      final second = m.c.useDemo('thaiTokyo', currency: 'JPY');
      await Future.wait([first, second]);
      expect(m.c.demoKey, 'thaiTokyo');
      final stops = m.c.cashPlan(const [], demo: true)!.stops;
      expect(
        stops.map((s) => s.event.location),
        contains('Tsukiji Outer Market'),
      );
      expect(
        stops.map((s) => s.event.location),
        isNot(contains('Terminal 21 Asok')),
      );
    },
  );
}
