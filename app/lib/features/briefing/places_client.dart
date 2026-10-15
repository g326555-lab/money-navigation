import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../rules/nearby_traps.dart';
import '../../rules/pay_route.dart';
import '../../services/ai/cloud_functions.dart';

/// A calendar place as Google Maps knows it.
class LookedUpPlace {
  const LookedUpPlace({required this.name, required this.payment});

  final String name;
  final PlacePayment payment;
}

/// Places facts for the briefing, through the project's Places functions.
/// Every failure (signed-out build, no network, slow) returns empty or null,
/// so the screens show only what was really found.
class PlacesClient {
  PlacesClient({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  static const lookupTimeout = Duration(seconds: 4);

  final CloudFunctions _functions;
  final Map<String, LookedUpPlace?> _lookups = {};

  /// ATMs and markets around [position] with their payment options.
  Future<List<NearbyPlaceFact>> nearby(Position position) async {
    if (!CloudFunctions.configured) return const [];
    final results = await Future.wait([
      _nearby(position, PlaceKind.atm, const ['atm']),
      _nearby(position, PlaceKind.market, const ['market']),
    ]);
    return [for (final list in results) ...list];
  }

  Future<List<NearbyPlaceFact>> _nearby(
    Position position,
    PlaceKind kind,
    List<String> types,
  ) async {
    try {
      final json = await _functions.call('places-market', {
        'lat': position.latitude,
        'lng': position.longitude,
        'types': types,
        'withPayment': true,
      }, timeout: lookupTimeout);
      final places = json['places'];
      if (places is! List) return const [];
      return [
        for (final p in places)
          if (p is Map &&
              p['name'] is String &&
              (p['name'] as String).isNotEmpty)
            NearbyPlaceFact(
              name: p['name'] as String,
              kind: kind,
              payment: paymentFromJson(p['payment']),
              distanceM: _distance(position, p['lat'], p['lng']),
            ),
      ];
    } on CloudFunctionError {
      return const [];
    }
  }

  /// The place Google Maps finds for a calendar [location], cached per text.
  Future<LookedUpPlace?> lookup(String location, {Position? near}) async {
    final key = location.trim().toLowerCase();
    if (key.isEmpty || !CloudFunctions.configured) return null;
    if (_lookups.containsKey(key)) return _lookups[key];
    try {
      final json = await _functions.call('places-lookup', {
        'query': location.trim(),
        if (near != null) 'lat': near.latitude,
        if (near != null) 'lng': near.longitude,
      }, timeout: lookupTimeout);
      final place = json['place'];
      final found = place is Map && place['name'] is String
          ? LookedUpPlace(
              name: place['name'] as String,
              payment: paymentFromJson(place['payment']),
            )
          : null;
      return _lookups[key] = found;
    } on CloudFunctionError {
      // Not cached: a later try may reach the network.
      return null;
    }
  }

  static double? _distance(Position from, Object? lat, Object? lng) {
    if (lat is! num || lng is! num) return null;
    return Geolocator.distanceBetween(
      from.latitude,
      from.longitude,
      lat.toDouble(),
      lng.toDouble(),
    );
  }
}

/// Google's payment options as the function returns them; anything not a
/// boolean stays unknown.
PlacePayment paymentFromJson(Object? json) {
  if (json is! Map) return PlacePayment.unknown;
  bool? flag(String key) => json[key] is bool ? json[key] as bool : null;
  return PlacePayment(
    cashOnly: flag('cashOnly'),
    cards: flag('cards'),
    nfc: flag('nfc'),
  );
}
