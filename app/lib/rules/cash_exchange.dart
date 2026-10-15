import 'dart:math' as math;

/// One banknote tier as published by a Thai exchange counter.
class ExchangeTier {
  const ExchangeTier({required this.denomination, required this.buyRate});

  final String denomination;
  final double buyRate;
}

class ExchangeShop {
  const ExchangeShop({
    required this.id,
    required this.brand,
    required this.name,
    required this.address,
    required this.city,
    required this.latitude,
    required this.longitude,
    required this.tiersByCurrency,
    required this.sourceFetchedAt,
    required this.sourceHealthy,
  });

  final String id;
  final String brand;
  final String name;
  final String address;
  final String city;
  final double? latitude;
  final double? longitude;
  final Map<String, List<ExchangeTier>> tiersByCurrency;
  final DateTime? sourceFetchedAt;
  final bool sourceHealthy;
}

class ExchangeOffer {
  const ExchangeOffer({
    required this.shop,
    required this.tier,
    required this.distanceMeters,
    required this.foreignAmount,
    required this.thbPayout,
  });

  final ExchangeShop shop;
  final ExchangeTier tier;
  final double distanceMeters;
  final double foreignAmount;
  final double thbPayout;
}

class CashExchangeData {
  const CashExchangeData({
    required this.generatedAt,
    required this.refreshedAt,
    required this.isSnapshotStale,
    required this.shops,
  });

  static const empty = CashExchangeData(
    generatedAt: null,
    refreshedAt: null,
    isSnapshotStale: true,
    shops: [],
  );

  final DateTime? generatedAt;
  final DateTime? refreshedAt;
  final bool isSnapshotStale;
  final List<ExchangeShop> shops;

  /// Parses the `exchange-rates` function response. ThaiRate publishes
  /// `stores` as a list of objects with an `id`; a map keyed by store id is
  /// accepted too, so a source format change cannot silently empty the list.
  factory CashExchangeData.fromResponse(
    Object? response, {
    required DateTime now,
  }) {
    if (response is! Map) return empty;
    final data = response['data'];
    if (data is! Map || data['rates'] is! Map) return empty;
    final rawStores = _storeList(data['stores']);
    if (rawStores == null) return empty;
    final sourceMap = data['sources'] is Map
        ? data['sources'] as Map
        : const {};
    final rateMap = data['rates'] as Map;
    final shops = <ExchangeShop>[];
    for (final rawStore in rawStores) {
      if (rawStore['id'] is! String) continue;
      // Closed counters stay in the feed with their last board; never rank them.
      final status = rawStore['status'];
      if (status is String && status != 'active') continue;
      final id = rawStore['id'] as String;
      final brand = rawStore['brand'] is String
          ? rawStore['brand'] as String
          : '';
      final rawRates = rateMap[id];
      final tiersByCurrency = <String, List<ExchangeTier>>{};
      if (rawRates is Map) {
        for (final entry in rawRates.entries) {
          if (entry.key is! String || entry.value is! Map) continue;
          final currency = (entry.key as String).toUpperCase();
          final rate = entry.value as Map;
          final rawTiers = rate['tiers'];
          final tiers = <ExchangeTier>[];
          if (rawTiers is List) {
            for (final rawTier in rawTiers) {
              if (rawTier is! Map || rawTier['denom'] is! String) continue;
              final buy = rawTier['buy'];
              if (buy is num && buy.isFinite && buy > 0) {
                tiers.add(
                  ExchangeTier(
                    denomination: _denomination(rawTier['denom'] as String),
                    buyRate: buy.toDouble(),
                  ),
                );
              }
            }
          }
          // Older source rows may have only a single tier at the top level.
          if (tiers.isEmpty && rate['denom'] is String && rate['buy'] is num) {
            final buy = rate['buy'] as num;
            if (buy.isFinite && buy > 0) {
              tiers.add(
                ExchangeTier(
                  denomination: _denomination(rate['denom'] as String),
                  buyRate: buy.toDouble(),
                ),
              );
            }
          }
          if (tiers.isNotEmpty) tiersByCurrency[currency] = tiers;
        }
      }
      final rawSource = sourceMap[brand];
      final sourceFetchedAt = rawSource is Map
          ? _date(rawSource['fetchedAt'])
          : null;
      final rawLat = rawStore['lat'];
      final rawLng = rawStore['lng'];
      shops.add(
        ExchangeShop(
          id: id,
          brand: brand,
          name: rawStore['name'] is String ? rawStore['name'] as String : '',
          address: rawStore['address'] is String
              ? rawStore['address'] as String
              : '',
          city: rawStore['city'] is String ? rawStore['city'] as String : '',
          latitude: rawLat is num && rawLat.isFinite ? rawLat.toDouble() : null,
          longitude: rawLng is num && rawLng.isFinite
              ? rawLng.toDouble()
              : null,
          tiersByCurrency: tiersByCurrency,
          sourceFetchedAt: sourceFetchedAt,
          sourceHealthy: rawSource is Map && rawSource['ok'] == true,
        ),
      );
    }
    final generatedAt = _date(data['generatedAt']);
    final refreshedAt = _date(response['refreshedAt']);
    return CashExchangeData(
      generatedAt: generatedAt,
      refreshedAt: refreshedAt,
      isSnapshotStale:
          response['stale'] != false ||
          !isExchangeTimeFresh(
            generatedAt,
            now,
            exchangeRatesSourceFreshness,
          ) ||
          !isExchangeTimeFresh(
            refreshedAt,
            now,
            exchangeRatesSnapshotFreshness,
          ),
      shops: shops,
    );
  }

  /// Foreign currencies that at least one live, healthy source can quote at
  /// [now]. Empty when the snapshot is stale or every source has gone stale.
  Set<String> currencies(DateTime now) {
    if (isSnapshotStale) return const {};
    return {
      for (final shop in shops)
        if (_sourceIsFresh(shop, now))
          ...shop.tiersByCurrency.keys.where(
            (currency) => currency != exchangeWalletCurrency,
          ),
    };
  }

  /// Banknote tiers quoted for [currency] by live sources, largest first.
  List<String> denominations(String currency, DateTime now) {
    if (isSnapshotStale) return const [];
    return <String>{
      for (final shop in shops)
        if (_sourceIsFresh(shop, now))
          for (final tier
              in shop.tiersByCurrency[currency.toUpperCase()] ?? const [])
            tier.denomination,
    }.toList()..sort(_compareDenominations);
  }
}

/// The currency exchange counters pay out: the published boards are Thai.
const exchangeWalletCurrency = 'THB';

/// How old a shop's board may be when ranked. ThaiRate polls each provider
/// on its own cycle; on 16 Oct 2026 the published `fetchedAt` values were
/// 12 to 48 minutes older than the feed's `generatedAt`, and our cache adds
/// up to one 15-minute refresh cycle on top. Each row still shows its time.
const exchangeRatesSourceFreshness = Duration(minutes: 60);

/// How old our server copy may be: two missed 15-minute refreshes.
const exchangeRatesSnapshotFreshness = Duration(minutes: 30);

/// Server and phone clocks may disagree slightly. A timestamp up to this far
/// in the future still counts as fresh; further ahead means a bad clock.
const exchangeClockSkewTolerance = Duration(minutes: 2);

const exchangeNearbyRadiusMeters = 15000.0;

/// True when [at] is no older than [maxAge] at [now], allowing small clock
/// skew in the future direction.
bool isExchangeTimeFresh(DateTime? at, DateTime now, Duration maxAge) {
  if (at == null) return false;
  final age = now.difference(at);
  return age >= -exchangeClockSkewTolerance && age <= maxAge;
}

/// Providers space the same tier differently ("20 - 10" and "20-10").
/// Only whitespace is removed; different tiers are never merged.
String _denomination(String raw) => raw.replaceAll(RegExp(r'\s+'), '');

List<Map>? _storeList(Object? stores) {
  if (stores is List) return stores.whereType<Map>().toList();
  if (stores is Map) {
    return [
      for (final entry in stores.entries)
        if (entry.value is Map)
          {if (entry.key is String) 'id': entry.key, ...(entry.value as Map)},
    ];
  }
  return null;
}

/// Compares only live, healthy source rows with the exact same banknote tier.
/// The ThaiRate API publishes tiers as ranges, so silently mixing different
/// tiers would produce a false payout comparison.
List<ExchangeOffer> nearbyCashExchangeOffers({
  required CashExchangeData data,
  required double latitude,
  required double longitude,
  required String currency,
  required String denomination,
  required double foreignAmount,
  required DateTime now,
  double radiusMeters = exchangeNearbyRadiusMeters,
}) {
  if (data.isSnapshotStale ||
      !latitude.isFinite ||
      !longitude.isFinite ||
      !foreignAmount.isFinite ||
      foreignAmount <= 0 ||
      radiusMeters <= 0) {
    return const [];
  }
  final offers = <ExchangeOffer>[];
  for (final shop in data.shops) {
    final lat = shop.latitude;
    final lng = shop.longitude;
    if (!_sourceIsFresh(shop, now) || lat == null || lng == null) continue;
    final distance = _distanceMeters(latitude, longitude, lat, lng);
    if (distance > radiusMeters) continue;
    final tier = (shop.tiersByCurrency[currency.toUpperCase()] ?? const [])
        .where((candidate) => candidate.denomination == denomination)
        .firstOrNull;
    if (tier == null) continue;
    offers.add(
      ExchangeOffer(
        shop: shop,
        tier: tier,
        distanceMeters: distance,
        foreignAmount: foreignAmount,
        thbPayout: foreignAmount * tier.buyRate,
      ),
    );
  }
  offers.sort((a, b) {
    final byPayout = b.thbPayout.compareTo(a.thbPayout);
    return byPayout != 0
        ? byPayout
        : a.distanceMeters.compareTo(b.distanceMeters);
  });
  return offers;
}

bool _sourceIsFresh(ExchangeShop shop, DateTime now) =>
    shop.sourceHealthy &&
    isExchangeTimeFresh(
      shop.sourceFetchedAt,
      now,
      exchangeRatesSourceFreshness,
    );

double _distanceMeters(double lat1, double lng1, double lat2, double lng2) {
  const earthRadius = 6371000.0;
  final dLat = _radians(lat2 - lat1);
  final dLng = _radians(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_radians(lat1)) *
          math.cos(_radians(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * earthRadius * math.atan2(math.sqrt(a), math.sqrt(1 - a));
}

double _radians(double value) => value * math.pi / 180;

DateTime? _date(Object? value) =>
    value is String ? DateTime.tryParse(value)?.toLocal() : null;

int _compareDenominations(String a, String b) {
  double highest(String value) {
    final numbers = RegExp(r'\d+(?:\.\d+)?')
        .allMatches(value)
        .map((match) => double.tryParse(match.group(0)!) ?? 0);
    return numbers.fold<double>(0, math.max);
  }

  return highest(b).compareTo(highest(a));
}

/// The foreign cash amount typed by the traveler, or null unless it is a
/// positive finite number. Thousands separators are allowed.
double? parseExchangeAmount(String text) {
  final value = double.tryParse(text.replaceAll(',', '').trim());
  return value != null && value.isFinite && value > 0 ? value : null;
}
