import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

/// The country the phone is in, from the platform geocoder (free, on the
/// phone's own map service). Null when it cannot tell.
class CountryLocator {
  static const timeout = Duration(seconds: 4);

  /// Created on first use: the platform side is not there in tests.
  Geocoding? _geocoding;

  Future<String?> countryAt(Position position) async {
    try {
      final geocoding = _geocoding ??= Geocoding();
      final marks = await geocoding
          .placemarkFromCoordinates(position.latitude, position.longitude)
          .timeout(timeout);
      for (final m in marks) {
        final code = m.isoCountryCode;
        if (code != null && code.length == 2) return code.toUpperCase();
      }
      return null;
    } on Object {
      return null;
    }
  }
}
