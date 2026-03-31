import 'dart:math';
import 'package:geolocator/geolocator.dart';

class LocationService {
  static double _userLat = -7.7956; // default: Yogyakarta
  static double _userLng = 110.3695;
  static bool _hasRealLocation = false;

  static double get userLat => _userLat;
  static double get userLng => _userLng;
  static bool get hasRealLocation => _hasRealLocation;

  /// Minta izin GPS dan ambil lokasi user. Panggil ini saat app start.
  static Future<void> fetchUserLocation() async {
    try {
      // Cek apakah GPS service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      // Cek & minta permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      // Ambil posisi
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _userLat = position.latitude;
      _userLng = position.longitude;
      _hasRealLocation = true;
    } catch (_) {
      // Tetap pakai default kalau gagal
    }
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
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    return earthRadius * 2 * atan2(sqrt(a), sqrt(1 - a));
  }

  static double _toRadians(double degree) => degree * pi / 180;
}