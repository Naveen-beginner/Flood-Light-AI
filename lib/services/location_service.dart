import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  static Position? currentPosition;
  static String? locationError;

  static Future<void> requestPermissionAndFetchLocation() async {
    try {
      final status = await Permission.locationWhenInUse.request();
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        currentPosition = position;
        locationError = null;
      } else {
        locationError = status.isPermanentlyDenied
            ? 'Location permission permanently denied.'
            : 'Location permission denied.';
      }
    } catch (e) {
      locationError = 'Error fetching location: $e';
    }
  }

  static Future<Position?> fetchPreciseLocation() async {
    try {
      final status = await Permission.locationWhenInUse.status;
      if (status.isGranted) {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        );
        currentPosition = position;
        return position;
      } else {
        await requestPermissionAndFetchLocation();
        return currentPosition;
      }
    } catch (e) {
      locationError = 'Error fetching location: $e';
      return currentPosition;
    }
  }
}
