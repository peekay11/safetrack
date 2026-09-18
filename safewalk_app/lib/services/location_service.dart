import 'package:geolocator/geolocator.dart';

/// Johannesburg CBD — used whenever we can't get a real device fix
/// (permission denied, desktop/web debug run, simulator without location).
const double fallbackLat = -26.2041;
const double fallbackLng = 28.0473;

class LocationService {
  static Future<(double lat, double lng)> getCurrent() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return (fallbackLat, fallbackLng);

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return (fallbackLat, fallbackLng);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return (fallbackLat, fallbackLng);
    }
  }
}
