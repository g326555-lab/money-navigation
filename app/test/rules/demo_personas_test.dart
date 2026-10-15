import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/atm_conversion.dart';
import 'package:money_navigation/rules/bill_check.dart' show BillKind;
import 'package:money_navigation/rules/cash_wallet.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/personal_context.dart';
import 'package:money_navigation/rules/receipt_record.dart';
import 'package:money_navigation/rules/trip_ledger.dart';

/// 16:00 local on the demo day.
final now = DateTime(2026, 10, 15, 16, 0);

Map<String, Object?> visitor() => {
  'key': 'visitorBangkok',
  'language': 'en',
  'homeCurrency': 'USD',
  'localCurrency': 'THB',
  'samples': [
    {
      'kind': 'haggle',
      'daysAgo': 3,
      'time': '10:20',
      'itemKey': 'mango',
      'askedThb': 140,
      'paidThb': 100,
      'paidWith': 'cash',
      'placeName': 'Or Tor Kor Market',
    },
    {
      'kind': 'haggle',
      'daysAgo': 0,
      'time': '09:05',
      'itemKey': 'coconut',
      'askedThb': 70,
      'paidThb': 70,
      'paidWith': 'cash',
    },
  ],
};

Map<String, Object?> thai() => {
  'key': 'thaiTokyo',
  'language': 'th',
  'homeCurrency': 'THB',
  'localCurrency': 'JPY',
  'samples': [
    {
      'kind': 'terminalDcc',
      'daysAgo': 1,
      'time': '18:05',
      'keptThb': 86.40,
      'placeName': 'Convenience store, Shinjuku',
    },
    {'kind': 'atmConversion', 'daysAgo': 2, 'time': '00:00', 'keptThb': 0},
  ],
};

String file(List<Map<String, Object?>> personas) =>
    jsonEncode({'_comment': 'test', 'personas': personas});

/// The valid two-persona file with one change applied to the first
/// persona (or to its first sample).
String withVisitor(void Function(Map<String, Object?> p) change) {
  final p = visitor();
  change(p);
  return file([p, thai()]);
}

String withVisitorSample(void Function(Map<String, Object?> s) change) =>
    withVisitor((p) {
      final samples = (p['samples']! as List).cast<Map<String, Object?>>();
      change(samples.first);
    });

String withThaiSample(void Function(Map<String, Object?> s) change) {
  final t = thai();
  change((t['samples']! as List).cast<Map<String, Object?>>().first);
  return file([visitor(), t]);
}

/// A restaurant bill that adds up: 400 + 10 % service 40 = 440, VAT
/// 28.79 inside.
Map<String, Object?> restaurantReceipt() => {
  'daysAgo': 2,
  'time': '19:30',
  'merchantName': 'Thai restaurant',
  'placeName': 'Sukhumvit Soi 12',
  'lat': 13.7363,
  'lng': 100.5579,
  'kind': 'serviceCharge',
  'subtotalThb': 400.0,
  'servicePercent': 10,
  'serviceThb': 40.0,
  'vatThb': 28.79,
  'totalThb': 440.0,
  'paidWith': 'cash',
  'category': 'food',
};

/// The valid file with the visitor carrying [restaurantReceipt] after
/// [change].
String withReceipt(void Function(Map<String, Object?> r) change) =>
    withVisitor((p) {
      final r = restaurantReceipt();
      change(r);
      p['receipts'] = [r];
    });

/// An airport ATM screen: 6000 + 220 fee = 6220 THB, or 212.64 USD at the
/// ATM's conversion against 6220 / 30.86 = 201.56 USD fair.
Map<String, Object?> atmSample() => {
  'kind': 'atmConversion',
  'daysAgo': 3,
  'time': '20:40',
  'placeName': 'Suvarnabhumi Airport',
  'atm': {
    'withdrawalThb': 6000,
    'accessFeeThb': 220,
    'thbPerUsd': 30.86,
    'markupPercent': 5.5,
    'chargedThb': 6220,
    'chargedUsd': 212.64,
  },
};

/// The valid file with the visitor carrying [atmSample] after [change] to
/// its atm block.
String withAtm(void Function(Map<String, Object?> atm) change) =>
    withVisitor((p) {
      final a = atmSample();
      change((a['atm']! as Map).cast<String, Object?>());
      p['samples'] = <Object?>[...(p['samples']! as List), a];
    });

/// Great-circle distance in metres.
double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  double rad(double d) => d * math.pi / 180;
  final h =
      math.pow(math.sin(rad(lat2 - lat1) / 2), 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.pow(math.sin(rad(lng2 - lng1) / 2), 2);
  return 2 * r * math.asin(math.sqrt(h));
}

void main() {
  group('parseDemoPersonas: valid file', () {
    test('two personas parse with their fields', () {
      final d = parseDemoPersonas(file([visitor(), thai()]))!;
      expect(d.personas.map((p) => p.key), ['visitorBangkok', 'thaiTokyo']);
      final v = d.personas.first;
      expect(v.language, 'en');
      expect(v.homeCurrency, 'USD');
      expect(v.localCurrency, 'THB');
      final t = d.personas.last;
      expect(t.language, 'th');
      expect(t.homeCurrency, 'THB');
      expect(t.localCurrency, 'JPY');
    });

    test('placeName is optional', () {
      final d = parseDemoPersonas(
        withVisitorSample((s) => s.remove('placeName')),
      );
      expect(d, isNotNull);
    });

    test('paid equal to asked is a valid haggle', () {
      // The second visitor sample already has asked 70 paid 70.
      expect(parseDemoPersonas(file([visitor(), thai()])), isNotNull);
    });

    test('keptThb 0 is valid for atmConversion / terminalDcc', () {
      // The second Thai sample is an atmConversion with keptThb 0.
      expect(parseDemoPersonas(file([visitor(), thai()])), isNotNull);
    });

    test('receipts are optional; a receipt that adds up parses', () {
      final d = parseDemoPersonas(withReceipt((_) {}))!;
      expect(d.byKey('visitorBangkok')!.receiptsAt(now), hasLength(1));
      expect(d.byKey('thaiTokyo')!.receiptsAt(now), isEmpty);
    });

    test('an ATM block parses; kept comes from evaluateAtm', () {
      final d = parseDemoPersonas(withAtm((_) {}))!;
      final atm = d
          .byKey('visitorBangkok')!
          .samplesAt(now)
          .singleWhere((s) => s.kind == SaveKind.atmConversion);
      expect(atm.keptThb, closeTo(342.07, 0.005));
    });
  });

  group('parseDemoPersonas: malformed gives null', () {
    final cases = <String, String>{
      'not json': 'not json',
      'root is a list': '[]',
      'personas missing': '{"_comment":"x"}',
      'personas not a list': '{"personas":{}}',
      'one persona only': file([visitor()]),
      'no personas': file([]),
      'duplicate key': file([visitor(), visitor()]),
      'persona not a map': jsonEncode({
        'personas': [visitor(), 'thaiTokyo'],
      }),
      'missing key': withVisitor((p) => p.remove('key')),
      'empty key': withVisitor((p) => p['key'] = ''),
      'missing language': withVisitor((p) => p.remove('language')),
      'missing homeCurrency': withVisitor((p) => p.remove('homeCurrency')),
      'homeCurrency not 3 letters': withVisitor(
        (p) => p['homeCurrency'] = 'US',
      ),
      'missing localCurrency': withVisitor((p) => p.remove('localCurrency')),
      'localCurrency not 3 letters': withVisitor(
        (p) => p['localCurrency'] = 'BAHT',
      ),
      'samples missing': withVisitor((p) => p.remove('samples')),
      'samples not a list': withVisitor((p) => p['samples'] = 'none'),
      'sample not a map': withVisitor(
        (p) => p['samples'] = <Object?>[...(p['samples']! as List), 'x'],
      ),
      'unknown kind': withVisitorSample((s) => s['kind'] = 'lottery'),
      'missing kind': withVisitorSample((s) => s.remove('kind')),
      'bad time 25:00': withVisitorSample((s) => s['time'] = '25:00'),
      'bad time 10:60': withVisitorSample((s) => s['time'] = '10:60'),
      'time not hh:mm': withVisitorSample((s) => s['time'] = 'morning'),
      'missing time': withVisitorSample((s) => s.remove('time')),
      'negative daysAgo': withVisitorSample((s) => s['daysAgo'] = -1),
      'missing daysAgo': withVisitorSample((s) => s.remove('daysAgo')),
      'haggle without itemKey': withVisitorSample((s) => s.remove('itemKey')),
      'haggle askedThb 0': withVisitorSample((s) => s['askedThb'] = 0),
      'haggle askedThb missing': withVisitorSample((s) => s.remove('askedThb')),
      'haggle paidThb 0': withVisitorSample((s) => s['paidThb'] = 0),
      'haggle paidThb missing': withVisitorSample((s) => s.remove('paidThb')),
      'haggle paid > asked': withVisitorSample((s) => s['paidThb'] = 141),
      'terminalDcc negative keptThb': withThaiSample(
        (s) => s['keptThb'] = -0.01,
      ),
      'terminalDcc keptThb missing': withThaiSample((s) => s.remove('keptThb')),
      'atmConversion negative keptThb': withThaiSample((s) {
        s['kind'] = 'atmConversion';
        s['keptThb'] = -5;
      }),
      'receipts not a list': withVisitor((p) => p['receipts'] = 'none'),
      'receipt service not 10 % of the subtotal': withReceipt((r) {
        r['serviceThb'] = 44.0;
        r['totalThb'] = 444.0;
        r.remove('vatThb');
      }),
      'receipt total does not add up': withReceipt(
        (r) => r['totalThb'] = 441.0,
      ),
      'receipt VAT wrong by 0.02': withReceipt((r) => r['vatThb'] = 28.81),
      'receipt missing lat': withReceipt((r) => r.remove('lat')),
      'receipt missing lng': withReceipt((r) => r.remove('lng')),
      'receipt unknown category': withReceipt((r) => r['category'] = 'casino'),
      'receipt itemsOnly with net != total': withReceipt((r) {
        r['kind'] = 'itemsOnly';
        r.remove('serviceThb');
        r.remove('servicePercent');
        r.remove('vatThb');
      }),
      'ATM chargedThb != withdrawal + fee': withAtm(
        (a) => a['chargedThb'] = 6200,
      ),
      'ATM chargedUsd not above the fair amount': withAtm(
        (a) => a['chargedUsd'] = 201.56,
      ),
      'ATM block missing chargedUsd': withAtm((a) => a.remove('chargedUsd')),
    };
    cases.forEach((name, json) {
      test(name, () => expect(parseDemoPersonas(json), isNull));
    });
  });

  group('DemoPersona.samplesAt', () {
    final d = parseDemoPersonas(file([visitor(), thai()]))!;
    final v = d.byKey('visitorBangkok')!;
    final t = d.byKey('thaiTokyo')!;

    TripSave byId(List<TripSave> saves, String id) =>
        saves.singleWhere((s) => s.id == id);

    test('one save per sample, ids demo-<key>-<index>, all samples', () {
      final saves = v.samplesAt(now);
      expect(
        saves.map((s) => s.id),
        unorderedEquals(['demo-visitorBangkok-0', 'demo-visitorBangkok-1']),
      );
      expect(saves.every((s) => s.isSample), isTrue);
      expect(
        t.samplesAt(now).map((s) => s.id),
        unorderedEquals(['demo-thaiTokyo-0', 'demo-thaiTokyo-1']),
      );
    });

    test('savedAt is local: now.day - daysAgo at the sample time', () {
      final saves = v.samplesAt(now);
      final first = byId(saves, 'demo-visitorBangkok-0').savedAt;
      expect(first, DateTime(2026, 10, 12, 10, 20));
      expect(first.isUtc, isFalse);
      expect(
        byId(saves, 'demo-visitorBangkok-1').savedAt,
        DateTime(2026, 10, 15, 9, 5),
      );
      final ts = t.samplesAt(now);
      expect(
        byId(ts, 'demo-thaiTokyo-0').savedAt,
        DateTime(2026, 10, 14, 18, 5),
      );
      expect(byId(ts, 'demo-thaiTokyo-1').savedAt, DateTime(2026, 10, 13));
    });

    test('daysAgo crossing a month start rolls back the calendar', () {
      final d2 = parseDemoPersonas(
        withVisitorSample((s) => s['daysAgo'] = 20),
      )!;
      final s = byId(
        d2.byKey('visitorBangkok')!.samplesAt(now),
        'demo-visitorBangkok-0',
      );
      expect(s.savedAt, DateTime(2026, 9, 25, 10, 20));
    });

    test('haggle fields copied, keptThb = asked - paid', () {
      final s = byId(v.samplesAt(now), 'demo-visitorBangkok-0');
      expect(s.kind, SaveKind.haggle);
      expect(s.itemKey, 'mango');
      expect(s.askedThb, 140);
      expect(s.paidThb, 100);
      expect(s.keptThb, 40);
      expect(s.placeName, 'Or Tor Kor Market');
      final even = byId(v.samplesAt(now), 'demo-visitorBangkok-1');
      expect(even.keptThb, 0);
      expect(even.placeName, isNull);
    });

    test('haggle keptThb in the file is ignored, computed instead', () {
      final d2 = parseDemoPersonas(
        withVisitorSample((s) => s['keptThb'] = 999),
      )!;
      final s = byId(
        d2.byKey('visitorBangkok')!.samplesAt(now),
        'demo-visitorBangkok-0',
      );
      expect(s.keptThb, 40);
    });

    test('terminalDcc / atmConversion keep keptThb from the file', () {
      final ts = t.samplesAt(now);
      final dcc = byId(ts, 'demo-thaiTokyo-0');
      expect(dcc.kind, SaveKind.terminalDcc);
      expect(dcc.keptThb, closeTo(86.40, 1e-9));
      expect(dcc.placeName, 'Convenience store, Shinjuku');
      expect(dcc.itemKey, isNull);
      final atm = byId(ts, 'demo-thaiTokyo-1');
      expect(atm.kind, SaveKind.atmConversion);
      expect(atm.keptThb, 0);
    });
  });

  group('DemoPersonas.byKey / other', () {
    final d = parseDemoPersonas(file([visitor(), thai()]))!;

    test('byKey finds each persona; unknown key gives null', () {
      expect(d.byKey('visitorBangkok')!.key, 'visitorBangkok');
      expect(d.byKey('thaiTokyo')!.key, 'thaiTokyo');
      expect(d.byKey('marsColony'), isNull);
      expect(d.byKey(''), isNull);
    });

    test('other swaps between the two', () {
      final v = d.byKey('visitorBangkok')!;
      final t = d.byKey('thaiTokyo')!;
      expect(d.other(v).key, 'thaiTokyo');
      expect(d.other(t).key, 'visitorBangkok');
    });
  });

  group('the real assets/data/demo_personas.json', () {
    final d = parseDemoPersonas(
      File('assets/data/demo_personas.json').readAsStringSync(),
    );

    test('parses, asset path constant names it', () {
      expect(demoPersonasAsset, 'assets/data/demo_personas.json');
      expect(d, isNotNull);
      expect(d!.byKey('visitorBangkok'), isNotNull);
      expect(d.byKey('thaiTokyo'), isNotNull);
      expect(d.other(d.byKey('visitorBangkok')!).key, 'thaiTokyo');
    });

    test('US visitor in Bangkok: en, USD at home, THB local', () {
      final v = d!.byKey('visitorBangkok')!;
      expect(v.language, 'en');
      expect(v.homeCurrency, 'USD');
      expect(v.localCurrency, 'THB');
      final saves = v.samplesAt(now);
      expect(saves.every((s) => s.isSample), isTrue);
      expect(saves.every((s) => s.savedAt.isBefore(now)), isTrue);
      // ATM 342.07 + haggles 100 + 40 + 100 + 60 + 10.
      expect(keptTotalThb(saves), closeTo(652.07, 0.005));
    });

    test('visitor ATM sample: kept is evaluateAtm on the screen figures', () {
      final atm = d!
          .byKey('visitorBangkok')!
          .samplesAt(now)
          .singleWhere((s) => s.kind == SaveKind.atmConversion);
      final verdict = evaluateAtm(
        const AtmScreenReading(
          withdrawalThb: 6000,
          accessFeeThb: 220,
          thbPerUsd: 30.86,
          markupPercent: 5.5,
          chargedThb: 6220,
          chargedUsd: 212.64,
        ),
      );
      expect(verdict.recommended, AtmChoice.declineConversion);
      expect(atm.keptThb, closeTo(verdict.extraCostThb, 0.005));
      expect(atm.keptThb, closeTo(342.07, 0.005));
      expect(atm.isSample, isTrue);
    });

    test('visitor memory lines: price memory, counter, morning cash', () {
      final history = pastPurchasesFromSaves(
        d!.byKey('visitorBangkok')!.samplesAt(now),
      );

      final memory = priceMemory('mango', history, now)!;
      expect(memory.lastPaidThb, 90);
      expect(memory.daysAgo, 1);
      expect(memory.recordsUsed, 2);
      expect(memory.sampleRecords, 2);
      expect(memory.lastPlaceName, 'Or Tor Kor Market');

      // Mango 140 -> 100 (28.57 %) and 150 -> 90 (40 %): median 34.29 %.
      final counter = counterFromHistory('mango', 150, history, now)!;
      expect(counter.medianDiscountPercent, closeTo(34.29, 0.005));
      expect(counter.offerThb, 95);
      expect(counter.recordsUsed, 2);
      expect(counter.sampleRecords, 2);

      // Day totals 200 + 100 + 400 = 700 and 90 + 60 = 150: median 425,
      // rounded up to 500.
      final cash = morningCash(history, now)!;
      expect(cash.amountThb, 500);
      expect(cash.daysUsed, 2);
    });

    test('visitor receipts: 5 checked samples from the trip', () {
      final receipts = d!.byKey('visitorBangkok')!.receiptsAt(now);
      expect(receipts, hasLength(5));
      expect(receipts.every((r) => r.isSample), isTrue);
      expect(receipts.every((r) => r.verified), isTrue);
      expect(receipts.every((r) => !r.userCorrected), isTrue);
      expect(receipts.every((r) => r.savedAt.isBefore(now)), isTrue);
      expect(receipts.every((r) => r.lat != null && r.lng != null), isTrue);
      expect(
        receipts.map((r) => r.id).toSet(),
        hasLength(5),
        reason: 'ids are distinct',
      );
      for (var i = 1; i < receipts.length; i++) {
        expect(
          receipts[i - 1].savedAt.isAfter(receipts[i].savedAt),
          isTrue,
          reason: 'newest first',
        );
      }

      final restaurant = receipts
          .where((r) => r.merchantName == 'Thai restaurant')
          .toList();
      expect(restaurant, hasLength(2));
      expect(restaurant[0].lat, restaurant[1].lat);
      expect(restaurant[0].lng, restaurant[1].lng);
      expect(restaurant[0].merchantKey, restaurant[1].merchantKey);
      final byTotal = {for (final r in restaurant) r.totalThb: r};
      expect(byTotal.keys, unorderedEquals([440.0, 418.0]));
      expect(byTotal[440.0]!.vatThb, closeTo(28.79, 1e-9));
      expect(byTotal[418.0]!.vatThb, closeTo(27.35, 1e-9));
      for (final r in restaurant) {
        expect(r.kind, BillKind.serviceCharge);
        expect(r.vatOnTop, isFalse, reason: 'VAT inside the total');
        expect(r.servicePercent, 10);
        expect(r.category, SpendCategory.food);
      }

      final sevens = receipts
          .where((r) => r.merchantName == '7-Eleven')
          .toList();
      expect(sevens, hasLength(2));
      expect(
        haversineMeters(
          sevens[0].lat!,
          sevens[0].lng!,
          sevens[1].lat!,
          sevens[1].lng!,
        ),
        greaterThan(5000),
      );
      expect(sevens.every((r) => r.category == SpendCategory.shopping), isTrue);

      final mbk = receipts.singleWhere(
        (r) => r.merchantName == 'MBK Center food court',
      );
      expect(mbk.totalThb, 165.0);
      expect(mbk.kind, BillKind.itemsOnly);
    });

    test('visitor cash is computed from the sample records', () {
      final v = d!.byKey('visitorBangkok')!;
      final movements = v.cashMovementsAt(now);
      final saves = v.samplesAt(now);
      final receipts = v.receiptsAt(now);
      expect(movements.every((m) => m.currency == 'THB'), isTrue);
      expect(movements.every((m) => m.at.isBefore(now)), isTrue);
      // The withdrawal is the ATM sample's own screen figure.
      final atm = saves.singleWhere((s) => s.kind == SaveKind.atmConversion);
      final withdrawal = movements.singleWhere(
        (m) => m.kind == CashMovementKind.withdrawal,
      );
      expect(withdrawal.sourceId, atm.id);
      expect(withdrawal.amount, atm.screen![AtmFigures.withdrawalThb]);
      expect(withdrawal.at, atm.savedAt);
      // Every haggle was paid in cash, at its own time and price.
      for (final s in saves.where((s) => s.kind == SaveKind.haggle)) {
        final m = movements.singleWhere((m) => m.sourceId == s.id);
        expect(m.kind, CashMovementKind.cashSpend);
        expect(m.amount, s.paidThb);
        expect(m.at, s.savedAt);
      }
      // Restaurants were paid by card: no cash movement for them.
      for (final r in receipts) {
        final linked = movements.where((m) => m.sourceId == r.id);
        if (r.merchantName == 'Thai restaurant') {
          expect(linked, isEmpty);
        } else {
          expect(linked.single.amount, r.totalThb);
        }
      }
      // 6,000 out of the ATM, 850 on haggles, 89 + 76 + 165 cash receipts.
      expect(cashBalance(movements, 'THB'), 4820);
    });

    test('a sample without paidWith refuses the file', () {
      final json = jsonDecode(
        File('assets/data/demo_personas.json').readAsStringSync(),
      ) as Map<String, Object?>;
      final visitor = (json['personas']! as List).first as Map;
      ((visitor['samples']! as List)[1] as Map).remove('paidWith');
      expect(parseDemoPersonas(jsonEncode(json)), isNull);
    });

    test('Tokyo cash: exchange counter and cash spends from the file', () {
      final movements = d!.byKey('thaiTokyo')!.cashMovementsAt(now);
      expect(movements.every((m) => m.currency == 'JPY'), isTrue);
      expect(movements.every((m) => m.at.isBefore(now)), isTrue);
      expect(cashBalance(movements, 'JPY'), 17000);
    });

    test('visitor receipts: the restaurant remembers the earlier visit', () {
      final receipts = d!.byKey('visitorBangkok')!.receiptsAt(now);
      final latest = receipts.firstWhere(
        (r) => r.merchantName == 'Thai restaurant',
      );
      final memory = merchantMemory(latest, receipts, now)!;
      expect(memory.visits, 1);
      expect(memory.lastTotalThb, 440.0);
      expect(memory.sampleRecords, 1);
      // The other 7-Eleven is a branch, not the same shop.
      final seven = receipts.firstWhere((r) => r.merchantName == '7-Eleven');
      expect(merchantMemory(seven, receipts, now), isNull);
      expect(brandMemory(seven, receipts, now)!.records, 1);
    });

    test('Thai traveler in Tokyo: th, THB at home, JPY local, no haggles', () {
      final t = d!.byKey('thaiTokyo')!;
      expect(t.language, 'th');
      expect(t.homeCurrency, 'THB');
      expect(t.localCurrency, 'JPY');
      final saves = t.samplesAt(now);
      expect(saves, isNotEmpty);
      expect(saves.every((s) => s.isSample), isTrue);
      expect(saves.any((s) => s.kind == SaveKind.haggle), isFalse);
      final history = pastPurchasesFromSaves(saves);
      expect(history, isEmpty);
      expect(morningCash(history, now), isNull);
      expect(t.receiptsAt(now), isEmpty);
    });
  });
}
