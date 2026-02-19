import 'dart:math';

class LocationService {
  // Simulated user location (Yogyakarta city center)
  static double _userLat = -7.7956;
  static double _userLng = 110.3695;

  static double get userLat => _userLat;
  static double get userLng => _userLng;

  static void setUserLocation(double lat, double lng) {
    _userLat = lat;
    _userLng = lng;
  }

  static double getDistanceFromMerapi() {
    return _calculateDistance(_userLat, _userLng, -7.5407, 110.4457);
  }

  static String getDistanceLabel() {
    final distance = getDistanceFromMerapi();
    return '${distance.toStringAsFixed(1)} km dari puncak Merapi';
  }

  static String getZoneLabel() {
    final distance = getDistanceFromMerapi();
    if (distance <= 5) return 'ZONA BAHAYA UTAMA';
    if (distance <= 10) return 'ZONA WASPADA';
    if (distance <= 15) return 'ZONA PERHATIAN';
    return 'ZONA RELATIF AMAN';
  }

  static int getZoneLevel() {
    final distance = getDistanceFromMerapi();
    if (distance <= 5) return 4;
    if (distance <= 10) return 3;
    if (distance <= 15) return 2;
    return 1;
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;
}
