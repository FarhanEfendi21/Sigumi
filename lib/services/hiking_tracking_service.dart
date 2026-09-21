import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'location_service.dart';
import 'notification_service.dart';

/// Mengelola sesi pendakian real-time, rute GPS lokal, dan sinkronisasi opsional ke Supabase.
class HikingTrackingService extends ChangeNotifier {
  HikingTrackingService({LocationService? locationService})
    : _locationService = locationService ?? LocationService();

  final LocationService _locationService;
  VoidCallback? _locationListener;
  Timer? _tickerTimer;

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
  final List<LatLng> _routePoints = [];

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
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);

  /// Menandakan apakah ada riwayat tracking (titik, jarak, atau waktu) yang tersimpan
  bool get hasHistory =>
      _pointsRecorded > 0 ||
      _distanceKm > 0 ||
      _startedAt != null ||
      _routePoints.isNotEmpty;

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

      await _locationService.initialize();
      if (_locationService.gpsStatus != GpsStatus.active) {
        throw StateError(
          _locationService.locationError ?? 'GPS belum siap digunakan.',
        );
      }

      final now = DateTime.now();
      String assignedSessionId = 'local_${now.millisecondsSinceEpoch}';
      DateTime assignedStartedAt = now;

      // Sinkronisasi database opsional (best-effort, tidak membatalkan tracking jika offline/tabel belum ada)
      try {
        final user = Supabase.instance.client.auth.currentUser;
        if (user != null) {
          final row =
              await Supabase.instance.client
                  .from('hiking_sessions')
                  .insert({
                    'user_id': user.id,
                    'started_at': now.toUtc().toIso8601String(),
                    'status': 'active',
                    'last_latitude': _locationService.userLat,
                    'last_longitude': _locationService.userLng,
                  })
                  .select('id, started_at')
                  .single();
          assignedSessionId = row['id'] as String;
          assignedStartedAt =
              DateTime.parse(row['started_at'] as String).toLocal();
        }
      } catch (dbErr) {
        debugPrint(
          '[HikingTracking] DB session skipped/fallback ke lokal: $dbErr',
        );
      }

      _sessionId = assignedSessionId;
      _startedAt = assignedStartedAt;
      _endedAt = null;
      _distanceKm = 0;
      _pointsRecorded = 0;
      _routePoints.clear();
      _lastUploadedAt = null;
      _lastLatitude = null;
      _lastLongitude = null;

      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(distanceFilterMeters: 20);
      await _recordCurrentPosition();

      // Ticker timer untuk update UI durasi setiap detik
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (isActive) notifyListeners();
      });

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
      _tickerTimer?.cancel();
      _tickerTimer = null;
      unawaited(
        NotificationService.instance.cancelHikingForegroundNotification(),
      );
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
      _routePoints.add(LatLng(latitude, longitude));
      _pointsRecorded++;

      // Sinkronisasi titik ke Supabase jika terhubung
      if (!sessionId.startsWith('local_')) {
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
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[HikingTracking] Point upload error (tetap rekam lokal): $e');
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final sessionId = _sessionId;
    if (sessionId == null || _isStopping) return;
    _isStopping = true;
    _tickerTimer?.cancel();
    _tickerTimer = null;
    notifyListeners();

    try {
      await _recordCurrentPosition();
      final endedAt = DateTime.now();
      if (!sessionId.startsWith('local_')) {
        await Supabase.instance.client
            .from('hiking_sessions')
            .update({
              'status': 'completed',
              'ended_at': endedAt.toUtc().toIso8601String(),
              'distance_km': _distanceKm,
            })
            .eq('id', sessionId);
      }
      _endedAt = endedAt;
    } catch (e) {
      _endedAt = DateTime.now();
      debugPrint('[HikingTracking] Stop DB update error (diabaikan): $e');
    } finally {
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      _sessionId = null;
      _isStopping = false;
      unawaited(
        NotificationService.instance.cancelHikingForegroundNotification(),
      );
      notifyListeners();
    }
  }

  /// Reset seluruh riwayat tracking lokal tanpa memerlukan interaksi database.
  Future<void> reset() async {
    _tickerTimer?.cancel();
    _tickerTimer = null;

    final sessionId = _sessionId;
    if (sessionId != null) {
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      unawaited(
        NotificationService.instance.cancelHikingForegroundNotification(),
      );

      // Best effort update DB status cancelled jika ada sesi aktif di remote
      if (!sessionId.startsWith('local_')) {
        try {
          await Supabase.instance.client
              .from('hiking_sessions')
              .update({'status': 'cancelled'})
              .eq('id', sessionId);
        } catch (e) {
          debugPrint('[HikingTracking] Reset DB update ignored: $e');
        }
      }
    }

    _sessionId = null;
    _startedAt = null;
    _endedAt = null;
    _distanceKm = 0;
    _pointsRecorded = 0;
    _routePoints.clear();
    _lastUploadedAt = null;
    _lastLatitude = null;
    _lastLongitude = null;
    _error = null;
    _isStarting = false;
    _isStopping = false;

    notifyListeners();
  }

  @override
  void dispose() {
    _tickerTimer?.cancel();
    _tickerTimer = null;
    _locationService.removeListener(_locationListener ?? () {});
    _locationService.stopTracking();
    super.dispose();
  }
}
