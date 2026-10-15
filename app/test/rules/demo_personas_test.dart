import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/demo_personas.dart';
import 'package:money_navigation/rules/personal_context.dart';
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
      'placeName': 'Or Tor Kor Market',
    },
    {
      'kind': 'haggle',
      'daysAgo': 0,
      'time': '09:05',
      'itemKey': 'coconut',
      'askedThb': 70,
      'paidThb': 70,
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
      expect(keptTotalThb(saves), 120);
    });

    test('visitor memory lines: price memory, counter, morning cash', () {
      final history = pastPurchasesFromSaves(
        d!.byKey('visitorBangkok')!.samplesAt(now),
      );

      final memory = priceMemory('mango', history, now)!;
      expect(memory.lastPaidThb, 90);
      expect(memory.daysAgo, 2);
      expect(memory.recordsUsed, 2);
      expect(memory.sampleRecords, 2);
      expect(memory.lastPlaceName, 'Chatuchak Weekend Market');

      final counter = counterFromHistory('mango', 150, history, now)!;
      expect(counter.offerThb, 95);
      expect(counter.recordsUsed, 2);
      expect(counter.sampleRecords, 2);

      final cash = morningCash(history, now)!;
      expect(cash.amountThb, 200);
      expect(cash.daysUsed, 2);
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
    });
  });
}
