import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/trip_period.dart';

void main() {
  final p = TripPeriod(
    start: DateTime(2026, 10, 13, 18, 30),
    end: DateTime(2026, 10, 17),
  );

  test('days include both ends and drop the time of day', () {
    expect(p.start, DateTime(2026, 10, 13));
    expect(p.length, 5);
    expect(p.days.last, DateTime(2026, 10, 17));
  });

  test('day numbers count from 1, null outside the trip', () {
    expect(p.dayNumber(DateTime(2026, 10, 13, 23, 59)), 1);
    expect(p.dayNumber(DateTime(2026, 10, 16, 8)), 4);
    expect(p.dayNumber(DateTime(2026, 10, 12)), isNull);
    expect(p.dayNumber(DateTime(2026, 10, 18)), isNull);
  });

  test('a trip across a month end keeps every day', () {
    final q = TripPeriod(
      start: DateTime(2026, 10, 30),
      end: DateTime(2026, 11, 2),
    );
    expect(q.days, [
      DateTime(2026, 10, 30),
      DateTime(2026, 10, 31),
      DateTime(2026, 11, 1),
      DateTime(2026, 11, 2),
    ]);
  });

  test('invalid periods are refused, not repaired', () {
    expect(
      tripPeriodOrNull(DateTime(2026, 10, 17), DateTime(2026, 10, 13)),
      isNull,
    );
    expect(
      tripPeriodOrNull(DateTime(2026, 1, 1), DateTime(2026, 12, 31)),
      isNull,
    );
    expect(
      TripPeriod.fromJson({'start': '2026-10-17', 'end': '2026-10-13'}),
      isNull,
    );
    expect(TripPeriod.fromJson({'start': 'x', 'end': '2026-10-13'}), isNull);
    expect(TripPeriod.fromJson(null), isNull);
  });

  test('JSON round trip', () {
    expect(p.toJson(), {'start': '2026-10-13', 'end': '2026-10-17'});
    expect(TripPeriod.fromJson(p.toJson()), p);
  });

  test('the default day is today inside the trip, else the nearest end', () {
    expect(
      defaultTripDay(p, DateTime(2026, 10, 15, 9)),
      DateTime(2026, 10, 15),
    );
    expect(defaultTripDay(p, DateTime(2026, 10, 1)), DateTime(2026, 10, 13));
    expect(defaultTripDay(p, DateTime(2026, 10, 30)), DateTime(2026, 10, 17));
    expect(
      defaultTripDay(null, DateTime(2026, 10, 30, 9)),
      DateTime(2026, 10, 30),
    );
  });
}
