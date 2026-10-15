import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:money_navigation/rules/cash_exchange.dart';

/// A trimmed copy of https://api.thairate.com/v1/rates.json captured on
/// 16 Oct 2026 (CC BY 4.0, ThaiRate): seven real stores, four currencies.
Map<String, Object?> capturedFeed() => jsonDecode(
  File('test/rules/fixtures/thairate_rates_2026-10-16.json').readAsStringSync(),
) as Map<String, Object?>;

void main() {
  final now = DateTime.utc(2026, 10, 16, 4);

  Map<String, Object?> source(Duration age, {bool ok = true}) => {
    'ok': ok,
    'fetchedAt': now.subtract(age).toIso8601String(),
  };

  Map<String, Object?> store(
    String id,
    String brand, {
    double lat = 13.0,
    double? lng = 100.0,
    String? status,
  }) => {
    'id': id,
    'brand': brand,
    'name': id,
    'address': id,
    'city': 'bangkok',
    'lat': lat,
    'lng': lng,
    'status': ?status,
  };

  Map<String, Object?> usd(double buy, {String denom = '100-50'}) => {
    'USD': {
      'buy': buy,
      'tiers': [
        {'denom': denom, 'buy': buy},
      ],
    },
  };

  Map<String, Object?> response({
    bool stale = false,
    DateTime? refreshedAt,
    Map<String, Object?>? sources,
    List<Object?>? stores,
    Map<String, Object?>? rates,
  }) => {
    'refreshedAt': (refreshedAt ?? now).toIso8601String(),
    'stale': stale,
    'data': {
      'generatedAt': now.toIso8601String(),
      'sources':
          sources ??
          {
            'green': source(const Duration(minutes: 5)),
            'orange': source(const Duration(minutes: 8)),
          },
      'stores':
          stores ??
          [store('Green A', 'green'), store('Orange B', 'orange', lat: 13.001)],
      'rates': rates ?? {'Green A': usd(33.0), 'Orange B': usd(33.5)},
    },
  };

  List<ExchangeOffer> offers(
    CashExchangeData data, {
    String currency = 'USD',
    String denomination = '100-50',
    double amount = 100,
    double latitude = 13,
    double longitude = 100,
    double radiusMeters = exchangeNearbyRadiusMeters,
    DateTime? at,
  }) => nearbyCashExchangeOffers(
    data: data,
    latitude: latitude,
    longitude: longitude,
    currency: currency,
    denomination: denomination,
    foreignAmount: amount,
    now: at ?? now,
    radiusMeters: radiusMeters,
  );

  List<String> names(List<ExchangeOffer> list) =>
      list.map((offer) => offer.shop.name).toList();

  test('parses published shop currencies and banknote tiers', () {
    final data = CashExchangeData.fromResponse(response(), now: now);

    expect(data.isSnapshotStale, isFalse);
    expect(data.currencies(now), {'USD'});
    expect(data.denominations('USD', now), ['100-50']);
    expect(data.shops.first.tiersByCurrency['USD']!.first.buyRate, 33);
    expect(data.generatedAt!.isAtSameMomentAs(now), isTrue);
  });

  test('ranks fresh nearby shops by actual payout for the same note tier', () {
    final data = CashExchangeData.fromResponse(response(), now: now);
    final ranked = offers(data);

    expect(names(ranked), ['Orange B', 'Green A']);
    expect(ranked.first.thbPayout, 3350);
    expect(ranked.last.distanceMeters, 0);
  });

  group('omits one kind of unusable quote at a time', () {
    final baseSources = {
      'green': source(const Duration(minutes: 5)),
      'orange': source(const Duration(minutes: 8)),
    };
    final baseStores = [
      store('Green A', 'green'),
      store('Orange B', 'orange', lat: 13.001),
    ];
    final baseRates = {'Green A': usd(33.0), 'Orange B': usd(33.5)};

    List<String> rankedWith({
      Map<String, Object?> sources = const {},
      List<Object?> stores = const [],
      Map<String, Object?> rates = const {},
    }) => names(
      offers(
        CashExchangeData.fromResponse(
          response(
            sources: {...baseSources, ...sources},
            stores: [...baseStores, ...stores],
            rates: {...baseRates, ...rates},
          ),
          now: now,
        ),
      ),
    );

    test('a stale source', () {
      expect(
        rankedWith(
          sources: {'old': source(const Duration(minutes: 61))},
          stores: [store('Old', 'old')],
          rates: {'Old': usd(40)},
        ),
        ['Orange B', 'Green A'],
      );
    });

    test('an unhealthy source', () {
      expect(
        rankedWith(
          sources: {'down': source(const Duration(minutes: 1), ok: false)},
          stores: [store('Down', 'down')],
          rates: {'Down': usd(40)},
        ),
        ['Orange B', 'Green A'],
      );
    });

    test('a shop outside the radius', () {
      expect(
        rankedWith(
          stores: [store('Far', 'green', lat: 14.0)],
          rates: {'Far': usd(40)},
        ),
        ['Orange B', 'Green A'],
      );
    });

    test('a different banknote tier', () {
      expect(
        rankedWith(
          stores: [store('Small notes', 'green')],
          rates: {'Small notes': usd(40, denom: '20-5')},
        ),
        ['Orange B', 'Green A'],
      );
    });

    test('a closed shop', () {
      expect(
        rankedWith(
          stores: [store('Closed', 'green', status: 'closed')],
          rates: {'Closed': usd(40)},
        ),
        ['Orange B', 'Green A'],
      );
    });

    test('a shop without coordinates', () {
      expect(
        rankedWith(
          stores: [store('Nowhere', 'green', lng: null)],
          rates: {'Nowhere': usd(40)},
        ),
        ['Orange B', 'Green A'],
      );
    });
  });

  test('includes a shop exactly on the radius and drops it just inside', () {
    final data = CashExchangeData.fromResponse(response(), now: now);
    final orangeDistance = offers(data).first.distanceMeters;

    expect(names(offers(data, radiusMeters: orangeDistance)), [
      'Orange B',
      'Green A',
    ]);
    expect(names(offers(data, radiusMeters: orangeDistance - 1)), ['Green A']);
  });

  test('equal payouts are ordered by distance', () {
    final data = CashExchangeData.fromResponse(
      response(
        stores: [
          store('Far', 'green', lat: 13.01),
          store('Near', 'orange', lat: 13.001),
        ],
        rates: {'Far': usd(33.5), 'Near': usd(33.5)},
      ),
      now: now,
    );
    expect(names(offers(data)), ['Near', 'Far']);
  });

  test('a row with only a top-level tier is still compared', () {
    final data = CashExchangeData.fromResponse(
      response(
        rates: {
          'Green A': {
            'USD': {'buy': 33.4, 'denom': '100'},
          },
          'Orange B': usd(33.5),
        },
      ),
      now: now,
    );
    expect(data.denominations('USD', now), ['100', '100-50']);
    expect(offers(data, denomination: '100').single.thbPayout, 3340);
  });

  test('a fresh snapshot whose sources all went stale offers nothing', () {
    final data = CashExchangeData.fromResponse(
      response(
        sources: {
          'green': source(const Duration(minutes: 70)),
          'orange': source(const Duration(minutes: 90)),
        },
      ),
      now: now,
    );
    expect(data.isSnapshotStale, isFalse);
    expect(data.currencies(now), isEmpty);
    expect(data.denominations('USD', now), isEmpty);
    expect(offers(data), isEmpty);
  });

  test('freshness is evaluated at the time passed in', () {
    final data = CashExchangeData.fromResponse(response(), now: now);
    final later = now.add(const Duration(minutes: 54));
    // Green was 5 min old and Orange 8 min old at [now].
    expect(names(offers(data, at: later)), ['Green A']);
    expect(data.currencies(now.add(const Duration(minutes: 56))), isEmpty);
  });

  test('tolerates small clock skew but not a clock far ahead', () {
    final slightlyAhead = CashExchangeData.fromResponse(
      response(
        refreshedAt: now.add(const Duration(minutes: 1)),
        sources: {
          'green': source(const Duration(minutes: -1)),
          'orange': source(const Duration(minutes: -5)),
        },
      ),
      now: now,
    );
    expect(slightlyAhead.isSnapshotStale, isFalse);
    expect(names(offers(slightlyAhead)), ['Green A']);

    final farAhead = CashExchangeData.fromResponse(
      response(refreshedAt: now.add(const Duration(minutes: 5))),
      now: now,
    );
    expect(farAhead.isSnapshotStale, isTrue);
  });

  test('does not rank a stale snapshot', () {
    final data = CashExchangeData.fromResponse(response(stale: true), now: now);
    expect(data.currencies(now), isEmpty);
    expect(offers(data), isEmpty);
  });

  test('a cached copy older than the snapshot limit is stale', () {
    final data = CashExchangeData.fromResponse(
      response(
        refreshedAt: now.subtract(
          exchangeRatesSnapshotFreshness + const Duration(minutes: 1),
        ),
      ),
      now: now,
    );
    expect(data.isSnapshotStale, isTrue);
  });

  test('malformed responses produce no rates', () {
    expect(CashExchangeData.fromResponse(null, now: now).shops, isEmpty);
    expect(
      CashExchangeData.fromResponse({'data': {}}, now: now).shops,
      isEmpty,
    );
    expect(
      CashExchangeData.fromResponse({
        'data': {'stores': 'x', 'rates': {}},
      }, now: now).shops,
      isEmpty,
    );
  });

  test('accepts stores keyed by id as well as a list', () {
    final raw = response();
    final data = raw['data']! as Map<String, Object?>;
    data['stores'] = {
      for (final s in data['stores']! as List)
        (s as Map)['id']: {...s}..remove('id'),
    };
    final parsed = CashExchangeData.fromResponse(raw, now: now);
    expect(names(offers(parsed)), ['Orange B', 'Green A']);
  });

  group('captured ThaiRate feed', () {
    final feed = capturedFeed();
    final generatedAt = DateTime.parse(feed['generatedAt']! as String);
    final at = generatedAt.add(const Duration(minutes: 1));
    final data = CashExchangeData.fromResponse({
      'data': feed,
      'refreshedAt': at.toIso8601String(),
      'stale': false,
    }, now: at);
    // CentralWorld, Bangkok.
    const lat = 13.746775;
    const lng = 100.539112;

    test('parses the live list shape and skips the closed store', () {
      expect(data.isSnapshotStale, isFalse);
      expect(data.shops.map((shop) => shop.id), isNot(contains('tt-12')));
      expect(data.shops, hasLength(6));
      expect(data.currencies(at), {'USD', 'EUR', 'JPY', 'KRW'});
    });

    test('ranks USD 100-50 notes near CentralWorld', () {
      final ranked = offers(data, latitude: lat, longitude: lng, at: at);
      expect(ranked.map((offer) => offer.shop.id), [
        'vp-centralworld',
        'vp-emquartier',
        'spr-50',
        'spr-27',
      ]);
      expect(ranked.first.thbPayout, closeTo(3336, 1e-9));
      expect(ranked.first.distanceMeters, 0);
    });

    test('treats "20 - 10" and "20-10" as the same tier', () {
      expect(data.denominations('USD', at), contains('20-10'));
      expect(data.denominations('USD', at), isNot(contains('20 - 10')));
      final ranked = offers(
        data,
        denomination: '20-10',
        latitude: lat,
        longitude: lng,
        at: at,
      );
      expect(ranked.map((offer) => offer.shop.brand).toSet(), {
        'srt',
        'vp',
        'spr',
      });
    });

    test('pays yen per single note unit', () {
      final ranked = offers(
        data,
        currency: 'JPY',
        denomination: '10000-1000',
        amount: 10000,
        latitude: lat,
        longitude: lng,
        at: at,
      );
      expect(ranked.map((offer) => offer.shop.id), ['spr-50', 'spr-27']);
      expect(ranked.first.thbPayout, closeTo(2115, 1e-9));
    });
  });

  test('an amount must be a positive number', () {
    expect(parseExchangeAmount('1,000'), 1000);
    expect(parseExchangeAmount(' 20.5 '), 20.5);
    expect(parseExchangeAmount('0'), isNull);
    expect(parseExchangeAmount('0.00'), isNull);
    expect(parseExchangeAmount(''), isNull);
    expect(parseExchangeAmount('.'), isNull);
  });
}
