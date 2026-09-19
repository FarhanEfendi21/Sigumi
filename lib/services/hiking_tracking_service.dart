import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_service.dart';
import 'notification_service.dart';

/// Mengelola satu sesi pendakian dan sinkronisasi titik GPS ke Supabase.
class HikingTrackingService extends ChangeNotifier {
  HikingTrackingService({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  final LocationService _locationService;
  VoidCallback? _locationListener;

  String? _sessionId;
  DateTime? _startedAt;
  DateTime? _endedAt;
  double _distanceKm = 0;
  int _pointsRecorded = 0;
  String? _error;
  bool _isStarting = false;
  bool _isStopping = false;
  DateTime? _lastUploadedAt;
  double? _lastLatitude;
  double? _lastLongitude;

  bool get isActive => _sessionId != null && _endedAt == null;
  bool get isStarting => _isStarting;
  bool get isStopping => _isStopping;
  String? get sessionId => _sessionId;
  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;
  double get distanceKm => _distanceKm;
  int get pointsRecorded => _pointsRecorded;
  String? get error => _error;
  LocationService get locationService => _locationService;

  Duration get elapsed =>
      (_startedAt == null)
          ? Duration.zero
          : (_endedAt ?? DateTime.now()).difference(_startedAt!);

  Future<bool> start({String? region}) async {
    if (isActive || _isStarting) return false;
    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      if (region != null && region.toLowerCase() != 'lombok') {
        throw StateError(
          'Fitur tracking pendakian saat ini hanya tersedia untuk wilayah Gunung Rinjani (Lombok).',
        );
      }

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw StateError(
          'Silakan masuk terlebih dahulu untuk memulai tracking.',
        );
      }

      await _locationService.initialize();
      if (_locationService.gpsStatus != GpsStatus.active) {
        throw StateError(
          _locationService.locationError ?? 'GPS belum siap digunakan.',
        );
      }

      final row =
          await Supabase.instance.client
              .from('hiking_sessions')
              .insert({
                'user_id': user.id,
                'started_at': DateTime.now().toUtc().toIso8601String(),
                'status': 'active',
                'last_latitude': _locationService.userLat,
                'last_longitude': _locationService.userLng,
              })
              .select('id, started_at')
              .single();

      _sessionId = row['id'] as String;
      _startedAt = DateTime.parse(row['started_at'] as String).toLocal();
      _endedAt = null;
      _distanceKm = 0;
      _pointsRecorded = 0;
      _lastUploadedAt = null;
      _lastLatitude = null;
      _lastLongitude = null;

      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(distanceFilterMeters: 20);
      await _recordCurrentPosition();

      // Tampilkan notifikasi sticky foreground agar GPS tetap aktif saat layar mati
      unawaited(
        NotificationService.instance.showHikingForegroundNotification(),
      );

      notifyListeners();
      return true;
    } catch (e) {
      _error =
          e is StateError ? e.message : 'Gagal memulai tracking pendakian.';
      debugPrint('[HikingTracking] Start error: $e');
      _sessionId = null;
      _startedAt = null;
      // Pastikan notifikasi juga dihapus jika start gagal
      unawaited(NotificationService.instance.cancelHikingForegroundNotification());
      return false;
    } finally {
      _isStarting = false;
      notifyListeners();
    }
  }

  void _onLocationChanged() {
    if (!isActive || !_locationService.isUsingRealGps) return;
    unawaited(_recordCurrentPosition());
    notifyListeners();
  }

  Future<void> _recordCurrentPosition() async {
    final sessionId = _sessionId;
    if (sessionId == null || !_locationService.isUsingRealGps) return;

    final now = DateTime.now();
    if (_lastUploadedAt != null &&
        now.difference(_lastUploadedAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastUploadedAt = now;

    try {
      final latitude = _locationService.userLat;
      final longitude = _locationService.userLng;
      if (_lastLatitude != null && _lastLongitude != null) {
        _distanceKm +=
            Geolocator.distanceBetween(
              _lastLatitude!,
              _lastLongitude!,
              latitude,
              longitude,
            ) /
            1000;
      }
      _lastLatitude = latitude;
      _lastLongitude = longitude;

      final position = {
        'session_id': sessionId,
        'recorded_at': now.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': null,
      };
      await Supabase.instance.client
          .from('hiking_track_points')
          .insert(position);
      await Supabase.instance.client
          .from('hiking_sessions')
          .update({
            'last_latitude': _locationService.userLat,
            'last_longitude': _locationService.userLng,
            'last_point_at': now.toUtc().toIso8601String(),
          })
          .eq('id', sessionId);
      _pointsRecorded++;
      notifyListeners();
    } catch (e) {
      debugPrint('[HikingTracking] Point upload error: $e');
      _error = 'Lokasi tersimpan sementara, menunggu koneksi.';
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final sessionId = _sessionId;
    if (sessionId == null || _isStopping) return;
    _isStopping = true;
    notifyListeners();

    try {
      await _recordCurrentPosition();
      final endedAt = DateTime.now();
      await Supabase.instance.client
          .from('hiking_sessions')
          .update({
            'status': 'completed',
            'ended_at': endedAt.toUtc().toIso8601String(),
            'distance_km': _distanceKm,
          })
          .eq('id', sessionId);
      _endedAt = endedAt;
    } catch (e) {
      _error = 'Sesi belum dapat ditutup. Periksa koneksi lalu coba lagi.';
      debugPrint('[HikingTracking] Stop error: $e');
      return;
    } finally {
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      _sessionId = null;
      _isStopping = false;
      // Hapus notifikasi sticky saat tracking selesai
      unawaited(NotificationService.instance.cancelHikingForegroundNotification());
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _locationService.removeListener(_locationListener ?? () {});
    _locationService.stopTracking();
    super.dispose();
  }
}
