import 'package:geolocator/geolocator.dart';

class LocationService {
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are disabled.
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied.
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null; // Permissions are denied forever.
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    // Spec: "single-shot GPS verification"
    return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
  }

  // Returns distance in meters between two points
  double getDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }

  bool isWithinRadius(double userLat, double userLng, double officeLat, double officeLng, double radius) {
    double distance = getDistance(userLat, userLng, officeLat, officeLng);
    return distance <= radius;
  }
}
