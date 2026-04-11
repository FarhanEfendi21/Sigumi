import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service untuk lokasi GPS real-time dan integrasi PostGIS Supabase.
///
/// Menangani:
/// - Request permission GPS
/// - Tracking lokasi real-time
/// - Deteksi daerah otomatis berdasarkan GPS
/// - Update lokasi ke Supabase RPC (menghitung zona risiko di database)
/// - Fallback ke lokasi simulasi jika GPS tidak tersedia
class LocationService extends ChangeNotifier {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ── Definisi daerah cakupan ──
  // Radius ~40km dari puncak gunung (area sekitar gunung saja)
  static const double _detectionRadiusKm = 40.0;

  static const Map<String, Map<String, double>> regionCenters = {
    'Yogyakarta': {'lat': -7.5407, 'lng': 110.4457}, // Merapi
    'Bali':       {'lat': -8.3433, 'lng': 115.5071}, // Agung
    'Lombok':     {'lat': -8.4111, 'lng': 116.4573}, // Rinjani
  };

  // ── State lokasi ──
  double _userLat = -7.7956;  // Default: Yogyakarta
  double _userLng = 110.3695;
  bool _isUsingRealGps = false;
  bool _isTracking = false;
  String? _locationError;
  DateTime? _lastUpdated;

  // ── Deteksi daerah otomatis ──
  String? _detectedRegion;        // Daerah yang terdeteksi GPS (null = di luar)
  bool _isRegionAutoDetected = false;

  // ── Gunung berapi aktif (target jarak) ──
  double _activeVolcanoLat = -7.5407;  // Default: Merapi
  double _activeVolcanoLng = 110.4457;
  String _activeVolcanoName = 'Gunung Merapi';

  // ── Nearest volcano risk info (dari Supabase RPC) ──
  String? _nearestVolcanoId;
  String _nearestVolcanoName = 'Gunung Merapi';
  double _distanceFromVolcano = 0;
  int _zoneLevel = 1;
  String _zoneLabel = 'ZONA RELATIF AMAN';
  int _volcanoStatusLevel = 1;

  // ── Stream subscription ──
  StreamSubscription<Position>? _positionStream;

  // ── Getters ──
  double get userLat => _userLat;
  double get userLng => _userLng;
  bool get isUsingRealGps => _isUsingRealGps;
  bool get isTracking => _isTracking;
  String? get locationError => _locationError;
  DateTime? get lastUpdated => _lastUpdated;

  String? get nearestVolcanoId => _nearestVolcanoId;
  String get nearestVolcanoName => _nearestVolcanoName;
  double get distanceFromVolcano => _distanceFromVolcano;
  int get zoneLevel => _zoneLevel;
  String get zoneLabel => _zoneLabel;
  int get volcanoStatusLevel => _volcanoStatusLevel;

  // ── Getters deteksi daerah ──
  String? get detectedRegion => _detectedRegion;
  bool get isRegionAutoDetected => _isRegionAutoDetected;

  /// Jarak dari gunung terdekat dalam format string
  String get distanceLabel =>
      '${_distanceFromVolcano.toStringAsFixed(1)} km dari puncak $_nearestVolcanoName';

  /// ──────────────────────────────────────────────
  /// DETEKSI DAERAH — Berdasarkan koordinat GPS
  /// ──────────────────────────────────────────────
  /// Mengecek apakah user berada dalam radius ~40km
  /// dari salah satu dari 3 gunung berapi.
  /// Return nama daerah atau null jika di luar cakupan.
  String? detectRegion() {
    String? closest;
    double closestDistance = double.infinity;

    for (final entry in regionCenters.entries) {
      final center = entry.value;
      final distance = _haversineDistance(
        _userLat, _userLng,
        center['lat']!, center['lng']!,
      );

      if (distance <= _detectionRadiusKm && distance < closestDistance) {
        closest = entry.key;
        closestDistance = distance;
      }
    }

    _detectedRegion = closest;
    _isRegionAutoDetected = closest != null;
    return closest;
  }

  /// ──────────────────────────────────────────────
  /// INISIALISASI — Request permission & mulai tracking
  /// ──────────────────────────────────────────────
  Future<void> initialize() async {
    try {
      // Cek apakah location service aktif
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _locationError = 'GPS tidak aktif. Aktifkan lokasi di pengaturan.';
        _calculateLocalDistance(); // Fallback ke kalkulasi lokal
        notifyListeners();
        return;
      }

      // Cek & request permission
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _locationError = 'Izin lokasi ditolak.';
          _calculateLocalDistance();
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError =
            'Izin lokasi diblokir permanen. Buka pengaturan untuk mengizinkan.';
        _calculateLocalDistance();
        notifyListeners();
        return;
      }

      // Ambil posisi pertama
      _locationError = null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 0,
        ),
      );
      
      _userLat = position.latitude;
      _userLng = position.longitude;
      _isUsingRealGps = true;
      _lastUpdated = DateTime.now();
      
      // Update ke Supabase & hitung zona risiko
      await _updateLocationToSupabase();
      
      notifyListeners();
    } catch (e) {
      debugPrint('[LocationService] Init error: $e');
      _locationError = 'Gagal mendapatkan lokasi GPS.';
      _calculateLocalDistance();
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  /// START TRACKING — Real-time GPS updates
  /// ──────────────────────────────────────────────
  void startTracking({int distanceFilterMeters = 50}) {
    if (_isTracking) return;

    _isTracking = true;
    _positionStream = Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilterMeters,
      ),
    ).listen(
      (Position position) async {
        _userLat = position.latitude;
        _userLng = position.longitude;
        _isUsingRealGps = true;
        _lastUpdated = DateTime.now();
        _locationError = null;

        // Update lokasi ke Supabase (akan menghitung zona risiko juga)
        await _updateLocationToSupabase();

        notifyListeners();
      },
      onError: (error) {
        debugPrint('[LocationService] Stream error: $error');
        _locationError = 'Tracking lokasi terganggu.';
        notifyListeners();
      },
    );
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// STOP TRACKING
  /// ──────────────────────────────────────────────
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTracking = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// SET GUNUNG AKTIF — Dipanggil saat user ganti region
  /// ──────────────────────────────────────────────
  /// Mengupdate target gunung & recalculate jarak secara otomatis
  void setActiveVolcano({
    required double lat,
    required double lng,
    required String name,
  }) {
    _activeVolcanoLat = lat;
    _activeVolcanoLng = lng;
    _activeVolcanoName = name;

    // Recalculate jarak ke gunung baru
    _calculateLocalDistance();

    // Juga update ke Supabase jika tersedia
    _updateLocationToSupabase();

    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// SET LOKASI MANUAL (untuk simulasi/testing)
  /// ──────────────────────────────────────────────
  Future<void> setManualLocation(double lat, double lng) async {
    _userLat = lat;
    _userLng = lng;
    _isUsingRealGps = false;
    _lastUpdated = DateTime.now();

    await _updateLocationToSupabase();
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// UPDATE KE SUPABASE RPC
  /// ──────────────────────────────────────────────
  /// Memanggil `update_user_location` RPC yang akan:
  /// 1. Simpan lokasi ke profiles.last_location
  /// 2. Hitung gunung terdekat & zona risiko via PostGIS
  /// 3. Return info risiko dalam satu atomic call
  Future<void> _updateLocationToSupabase() async {
    try {
      final client = Supabase.instance.client;
      
      // Hanya update ke Supabase jika user sudah login
      if (client.auth.currentUser != null) {
        final result = await client.rpc('update_user_location', params: {
          'p_lat': _userLat,
          'p_lng': _userLng,
        });

        if (result != null && result['success'] == true) {
          final volcano = result['nearest_volcano'];
          _nearestVolcanoId = volcano['id'];
          _nearestVolcanoName = volcano['name'] ?? 'Gunung Merapi';
          _distanceFromVolcano = (volcano['distance_km'] as num).toDouble();
          _zoneLevel = volcano['zone_level'] as int;
          _zoneLabel = volcano['zone_label'] ?? 'ZONA RELATIF AMAN';
          _volcanoStatusLevel = volcano['status_level'] as int;
        }
      } else {
        // Jika belum login, hitung lokal sebagai fallback
        _calculateLocalDistance();
      }
    } catch (e) {
      debugPrint('[LocationService] Supabase update error: $e');
      // Fallback ke kalkulasi lokal jika Supabase gagal
      _calculateLocalDistance();
    }
  }

  /// ──────────────────────────────────────────────
  /// KALKULASI LOKAL (Fallback)
  /// ──────────────────────────────────────────────
  /// Digunakan saat offline atau Supabase error.
  /// Menghitung jarak ke gunung AKTIF menggunakan formula Haversine.
  void _calculateLocalDistance() {
    _distanceFromVolcano = _haversineDistance(
      _userLat, _userLng, _activeVolcanoLat, _activeVolcanoLng,
    );
    _nearestVolcanoName = _activeVolcanoName;

    if (_distanceFromVolcano <= 5) {
      _zoneLevel = 4;
      _zoneLabel = 'ZONA BAHAYA UTAMA';
    } else if (_distanceFromVolcano <= 10) {
      _zoneLevel = 3;
      _zoneLabel = 'ZONA WASPADA';
    } else if (_distanceFromVolcano <= 15) {
      _zoneLevel = 2;
      _zoneLabel = 'ZONA PERHATIAN';
    } else {
      _zoneLevel = 1;
      _zoneLabel = 'ZONA RELATIF AMAN';
    }
  }

  /// Formula Haversine untuk jarak antara 2 titik GPS (km)
  double _haversineDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  /// ──────────────────────────────────────────────
  /// REFRESH LOKASI — Ambil posisi terbaru sekali
  /// ──────────────────────────────────────────────
  Future<void> refreshLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _userLat = position.latitude;
      _userLng = position.longitude;
      _isUsingRealGps = true;
      _lastUpdated = DateTime.now();
      _locationError = null;

      await _updateLocationToSupabase();
      notifyListeners();
    } catch (e) {
      _locationError = 'Gagal refresh lokasi.';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
