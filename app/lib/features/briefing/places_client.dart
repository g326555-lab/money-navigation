import 'dart:async';

import 'package:geolocator/geolocator.dart';

import '../../rules/nearby_traps.dart';
import '../../rules/pay_route.dart';
import '../../services/ai/cloud_functions.dart';

/// A calendar place as Google Maps knows it.
class LookedUpPlace {
  const LookedUpPlace({
    required this.name,
    required this.payment,
    this.lat,
    this.lng,
  });

  final String name;
  final PlacePayment payment;
  final double? lat;
  final double? lng;
}

/// Places facts for the briefing, through the project's Places functions.
/// Every failure (signed-out build, no network, slow) returns empty or null,
/// so the screens show only what was really found.
class PlacesClient {
  PlacesClient({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  static const lookupTimeout = Duration(seconds: 4);

  final CloudFunctions _functions;

  /// The app's language, so Google names places in it.
  String? languageCode;
  final Map<String, LookedUpPlace?> _lookups = {};

  /// ATMs and markets around [position] with their payment options.
  Future<List<NearbyPlaceFact>> nearby(Position position) =>
      nearbyAt(position.latitude, position.longitude);

  /// The same around any point (a demo stop, never the real phone).
  Future<List<NearbyPlaceFact>> nearbyAt(double lat, double lng) async {
    if (!CloudFunctions.configured) return const [];
    final results = await Future.wait([
      _nearby(lat, lng, PlaceKind.atm, const ['atm']),
      _nearby(lat, lng, PlaceKind.market, const ['market']),
    ]);
    return [for (final list in results) ...list];
  }

  Future<List<NearbyPlaceFact>> _nearby(
    double lat,
    double lng,
    PlaceKind kind,
    List<String> types,
  ) async {
    try {
      final json = await _functions.call('places-market', {
        'lat': lat,
        'lng': lng,
        'types': types,
        'withPayment': true,
        'languageCode': ?languageCode,
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
              distanceM: _distance(lat, lng, p['lat'], p['lng']),
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
        'languageCode': ?languageCode,
        if (near != null) 'lat': near.latitude,
        if (near != null) 'lng': near.longitude,
      }, timeout: lookupTimeout);
      final place = json['place'];
      final found = place is Map && place['name'] is String
          ? LookedUpPlace(
              name: place['name'] as String,
              payment: paymentFromJson(place['payment']),
              lat: place['lat'] is num
                  ? (place['lat'] as num).toDouble()
                  : null,
              lng: place['lng'] is num
                  ? (place['lng'] as num).toDouble()
                  : null,
            )
          : null;
      return _lookups[key] = found;
    } on CloudFunctionError {
      // Not cached: a later try may reach the network.
      return null;
    }
  }

  static double? _distance(
    double fromLat,
    double fromLng,
    Object? lat,
    Object? lng,
  ) {
    if (lat is! num || lng is! num) return null;
    return Geolocator.distanceBetween(
      fromLat,
      fromLng,
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
  final cards = flag('cards');
  final nfc = flag('nfc');
  // Google sometimes says "cash only" and "takes cards" for the same place
  // (seen for a Bangkok hotel). Conflicting evidence is no evidence.
  if (flag('cashOnly') == true && (cards == true || nfc == true)) {
    return PlacePayment.unknown;
  }
  return PlacePayment(cashOnly: flag('cashOnly'), cards: cards, nfc: nfc);
}
