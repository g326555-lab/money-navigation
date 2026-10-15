import 'dart:async';

import 'package:geolocator/geolocator.dart';

import 'ai/ai_trace.dart';
import 'ai/cloud_functions.dart';

/// A rated place near the traveler, from Google Maps.
class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.rating,
    required this.ratingCount,
  });

  final String name;
  final double rating;
  final int ratingCount;
}

/// The busiest rated market near the traveler, with the measured Google Maps
/// step. Shown under the usual price as local evidence.
class PlacesEvidence {
  const PlacesEvidence({required this.place, required this.trace});

  final NearbyPlace place;
  final AiTrace trace;
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
      final position = await _position();
      if (position == null) return null;
      final (places, trace) = await AiTrace.measure(
        AiEngine.googleMaps,
        () => _lookup(position),
        count: (List<NearbyPlace> p) =>
            p.fold<int>(0, (sum, x) => sum + x.ratingCount),
      );
      if (places.isEmpty) return null;
      return PlacesEvidence(place: places.first, trace: trace);
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
          ),
    ];
  }

  /// The phone's position within [locationTimeout], asking for permission
  /// once if it was never asked. Null when off, denied or too slow.
  Future<Position?> _position() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever ||
        permission == LocationPermission.unableToDetermine) {
      return null;
    }
    final last = await Geolocator.getLastKnownPosition();
    if (last != null) return last;
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: locationTimeout,
        ),
      );
    } on TimeoutException {
      return null;
    }
  }
}
