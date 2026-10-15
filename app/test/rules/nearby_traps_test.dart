import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/nearby_traps.dart';
import 'package:money_navigation/rules/pay_facts.dart';
import 'package:money_navigation/rules/pay_route.dart';

final SourcedFee thAtmFee = SourcedFee(
  value: 220,
  currency: 'THB',
  isPercent: false,
  source: 'Bangkok Bank fee schedule',
  checked: '2026-10-15',
);

final CountryPayFacts thFacts = CountryPayFacts(
  country: 'TH',
  currency: 'THB',
  foreignCardAtmFee: thAtmFee,
  atmOffersConversion: true,
);

NearbyPlaceFact place(
  String name,
  PlaceKind kind,
  double? distanceM, {
  PlacePayment payment = PlacePayment.unknown,
}) => NearbyPlaceFact(
  name: name,
  kind: kind,
  payment: payment,
  distanceM: distanceM,
);

final NearbyPlaceFact atm120 = place('ATM Silom 120', PlaceKind.atm, 120);
final NearbyPlaceFact cashMarket400 = place(
  'Soi 20 Market',
  PlaceKind.market,
  400,
  payment: const PlacePayment(cashOnly: true),
);
final NearbyPlaceFact unknownMarket = place(
  'Night Bazaar',
  PlaceKind.market,
  250,
);

void main() {
  group('TH facts, ATM 120 m, cash-only market 400 m, unknown market', () {
    late List<TrapWarning> traps;
    setUp(
      () =>
          traps = nearbyTraps([cashMarket400, unknownMarket, atm120], thFacts),
    );

    test('three warnings: atmFee, atmConversion, cashOnlyMarket', () {
      expect(
        [for (final t in traps) t.kind],
        [TrapKind.atmFee, TrapKind.atmConversion, TrapKind.cashOnlyMarket],
      );
    });

    test('atmFee carries the 220 THB fee with its source and date', () {
      final t = traps[0];
      expect(t.placeName, 'ATM Silom 120');
      expect(t.distanceM, 120);
      expect(t.fee, isNotNull);
      expect(t.fee!.value, 220);
      expect(t.fee!.currency, 'THB');
      expect(t.source, 'Bangkok Bank fee schedule');
      expect(t.checked, '2026-10-15');
    });

    test('atmConversion is for the same ATM and has no fee', () {
      final t = traps[1];
      expect(t.placeName, 'ATM Silom 120');
      expect(t.distanceM, 120);
      expect(t.fee, isNull);
    });

    test('cash-only market comes from Google Maps, no checked date', () {
      final t = traps[2];
      expect(t.placeName, 'Soi 20 Market');
      expect(t.distanceM, 400);
      expect(t.fee, isNull);
      expect(t.source, 'Google Maps');
      expect(t.checked, isNull);
    });

    test('market without cash-only evidence gives no warning', () {
      expect(traps.where((t) => t.placeName == 'Night Bazaar'), isEmpty);
    });
  });

  group('atmConversion source', () {
    test('without a conversion source it falls back to Google Maps', () {
      final t = nearbyTraps([
        atm120,
      ], thFacts).firstWhere((t) => t.kind == TrapKind.atmConversion);
      expect(t.source, 'Google Maps');
      expect(t.source, googleMapsSource);
      expect(t.checked, isNull);
    });

    test('carries the facts file conversion source and checked date', () {
      final facts = CountryPayFacts(
        country: 'JP',
        currency: 'JPY',
        atmOffersConversion: true,
        atmConversionSource: 'Seven Bank international card service',
        atmConversionChecked: '2026-10-15',
      );
      final traps = nearbyTraps([atm120], facts);
      expect([for (final t in traps) t.kind], [TrapKind.atmConversion]);
      expect(traps.single.source, 'Seven Bank international card service');
      expect(traps.single.checked, '2026-10-15');
      expect(traps.single.fee, isNull);
    });

    test('source without a checked date keeps checked null', () {
      final facts = CountryPayFacts(
        country: 'JP',
        currency: 'JPY',
        atmOffersConversion: true,
        atmConversionSource: 'Seven Bank international card service',
      );
      final t = nearbyTraps([atm120], facts).single;
      expect(t.source, 'Seven Bank international card service');
      expect(t.checked, isNull);
    });

    test('the fee warning keeps its own source next to the conversion one', () {
      final facts = CountryPayFacts(
        country: 'TH',
        currency: 'THB',
        foreignCardAtmFee: thAtmFee,
        atmOffersConversion: true,
        atmConversionSource: 'Portail Asie',
        atmConversionChecked: '2026-10-14',
      );
      final traps = nearbyTraps([atm120], facts);
      expect(traps[0].kind, TrapKind.atmFee);
      expect(traps[0].source, 'Bangkok Bank fee schedule');
      expect(traps[0].checked, '2026-10-15');
      expect(traps[1].kind, TrapKind.atmConversion);
      expect(traps[1].source, 'Portail Asie');
      expect(traps[1].checked, '2026-10-14');
    });
  });

  group('limit', () {
    test('limit 2 keeps the first two', () {
      final traps = nearbyTraps(
        [cashMarket400, unknownMarket, atm120],
        thFacts,
        limit: 2,
      );
      expect(
        [for (final t in traps) t.kind],
        [TrapKind.atmFee, TrapKind.atmConversion],
      );
    });

    test('default limit is 3', () {
      final traps = nearbyTraps([
        atm120,
        cashMarket400,
        place(
          'Market B',
          PlaceKind.market,
          500,
          payment: const PlacePayment(cashOnly: true),
        ),
      ], thFacts);
      expect(traps.length, 3);
      expect(traps.last.placeName, 'Soi 20 Market');
    });
  });

  group('missing evidence', () {
    test('no facts: only the cash-only market', () {
      final traps = nearbyTraps([cashMarket400, unknownMarket, atm120], null);
      expect([for (final t in traps) t.kind], [TrapKind.cashOnlyMarket]);
      expect(traps.single.placeName, 'Soi 20 Market');
    });

    test('empty list gives no warnings', () {
      expect(nearbyTraps(const [], thFacts), isEmpty);
    });

    test('facts without a sourced fee: conversion warning only', () {
      final traps = nearbyTraps(
        [atm120],
        CountryPayFacts(
          country: 'TH',
          currency: 'THB',
          foreignCardAtmFee: null,
          atmOffersConversion: true,
        ),
      );
      expect([for (final t in traps) t.kind], [TrapKind.atmConversion]);
    });

    test('ATMs that do not offer conversion: fee warning only', () {
      final traps = nearbyTraps(
        [atm120],
        CountryPayFacts(
          country: 'JP',
          currency: 'JPY',
          foreignCardAtmFee: SourcedFee(
            value: 110,
            currency: 'JPY',
            isPercent: false,
            source: 'Seven Bank fee schedule',
            checked: '2026-10-14',
          ),
          atmOffersConversion: false,
        ),
      );
      expect([for (final t in traps) t.kind], [TrapKind.atmFee]);
      expect(traps.single.fee!.value, 110);
      expect(traps.single.source, 'Seven Bank fee schedule');
    });

    test('facts but no ATM nearby: no ATM warnings', () {
      final traps = nearbyTraps([cashMarket400], thFacts);
      expect([for (final t in traps) t.kind], [TrapKind.cashOnlyMarket]);
    });

    test('cashOnly false market and cash-only non-market give nothing', () {
      final traps = nearbyTraps([
        place(
          'Card Market',
          PlaceKind.market,
          100,
          payment: const PlacePayment(cashOnly: false),
        ),
        place(
          'Noodle Shop',
          PlaceKind.other,
          50,
          payment: const PlacePayment(cashOnly: true),
        ),
      ], null);
      expect(traps, isEmpty);
    });
  });

  group('which ATM and order of markets', () {
    test('only the nearest ATM is warned about', () {
      final traps = nearbyTraps([
        place('ATM Far', PlaceKind.atm, 300),
        atm120,
      ], thFacts);
      expect(traps.length, 2);
      expect(traps.every((t) => t.placeName == 'ATM Silom 120'), isTrue);
    });

    test('ATM with unknown distance sorts last', () {
      final traps = nearbyTraps([
        place('ATM Unknown', PlaceKind.atm, null),
        place('ATM Far', PlaceKind.atm, 300),
      ], thFacts);
      expect(traps.first.placeName, 'ATM Far');
    });

    test('only ATMs with unknown distance: first one, distance null', () {
      final traps = nearbyTraps([
        place('ATM One', PlaceKind.atm, null),
        place('ATM Two', PlaceKind.atm, null),
      ], thFacts);
      expect(traps.first.placeName, 'ATM One');
      expect(traps.first.distanceM, isNull);
    });

    test('ties keep input order', () {
      final traps = nearbyTraps([
        place('ATM A', PlaceKind.atm, 200),
        place('ATM B', PlaceKind.atm, 200),
      ], thFacts);
      expect(traps.first.placeName, 'ATM A');
    });

    test('cash-only markets by distance, unknown distance last', () {
      final traps = nearbyTraps(
        [
          place(
            'Market Far',
            PlaceKind.market,
            900,
            payment: const PlacePayment(cashOnly: true),
          ),
          place(
            'Market Unknown',
            PlaceKind.market,
            null,
            payment: const PlacePayment(cashOnly: true),
          ),
          place(
            'Market Near',
            PlaceKind.market,
            150,
            payment: const PlacePayment(cashOnly: true),
          ),
        ],
        null,
        limit: 10,
      );
      expect(
        [for (final t in traps) t.placeName],
        ['Market Near', 'Market Far', 'Market Unknown'],
      );
    });

    test('ATM warnings come first even when a market is nearer', () {
      final traps = nearbyTraps([
        place(
          'Market Close',
          PlaceKind.market,
          20,
          payment: const PlacePayment(cashOnly: true),
        ),
        atm120,
      ], thFacts);
      expect(
        [for (final t in traps) t.kind],
        [TrapKind.atmFee, TrapKind.atmConversion, TrapKind.cashOnlyMarket],
      );
    });
  });
}
