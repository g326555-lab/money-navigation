import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// Where the phone is, for nearby warnings and the arrival alert.
enum LocationState { unknown, off, denied, found }

class PhoneLocation {
  static const timeout = Duration(seconds: 4);

  LocationState state = LocationState.unknown;
  Position? position;

  /// Reads the position, asking for permission only when [ask] is set (the
  /// traveler tapped something that needs it). Never throws.
  Future<Position?> read({bool ask = false}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        state = LocationState.off;
        return null;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && ask) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever ||
          permission == LocationPermission.unableToDetermine) {
        state = LocationState.denied;
        return null;
      }
      final found =
          await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: timeout,
            ),
          );
      position = found;
      state = LocationState.found;
      return found;
    } on TimeoutException {
      state = LocationState.unknown;
      return null;
    } on Exception {
      state = LocationState.unknown;
      return null;
    }
  }

  /// True when the system will not show the permission prompt again.
  Future<bool> deniedForever() async {
    try {
      return await Geolocator.checkPermission() ==
          LocationPermission.deniedForever;
    } on Exception {
      return false;
    }
  }
}
