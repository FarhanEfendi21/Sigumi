import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Status kesehatan GPS tracking
enum GpsStatus {
  unknown, // Belum dicek
  active, // GPS aktif dan tracking berjalan lancar
  unstable, // Ada error tapi masih retry
  error, // Error persisten setelah beberapa kali retry
  disabled, // GPS dimatikan oleh user
  denied, // Permission ditolak
}

/// Service untuk lokasi GPS real-time dan integrasi PostGIS Supabase.
///
/// Menangani:
/// - Request permission GPS
/// - Tracking lokasi real-time
/// - Deteksi daerah otomatis berdasarkan GPS
/// - Update lokasi ke Supabase RPC (menghitung zona risiko di database)
/// - Fallback ke lokasi simulasi jika GPS tidak tersedia
/// - Auto-retry mechanism saat tracking error
class LocationService extends ChangeNotifier {
  // Singleton pattern
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  // ── Definisi daerah cakupan ──
  static const double _detectionRadiusKm = 40.0;
  static const Map<String, Map<String, double>> regionCenters = {
    'Yogyakarta': {'lat': -7.5407, 'lng': 110.4457}, // Merapi
    'Bali': {'lat': -8.3433, 'lng': 115.5071}, // Agung
    'Lombok': {'lat': -8.4111, 'lng': 116.4573}, // Rinjani
  };

  // ── Konfigurasi retry ──
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 5);
  static const Duration _errorCooldown = Duration(seconds: 30);

  // ── State lokasi ──
  double _userLat = -7.7956; // Default: Yogyakarta
  double _userLng = 110.3695;
  bool _isUsingRealGps = false;
  bool _isTracking = false;
  String? _locationError;
  DateTime? _lastUpdated;
  GpsStatus _gpsStatus = GpsStatus.unknown;

  // ── Error tracking ──
  int _consecutiveErrors = 0;
  DateTime? _lastErrorShown;
  Timer? _retryTimer;
  bool _isRetrying = false;

  // ── Deteksi daerah otomatis ──
  String? _detectedRegion; // Daerah yang terdeteksi GPS (null = di luar)
  bool _isRegionAutoDetected = false;

  // ── Gunung berapi aktif (target jarak) ──
  double _activeVolcanoLat = -7.5407; // Default: Merapi
  double _activeVolcanoLng = 110.4457;
  String _activeVolcanoName = 'Gunung Merapi';

  // ── Nearest volcano risk info (dari Supabase RPC) ──
  String? _nearestVolcanoId;
  String _nearestVolcanoName = 'Gunung Merapi';
  double _distanceFromVolcano = 0;
  int _zoneLevel = 1;
  String _zoneLabel = 'Zona Aman';
  final int _volcanoStatusLevel = 1;

  // ── Stream subscription ──
  StreamSubscription<Position>? _positionStream;

  // ── Getters ──
  double get userLat => _userLat;
  double get userLng => _userLng;
  bool get isUsingRealGps => _isUsingRealGps;
  bool get isTracking => _isTracking;
  String? get locationError => _locationError;
  DateTime? get lastUpdated => _lastUpdated;
  GpsStatus get gpsStatus => _gpsStatus;
  bool get isRetrying => _isRetrying;

  String? get nearestVolcanoId => _nearestVolcanoId;
  String get nearestVolcanoName => _nearestVolcanoName;
  String get activeVolcanoName => _activeVolcanoName;
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
  /// Mencari daerah paling dekat tanpa batasan radius
  String getClosestRegion() {
    String closest = 'Yogyakarta'; // default fallback
    double closestDistance = double.infinity;

    for (final entry in regionCenters.entries) {
      final center = entry.value;
      final distance = _haversineDistance(
        _userLat,
        _userLng,
        center['lat']!,
        center['lng']!,
      );

      if (distance < closestDistance) {
        closest = entry.key;
        closestDistance = distance;
      }
    }
    return closest;
  }

  /// Return nama daerah jika dalam jarak 40km, atau null jika di luar.
  String? detectRegion() {
    String? closest;
    double closestDistance = double.infinity;

    for (final entry in regionCenters.entries) {
      final center = entry.value;
      final distance = _haversineDistance(
        _userLat,
        _userLng,
        center['lat']!,
        center['lng']!,
      );

      if (distance < closestDistance) {
        closest = entry.key;
        closestDistance = distance;
      }
    }

    if (closestDistance <= _detectionRadiusKm) {
      _detectedRegion = closest;
      _isRegionAutoDetected = true;
      return closest;
    } else {
      _detectedRegion = null;
      _isRegionAutoDetected = false;
      return null;
    }
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
        _gpsStatus = GpsStatus.disabled;
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
          _gpsStatus = GpsStatus.denied;
          _calculateLocalDistance();
          notifyListeners();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _locationError =
            'Izin lokasi diblokir permanen. Buka pengaturan untuk mengizinkan.';
        _gpsStatus = GpsStatus.denied;
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
      _gpsStatus = GpsStatus.active;
      _consecutiveErrors = 0;

      // Update ke Supabase & hitung zona risiko
      await _updateLocationToSupabase();

      notifyListeners();
    } catch (e) {
      debugPrint('[LocationService] Init error: $e');
      _locationError = 'Gagal mendapatkan lokasi GPS.';
      _gpsStatus = GpsStatus.error;
      _calculateLocalDistance();
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  /// START TRACKING — Real-time GPS updates dengan auto-retry
  /// ──────────────────────────────────────────────
  void startTracking({int distanceFilterMeters = 50}) {
    if (_isTracking) return;

    _isTracking = true;
    _consecutiveErrors = 0;
    _startPositionStream(distanceFilterMeters);
    notifyListeners();
  }

  /// Internal: start/restart position stream
  void _startPositionStream(int distanceFilterMeters) {
    _positionStream?.cancel();
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

        // Reset error state saat berhasil dapat posisi baru
        _locationError = null;
        _consecutiveErrors = 0;
        _isRetrying = false;
        _gpsStatus = GpsStatus.active;

        // Update lokasi ke Supabase (akan menghitung zona risiko juga)
        await _updateLocationToSupabase();

        notifyListeners();
      },
      onError: (error) {
        debugPrint('[LocationService] Stream error: $error');
        _handleTrackingError(distanceFilterMeters);
      },
    );
  }

  /// Handle tracking error dengan retry logic
  void _handleTrackingError(int distanceFilterMeters) {
    _consecutiveErrors++;

    if (_consecutiveErrors <= _maxRetryAttempts) {
      // ── Retry: coba reconnect otomatis ──
      _gpsStatus = GpsStatus.unstable;
      _isRetrying = true;

      // Jangan spam error message — hanya tampilkan sekali
      final now = DateTime.now();
      if (_lastErrorShown == null ||
          now.difference(_lastErrorShown!) > _errorCooldown) {
        _locationError = 'Lokasi tidak stabil, mencoba memperbarui…';
        _lastErrorShown = now;
      }

      notifyListeners();

      // Auto retry setelah delay
      _retryTimer?.cancel();
      _retryTimer = Timer(_retryDelay, () {
        if (_isTracking) {
          debugPrint(
            '[LocationService] Retry attempt $_consecutiveErrors/$_maxRetryAttempts',
          );
          _startPositionStream(distanceFilterMeters);
        }
      });
    } else {
      // ── Error persisten — beri tahu user tapi jangan blocking ──
      _gpsStatus = GpsStatus.error;
      _isRetrying = false;
      _locationError = 'GPS tidak tersedia. Menggunakan lokasi terakhir.';

      // Tetap pakai lokasi terakhir yang valid (fallback UX)
      // Jangan kosongkan data atau hapus peta

      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  /// RETRY MANUAL — Dipanggil saat user tap "Coba Lagi"
  /// ──────────────────────────────────────────────
  Future<void> retryTracking() async {
    _consecutiveErrors = 0;
    _isRetrying = true;
    _locationError = null;
    _gpsStatus = GpsStatus.unstable;
    notifyListeners();

    // Coba init ulang dulu
    await initialize();

    // Jika berhasil, restart tracking
    if (_gpsStatus == GpsStatus.active) {
      stopTracking();
      startTracking(distanceFilterMeters: 30);
    } else {
      _isRetrying = false;
      notifyListeners();
    }
  }

  /// ──────────────────────────────────────────────
  /// CLEAR ERROR — Untuk dismiss error dari UI
  /// ──────────────────────────────────────────────
  void clearLocationError() {
    _locationError = null;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────
  /// STOP TRACKING
  /// ──────────────────────────────────────────────
  void stopTracking() {
    _positionStream?.cancel();
    _positionStream = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _isTracking = false;
    _isRetrying = false;
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

      // Update data lokasi ke Supabase jika login
      if (client.auth.currentUser != null) {
        await client.rpc(
          'update_user_location',
          params: {'p_lat': _userLat, 'p_lng': _userLng},
        );
      }

      // KEMBALIKAN LOGIKA LOKASI:
      // Selalu gunakan kalkulasi lokal agar jarak yang ditampilkan
      // secara real-time selalu mengacu pada gunung yang dipilih user
      // (active volcano) dan tidak di-override oleh hasil RPC Supabase.
      _calculateLocalDistance();
    } catch (e) {
      debugPrint('[LocationService] Supabase update error: $e');
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
      _userLat,
      _userLng,
      _activeVolcanoLat,
      _activeVolcanoLng,
    );
    _nearestVolcanoName = _activeVolcanoName;

    if (_distanceFromVolcano <= 5) {
      _zoneLevel = 4;
      _zoneLabel = 'Zona Bahaya';
    } else if (_distanceFromVolcano <= 10) {
      _zoneLevel = 3;
      _zoneLabel = 'Zona Waspada';
    } else if (_distanceFromVolcano <= 15) {
      _zoneLevel = 2;
      _zoneLabel = 'Zona Perhatian';
    } else {
      _zoneLevel = 1;
      _zoneLabel = 'Zona Aman';
    }
  }

  /// Formula Haversine untuk jarak antara 2 titik GPS (km)
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
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
      _gpsStatus = GpsStatus.active;
      _consecutiveErrors = 0;

      await _updateLocationToSupabase();
      notifyListeners();
    } catch (e) {
      _locationError = 'Gagal refresh lokasi.';
      _gpsStatus = GpsStatus.error;
      notifyListeners();
    }
  }

  /// Singleton tidak memanggil super.dispose() karena akan membuat
  /// ChangeNotifier tidak bisa dipakai lagi setelah logout/re-init.
  /// Cukup stop tracking saja.
  @override
  void dispose() {
    stopTracking();
    // CATATAN: sengaja TIDAK memanggil super.dispose() karena
    // LocationService adalah singleton — jika dispose dipanggil,
    // instance tetap hidup dan harus tetap bisa notify listeners.
  }
}
