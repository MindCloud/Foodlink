// lib/services/haversine.dart
import 'dart:math';

class Haversine {
  static const double _earthRadiusKm = 6371.0; // Earth's radius in km

  /// Calculates distance in kilometers between two GPS points using Haversine Formula
  static double calculateDistance({
    required double lat1,
    required double lon1,
    required double lat2,
    required double lon2,
  }) {
    final double dLat = _toRadians(lat2 - lat1);
    final double dLon = _toRadians(lon2 - lon1);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return _earthRadiusKm * c; // Distance in km
  }

  static double _toRadians(double degree) {
    return degree * (pi / 180);
  }

  /// Checks if distance is strictly between 8 and 12 km (as per SOW)
  static bool isWithinGeofence(double distanceKm) {
    return distanceKm >= 8.0 && distanceKm <= 12.0;
  }
}