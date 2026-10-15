import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'ai/ai_trace.dart';
import 'location_service.dart';
import 'ai/cloud_functions.dart';

/// A rated place near the traveler, from Google Maps.
class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.rating,
    required this.ratingCount,
    this.lat,
    this.lng,
  });

  final String name;
  final double rating;
  final int ratingCount;

  /// The place's own location, when the lookup returns it.
  final double? lat;
  final double? lng;
}

/// The busiest rated market near the traveler, with the measured Google Maps
/// step. Shown under the usual price as local evidence.
class PlacesEvidence {
  const PlacesEvidence({
    required this.place,
    required this.trace,
    required this.phoneLat,
    required this.phoneLng,
  });

  final NearbyPlace place;
  final AiTrace trace;

  /// Where the phone was for the lookup.
  final double phoneLat;
  final double phoneLng;

  /// Where a saved record goes on the map: where the phone was. The
  /// busiest market nearby is evidence, not proof of where the haggle was.
  double get lat => phoneLat;
  double get lng => phoneLng;
}

/// Looks up rated markets around the phone through the `places-market`
/// function. Any failure (no location, no network, slow) returns null and
/// the screen simply leaves the line out.
class PlacesService {
  PlacesService({CloudFunctions? functions})
    : _functions = functions ?? CloudFunctions();

  static const locationTimeout = Duration(seconds: 3);
  static const lookupTimeout = Duration(seconds: 3);

  final CloudFunctions _functions;

  Future<PlacesEvidence?> nearbyMarket() async {
    if (!CloudFunctions.configured) return null;
    try {
      final position = await LocationService.current();
      if (position == null) return null;
      final (places, trace) = await AiTrace.measure(
        AiEngine.googleMaps,
        () => _lookup(position),
        count: (List<NearbyPlace> p) =>
            p.fold<int>(0, (sum, x) => sum + x.ratingCount),
      );
      if (places.isEmpty) return null;
      return PlacesEvidence(
        place: places.first,
        trace: trace,
        phoneLat: position.latitude,
        phoneLng: position.longitude,
      );
    } on CloudFunctionError {
      return null;
    } on Exception {
      return null;
    }
  }

  Future<List<NearbyPlace>> _lookup(Position p) async {
    final json = await _functions.call('places-market', {
      'lat': p.latitude,
      'lng': p.longitude,
    }, timeout: lookupTimeout);
    final places = json['places'];
    if (places is! List) return const [];
    return [
      for (final e in places)
        if (e is Map &&
            e['name'] is String &&
            e['rating'] is num &&
            e['ratingCount'] is num)
          NearbyPlace(
            name: e['name'] as String,
            rating: (e['rating'] as num).toDouble(),
            ratingCount: (e['ratingCount'] as num).toInt(),
            lat: e['lat'] is num ? (e['lat'] as num).toDouble() : null,
            lng: e['lng'] is num ? (e['lng'] as num).toDouble() : null,
          ),
    ];
  }
}
