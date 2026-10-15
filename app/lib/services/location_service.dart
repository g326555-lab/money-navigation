import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Where the phone is, for records that belong on the trip map and for
/// nearby lookups. Asks for permission once; returns null when location is
/// off, refused or too slow, and the caller simply goes without.
abstract final class LocationService {
  static const timeout = Duration(seconds: 3);

  static Future<Position?> current() async {
    try {
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
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: timeout,
        ),
      );
    } on TimeoutException {
      return null;
    } on Exception {
      return null;
    }
  }
}
