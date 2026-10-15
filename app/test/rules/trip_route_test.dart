import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/trip_ledger.dart';
import 'package:money_navigation/rules/trip_route.dart';

// All local DateTime. "Today" is 15 Oct 2026.
TripSave save(
  String id,
  DateTime at,
  double kept, {
  SaveKind kind = SaveKind.haggle,
  String? place,
  bool sample = false,
}) => TripSave(
  id: id,
  kind: kind,
  keptThb: kept,
  savedAt: at,
  placeName: place,
  isSample: sample,
);

/// demo_personas.json visitorBangkok samples as saves (kept = asked - paid).
final List<TripSave> visitorSamples = [
  save(
    's1',
    DateTime(2026, 10, 12, 10, 20),
    40,
    place: 'Or Tor Kor Market',
    sample: true,
  ),
  save(
    's2',
    DateTime(2026, 10, 12, 12, 40),
    10,
    place: 'Or Tor Kor Market',
    sample: true,
  ),
  save(
    's3',
    DateTime(2026, 10, 13, 11, 5),
    60,
    place: 'Chatuchak Weekend Market',
    sample: true,
  ),
  save(
    's4',
    DateTime(2026, 10, 13, 13, 30),
    10,
    place: 'Chatuchak Weekend Market',
    sample: true,
  ),
];

final TripSave atmToday = save(
  'atm-1',
  DateTime(2026, 10, 15, 9, 30),
  246,
  kind: SaveKind.atmConversion,
);

void main() {
  group('visitor demo samples', () {
    late List<RouteStop> route;
    setUp(() => route = tripRoute(visitorSamples));

    test('two stops, oldest first', () {
      expect(route.length, 2);
      expect(route[0].placeName, 'Or Tor Kor Market');
      expect(route[1].placeName, 'Chatuchak Weekend Market');
    });
    test('Or Tor Kor: 40 + 10 = 50 kept over 2 saves', () {
      expect(route[0].keptThb, 50);
      expect(route[0].saves, 2);
      expect(route[0].kind, SaveKind.haggle);
      expect(route[0].at, DateTime(2026, 10, 12, 10, 20));
      expect(route[0].isSample, isTrue);
    });
    test('Chatuchak: 60 + 10 = 70 kept over 2 saves', () {
      expect(route[1].keptThb, 70);
      expect(route[1].saves, 2);
      expect(route[1].at, DateTime(2026, 10, 13, 11, 5));
      expect(route[1].isSample, isTrue);
    });
    test('input order does not matter', () {
      final shuffled = tripRoute(visitorSamples.reversed.toList());
      expect([for (final s in shuffled) s.keptThb], [50, 70]);
    });
  });

  group('plus a new ATM save today without a place', () {
    late List<RouteStop> route;
    setUp(() => route = tripRoute([...visitorSamples, atmToday]));

    test('three stops', () => expect(route.length, 3));
    test('last stop is the ATM save, 246 kept', () {
      final last = route.last;
      expect(last.kind, SaveKind.atmConversion);
      expect(last.keptThb, 246);
      expect(last.placeName, isNull);
      expect(last.saves, 1);
      expect(last.isSample, isFalse);
      expect(last.at, DateTime(2026, 10, 15, 9, 30));
    });
  });

  group('merging', () {
    test('placeless saves never merge', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 10),
        save('b', DateTime(2026, 10, 15, 10), 20),
      ]);
      expect(route.length, 2);
    });

    test('same place, case-insensitive, same day merges', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 10, place: 'Chatuchak'),
        save('b', DateTime(2026, 10, 15, 10), 20, place: 'CHATUCHAK'),
      ]);
      expect(route.length, 1);
      expect(route.single.keptThb, 30);
      expect(route.single.saves, 2);
      expect(route.single.placeName!.toLowerCase(), 'chatuchak');
    });

    test('same place on different days stays separate', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 14, 20), 10, place: 'Chatuchak'),
        save('b', DateTime(2026, 10, 15, 9), 20, place: 'Chatuchak'),
      ]);
      expect(route.length, 2);
    });

    test('only consecutive saves merge', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 10, place: 'Chatuchak'),
        save('b', DateTime(2026, 10, 15, 10), 5, place: 'Talat Noi'),
        save('c', DateTime(2026, 10, 15, 11), 20, place: 'Chatuchak'),
      ]);
      expect([for (final s in route) s.keptThb], [10, 5, 20]);
    });

    test('a placeless save in between breaks the run', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 10, place: 'Chatuchak'),
        save(
          'b',
          DateTime(2026, 10, 15, 10),
          246,
          kind: SaveKind.atmConversion,
        ),
        save('c', DateTime(2026, 10, 15, 11), 20, place: 'Chatuchak'),
      ]);
      expect(route.length, 3);
    });

    test('kind is the kind of the largest save in the stop', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 10, place: 'Shibuya'),
        save(
          'b',
          DateTime(2026, 10, 15, 10),
          152.1,
          kind: SaveKind.terminalDcc,
          place: 'Shibuya',
        ),
      ]);
      expect(route.single.kind, SaveKind.terminalDcc);
      expect(route.single.keptThb, closeTo(162.1, 1e-9));
      expect(route.single.at, DateTime(2026, 10, 15, 9));
    });

    test('sample mixed with own save is not a sample stop', () {
      final route = tripRoute([
        save(
          'a',
          DateTime(2026, 10, 15, 9),
          10,
          place: 'Chatuchak',
          sample: true,
        ),
        save('b', DateTime(2026, 10, 15, 10), 20, place: 'Chatuchak'),
      ]);
      expect(route.single.isSample, isFalse);
    });

    test('saves that kept 0 still appear', () {
      final route = tripRoute([
        save('a', DateTime(2026, 10, 15, 9), 0, place: 'Chatuchak'),
      ]);
      expect(route.length, 1);
      expect(route.single.keptThb, 0);
    });
  });

  group('maxStops', () {
    final six = [
      for (var i = 0; i < 6; i++)
        save('p$i', DateTime(2026, 10, 15, 8 + i), (i + 1).toDouble()),
    ];

    test('six placeless saves with maxStops 4 keep the last four', () {
      final route = tripRoute(six, maxStops: 4);
      expect([for (final s in route) s.keptThb], [3, 4, 5, 6]);
    });

    test('default maxStops is 4', () {
      final route = tripRoute(six);
      expect(route.length, 4);
      expect(route.first.keptThb, 3);
    });

    test('fewer stops than maxStops keeps them all', () {
      expect(tripRoute(six.take(2).toList()).length, 2);
    });
  });

  test(
    'empty gives an empty route',
    () => expect(tripRoute(const []), isEmpty),
  );
}
