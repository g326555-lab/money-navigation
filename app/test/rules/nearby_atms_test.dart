import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/nearby_atms.dart';
import 'package:money_navigation/rules/nearby_traps.dart';

NearbyPlaceFact atm(String name, double? d, {double? lat, double? lng}) =>
    NearbyPlaceFact(
      name: name,
      kind: PlaceKind.atm,
      distanceM: d,
      lat: lat,
      lng: lng,
    );

void main() {
  group('nearbyAtms', () {
    test('nearest first, places without a position left out', () {
      final found = nearbyAtms([
        atm('Far', 900, lat: 13.74, lng: 100.55),
        atm('No position', 50),
        atm('Near', 120, lat: 13.73, lng: 100.54),
        const NearbyPlaceFact(
          name: 'Market',
          kind: PlaceKind.market,
          distanceM: 10,
          lat: 13.7,
          lng: 100.5,
        ),
      ]);
      expect(found.map((a) => a.name), ['Near', 'Far']);
      expect(found.first.distanceM, 120);
    });

    test('unknown distance goes last; ties keep Google order', () {
      final found = nearbyAtms([
        atm('Unknown', null, lat: 13.70, lng: 100.50),
        atm('B', 200, lat: 13.71, lng: 100.51),
        atm('A', 200, lat: 13.72, lng: 100.52),
      ]);
      expect(found.map((a) => a.name), ['B', 'A', 'Unknown']);
    });

    test('the same machine listed twice appears once', () {
      final found = nearbyAtms([
        atm('Kbank', 100, lat: 13.7, lng: 100.5),
        atm('Kbank', 100, lat: 13.7, lng: 100.5),
      ]);
      expect(found, hasLength(1));
    });

    test('a (0, 0) fix and out-of-range values are not positions', () {
      expect(isMapPosition(0, 0), isFalse);
      expect(isMapPosition(91, 10), isFalse);
      expect(isMapPosition(10, 181), isFalse);
      expect(isMapPosition(double.nan, 10), isFalse);
      expect(isMapPosition(13.7, 100.5), isTrue);
      expect(nearbyAtms([atm('Zero', 5, lat: 0, lng: 0)]), isEmpty);
    });

    test('limit caps the list and a negative limit is empty', () {
      final many = [
        for (var i = 0; i < 5; i++)
          atm('ATM $i', i * 10.0, lat: 13 + i / 100, lng: 100),
      ];
      expect(nearbyAtms(many, limit: 2), hasLength(2));
      expect(nearbyAtms(many, limit: -1), isEmpty);
    });
  });

  test('trapsAt keeps only ATM warnings for this machine', () {
    const a = NearbyAtm(name: 'Kbank', lat: 13.7, lng: 100.5, distanceM: 90);
    const traps = [
      TrapWarning(
        kind: TrapKind.atmConversion,
        placeName: 'Kbank',
        distanceM: 90,
        source: 'Guide',
      ),
      TrapWarning(
        kind: TrapKind.cashOnlyMarket,
        placeName: 'Kbank',
        distanceM: 90,
        source: googleMapsSource,
      ),
      TrapWarning(
        kind: TrapKind.atmConversion,
        placeName: 'Other',
        distanceM: 300,
        source: 'Guide',
      ),
    ];
    expect(trapsAt(a, traps).single.kind, TrapKind.atmConversion);
  });
}
