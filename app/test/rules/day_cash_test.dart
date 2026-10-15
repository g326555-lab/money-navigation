import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/day_cash.dart';
import 'package:money_navigation/rules/pay_route.dart';
import 'package:money_navigation/rules/personal_context.dart';

// All local DateTime. "Today" is 15 Oct 2026, briefing at 08:00.
final DateTime now = DateTime(2026, 10, 15, 8);
final DateTime threeDaysAgo = DateTime(2026, 10, 12);
final DateTime twoDaysAgo = DateTime(2026, 10, 13);

PastPurchase buy(
  String item,
  double paid,
  DateTime at,
  String? place, {
  bool sample = true,
}) => PastPurchase(
  itemKey: item,
  paidThb: paid,
  placeName: place,
  at: at,
  isSample: sample,
);

/// demo_personas.json visitorBangkok samples.
final List<PastPurchase> visitorHistory = [
  buy('mango', 100, DateTime(2026, 10, 12, 10, 20), 'Or Tor Kor Market'),
  buy('coconut', 60, DateTime(2026, 10, 12, 12, 40), 'Or Tor Kor Market'),
  buy('mango', 90, DateTime(2026, 10, 13, 11, 5), 'Chatuchak Weekend Market'),
  buy(
    'pad_thai',
    80,
    DateTime(2026, 10, 13, 13, 30),
    'Chatuchak Weekend Market',
  ),
];

const PlacePayment cashOnly = PlacePayment(cashOnly: true);
const PlacePayment takesCards = PlacePayment(cashOnly: false, cards: true);

DayEvent event(
  String title,
  String? location,
  DateTime start, {
  PlacePayment payment = PlacePayment.unknown,
  String? matchedPlace,
}) => DayEvent(
  title: title,
  location: location,
  start: start,
  payment: payment,
  matchedPlace: matchedPlace,
);

void expectSameDay(DateTime? actual, DateTime expected) {
  expect(actual, isNotNull);
  expect(
    [actual!.year, actual.month, actual.day],
    [expected.year, expected.month, expected.day],
  );
}

void main() {
  group('visitor history, Chatuchak today (cash only)', () {
    late DayCashPlan plan;
    setUp(() {
      plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Chatuchak',
            'Chatuchak Weekend Market',
            DateTime(2026, 10, 15, 14),
            payment: cashOnly,
          ),
        ],
        now: now,
      )!;
    });

    test('pattern: median of 160 and 170 = 165, rounded up to 200', () {
      expect(plan.pattern, isNotNull);
      expect(plan.pattern!.amountThb, 200);
      expect(plan.pattern!.daysUsed, 2);
    });
    test('one stop, cash only', () {
      expect(plan.stops.length, 1);
      expect(plan.stops.single.cashOnly, isTrue);
      expect(plan.stops.single.cardsAccepted, isFalse);
      expect(plan.cashOnlyStops, 1);
    });
    test('last spent there 170 two days ago, all samples', () {
      final stop = plan.stops.single;
      expect(stop.lastSpentThb, 170);
      expectSameDay(stop.lastVisit, twoDaysAgo);
      expect(stop.lastFromSamples, isTrue);
    });
    test('stops floor 200, amount 200', () {
      expect(plan.stopsFloorThb, 200);
      expect(plan.amountThb, 200);
    });
    test('always an estimate', () => expect(plan.isEstimate, isTrue));
  });

  group('amount from pattern and stops', () {
    test('new cash-only place without history: lastSpent null, pattern', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Street food',
            'Talat Noi',
            DateTime(2026, 10, 15, 19),
            payment: cashOnly,
          ),
        ],
        now: now,
      )!;
      final stop = plan.stops.single;
      expect(stop.lastSpentThb, isNull);
      expect(stop.lastVisit, isNull);
      expect(stop.lastFromSamples, isFalse);
      expect(plan.stopsFloorThb, isNull);
      expect(plan.amountThb, 200);
      expect(plan.cashOnlyStops, 1);
    });

    test('no history + one cash-only stop: amount null, plan kept', () {
      final plan = dayCash(
        history: const [],
        events: [
          event(
            'Night market',
            'Jodd Fairs',
            DateTime(2026, 10, 15, 18),
            payment: cashOnly,
          ),
        ],
        now: now,
      );
      expect(plan, isNotNull);
      expect(plan!.amountThb, isNull);
      expect(plan.pattern, isNull);
      expect(plan.stopsFloorThb, isNull);
      expect(plan.cashOnlyStops, 1);
      expect(plan.stops.single.lastSpentThb, isNull);
    });

    test('two cash-only stops: floor 160 + 170 = 330 -> 400 beats 200', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Fruit',
            'Or Tor Kor Market',
            DateTime(2026, 10, 15, 10),
            payment: cashOnly,
          ),
          event(
            'Chatuchak',
            'Chatuchak Weekend Market',
            DateTime(2026, 10, 15, 14),
            payment: cashOnly,
          ),
        ],
        now: now,
      )!;
      expect(plan.stopsFloorThb, 400);
      expect(plan.amountThb, 400);
      expect(plan.cashOnlyStops, 2);
    });

    test('stop that takes cards does not add to the floor', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Chatuchak',
            'Chatuchak Weekend Market',
            DateTime(2026, 10, 15, 14),
            payment: takesCards,
          ),
        ],
        now: now,
      )!;
      final stop = plan.stops.single;
      expect(stop.cashOnly, isFalse);
      expect(stop.cardsAccepted, isTrue);
      expect(stop.lastSpentThb, 170);
      expect(plan.stopsFloorThb, isNull);
      expect(plan.cashOnlyStops, 0);
      expect(plan.amountThb, 200);
    });

    test('unknown payment: neither cash only nor cards accepted', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Lunch',
            'Chatuchak Weekend Market',
            DateTime(2026, 10, 15, 12),
          ),
        ],
        now: now,
      )!;
      final stop = plan.stops.single;
      expect(stop.cashOnly, isFalse);
      expect(stop.cardsAccepted, isFalse);
      expect(plan.stopsFloorThb, isNull);
    });

    test('cards true with cashOnly true is not cards accepted', () {
      final plan = dayCash(
        history: const [],
        events: [
          event(
            'Odd data',
            'Some Market',
            DateTime(2026, 10, 15, 12),
            payment: const PlacePayment(cashOnly: true, cards: true),
          ),
        ],
        now: now,
      )!;
      expect(plan.stops.single.cashOnly, isTrue);
      expect(plan.stops.single.cardsAccepted, isFalse);
    });

    test('pattern only, no stops today: plan with pattern amount', () {
      final plan = dayCash(
        history: visitorHistory,
        events: const [],
        now: now,
      )!;
      expect(plan.stops, isEmpty);
      expect(plan.amountThb, 200);
      expect(plan.stopsFloorThb, isNull);
      expect(plan.cashOnlyStops, 0);
    });

    test('one earlier day only: no pattern', () {
      final plan = dayCash(
        history: visitorHistory.take(2).toList(),
        events: [
          event(
            'Fruit',
            'Or Tor Kor Market',
            DateTime(2026, 10, 15, 10),
            payment: cashOnly,
          ),
        ],
        now: now,
      )!;
      expect(plan.pattern, isNull);
      expect(plan.stops.single.lastSpentThb, 160);
      expect(plan.stopsFloorThb, 200);
      expect(plan.amountThb, 200);
    });
  });

  group('which events count', () {
    test('event tomorrow is ignored', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event(
            'Chatuchak',
            'Chatuchak Weekend Market',
            DateTime(2026, 10, 16, 10),
            payment: cashOnly,
          ),
        ],
        now: now,
      )!;
      expect(plan.stops, isEmpty);
      expect(plan.amountThb, 200);
    });

    test('event yesterday is ignored', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event('Old', 'Chatuchak Weekend Market', DateTime(2026, 10, 14, 10)),
        ],
        now: now,
      )!;
      expect(plan.stops, isEmpty);
    });

    test('event earlier today (before now) still counts', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event('Early', 'Or Tor Kor Market', DateTime(2026, 10, 15, 6)),
        ],
        now: now,
      )!;
      expect(plan.stops.length, 1);
    });

    test('event without location is ignored', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event('Call home', null, DateTime(2026, 10, 15, 9)),
          event('Blank', '   ', DateTime(2026, 10, 15, 10)),
          event('Empty', '', DateTime(2026, 10, 15, 11)),
        ],
        now: now,
      )!;
      expect(plan.stops, isEmpty);
    });

    test('stops are in start order', () {
      final plan = dayCash(
        history: visitorHistory,
        events: [
          event('Late', 'Chatuchak Weekend Market', DateTime(2026, 10, 15, 16)),
          event('Early', 'Or Tor Kor Market', DateTime(2026, 10, 15, 9)),
          event('Mid', 'Talat Noi', DateTime(2026, 10, 15, 12)),
        ],
        now: now,
      )!;
      expect(
        [for (final s in plan.stops) s.event.title],
        ['Early', 'Mid', 'Late'],
      );
    });

    test('empty history and no events: null', () {
      expect(dayCash(history: const [], events: const [], now: now), isNull);
    });

    test('no pattern and only events on other days: null', () {
      expect(
        dayCash(
          history: const [],
          events: [event('Tomorrow', 'Chatuchak', DateTime(2026, 10, 16, 10))],
          now: now,
        ),
        isNull,
      );
    });
  });

  group('place matching', () {
    DayCashPlan planFor(
      String location, {
      String? matchedPlace,
      List<PastPurchase>? history,
    }) => dayCash(
      history: history ?? visitorHistory,
      events: [
        event(
          'Stop',
          location,
          DateTime(2026, 10, 15, 12),
          payment: cashOnly,
          matchedPlace: matchedPlace,
        ),
      ],
      now: now,
    )!;

    test('"Or Tor Kor" matches "Or Tor Kor Market" (contains, >= 6)', () {
      final stop = planFor('Or Tor Kor').stops.single;
      expect(stop.lastSpentThb, 160);
      expectSameDay(stop.lastVisit, threeDaysAgo);
    });

    test('case and spaces do not matter', () {
      final stop = planFor('  chatuchak weekend MARKET ').stops.single;
      expect(stop.lastSpentThb, 170);
    });

    test('matchedPlace from Google Maps is used', () {
      final stop = planFor(
        'Kamphaeng Phet 3 Rd',
        matchedPlace: 'Chatuchak Weekend Market',
      ).stops.single;
      expect(stop.lastSpentThb, 170);
    });

    test('"Mall" (4 chars) does not match "Mall of Asia Market"', () {
      final stop = planFor(
        'Mall',
        history: [
          buy('mango', 120, DateTime(2026, 10, 13, 11), 'Mall of Asia Market'),
        ],
      ).stops.single;
      expect(stop.lastSpentThb, isNull);
      expect(stop.lastVisit, isNull);
    });

    test('purchases without a place never match', () {
      final stop = planFor(
        'Chatuchak Weekend Market',
        history: [buy('mango', 120, DateTime(2026, 10, 13, 11), null)],
      ).stops.single;
      expect(stop.lastSpentThb, isNull);
    });

    test('latest day wins and only that day is summed', () {
      final stop = planFor(
        'Chatuchak Weekend Market',
        history: [
          ...visitorHistory,
          buy(
            'mango',
            300,
            DateTime(2026, 10, 10, 11),
            'Chatuchak Weekend Market',
          ),
        ],
      ).stops.single;
      expect(stop.lastSpentThb, 170);
      expectSameDay(stop.lastVisit, twoDaysAgo);
    });

    test('purchases earlier today do not count as the last visit', () {
      final stop = planFor(
        'Chatuchak Weekend Market',
        history: [
          ...visitorHistory,
          buy(
            'mango',
            300,
            DateTime(2026, 10, 15, 7),
            'Chatuchak Weekend Market',
          ),
        ],
      ).stops.single;
      expect(stop.lastSpentThb, 170);
      expectSameDay(stop.lastVisit, twoDaysAgo);
    });

    test('other places that day are not summed', () {
      final stop = planFor(
        'Chatuchak Weekend Market',
        history: [
          ...visitorHistory,
          buy('tea', 50, DateTime(2026, 10, 13, 16), 'Talat Noi'),
        ],
      ).stops.single;
      expect(stop.lastSpentThb, 170);
    });

    test('own record mixed with a sample: not all samples', () {
      final stop = planFor(
        'Chatuchak Weekend Market',
        history: [
          ...visitorHistory,
          buy(
            'tea',
            30,
            DateTime(2026, 10, 13, 16),
            'Chatuchak Weekend Market',
            sample: false,
          ),
        ],
      ).stops.single;
      expect(stop.lastSpentThb, 200);
      expect(stop.lastFromSamples, isFalse);
    });
  });
}
