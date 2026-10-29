import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hiking_sos.dart';
import 'location_service.dart';
import 'notification_service.dart';

/// Mengelola sesi pendakian real-time, rute GPS lokal, dan sinkronisasi opsional ke Supabase.
class HikingTrackingService extends ChangeNotifier {
  HikingTrackingService({LocationService? locationService})
    : _locationService = locationService ?? LocationService() {
    unawaited(_restoreSessionIfNeeded());
  }

  static const _pendingPointsKey = 'hiking_pending_track_points_v1';
  static const _pendingSosKey = 'hiking_pending_sos_alerts_v1';
  static const _activeSessionKey = 'hiking_active_session_v1';
  static const _localSessionsKey = 'hiking_local_sessions_v1';

  final LocationService _locationService;
  VoidCallback? _locationListener;
  Timer? _tickerTimer;

  String? _sessionId;
  String? _trackingRegion;
  DateTime? _startedAt;
  DateTime? _endedAt;
  DateTime? _pausedAt;
  Duration _totalPausedDuration = Duration.zero;
  double _distanceKm = 0;
  int _pointsRecorded = 0;
  String? _error;
  bool _isStarting = false;
  bool _isStopping = false;
  bool _isPausing = false;
  DateTime? _lastUploadedAt;
  double? _lastLatitude;
  double? _lastLongitude;
  DateTime? _lastPositionRecordedAt;
  double? _lastPositionAccuracyMeters;
  DateTime? _lastGeofenceFixAt;
  int _consecutiveOutsideRegionFixes = 0;
  final List<LatLng> _routePoints = [];
  final List<Map<String, dynamic>> _pendingPoints = [];
  final List<Map<String, dynamic>> _pendingSosAlerts = [];
  final Map<String, Map<String, dynamic>> _localSessions = {};
  Future<void>? _restoreFuture;
  bool _restored = false;
  bool _isFlushing = false;
  bool _isSubmittingSos = false;
  final Set<String> _uploadedSosAlertIds = {};

  bool get isActive => _sessionId != null && _endedAt == null;
  bool get isPaused => isActive && _pausedAt != null;
  Future<void> ensureRestored() => _restoreSessionIfNeeded();
  String? get trackingRegion => _trackingRegion;
  bool get isStarting => _isStarting;
  bool get isStopping => _isStopping;
  bool get isPausing => _isPausing;
  String? get sessionId => _sessionId;
  DateTime? get startedAt => _startedAt;
  DateTime? get endedAt => _endedAt;
  double get distanceKm => _distanceKm;
  int get pointsRecorded => _pointsRecorded;
  String? get error => _error;
  LocationService get locationService => _locationService;
  List<LatLng> get routePoints => List.unmodifiable(_routePoints);
  HikingSosLocation? get lastRecordedSosLocation => _latestRealLocation();

  bool isSosPending(String alertId) =>
      _pendingSosAlerts.any((alert) => alert['client_alert_id'] == alertId);

  bool wasSosUploaded(String alertId) => _uploadedSosAlertIds.contains(alertId);

  /// Menandakan apakah ada riwayat tracking (titik, jarak, atau waktu) yang tersimpan
  bool get hasHistory =>
      _pointsRecorded > 0 ||
      _distanceKm > 0 ||
      _startedAt != null ||
      _routePoints.isNotEmpty;

  Duration get elapsed {
    if (_startedAt == null) return Duration.zero;
    final end = _pausedAt ?? _endedAt ?? DateTime.now();
    return end.difference(_startedAt!) - _totalPausedDuration;
  }

  Future<bool> start({String? region}) async {
    await _restoreSessionIfNeeded();
    if (isActive || _isStarting) return false;
    _isStarting = true;
    _error = null;
    notifyListeners();

    try {
      final normalizedRegion = region?.trim().toLowerCase();
      if (!const {'lombok', 'bali'}.contains(normalizedRegion)) {
        throw StateError(
          'Fitur tracking pendakian tersedia untuk Gunung Rinjani (Lombok) dan Gunung Agung (Bali).',
        );
      }

      await _locationService.initialize();
      if (_locationService.gpsStatus != GpsStatus.active) {
        throw StateError(
          _locationService.locationError ?? 'GPS belum siap digunakan.',
        );
      }
      if (!_locationService.isWithinHikingRegion(normalizedRegion!)) {
        throw StateError(
          'Tracking hanya dapat dimulai dengan sinyal GPS terbaru dalam radius ${LocationService.hikingTrackingRadiusKm.toStringAsFixed(0)} km dari Gunung ${normalizedRegion == 'bali' ? 'Agung' : 'Rinjani'}.',
        );
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.always) {
          throw StateError(
            'Izinkan akses lokasi "Selalu" agar tracking tetap berjalan di latar belakang.',
          );
        }
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
      _trackingRegion = normalizedRegion;
      _startedAt = assignedStartedAt;
      _endedAt = null;
      _pausedAt = null;
      _totalPausedDuration = Duration.zero;
      _distanceKm = 0;
      _pointsRecorded = 0;
      _routePoints.clear();
      _lastUploadedAt = null;
      _lastLatitude = null;
      _lastLongitude = null;
      _lastPositionRecordedAt = null;
      _lastPositionAccuracyMeters = null;
      _lastGeofenceFixAt = null;
      _consecutiveOutsideRegionFixes = 0;
      if (assignedSessionId.startsWith('local_')) {
        _localSessions[assignedSessionId] = {
          'client_session_id': assignedSessionId,
          'user_id': Supabase.instance.client.auth.currentUser?.id,
          'started_at': assignedStartedAt.toUtc().toIso8601String(),
          'status': 'active',
          'last_latitude': _locationService.userLat,
          'last_longitude': _locationService.userLng,
          'distance_km': 0,
        };
        await _persistLocalSessions();
      }
      await _persistSessionState();

      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(
        distanceFilterMeters: 20,
        hikingTracking: true,
      );
      await _recordCurrentPosition();

      // Ticker timer untuk update UI durasi setiap detik
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isActive) {
          if (timer.tick % 15 == 0) unawaited(_flushPendingData());
          notifyListeners();
        }
      });

      notifyListeners();
      return true;
    } catch (e) {
      _error =
          e is StateError ? e.message : 'Gagal memulai tracking pendakian.';
      debugPrint('[HikingTracking] Start error: $e');
      _sessionId = null;
      _trackingRegion = null;
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
    if (!isActive ||
        isPaused ||
        _isPausing ||
        !_locationService.isUsingRealGps) {
      return;
    }
    final fixAt = _locationService.lastUpdated;
    if (!_locationService.hasFreshRealPosition ||
        fixAt == null ||
        fixAt == _lastGeofenceFixAt) {
      return;
    }
    _lastGeofenceFixAt = fixAt;
    final region = _trackingRegion;
    if (region == null) {
      _error =
          'Tracking dihentikan karena wilayah sesi pendakian tidak diketahui.';
      unawaited(stop());
      return;
    }
    if (!_locationService.isWithinHikingRegion(region)) {
      _consecutiveOutsideRegionFixes++;
      if (_consecutiveOutsideRegionFixes >= 3) {
        _error =
            'Tracking dihentikan karena 3 pembaruan GPS berturut-turut berada di luar radius ${LocationService.hikingTrackingRadiusKm.toStringAsFixed(0)} km area pendakian.';
        unawaited(stop());
      } else {
        notifyListeners();
      }
      return;
    }
    _consecutiveOutsideRegionFixes = 0;
    unawaited(_recordCurrentPosition());
    notifyListeners();
  }

  Future<void> _recordCurrentPosition() async {
    final sessionId = _sessionId;
    final region = _trackingRegion;
    if (sessionId == null ||
        region == null ||
        !_locationService.isWithinHikingRegion(region)) {
      return;
    }

    final now = DateTime.now();
    if (_lastUploadedAt != null &&
        now.difference(_lastUploadedAt!) < const Duration(seconds: 5)) {
      return;
    }
    _lastUploadedAt = now;

    try {
      final latitude = _locationService.userLat;
      final longitude = _locationService.userLng;
      final recordedAt = _locationService.lastUpdated ?? now;
      final accuracyMeters = _locationService.accuracyMeters;
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
      _lastPositionRecordedAt = recordedAt;
      _lastPositionAccuracyMeters = accuracyMeters;
      _routePoints.add(LatLng(latitude, longitude));
      _pointsRecorded++;
      final localSession = _localSessions[sessionId];
      if (localSession != null) {
        localSession['last_latitude'] = latitude;
        localSession['last_longitude'] = longitude;
        localSession['last_point_at'] = recordedAt.toUtc().toIso8601String();
        localSession['last_accuracy_meters'] = accuracyMeters;
        localSession['distance_km'] = _distanceKm;
        await _persistLocalSessions();
      }
      _pendingPoints.add({
        'client_point_id': '${sessionId}_${now.microsecondsSinceEpoch}',
        'session_id': sessionId,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': accuracyMeters,
      });
      await _persistPendingData();
      await _persistSessionState();
      await _flushPendingData();
      notifyListeners();
    } catch (e) {
      debugPrint('[HikingTracking] Point upload error (tetap rekam lokal): $e');
      notifyListeners();
    }
  }

  Future<void> pause() async {
    final sessionId = _sessionId;
    if (sessionId == null ||
        !isActive ||
        isPaused ||
        _isStopping ||
        _isPausing) {
      return;
    }
    _isPausing = true;
    notifyListeners();
    try {
      _tickerTimer?.cancel();
      _tickerTimer = null;
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      _pausedAt = DateTime.now();
      await _recordCurrentPosition();
      await _persistSessionState();
      unawaited(
        NotificationService.instance.cancelHikingForegroundNotification(),
      );
    } finally {
      _isPausing = false;
      notifyListeners();
    }
  }

  Future<bool> resume() async {
    final region = _trackingRegion;
    final pausedAt = _pausedAt;
    if (_sessionId == null || !isPaused || region == null || _isStarting) {
      return false;
    }
    _isStarting = true;
    _error = null;
    notifyListeners();
    try {
      await _locationService.initialize();
      if (_locationService.gpsStatus != GpsStatus.active ||
          !_locationService.hasFreshRealPosition ||
          !_locationService.isWithinHikingRegion(region)) {
        throw StateError(
          _locationService.locationError ??
              'Lokasi GPS terbaru belum terdeteksi di area pendakian.',
        );
      }
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        var permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.whileInUse) {
          permission = await Geolocator.requestPermission();
        }
        if (permission != LocationPermission.always) {
          throw StateError(
            'Izinkan akses lokasi "Selalu" agar tracking berjalan di latar belakang.',
          );
        }
      }

      if (pausedAt != null) {
        _totalPausedDuration += DateTime.now().difference(pausedAt);
      }
      _pausedAt = null;
      _lastGeofenceFixAt = null;
      _consecutiveOutsideRegionFixes = 0;
      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(
        distanceFilterMeters: 20,
        hikingTracking: true,
      );
      await _recordCurrentPosition();
      _tickerTimer?.cancel();
      _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (isActive && !isPaused && timer.tick % 15 == 0) {
          unawaited(_flushPendingData());
        }
        notifyListeners();
      });
      await _persistSessionState();
      notifyListeners();
      return true;
    } catch (error) {
      _error =
          error is StateError ? error.message : 'Gagal melanjutkan tracking.';
      return false;
    } finally {
      _isStarting = false;
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
      if (!isPaused) await _recordCurrentPosition();
      final endedAt = DateTime.now();
      if (_pausedAt != null) {
        _totalPausedDuration += endedAt.difference(_pausedAt!);
        _pausedAt = null;
      }
      final localSession = _localSessions[sessionId];
      if (localSession != null) {
        localSession['status'] = 'completed';
        localSession['ended_at'] = endedAt.toUtc().toIso8601String();
        localSession['distance_km'] = _distanceKm;
      }
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
      _pausedAt = null;
    } catch (e) {
      _endedAt = DateTime.now();
      debugPrint('[HikingTracking] Stop DB update error (diabaikan): $e');
    } finally {
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      if (!sessionId.startsWith('local_')) _sessionId = null;
      _pausedAt = null;
      _isStopping = false;
      await _persistLocalSessions();
      await _persistSessionState();
      unawaited(_flushPendingData());
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
      _localSessions.remove(sessionId);
      _pendingPoints.removeWhere((point) => point['session_id'] == sessionId);
      _pendingSosAlerts.removeWhere(
        (alert) => alert['session_id'] == sessionId,
      );
      await _persistLocalSessions();
      await _persistPendingData();
    }

    _sessionId = null;
    _trackingRegion = null;
    _startedAt = null;
    _endedAt = null;
    _pausedAt = null;
    _totalPausedDuration = Duration.zero;
    _distanceKm = 0;
    _pointsRecorded = 0;
    _routePoints.clear();
    _lastUploadedAt = null;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastPositionRecordedAt = null;
    _lastPositionAccuracyMeters = null;
    _error = null;
    _isStarting = false;
    _isStopping = false;
    _isPausing = false;
    await _persistSessionState();

    notifyListeners();
  }

  Future<void> _restoreSessionIfNeeded() {
    return _restoreFuture ??= _restorePersistedSession();
  }

  Future<void> _restorePersistedSession() async {
    if (_restored) return;
    _restored = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      _pendingPoints
        ..clear()
        ..addAll(_decodeMapList(prefs.getString(_pendingPointsKey)));
      _pendingSosAlerts
        ..clear()
        ..addAll(_decodeMapList(prefs.getString(_pendingSosKey)));

      final localSessionsJson = prefs.getString(_localSessionsKey);
      if (localSessionsJson != null) {
        final stored = jsonDecode(localSessionsJson) as Map<String, dynamic>;
        for (final entry in stored.entries) {
          _localSessions[entry.key] = Map<String, dynamic>.from(
            entry.value as Map,
          );
        }
      }

      final sessionJson = prefs.getString(_activeSessionKey);
      if (sessionJson != null) {
        final value = jsonDecode(sessionJson) as Map<String, dynamic>;
        _sessionId = value['session_id'] as String?;
        _trackingRegion =
            (value['tracking_region'] as String?)?.trim().toLowerCase();
        _startedAt = DateTime.tryParse(value['started_at'] as String? ?? '');
        _pausedAt = DateTime.tryParse(value['paused_at'] as String? ?? '');
        _totalPausedDuration = Duration(
          milliseconds: (value['paused_duration_ms'] as num?)?.toInt() ?? 0,
        );
        _distanceKm = (value['distance_km'] as num?)?.toDouble() ?? 0;
        _pointsRecorded = (value['points_recorded'] as num?)?.toInt() ?? 0;
        _lastLatitude = (value['last_latitude'] as num?)?.toDouble();
        _lastLongitude = (value['last_longitude'] as num?)?.toDouble();
        _lastPositionRecordedAt = DateTime.tryParse(
          value['last_position_recorded_at'] as String? ?? '',
        );
        _lastPositionAccuracyMeters =
            (value['last_position_accuracy_meters'] as num?)?.toDouble();
        _routePoints
          ..clear()
          ..addAll(
            (value['route'] as List<dynamic>? ?? const []).map((point) {
              final coordinates = point as List<dynamic>;
              return LatLng(
                (coordinates[0] as num).toDouble(),
                (coordinates[1] as num).toDouble(),
              );
            }),
          );
        if (_sessionId != null && _startedAt != null) {
          if (!const {'bali', 'lombok'}.contains(_trackingRegion)) {
            _trackingRegion = null;
          }
          _trackingRegion ??= _inferRegionFromCoordinates(
            _lastLatitude,
            _lastLongitude,
          );
          final region = _trackingRegion;
          if (_pausedAt != null) {
            notifyListeners();
          } else {
            await _locationService.initialize();
            if (region != null) {
              _locationListener = _onLocationChanged;
              _locationService.addListener(_locationListener!);
              _locationService.startTracking(
                distanceFilterMeters: 20,
                hikingTracking: true,
              );
              _tickerTimer = Timer.periodic(const Duration(seconds: 1), (
                timer,
              ) {
                if (isActive && !isPaused && timer.tick % 15 == 0) {
                  unawaited(_flushPendingData());
                }
                notifyListeners();
              });
            } else {
              await _closeRestoredSessionOutsideArea();
            }
          }
        }
      }
      unawaited(_flushPendingData());
    } catch (e) {
      debugPrint('[HikingTracking] Restore local state skipped: $e');
    }
  }

  String? _inferRegionFromCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return null;
    for (final region in const ['bali', 'lombok']) {
      final center =
          LocationService.regionCenters.entries
              .firstWhere((entry) => entry.key.toLowerCase() == region)
              .value;
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        center['lat']!,
        center['lng']!,
      );
      if (distance <= LocationService.hikingTrackingRadiusKm * 1000) {
        return region;
      }
    }
    return null;
  }

  Future<void> _closeRestoredSessionOutsideArea() async {
    final sessionId = _sessionId;
    if (sessionId == null) return;
    final endedAt = DateTime.now();
    _endedAt = endedAt;
    _pausedAt = null;
    final localSession = _localSessions[sessionId];
    if (localSession != null) {
      localSession['status'] = 'completed';
      localSession['ended_at'] = endedAt.toUtc().toIso8601String();
    }
    if (!sessionId.startsWith('local_')) {
      try {
        await Supabase.instance.client
            .from('hiking_sessions')
            .update({
              'status': 'completed',
              'ended_at': endedAt.toUtc().toIso8601String(),
            })
            .eq('id', sessionId);
      } catch (e) {
        debugPrint('[HikingTracking] Restore close deferred: $e');
      }
    }
    await _persistLocalSessions();
    await _persistSessionState();
    unawaited(
      NotificationService.instance.cancelHikingForegroundNotification(),
    );
    notifyListeners();
  }

  List<Map<String, dynamic>> _decodeMapList(String? value) {
    if (value == null) return [];
    try {
      return (jsonDecode(value) as List<dynamic>)
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _persistSessionState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_sessionId == null || _startedAt == null || _endedAt != null) {
        await prefs.remove(_activeSessionKey);
        return;
      }
      await prefs.setString(
        _activeSessionKey,
        jsonEncode({
          'session_id': _sessionId,
          'tracking_region': _trackingRegion,
          'started_at': _startedAt!.toUtc().toIso8601String(),
          'paused_at': _pausedAt?.toUtc().toIso8601String(),
          'paused_duration_ms': _totalPausedDuration.inMilliseconds,
          'distance_km': _distanceKm,
          'points_recorded': _pointsRecorded,
          'last_latitude': _lastLatitude,
          'last_longitude': _lastLongitude,
          'last_position_recorded_at':
              _lastPositionRecordedAt?.toUtc().toIso8601String(),
          'last_position_accuracy_meters': _lastPositionAccuracyMeters,
          'route':
              _routePoints
                  .map((point) => [point.latitude, point.longitude])
                  .toList(),
        }),
      );
    } catch (e) {
      debugPrint('[HikingTracking] Session persistence failed: $e');
    }
  }

  Future<void> _persistPendingData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_pendingPointsKey, jsonEncode(_pendingPoints));
      await prefs.setString(_pendingSosKey, jsonEncode(_pendingSosAlerts));
    } catch (e) {
      debugPrint('[HikingTracking] Pending data persistence failed: $e');
    }
  }

  Future<void> _persistPendingSosAlerts() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = await prefs.setString(
      _pendingSosKey,
      jsonEncode(_pendingSosAlerts),
    );
    if (!saved) throw StateError('SOS lokal gagal disimpan.');
  }

  Future<void> _persistLocalSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localSessionsKey, jsonEncode(_localSessions));
    } catch (e) {
      debugPrint('[HikingTracking] Local session persistence failed: $e');
    }
  }

  Future<String?> _ensureRemoteSession(String localSessionId) async {
    final session = _localSessions[localSessionId];
    if (session == null) return null;
    final remoteId = session['remote_id'] as String?;
    if (remoteId != null) return remoteId;
    final user = Supabase.instance.client.auth.currentUser;
    final userId = session['user_id'] as String? ?? user?.id;
    if (userId == null) return null;

    final row =
        await Supabase.instance.client
            .from('hiking_sessions')
            .upsert({
              'client_session_id':
                  session['client_session_id'] ?? localSessionId,
              'user_id': userId,
              'started_at': session['started_at'],
              'status': session['status'] ?? 'active',
              'ended_at': session['ended_at'],
              'distance_km': session['distance_km'] ?? 0,
              'last_latitude': session['last_latitude'],
              'last_longitude': session['last_longitude'],
              'last_point_at': session['last_point_at'],
            }, onConflict: 'client_session_id')
            .select('id')
            .single();
    final remoteSessionId = row['id'] as String;
    session['remote_id'] = remoteSessionId;
    for (final point in _pendingPoints) {
      if (point['session_id'] == localSessionId) {
        point['session_id'] = remoteSessionId;
      }
    }
    for (final alert in _pendingSosAlerts) {
      if (alert['session_id'] == localSessionId) {
        alert['session_id'] = remoteSessionId;
      }
    }
    if (_sessionId == localSessionId) _sessionId = remoteSessionId;
    await _persistLocalSessions();
    await _persistSessionState();
    await _persistPendingData();
    return remoteSessionId;
  }

  Future<void> _flushPendingData() async {
    if (_isFlushing) return;
    _isFlushing = true;
    try {
      final client = Supabase.instance.client;
      if (client.auth.currentUser == null) return;
      for (final localId in _localSessions.keys.toList()) {
        if (localId.startsWith('local_')) {
          try {
            await _ensureRemoteSession(localId);
          } catch (e) {
            debugPrint(
              '[HikingTracking] Session sync deferred for $localId: $e',
            );
          }
        }
      }

      for (final point in _pendingPoints.toList()) {
        final id = point['session_id'] as String?;
        if (id == null || id.startsWith('local_')) continue;
        await client
            .from('hiking_track_points')
            .upsert(
              point,
              onConflict: 'client_point_id',
              ignoreDuplicates: true,
            );
        await client
            .from('hiking_sessions')
            .update({
              'last_latitude': point['latitude'],
              'last_longitude': point['longitude'],
              'last_point_at': point['recorded_at'],
            })
            .eq('id', id);
        _pendingPoints.removeWhere(
          (queued) => queued['client_point_id'] == point['client_point_id'],
        );
        await _persistPendingData();
      }

      for (final alert in _pendingSosAlerts.toList()) {
        final id = alert['session_id'] as String?;
        if (id != null && id.startsWith('local_')) continue;
        await _tryUploadSosAlert(alert);
      }
    } catch (e) {
      debugPrint('[HikingTracking] Offline sync deferred: $e');
    } finally {
      _isFlushing = false;
    }
  }

  Future<HikingSosResult> sendSos() async {
    try {
      await _restoreSessionIfNeeded().timeout(const Duration(seconds: 8));
    } catch (error) {
      debugPrint('[HikingTracking] SOS session restore timed out: $error');
      return HikingSosResult(
        status: HikingSosStatus.failed,
        failure: HikingSosFailure.sessionInactive,
      );
    }
    if (_isSubmittingSos) {
      return HikingSosResult(
        status: HikingSosStatus.queuedOffline,
        location: _latestRealLocation(),
      );
    }
    _isSubmittingSos = true;
    try {
      final user = Supabase.instance.client.auth.currentUser;
      final sessionId = _sessionId;
      final location = _latestRealLocation();
      if (user == null) {
        return HikingSosResult(
          status: HikingSosStatus.failed,
          failure: HikingSosFailure.signInRequired,
          location: location,
        );
      }
      if (sessionId == null || !isActive || _trackingRegion == null) {
        return HikingSosResult(
          status: HikingSosStatus.failed,
          failure: HikingSosFailure.sessionInactive,
          location: location,
        );
      }
      if (location == null) {
        return const HikingSosResult(
          status: HikingSosStatus.failed,
          failure: HikingSosFailure.locationUnavailable,
        );
      }

      // Reuse an unsent alert for this session so repeated taps do not create
      // duplicate emergencies while the device is offline.
      final queued = _pendingSosAlerts.cast<Map<String, dynamic>?>().firstWhere(
        (alert) =>
            alert != null &&
            alert['user_id'] == user.id &&
            alert['session_id'] == sessionId,
        orElse: () => null,
      );
      if (queued != null) {
        final uploaded = await _tryUploadSosAlert(queued);
        notifyListeners();
        return HikingSosResult(
          status:
              uploaded
                  ? HikingSosStatus.savedToServer
                  : HikingSosStatus.queuedOffline,
          alertId: queued['client_alert_id'] as String?,
          location: _locationFromSosAlert(queued) ?? location,
        );
      }

      final now = DateTime.now();
      final alertId = '${user.id}_${now.microsecondsSinceEpoch}';
      final alert = <String, dynamic>{
        'client_alert_id': alertId,
        'session_id': sessionId,
        'user_id': user.id,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy_meters': location.accuracyMeters,
        'location_recorded_at': location.recordedAt.toUtc().toIso8601String(),
        'message': 'Pengguna meminta bantuan melalui SOS.',
        'status': 'open',
        'created_at': now.toUtc().toIso8601String(),
      };
      _pendingSosAlerts.add(alert);
      try {
        await _persistPendingSosAlerts();
      } catch (error) {
        _pendingSosAlerts.removeWhere(
          (queuedAlert) => queuedAlert['client_alert_id'] == alertId,
        );
        debugPrint('[HikingTracking] SOS local save failed: $error');
        return HikingSosResult(
          status: HikingSosStatus.failed,
          failure: HikingSosFailure.localStorageUnavailable,
          location: location,
        );
      }
      notifyListeners();

      final uploaded = await _tryUploadSosAlert(alert);
      notifyListeners();
      return HikingSosResult(
        status:
            uploaded
                ? HikingSosStatus.savedToServer
                : HikingSosStatus.queuedOffline,
        alertId: alertId,
        location: location,
      );
    } catch (error) {
      debugPrint('[HikingTracking] SOS submission deferred: $error');
      return HikingSosResult(
        status: HikingSosStatus.queuedOffline,
        location: _latestRealLocation(),
      );
    } finally {
      _isSubmittingSos = false;
      notifyListeners();
    }
  }

  Future<bool> retryPendingSos(String alertId) async {
    final alert = _pendingSosAlerts.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['client_alert_id'] == alertId,
      orElse: () => null,
    );
    if (alert == null) return _uploadedSosAlertIds.contains(alertId);
    return _tryUploadSosAlert(alert);
  }

  Future<bool> _tryUploadSosAlert(Map<String, dynamic> alert) async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null || user.id != alert['user_id']) return false;
    try {
      var sessionId = alert['session_id'] as String?;
      if (sessionId != null && sessionId.startsWith('local_')) {
        sessionId = await _ensureRemoteSession(
          sessionId,
        ).timeout(const Duration(seconds: 12));
      }
      if (sessionId == null || sessionId.startsWith('local_')) return false;
      alert['session_id'] = sessionId;
      await client
          .from('hiking_sos_alerts')
          .upsert(alert, onConflict: 'client_alert_id', ignoreDuplicates: true)
          .timeout(const Duration(seconds: 12));
      final alertId = alert['client_alert_id'] as String;
      _pendingSosAlerts.removeWhere(
        (queued) => queued['client_alert_id'] == alertId,
      );
      _uploadedSosAlertIds.add(alertId);
      await _persistPendingData();
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('[HikingTracking] SOS upload deferred: $error');
      return false;
    }
  }

  HikingSosLocation? _latestRealLocation() {
    final region = _trackingRegion;
    if (_locationService.isUsingRealGps &&
        _locationService.lastUpdated != null &&
        region != null &&
        _locationService.isCoordinateWithinHikingRegion(
          region,
          _locationService.userLat,
          _locationService.userLng,
        )) {
      final currentRecordedAt = _locationService.lastUpdated!;
      if (_lastPositionRecordedAt == null ||
          currentRecordedAt.isAfter(_lastPositionRecordedAt!)) {
        return HikingSosLocation(
          latitude: _locationService.userLat,
          longitude: _locationService.userLng,
          recordedAt: currentRecordedAt,
          accuracyMeters: _locationService.accuracyMeters,
        );
      }
    }
    if (_lastLatitude == null ||
        _lastLongitude == null ||
        _lastPositionRecordedAt == null) {
      return null;
    }
    return HikingSosLocation(
      latitude: _lastLatitude!,
      longitude: _lastLongitude!,
      recordedAt: _lastPositionRecordedAt!,
      accuracyMeters: _lastPositionAccuracyMeters,
    );
  }

  HikingSosLocation? _locationFromSosAlert(Map<String, dynamic> alert) {
    try {
      return HikingSosLocation.fromJson({
        'latitude': alert['latitude'],
        'longitude': alert['longitude'],
        'recorded_at': alert['location_recorded_at'],
        'accuracy_meters': alert['accuracy_meters'],
      });
    } catch (_) {
      return null;
    }
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
