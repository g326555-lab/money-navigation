import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:money_navigation/rules/trip_map.dart';

// Real Bangkok places the demo walks through.
const chatuchak = (lat: 13.7999, lng: 100.5500);
const sukhumvit11 = (lat: 13.7445, lng: 100.5560);
const siam = (lat: 13.7456, lng: 100.5341);

// Two local days, with records one minute either side of midnight.
final day1 = DateTime(2026, 10, 15);
final day2 = DateTime(2026, 10, 16);

final noodles = ReceiptRecord(
  id: 'r-noodles',
  savedAt: DateTime(2026, 10, 15, 13, 20),
  totalThb: 450,
  verified: true,
  merchantName: 'Chatuchak Boat Noodles',
  placeName: 'Chatuchak Weekend Market',
  lat: chatuchak.lat,
  lng: chatuchak.lng,
  serviceThb: 0,
);

final lateDinner = ReceiptRecord(
  id: 'r-late-dinner',
  savedAt: DateTime(2026, 10, 15, 23, 59),
  totalThb: 1284,
  verified: false,
  userCorrected: true,
  placeName: 'Siam Square',
  lat: siam.lat,
  lng: siam.lng,
  serviceThb: 100,
  servicePercent: 10,
);

final noLocation = ReceiptRecord(
  id: 'r-no-location',
  savedAt: DateTime(2026, 10, 15, 12),
  totalThb: 90,
  verified: true,
  merchantName: '7-Eleven',
);

final nullIsland = ReceiptRecord(
  id: 'r-null-island',
  savedAt: DateTime(2026, 10, 15, 15),
  totalThb: 60,
  verified: true,
  lat: 0,
  lng: 0,
);

final latOnly = ReceiptRecord(
  id: 'r-lat-only',
  savedAt: DateTime(2026, 10, 15, 16),
  totalThb: 70,
  verified: true,
  lat: siam.lat,
);

final outOfRange = ReceiptRecord(
  id: 'r-out-of-range',
  savedAt: DateTime(2026, 10, 15, 17),
  totalThb: 80,
  verified: true,
  lat: 113.7456,
  lng: 100.5341,
);

final mangoHaggle = TripSave(
  id: 's-mango',
  kind: SaveKind.haggle,
  keptThb: 150,
  savedAt: DateTime(2026, 10, 16, 0, 1),
  itemKey: 'mango',
  askedThb: 400,
  paidThb: 250,
  placeName: 'Chatuchak Weekend Market',
  placeLat: chatuchak.lat,
  placeLng: chatuchak.lng,
);

final atmSave = TripSave(
  id: 's-atm',
  kind: SaveKind.atmConversion,
  keptThb: 232.06,
  savedAt: DateTime(2026, 10, 16, 10, 30),
  placeName: 'Sukhumvit Soi 11',
  placeLat: sukhumvit11.lat,
  placeLng: sukhumvit11.lng,
);

final sampleTerminal = TripSave(
  id: 's-terminal-sample',
  kind: SaveKind.terminalDcc,
  keptThb: 180,
  savedAt: DateTime(2026, 10, 16, 18),
  placeName: 'Siam Paragon',
  placeLat: siam.lat,
  placeLng: siam.lng,
  isSample: true,
);

final atmNoPlace = TripSave(
  id: 's-atm-no-place',
  kind: SaveKind.atmConversion,
  keptThb: 99,
  savedAt: DateTime(2026, 10, 16, 11),
);

final allReceipts = [
  noodles,
  lateDinner,
  noLocation,
  nullIsland,
  latOnly,
  outOfRange,
];
final allSaves = [mangoHaggle, atmSave, sampleTerminal, atmNoPlace];

List<MapPin> allPins() => pinsFrom(receipts: allReceipts, saves: allSaves);

MapPin pinById(List<MapPin> pins, String id) =>
    pins.singleWhere((p) => p.id == id);

void main() {
  group('pinsFrom keeps only records with a usable location', () {
    test('five located records become five pins', () {
      final ids = allPins().map((p) => p.id).toSet();
      expect(ids, {
        'r-noodles',
        'r-late-dinner',
        's-mango',
        's-atm',
        's-terminal-sample',
      });
    });

    test('a receipt without lat and lng is skipped', () {
      expect(pinsFrom(receipts: [noLocation], saves: const []), isEmpty);
    });

    test('a receipt with only lat is skipped', () {
      expect(pinsFrom(receipts: [latOnly], saves: const []), isEmpty);
    });

    test('(0, 0) is treated as missing, not as the Gulf of Guinea', () {
      expect(pinsFrom(receipts: [nullIsland], saves: const []), isEmpty);
    });

    test('a latitude outside -90..90 is skipped', () {
      expect(pinsFrom(receipts: [outOfRange], saves: const []), isEmpty);
    });

    test('a longitude outside -180..180 is skipped', () {
      final badLng = ReceiptRecord(
        id: 'r-bad-lng',
        savedAt: DateTime(2026, 10, 15, 18),
        totalThb: 50,
        verified: true,
        lat: siam.lat,
        lng: 200.5341,
      );
      expect(pinsFrom(receipts: [badLng], saves: const []), isEmpty);
    });

    test('the edges of the valid range are kept', () {
      final edge = ReceiptRecord(
        id: 'r-edge',
        savedAt: DateTime(2026, 10, 15, 18),
        totalThb: 50,
        verified: true,
        lat: -90,
        lng: 180,
      );
      expect(pinsFrom(receipts: [edge], saves: const []), hasLength(1));
    });

    test('a trip save without a place is skipped', () {
      expect(pinsFrom(receipts: const [], saves: [atmNoPlace]), isEmpty);
    });

    test('no records give no pins', () {
      expect(pinsFrom(receipts: const [], saves: const []), isEmpty);
    });
  });

  group('pinsFrom carries each record faithfully', () {
    test('a verified receipt: kind, place, time, total, title', () {
      final pin = pinById(allPins(), 'r-noodles');
      expect(pin.kind, PinKind.receipt);
      expect(pin.lat, chatuchak.lat);
      expect(pin.lng, chatuchak.lng);
      expect(pin.at, DateTime(2026, 10, 15, 13, 20));
      expect(pin.title, 'Chatuchak Boat Noodles');
      expect(pin.amountThb, 450);
      expect(pin.keptThb, isNull);
      expect(pin.verified, isTrue);
      expect(pin.isSample, isFalse);
    });

    test('a corrected receipt stays unverified and falls back to the place '
        'name', () {
      final pin = pinById(allPins(), 'r-late-dinner');
      expect(pin.kind, PinKind.receipt);
      expect(pin.verified, isFalse);
      expect(pin.title, 'Siam Square');
      expect(pin.amountThb, 1284);
      expect(pin.keptThb, isNull);
    });

    test('a receipt with neither merchant nor place has no title', () {
      final bare = ReceiptRecord(
        id: 'r-bare',
        savedAt: DateTime(2026, 10, 15, 9),
        totalThb: 40,
        verified: true,
        lat: siam.lat,
        lng: siam.lng,
      );
      final pin = pinsFrom(receipts: [bare], saves: const []).single;
      expect(pin.title, isNull);
    });

    test('a haggle: paid amount, kept amount, market name', () {
      final pin = pinById(allPins(), 's-mango');
      expect(pin.kind, PinKind.haggle);
      expect(pin.lat, chatuchak.lat);
      expect(pin.lng, chatuchak.lng);
      expect(pin.at, DateTime(2026, 10, 16, 0, 1));
      expect(pin.title, 'Chatuchak Weekend Market');
      expect(pin.amountThb, 250);
      expect(pin.keptThb, 150);
      expect(pin.verified, isTrue);
      expect(pin.isSample, isFalse);
    });

    test('an ATM save has no amount, only what was kept', () {
      final pin = pinById(allPins(), 's-atm');
      expect(pin.kind, PinKind.atm);
      expect(pin.lat, sukhumvit11.lat);
      expect(pin.lng, sukhumvit11.lng);
      expect(pin.amountThb, isNull);
      expect(pin.keptThb, 232.06);
      expect(pin.verified, isTrue);
    });

    test('a terminal save keeps its sample flag', () {
      final pin = pinById(allPins(), 's-terminal-sample');
      expect(pin.kind, PinKind.terminal);
      expect(pin.amountThb, isNull);
      expect(pin.keptThb, 180);
      expect(pin.isSample, isTrue);
    });

    test('a sample receipt is marked as a sample', () {
      final sample = ReceiptRecord(
        id: 'r-sample',
        savedAt: DateTime(2026, 10, 15, 10),
        totalThb: 320,
        verified: true,
        merchantName: 'Sample Cafe',
        lat: sukhumvit11.lat,
        lng: sukhumvit11.lng,
        isSample: true,
      );
      final pin = pinsFrom(receipts: [sample], saves: const []).single;
      expect(pin.isSample, isTrue);
    });
  });

  group('TripSave place coordinates survive JSON', () {
    test('placeLat and placeLng are written under their own keys', () {
      final json = mangoHaggle.toJson();
      expect(json['placeLat'], chatuchak.lat);
      expect(json['placeLng'], chatuchak.lng);
    });

    test('a save without a place writes neither key', () {
      final json = atmNoPlace.toJson();
      expect(json.containsKey('placeLat'), isFalse);
      expect(json.containsKey('placeLng'), isFalse);
    });

    test('round trip keeps the coordinates', () {
      final back = TripSave.fromJson(mangoHaggle.toJson())!;
      expect(back.placeLat, chatuchak.lat);
      expect(back.placeLng, chatuchak.lng);
    });

    test('an older save without the keys still loads, with no place', () {
      final json = mangoHaggle.toJson()
        ..remove('placeLat')
        ..remove('placeLng');
      final back = TripSave.fromJson(json)!;
      expect(back.placeLat, isNull);
      expect(back.placeLng, isNull);
    });
  });

  group('pinsByDay groups by local calendar day', () {
    test('23:59 and 00:01 land on different days, newest day first', () {
      final days = pinsByDay(allPins());
      expect(days.map((d) => d.day).toList(), [day2, day1]);
    });

    test('each day holds its own pins, newest first', () {
      final days = pinsByDay(allPins());
      expect(days[0].pins.map((p) => p.id).toList(), [
        's-terminal-sample',
        's-atm',
        's-mango',
      ]);
      expect(days[1].pins.map((p) => p.id).toList(), [
        'r-late-dinner',
        'r-noodles',
      ]);
    });

    test('the day is the local midnight of that date', () {
      for (final d in pinsByDay(allPins())) {
        expect(d.day.hour, 0);
        expect(d.day.minute, 0);
        expect(d.day.isUtc, isFalse);
      }
    });

    test('input order does not matter', () {
      final reversed = allPins().reversed.toList();
      final days = pinsByDay(reversed);
      expect(days.map((d) => d.day).toList(), [day2, day1]);
      expect(days[0].pins.first.id, 's-terminal-sample');
      expect(days[1].pins.first.id, 'r-late-dinner');
    });

    test('no pins give no days', () {
      expect(pinsByDay(const []), isEmpty);
    });
  });

  group('keptOnDay sums what the traveler kept', () {
    test('day 2: haggle 150 + ATM 232.06 + terminal 180 = 562.06', () {
      final day = pinsByDay(allPins()).first;
      expect(keptOnDay(day.pins), closeTo(562.06, 1e-9));
    });

    test('receipts count zero', () {
      final day = pinsByDay(allPins()).last;
      expect(keptOnDay(day.pins), 0);
    });

    test('an empty day keeps nothing', () {
      expect(keptOnDay(const []), 0);
    });
  });

  group('pinBounds frames the pins', () {
    test('no pins give no box', () {
      expect(pinBounds(const []), isNull);
    });

    test('three places across Bangkok, 15% padding on each side', () {
      final box = pinBounds(allPins())!;
      // lat span 13.7999 - 13.7445 = 0.0554, pad 0.00831
      // lng span 100.5560 - 100.5341 = 0.0219, pad 0.003285
      expect(box.south, closeTo(13.73619, 1e-9));
      expect(box.north, closeTo(13.80821, 1e-9));
      expect(box.west, closeTo(100.530815, 1e-9));
      expect(box.east, closeTo(100.559285, 1e-9));
    });

    test('padFraction 0 hugs the extreme pins', () {
      final box = pinBounds(allPins(), padFraction: 0)!;
      expect(box.south, closeTo(sukhumvit11.lat, 1e-9));
      expect(box.north, closeTo(chatuchak.lat, 1e-9));
      expect(box.west, closeTo(siam.lng, 1e-9));
      expect(box.east, closeTo(sukhumvit11.lng, 1e-9));
    });

    test('one pin still frames a neighbourhood around itself', () {
      final pins = pinsFrom(receipts: [noodles], saves: const []);
      final box = pinBounds(pins)!;
      expect(box.north - box.south, greaterThanOrEqualTo(0.01 - 1e-12));
      expect(box.east - box.west, greaterThanOrEqualTo(0.01 - 1e-12));
      expect((box.north + box.south) / 2, closeTo(chatuchak.lat, 1e-9));
      expect((box.east + box.west) / 2, closeTo(chatuchak.lng, 1e-9));
    });

    test('a narrow axis is widened to the minimum span, centred', () {
      // The Siam receipt and the Siam Paragon save share one spot, so both
      // axes have zero span and must widen to 0.01 around it.
      final pins = pinsFrom(receipts: [lateDinner], saves: [sampleTerminal]);
      final box = pinBounds(pins, padFraction: 0)!;
      expect(box.north - box.south, closeTo(0.01, 1e-9));
      expect(box.east - box.west, closeTo(0.01, 1e-9));
      expect((box.north + box.south) / 2, closeTo(siam.lat, 1e-9));
      expect((box.east + box.west) / 2, closeTo(siam.lng, 1e-9));
    });

    test('every pin lies inside the box', () {
      final pins = allPins();
      final box = pinBounds(pins)!;
      for (final p in pins) {
        expect(p.lat, inInclusiveRange(box.south, box.north));
        expect(p.lng, inInclusiveRange(box.west, box.east));
      }
    });
  });
}
