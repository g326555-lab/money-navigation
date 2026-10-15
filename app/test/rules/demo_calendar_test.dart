import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/day_cash.dart';
import 'package:money_navigation/rules/demo_calendar.dart';
import 'package:money_navigation/rules/pay_route.dart';

String _json(List<Map<String, Object?>> personas) =>
    jsonEncode({'personas': personas});

Map<String, Object?> _persona(String key, Object? calendar) => {
  'key': key,
  'calendar': ?calendar,
};

Map<String, Object?> _ev(Object? time, Object? title, Object? location) => {
  'time': time,
  'title': title,
  'location': location,
};

void main() {
  final now = DateTime(2026, 10, 16, 9, 30);

  List<DayEvent>? run(Object? calendar, {DateTime? at, String key = 'p'}) =>
      demoCalendarEvents(_json([_persona(key, calendar)]), key, at ?? now);

  test('asset path constant', () {
    expect(demoCalendarAsset, 'assets/data/demo_personas.json');
  });

  group('demoCalendarEvents', () {
    test('valid events are sorted by start even when given unsorted', () {
      final r = run([
        _ev('18:30', 'Dinner', 'Thip Samai'),
        _ev('10:00', 'Market', 'Chatuchak'),
        _ev('9:05', 'Breakfast', 'Cafe'),
      ])!;
      expect(r.map((e) => e.title), ['Breakfast', 'Market', 'Dinner']);
      expect(r[0].start, DateTime(2026, 10, 16, 9, 5));
      expect(r[1].start, DateTime(2026, 10, 16, 10, 0));
      expect(r[2].start, DateTime(2026, 10, 16, 18, 30));
      expect(r[1].location, 'Chatuchak');
      expect(r[1].payment, PlacePayment.unknown);
      expect(r[1].matchedPlace, isNull);
    });

    test('unknown persona gives empty list', () {
      expect(
        demoCalendarEvents(
          _json([
            _persona('a', [_ev('10:00', 't', 'l')]),
          ]),
          'zzz',
          now,
        ),
        isEmpty,
      );
    });

    test('persona without calendar gives empty list', () {
      expect(run(null), isEmpty);
    });

    test('calendar not a list gives empty list', () {
      expect(run('nope'), isEmpty);
      expect(run({'time': '10:00'}), isEmpty);
    });

    test('bad times are skipped', () {
      final r = run([
        _ev('25:00', 'a', 'l'),
        _ev('10-00', 'b', 'l'),
        _ev('', 'c', 'l'),
        _ev(10, 'd', 'l'),
        _ev('10:60', 'e', 'l'),
        _ev('12:00', 'ok', 'l'),
      ])!;
      expect(r.map((e) => e.title), ['ok']);
    });

    test('blank or missing location is skipped', () {
      final r = run([
        _ev('10:00', 'a', ''),
        _ev('10:30', 'b', '   '),
        _ev('11:00', 'c', null),
        _ev('11:30', 'd', 5),
        _ev('12:00', 'ok', 'Place'),
      ])!;
      expect(r.map((e) => e.title), ['ok']);
    });

    test('missing title becomes empty string', () {
      final r = run([
        {'time': '10:00', 'location': 'Place'},
      ])!;
      expect(r, hasLength(1));
      expect(r.single.title, '');
    });

    test('non-object entries are skipped', () {
      final r = run(['x', 3, null, _ev('10:00', 'ok', 'Place')])!;
      expect(r.map((e) => e.title), ['ok']);
    });

    test('extra fields are ignored', () {
      final r = run([
        {'time': '10:00', 'title': 't', 'location': 'l', 'foo': 1},
      ])!;
      expect(r, hasLength(1));
    });

    test('non-JSON gives null', () {
      expect(demoCalendarEvents('not json', 'p', now), isNull);
    });

    test('JSON without personas list gives null', () {
      expect(demoCalendarEvents('{"x":1}', 'p', now), isNull);
      expect(demoCalendarEvents('{"personas":5}', 'p', now), isNull);
    });

    test('late evening now still dates events the same day', () {
      final r = run([
        _ev('10:00', 'a', 'l'),
      ], at: DateTime(2026, 10, 16, 23, 59))!;
      expect(r.single.start, DateTime(2026, 10, 16, 10, 0));
    });

    test('two personas keep their own events', () {
      final j = _json([
        _persona('a', [_ev('10:00', 'A1', 'l')]),
        _persona('b', [_ev('11:00', 'B1', 'l'), _ev('12:00', 'B2', 'l')]),
      ]);
      expect(demoCalendarEvents(j, 'a', now)!.map((e) => e.title), ['A1']);
      expect(demoCalendarEvents(j, 'b', now)!.map((e) => e.title), [
        'B1',
        'B2',
      ]);
    });
  });
}
