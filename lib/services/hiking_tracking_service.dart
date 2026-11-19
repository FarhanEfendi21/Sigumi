import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/hiking_sos.dart';
import 'location_service.dart';
import 'notification_service.dart';

enum HikingTrackingStatus { tracking, outsideGrace, gpsUnavailable }

/// Abstraksi gateway sinkronisasi remote untuk sesi, titik rute, dan SOS pendakian.
abstract class HikingRemoteGateway {
  String? get currentUserId;

  Future<Map<String, dynamic>?> insertSession(Map<String, dynamic> payload);

  Future<String?> upsertSessionByClientId(Map<String, dynamic> payload);

  Future<void> updateSession(String sessionId, Map<String, dynamic> payload);

  Future<void> upsertTrackPointsBatch(List<Map<String, dynamic>> points);

  Future<void> upsertSosAlert(Map<String, dynamic> alert);

  Future<Map<String, dynamic>?> fetchSosAlert({
    String? clientAlertId,
    String? sessionId,
  });
}

class _SupabaseHikingRemoteGateway implements HikingRemoteGateway {
  const _SupabaseHikingRemoteGateway();

  SupabaseClient? get _client {
    try {
      return Supabase.instance.isInitialized ? Supabase.instance.client : null;
    } catch (_) {
      return null;
    }
  }

  @override
  String? get currentUserId => _client?.auth.currentUser?.id;

  @override
  Future<Map<String, dynamic>?> insertSession(
    Map<String, dynamic> payload,
  ) async {
    final client = _client;
    if (client == null) return null;
    final row =
        await client
            .from('hiking_sessions')
            .insert(payload)
            .select('id, started_at')
            .single();
    return Map<String, dynamic>.from(row);
  }

  @override
  Future<String?> upsertSessionByClientId(Map<String, dynamic> payload) async {
    final client = _client;
    if (client == null) return null;
    final row =
        await client
            .from('hiking_sessions')
            .upsert(payload, onConflict: 'client_session_id')
            .select('id')
            .single();
    return row['id'] as String?;
  }

  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    final client = _client;
    if (client == null) throw StateError('Supabase belum terinisialisasi.');
    await client.from('hiking_sessions').update(payload).eq('id', sessionId);
  }

  @override
  Future<void> upsertTrackPointsBatch(List<Map<String, dynamic>> points) async {
    if (points.isEmpty) return;
    final client = _client;
    if (client == null) throw StateError('Supabase belum terinisialisasi.');
    await client
        .from('hiking_track_points')
        .upsert(
          points,
          onConflict: 'client_point_id',
          ignoreDuplicates: true,
        );
  }

  @override
  Future<void> upsertSosAlert(Map<String, dynamic> alert) async {
    final client = _client;
    if (client == null) throw StateError('Supabase belum terinisialisasi.');
    await client
        .from('hiking_sos_alerts')
        .upsert(alert, onConflict: 'client_alert_id', ignoreDuplicates: true)
        .timeout(const Duration(seconds: 12));
  }

  @override
  Future<Map<String, dynamic>?> fetchSosAlert({
    String? clientAlertId,
    String? sessionId,
  }) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;

    const columns =
        'id, client_alert_id, session_id, user_id, latitude, longitude, accuracy_meters, location_recorded_at, message, status, created_at, acknowledged_at, resolved_at';

    if (clientAlertId != null && clientAlertId.isNotEmpty) {
      final row = await client
          .from('hiking_sos_alerts')
          .select(columns)
          .eq('user_id', userId)
          .eq('client_alert_id', clientAlertId)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (row != null) return Map<String, dynamic>.from(row);
    }

    if (sessionId != null &&
        sessionId.isNotEmpty &&
        !sessionId.startsWith('local_')) {
      final row = await client
          .from('hiking_sos_alerts')
          .select(columns)
          .eq('user_id', userId)
          .eq('session_id', sessionId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle()
          .timeout(const Duration(seconds: 10));
      if (row != null) return Map<String, dynamic>.from(row);
    }

    return null;
  }
}

/// Mengelola sesi pendakian real-time, rute GPS lokal, dan sinkronisasi opsional ke Supabase.
class HikingTrackingService extends ChangeNotifier {
  HikingTrackingService({
    LocationService? locationService,
    HikingRemoteGateway? remoteGateway,
  }) : _locationService = locationService ?? LocationService(),
       _remoteGateway = remoteGateway ?? const _SupabaseHikingRemoteGateway() {
    unawaited(_restoreSessionIfNeeded());
  }

  static const _pendingPointsKey = 'hiking_pending_track_points_v1';
  static const _pendingSosKey = 'hiking_pending_sos_alerts_v1';
  static const _activeSessionKey = 'hiking_active_session_v1';
  static const _localSessionsKey = 'hiking_local_sessions_v1';
  static const _maxGpsAccuracyMeters = 100.0;
  static const _outsideGracePeriod = Duration(minutes: 2);
  static const int syncBatchSize = 100;

  final LocationService _locationService;
  final HikingRemoteGateway _remoteGateway;
  VoidCallback? _locationListener;
  Timer? _tickerTimer;
  int _pointSequence = 0;
  int _alertSequence = 0;

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
  DateTime? _sessionGpsBoundaryAt;
  double? _lastPositionAccuracyMeters;
  DateTime? _lastGeofenceFixAt;
  int _consecutiveOutsideRegionFixes = 0;
  int _consecutiveInsideRegionFixes = 0;
  bool _isOutsideGrace = false;
  Duration _outsideGraceElapsed = Duration.zero;
  bool _breakDistanceChain = false;
  HikingTrackingStatus _lastNotifiedTrackingStatus =
      HikingTrackingStatus.tracking;
  final List<LatLng> _routePoints = [];
  final List<List<LatLng>> _routeSegments = [];
  LatLng? _previousLiveGpsPoint;
  LatLng? _currentLiveGpsPoint;
  DateTime? _lastLiveGpsFixAt;
  final List<Map<String, dynamic>> _pendingPoints = [];
  final List<Map<String, dynamic>> _pendingSosAlerts = [];
  final Map<String, Map<String, dynamic>> _localSessions = {};
  Future<void>? _restoreFuture;
  bool _restored = false;
  Future<void>? _flushFuture;
  bool _flushRequestedAgain = false;
  Future<void>? _persistFuture;
  bool _persistRequestedAgain = false;
  bool _isDisposed = false;
  bool _isSubmittingSos = false;
  bool _isRefreshingSosStatus = false;
  String? _activeSosAlertId;
  final Map<String, HikingSosResult> _sosResultsByAlertId = {};
  RealtimeChannel? _sosRealtimeChannel;
  final Set<String> _uploadedSosAlertIds = {};
  final Set<String> _uploadingSosAlertIds = {};

  bool get isActive => _sessionId != null && _endedAt == null;
  bool get isPaused => isActive && _pausedAt != null;
  int get pendingPointsCount => _pendingPoints.length;
  int get pendingSosCount => _pendingSosAlerts.length;
  bool get isRefreshingSosStatus => _isRefreshingSosStatus;
  String? get activeSosAlertId => _activeSosAlertId;
  HikingSosResult? get activeSosResult =>
      _activeSosAlertId != null ? getSosResult(_activeSosAlertId!) : null;
  HikingSosStatus? get activeSosStatus => activeSosResult?.status;
  bool get hasActiveSos {
    final status = activeSosStatus;
    return status != null &&
        status != HikingSosStatus.resolved &&
        status != HikingSosStatus.cancelled &&
        status != HikingSosStatus.failed;
  }

  HikingSosResult? getSosResult(String alertId) {
    final stored = _sosResultsByAlertId[alertId];
    if (stored != null) return stored;
    if (_uploadedSosAlertIds.contains(alertId)) {
      return HikingSosResult(
        status: HikingSosStatus.savedToServer,
        alertId: alertId,
        location: _latestRealLocation(),
      );
    }
    final pending = _pendingSosAlerts.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['client_alert_id'] == alertId,
      orElse: () => null,
    );
    if (pending != null) {
      return HikingSosResult(
        status: HikingSosStatus.queuedOffline,
        alertId: alertId,
        location: _locationFromSosAlert(pending) ?? _latestRealLocation(),
        createdAt: DateTime.tryParse(
          pending['created_at']?.toString() ?? '',
        )?.toLocal(),
      );
    }
    return null;
  }

  /// Memicu pengurasan antrean lokal secara eksplisit (misal saat jaringan pulih atau pengujian).
  Future<void> flushPendingData() => _flushPendingData();
  HikingTrackingStatus get trackingStatus {
    if (isActive && !isPaused && !_hasUsableGpsFix) {
      return HikingTrackingStatus.gpsUnavailable;
    }
    return _isOutsideGrace
        ? HikingTrackingStatus.outsideGrace
        : HikingTrackingStatus.tracking;
  }

  Duration get outsideGraceRemaining {
    final remaining = _outsideGracePeriod - _outsideGraceElapsed;
    return remaining.isNegative ? Duration.zero : remaining;
  }

  double? get distanceFromHikingRadiusKm {
    final region = _trackingRegion;
    if (region == null || !_locationService.hasFreshRealPosition) return null;
    return _locationService.getDistanceToRegion(region) -
        LocationService.hikingTrackingRadiusKm;
  }

  double? get _effectiveAccuracyMeters {
    final accuracy = _locationService.accuracyMeters;
    if (accuracy != null) return accuracy;
    return _locationService.isUsingRealGps ? 0.0 : null;
  }

  bool get _hasUsableGpsFix =>
      _locationService.hasFreshRealPosition &&
      (_effectiveAccuracyMeters ?? double.infinity) <= _maxGpsAccuracyMeters;

  List<LatLng> get liveMovementSegment {
    if (!isActive ||
        isPaused ||
        _isOutsideGrace ||
        !_hasUsableGpsFix ||
        _previousLiveGpsPoint == null ||
        _currentLiveGpsPoint == null ||
        _previousLiveGpsPoint == _currentLiveGpsPoint) {
      return const [];
    }
    return List.unmodifiable([
      _previousLiveGpsPoint!,
      _currentLiveGpsPoint!,
    ]);
  }

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
  List<List<LatLng>> get routeSegments => List.unmodifiable(
    _routeSegments.map((segment) => List<LatLng>.unmodifiable(segment)),
  );
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
        final userId = _remoteGateway.currentUserId;
        if (userId != null) {
          final row = await _remoteGateway.insertSession({
            'user_id': userId,
            'started_at': now.toUtc().toIso8601String(),
            'status': 'active',
          });
          if (row != null) {
            assignedSessionId = row['id'] as String;
            assignedStartedAt =
                DateTime.parse(row['started_at'] as String).toLocal();
          }
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
      _routeSegments
        ..clear()
        ..add(<LatLng>[]);
      _clearLiveMovement();
      _lastUploadedAt = null;
      _lastLatitude = null;
      _lastLongitude = null;
      _lastPositionRecordedAt = null;
      _sessionGpsBoundaryAt = null;
      _lastPositionAccuracyMeters = null;
      _lastGeofenceFixAt = null;
      _consecutiveOutsideRegionFixes = 0;
      _consecutiveInsideRegionFixes = 0;
      _isOutsideGrace = false;
      _outsideGraceElapsed = Duration.zero;
      _breakDistanceChain = false;
      _activeSosAlertId = null;
      _sosResultsByAlertId.clear();
      unawaited(_unsubscribeSosRealtime());
      _lastNotifiedTrackingStatus = HikingTrackingStatus.tracking;
      if (assignedSessionId.startsWith('local_')) {
        _localSessions[assignedSessionId] = {
          'client_session_id': assignedSessionId,
          'user_id': _remoteGateway.currentUserId,
          'started_at': assignedStartedAt.toUtc().toIso8601String(),
          'status': 'active',
          'distance_km': 0,
        };
        await _persistLocalSessions();
      }
      await _persistSessionState();

      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(
        distanceFilterMeters: 5,
        hikingTracking: true,
      );
      _startNewRouteSegment();
      _resetLiveMovementBaseline();
      await _recordCurrentPosition();
      _lastGeofenceFixAt = _locationService.lastUpdated;
      _lastNotifiedTrackingStatus = trackingStatus;

      _startTicker();

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
    if (!_hasUsableGpsFix) {
      _clearLiveMovement();
      _consecutiveOutsideRegionFixes = 0;
      _consecutiveInsideRegionFixes = 0;
      _syncTrackingStatus();
      notifyListeners();
      return;
    }
    if (fixAt == null ||
        (_lastGeofenceFixAt != null && !fixAt.isAfter(_lastGeofenceFixAt!))) {
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
    final accuracyMeters = _effectiveAccuracyMeters!;
    final distanceMeters =
        _locationService.getDistanceToRegion(region) * 1000;
    final radiusMeters = LocationService.hikingTrackingRadiusKm * 1000;
    final confidentlyOutside = distanceMeters > radiusMeters + accuracyMeters;
    final confidentlyInside = distanceMeters <= radiusMeters - accuracyMeters;

    if (confidentlyOutside) {
      _clearLiveMovement();
      _consecutiveOutsideRegionFixes++;
      _consecutiveInsideRegionFixes = 0;
      if (!_isOutsideGrace && _consecutiveOutsideRegionFixes >= 3) {
        _isOutsideGrace = true;
        _outsideGraceElapsed = Duration.zero;
        _startNewRouteSegment();
        _syncTrackingStatus(force: true);
      }
      unawaited(_persistSessionState());
      notifyListeners();
      return;
    }

    _consecutiveOutsideRegionFixes = 0;
    if (confidentlyInside) {
      _consecutiveInsideRegionFixes++;
      if (_isOutsideGrace && _consecutiveInsideRegionFixes >= 2) {
        _isOutsideGrace = false;
        _outsideGraceElapsed = Duration.zero;
        _startNewRouteSegment();
        _syncTrackingStatus(force: true);
      }
    } else {
      // Posisi berada di pita batas yang tidak meyakinkan; pertahankan status.
      _clearLiveMovement();
      _consecutiveInsideRegionFixes = 0;
    }

    if (_isOutsideGrace) {
      notifyListeners();
      return;
    }
    _consecutiveOutsideRegionFixes = 0;
    _syncTrackingStatus();
    if (confidentlyInside) {
      unawaited(_recordCurrentPosition());
    }
    notifyListeners();
  }

  bool _isConfidentlyInsideHikingRegion(String region) {
    final accuracy = _effectiveAccuracyMeters;
    if (accuracy == null || accuracy > _maxGpsAccuracyMeters) return false;
    final distanceMeters = _locationService.getDistanceToRegion(region) * 1000;
    final radiusMeters = LocationService.hikingTrackingRadiusKm * 1000;
    return distanceMeters <= radiusMeters - accuracy;
  }

  void _startNewRouteSegment() {
    _breakDistanceChain = true;
    _clearLiveMovement();
    if (_routeSegments.isEmpty || _routeSegments.last.isNotEmpty) {
      _routeSegments.add(<LatLng>[]);
    }
  }

  void _resetLiveMovementBaseline() {
    _clearLiveMovement();
    final region = _trackingRegion;
    final fixAt = _locationService.lastUpdated;
    if (region == null ||
        fixAt == null ||
        !_hasUsableGpsFix ||
        !_isConfidentlyInsideHikingRegion(region)) {
      return;
    }
    final point = LatLng(_locationService.userLat, _locationService.userLng);
    _previousLiveGpsPoint = point;
    _currentLiveGpsPoint = point;
    _lastLiveGpsFixAt = fixAt;
  }

  void _recordLiveMovementPoint(LatLng point, DateTime fixAt) {
    if (_lastLiveGpsFixAt != null && !fixAt.isAfter(_lastLiveGpsFixAt!)) {
      return;
    }
    if (_currentLiveGpsPoint != null &&
        Geolocator.distanceBetween(
              _currentLiveGpsPoint!.latitude,
              _currentLiveGpsPoint!.longitude,
              point.latitude,
              point.longitude,
            ) <
            0.5) {
      _lastLiveGpsFixAt = fixAt;
      return;
    }
    _previousLiveGpsPoint = _currentLiveGpsPoint ?? point;
    _currentLiveGpsPoint = point;
    _lastLiveGpsFixAt = fixAt;
  }

  void _clearLiveMovement() {
    _previousLiveGpsPoint = null;
    _currentLiveGpsPoint = null;
    _lastLiveGpsFixAt = null;
  }

  void _startTicker() {
    _tickerTimer?.cancel();
    _tickerTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isActive || isPaused) return;
      if (_isOutsideGrace && _hasUsableGpsFix) {
        _outsideGraceElapsed += const Duration(seconds: 1);
        if (_outsideGraceElapsed >= _outsideGracePeriod) {
          _error =
              'Tracking dihentikan setelah 2 menit berada di luar radius pendakian.';
          unawaited(stop());
          return;
        }
      }
      _syncTrackingStatus();
      if (timer.tick % 15 == 0) unawaited(_flushPendingData());
      if (timer.tick % 5 == 0) {
        unawaited(_persistSessionState());
        if (_activeSosAlertId != null && hasActiveSos) {
          unawaited(refreshSosStatus(alertId: _activeSosAlertId));
        }
      }
      notifyListeners();
    });
  }

  void _syncTrackingStatus({bool force = false}) {
    final currentStatus = trackingStatus;
    if (!force && currentStatus == _lastNotifiedTrackingStatus) return;
    final previousStatus = _lastNotifiedTrackingStatus;
    _lastNotifiedTrackingStatus = currentStatus;
    if (currentStatus == HikingTrackingStatus.gpsUnavailable &&
        previousStatus != HikingTrackingStatus.gpsUnavailable) {
      _startNewRouteSegment();
    }
    unawaited(_persistSessionState());

    if (currentStatus == HikingTrackingStatus.tracking ||
        currentStatus == HikingTrackingStatus.outsideGrace ||
        currentStatus == HikingTrackingStatus.gpsUnavailable) {
      if (currentStatus == previousStatus) return;
      final title = switch (currentStatus) {
        HikingTrackingStatus.tracking => 'GPS tracking pulih',
        HikingTrackingStatus.outsideGrace => 'Di luar area tracking',
        HikingTrackingStatus.gpsUnavailable => 'Sinyal GPS bermasalah',
      };
      final body = switch (currentStatus) {
        HikingTrackingStatus.tracking =>
          'Tracking pendakian kembali merekam lokasi.',
        HikingTrackingStatus.outsideGrace =>
          'Pencatatan titik ditahan. Kembali ke area dalam ${_outsideGracePeriod.inMinutes} menit atau tracking akan berakhir.',
        HikingTrackingStatus.gpsUnavailable =>
          'Pencatatan titik ditahan sampai GPS kembali akurat.',
      };
      if (WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
        unawaited(
          NotificationService.instance.showLocalNotification(
            title: title,
            body: body,
            level: 2,
          ),
        );
      }
    }
  }

  Future<void> _recordCurrentPosition() async {
    final sessionId = _sessionId;
    final region = _trackingRegion;
    if (sessionId == null ||
        region == null ||
        !_hasUsableGpsFix ||
        _isOutsideGrace ||
        !_isConfidentlyInsideHikingRegion(region)) {
      return;
    }

    final now = DateTime.now();

    try {
      final latitude = _locationService.userLat;
      final longitude = _locationService.userLng;
      final recordedAt = _locationService.lastUpdated ?? now;
      final accuracyMeters = _locationService.accuracyMeters;
      if ((_sessionGpsBoundaryAt != null &&
              !recordedAt.isAfter(_sessionGpsBoundaryAt!)) ||
          (_lastPositionRecordedAt != null &&
              !recordedAt.isAfter(_lastPositionRecordedAt!))) {
        return;
      }
      if (_lastLatitude != null &&
          _lastLongitude != null &&
          !_breakDistanceChain) {
        final previousAt = _lastPositionRecordedAt;
        if (previousAt == null || !recordedAt.isAfter(previousAt)) return;
        final distanceMeters = Geolocator.distanceBetween(
          _lastLatitude!,
          _lastLongitude!,
          latitude,
          longitude,
        );
        if (distanceMeters < 1.0) {
          _lastLiveGpsFixAt = recordedAt;
          notifyListeners();
          return;
        }
        _distanceKm += distanceMeters / 1000;
      }
      _lastLatitude = latitude;
      _lastLongitude = longitude;
      _lastPositionRecordedAt = recordedAt;
      _lastPositionAccuracyMeters = accuracyMeters;
      _breakDistanceChain = false;
      final point = LatLng(latitude, longitude);
      _routePoints.add(point);
      if (_routeSegments.isEmpty) _routeSegments.add(<LatLng>[]);
      _routeSegments.last.add(point);
      _recordLiveMovementPoint(point, recordedAt);
      _pointsRecorded++;
      final shouldFlushToRemote =
          _lastUploadedAt == null ||
          now.difference(_lastUploadedAt!) >= const Duration(seconds: 5);
      if (shouldFlushToRemote) _lastUploadedAt = now;
      final localSession = _localSessions[sessionId];
      if (localSession != null) {
        localSession['last_latitude'] = latitude;
        localSession['last_longitude'] = longitude;
        localSession['last_point_at'] = recordedAt.toUtc().toIso8601String();
        localSession['last_accuracy_meters'] = accuracyMeters;
        localSession['distance_km'] = _distanceKm;
      }
      _pointSequence++;
      _pendingPoints.add({
        'client_point_id':
            '${sessionId}_${recordedAt.microsecondsSinceEpoch}_$_pointSequence',
        'session_id': sessionId,
        'recorded_at': recordedAt.toUtc().toIso8601String(),
        'latitude': latitude,
        'longitude': longitude,
        'accuracy_meters': accuracyMeters,
      });
      // Update visible distance before local disk or network operations.
      notifyListeners();
      await _persistCheckpoint();
      if (shouldFlushToRemote) unawaited(_flushPendingData());
    } catch (e) {
      debugPrint('[HikingTracking] Point upload error (tetap rekam lokal): $e');
      notifyListeners();
    }
  }

  Future<void> _persistCheckpoint() {
    if (_isDisposed) return Future.value();
    if (_persistFuture != null) {
      _persistRequestedAgain = true;
      return _persistFuture!;
    }
    final future = _runPersistCheckpointLoop();
    _persistFuture = future;
    return future;
  }

  Future<void> _runPersistCheckpointLoop() async {
    try {
      do {
        _persistRequestedAgain = false;
        if (_localSessions.isNotEmpty) {
          await _persistLocalSessions();
        }
        await _persistPendingData();
        await _persistSessionState();
      } while (_persistRequestedAgain && !_isDisposed);
    } finally {
      _persistFuture = null;
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
          !_hasUsableGpsFix ||
          !_isConfidentlyInsideHikingRegion(region)) {
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
      _sessionGpsBoundaryAt = null;
      _consecutiveOutsideRegionFixes = 0;
      _locationListener = _onLocationChanged;
      _locationService.addListener(_locationListener!);
      _locationService.startTracking(
        distanceFilterMeters: 5,
        hikingTracking: true,
      );
      _startNewRouteSegment();
      _resetLiveMovementBaseline();
      await _recordCurrentPosition();
      _lastGeofenceFixAt = _locationService.lastUpdated;
      _lastNotifiedTrackingStatus = trackingStatus;
      _startTicker();
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
      _isOutsideGrace = false;
      _outsideGraceElapsed = Duration.zero;
      final localSession = _localSessions[sessionId];
      if (localSession != null) {
        localSession['status'] = 'completed';
        localSession['ended_at'] = endedAt.toUtc().toIso8601String();
        localSession['distance_km'] = _distanceKm;
      }
      if (!sessionId.startsWith('local_')) {
        await _remoteGateway.updateSession(sessionId, {
          'status': 'completed',
          'ended_at': endedAt.toUtc().toIso8601String(),
          'distance_km': _distanceKm,
        });
      }
      _endedAt = endedAt;
      _pausedAt = null;
    } catch (e) {
      _endedAt = DateTime.now();
      _isOutsideGrace = false;
      _outsideGraceElapsed = Duration.zero;
      debugPrint('[HikingTracking] Stop DB update error (diabaikan): $e');
    } finally {
      _locationService.removeListener(_locationListener ?? () {});
      _locationListener = null;
      _locationService.stopTracking();
      _clearLiveMovement();
      unawaited(_unsubscribeSosRealtime());
      if (!sessionId.startsWith('local_')) _sessionId = null;
      _pausedAt = null;
      _isStopping = false;
      _lastNotifiedTrackingStatus = HikingTrackingStatus.tracking;
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
    unawaited(_unsubscribeSosRealtime());

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
          await _remoteGateway.updateSession(sessionId, {
            'status': 'cancelled',
          });
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
    _routeSegments.clear();
    _clearLiveMovement();
    _lastUploadedAt = null;
    _lastLatitude = null;
    _lastLongitude = null;
    _lastPositionRecordedAt = null;
    _sessionGpsBoundaryAt = null;
    _lastPositionAccuracyMeters = null;
    _consecutiveOutsideRegionFixes = 0;
    _consecutiveInsideRegionFixes = 0;
    _isOutsideGrace = false;
    _outsideGraceElapsed = Duration.zero;
    _breakDistanceChain = false;
    _activeSosAlertId = null;
    _sosResultsByAlertId.clear();
    _uploadedSosAlertIds.clear();
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
        _isOutsideGrace = value['outside_grace'] as bool? ?? false;
        _outsideGraceElapsed = Duration(
          milliseconds:
              (value['outside_grace_elapsed_ms'] as num?)?.toInt() ?? 0,
        );
        _breakDistanceChain =
            value['break_distance_chain'] as bool? ??
            (_isOutsideGrace ||
                value['tracking_status'] ==
                    HikingTrackingStatus.gpsUnavailable.name);
        _lastLatitude = (value['last_latitude'] as num?)?.toDouble();
        _lastLongitude = (value['last_longitude'] as num?)?.toDouble();
        _lastPositionRecordedAt = DateTime.tryParse(
          value['last_position_recorded_at'] as String? ?? '',
        );
        _lastPositionAccuracyMeters =
            (value['last_position_accuracy_meters'] as num?)?.toDouble();
        _routePoints.clear();
        _routeSegments.clear();
        final storedSegments = value['route_segments'] as List<dynamic>?;
        if (storedSegments != null) {
          for (final segment in storedSegments) {
            final points = _decodeRoutePoints(segment as List<dynamic>);
            if (points.isNotEmpty) _routeSegments.add(points);
            _routePoints.addAll(points);
          }
        } else {
          final legacyPoints = _decodeRoutePoints(
            value['route'] as List<dynamic>? ?? const [],
          );
          _routePoints.addAll(legacyPoints);
          if (legacyPoints.isNotEmpty) _routeSegments.add(legacyPoints);
        }
        if (_routeSegments.isEmpty) _routeSegments.add(<LatLng>[]);
        final restoredSosId = value['active_sos_alert_id'] as String?;
        final restoredSosStatusStr = value['active_sos_status'] as String?;
        if (restoredSosId != null && restoredSosId.isNotEmpty) {
          _activeSosAlertId = restoredSosId;
          final restoredStatus = switch (restoredSosStatusStr) {
            'acknowledged' => HikingSosStatus.acknowledged,
            'resolved' => HikingSosStatus.resolved,
            'cancelled' => HikingSosStatus.cancelled,
            'savedToServer' => HikingSosStatus.savedToServer,
            _ => HikingSosStatus.queuedOffline,
          };
          if (restoredStatus != HikingSosStatus.queuedOffline) {
            _uploadedSosAlertIds.add(restoredSosId);
          }
          HikingSosLocation? restoredLocation;
          if (value['active_sos_location'] is Map) {
            try {
              restoredLocation = HikingSosLocation.fromJson(
                Map<String, dynamic>.from(value['active_sos_location'] as Map),
              );
            } catch (_) {}
          }
          _sosResultsByAlertId[restoredSosId] = HikingSosResult(
            status: restoredStatus,
            alertId: restoredSosId,
            remoteId: value['active_sos_remote_id'] as String?,
            location: restoredLocation ?? _latestRealLocation(),
            createdAt: DateTime.tryParse(
              value['active_sos_created_at'] as String? ?? '',
            )?.toLocal(),
            acknowledgedAt: DateTime.tryParse(
              value['active_sos_acknowledged_at'] as String? ?? '',
            )?.toLocal(),
            resolvedAt: DateTime.tryParse(
              value['active_sos_resolved_at'] as String? ?? '',
            )?.toLocal(),
          );
        }
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
            if (_activeSosAlertId != null) {
              _subscribeToSosRealtime();
              unawaited(refreshSosStatus(alertId: _activeSosAlertId));
            }
            notifyListeners();
          } else {
            await _locationService.initialize();
            if (region != null) {
              _lastGeofenceFixAt = null;
              _sessionGpsBoundaryAt = null;
              _locationListener = _onLocationChanged;
              _locationService.addListener(_locationListener!);
              _locationService.startTracking(
                distanceFilterMeters: 5,
                hikingTracking: true,
              );
              _startNewRouteSegment();
              _resetLiveMovementBaseline();
              await _recordCurrentPosition();
              _lastGeofenceFixAt = _locationService.lastUpdated;
              _lastNotifiedTrackingStatus = trackingStatus;
              if (_activeSosAlertId != null) {
                _subscribeToSosRealtime();
                unawaited(refreshSosStatus(alertId: _activeSosAlertId));
              }
              _startTicker();
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
        await _remoteGateway.updateSession(sessionId, {
          'status': 'completed',
          'ended_at': endedAt.toUtc().toIso8601String(),
        });
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

  List<LatLng> _decodeRoutePoints(List<dynamic> values) =>
      values.map((point) {
        final coordinates = point as List<dynamic>;
        return LatLng(
          (coordinates[0] as num).toDouble(),
          (coordinates[1] as num).toDouble(),
        );
      }).toList();

  Future<void> _persistSessionState() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isDisposed) return;
      if (_sessionId == null || _startedAt == null || _endedAt != null) {
        await prefs.remove(_activeSessionKey);
        return;
      }
      final activeSos = activeSosResult;
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
          'outside_grace': _isOutsideGrace,
          'outside_grace_elapsed_ms': _outsideGraceElapsed.inMilliseconds,
          'tracking_status': trackingStatus.name,
          'break_distance_chain': _breakDistanceChain,
          'active_sos_alert_id': _activeSosAlertId,
          'active_sos_remote_id': activeSos?.remoteId,
          'active_sos_status': activeSos?.status.name,
          'active_sos_location': activeSos?.location?.toJson(),
          'active_sos_created_at':
              activeSos?.createdAt?.toUtc().toIso8601String(),
          'active_sos_acknowledged_at':
              activeSos?.acknowledgedAt?.toUtc().toIso8601String(),
          'active_sos_resolved_at':
              activeSos?.resolvedAt?.toUtc().toIso8601String(),
          'route_segments':
              _routeSegments
                  .map(
                    (segment) =>
                        segment
                            .map((point) => [point.latitude, point.longitude])
                            .toList(),
                  )
                  .toList(),
        }),
      );
    } catch (e) {
      debugPrint('[HikingTracking] Session persistence failed: $e');
    }
  }

  Future<void> _persistPendingData() async {
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isDisposed) return;
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
    if (_isDisposed) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_isDisposed) return;
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
    final userId = session['user_id'] as String? ?? _remoteGateway.currentUserId;
    if (userId == null) return null;

    final remoteSessionId = await _remoteGateway.upsertSessionByClientId({
      'client_session_id': session['client_session_id'] ?? localSessionId,
      'user_id': userId,
      'started_at': session['started_at'],
      'status': session['status'] ?? 'active',
      'ended_at': session['ended_at'],
      'distance_km': session['distance_km'] ?? 0,
      'last_latitude': session['last_latitude'],
      'last_longitude': session['last_longitude'],
      'last_point_at': session['last_point_at'],
    });
    if (remoteSessionId == null) return null;
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

  Future<void> _flushPendingData() {
    if (_isDisposed) return Future.value();
    if (_flushFuture != null) {
      _flushRequestedAgain = true;
      return _flushFuture!;
    }
    final future = _runFlushLoop();
    _flushFuture = future;
    return future;
  }

  Future<void> _runFlushLoop() async {
    try {
      do {
        _flushRequestedAgain = false;
        await _flushPendingDataOnce();
      } while (_flushRequestedAgain && !_isDisposed);
    } finally {
      _flushFuture = null;
    }
  }

  Future<void> _flushPendingDataOnce() async {
    try {
      if (_isDisposed || _remoteGateway.currentUserId == null) return;
      for (final localId in _localSessions.keys.toList()) {
        if (localId.startsWith('local_') &&
            _localSessions[localId]?['remote_id'] == null) {
          try {
            await _ensureRemoteSession(localId);
          } catch (e) {
            debugPrint(
              '[HikingTracking] Session sync deferred for $localId: $e',
            );
          }
        }
      }

      // Kelompokkan titik yang siap dikirim berdasarkan session_id, lalu kirim per batch
      final readyBySession = <String, List<Map<String, dynamic>>>{};
      for (final point in _pendingPoints) {
        final id = point['session_id'] as String?;
        if (id == null || id.startsWith('local_')) continue;
        (readyBySession[id] ??= <Map<String, dynamic>>[]).add(point);
      }

      for (final entry in readyBySession.entries) {
        final sessionId = entry.key;
        final sessionPoints = entry.value;
        for (var i = 0; i < sessionPoints.length; i += syncBatchSize) {
          final end =
              (i + syncBatchSize < sessionPoints.length)
                  ? i + syncBatchSize
                  : sessionPoints.length;
          final batch = sessionPoints.sublist(i, end);

          await _remoteGateway.upsertTrackPointsBatch(batch);

          final lastPoint = batch.last;
          final sessionUpdate = <String, dynamic>{
            'last_latitude': lastPoint['latitude'],
            'last_longitude': lastPoint['longitude'],
            'last_point_at': lastPoint['recorded_at'],
          };
          if (_sessionId == sessionId && isActive) {
            sessionUpdate['distance_km'] = _distanceKm;
          }
          await _remoteGateway.updateSession(sessionId, sessionUpdate);

          final flushedIds =
              batch.map((point) => point['client_point_id']).toSet();
          _pendingPoints.removeWhere(
            (queued) => flushedIds.contains(queued['client_point_id']),
          );
          await _persistPendingData();
        }
      }

      for (final alert in _pendingSosAlerts.toList()) {
        final id = alert['session_id'] as String?;
        if (id != null && id.startsWith('local_')) continue;
        await _tryUploadSosAlert(alert);
      }
    } catch (e) {
      debugPrint('[HikingTracking] Offline sync deferred: $e');
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
      final active = activeSosResult;
      if (active != null) return active;
      return HikingSosResult(
        status: HikingSosStatus.queuedOffline,
        location: _latestRealLocation(),
      );
    }
    _isSubmittingSos = true;
    try {
      final userId = _remoteGateway.currentUserId;
      final sessionId = _sessionId;
      final location = _latestRealLocation();
      if (userId == null) {
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
            alert['user_id'] == userId &&
            (alert['session_id'] == sessionId ||
                _localSessions[alert['session_id']]?['remote_id'] == sessionId),
        orElse: () => null,
      );
      if (queued != null) {
        final queuedId = queued['client_alert_id'] as String?;
        if (queuedId != null) _activeSosAlertId = queuedId;
        final uploaded = await _tryUploadSosAlert(queued);
        notifyListeners();
        if (queuedId != null) {
          final existing = getSosResult(queuedId);
          if (existing != null) return existing;
        }
        return HikingSosResult(
          status:
              uploaded
                  ? HikingSosStatus.savedToServer
                  : HikingSosStatus.queuedOffline,
          alertId: queuedId,
          location: _locationFromSosAlert(queued) ?? location,
        );
      }

      // If an active (non-resolved/non-cancelled) SOS was already uploaded in
      // this session, sync and return its latest backoffice handling status
      // rather than inserting a duplicate alert row.
      final existingActiveId = _activeSosAlertId;
      if (existingActiveId != null &&
          hasActiveSos &&
          _uploadedSosAlertIds.contains(existingActiveId)) {
        final refreshed = await refreshSosStatus(alertId: existingActiveId);
        notifyListeners();
        if (refreshed != null) return refreshed;
        final cached = getSosResult(existingActiveId);
        if (cached != null) return cached;
      }

      final now = DateTime.now();
      _alertSequence++;
      final alertId = '${userId}_${now.microsecondsSinceEpoch}_$_alertSequence';
      final alert = <String, dynamic>{
        'client_alert_id': alertId,
        'session_id': sessionId,
        'user_id': userId,
        'latitude': location.latitude,
        'longitude': location.longitude,
        'accuracy_meters': location.accuracyMeters,
        'location_recorded_at': location.recordedAt.toUtc().toIso8601String(),
        'message': 'Pengguna meminta bantuan melalui SOS.',
        'status': 'open',
        'created_at': now.toUtc().toIso8601String(),
      };
      _activeSosAlertId = alertId;
      _sosResultsByAlertId[alertId] = HikingSosResult(
        status: HikingSosStatus.queuedOffline,
        alertId: alertId,
        location: location,
        createdAt: now,
      );
      _pendingSosAlerts.add(alert);
      try {
        await _persistPendingSosAlerts();
        await _persistSessionState();
      } catch (error) {
        _pendingSosAlerts.removeWhere(
          (queuedAlert) => queuedAlert['client_alert_id'] == alertId,
        );
        _sosResultsByAlertId.remove(alertId);
        if (_activeSosAlertId == alertId) _activeSosAlertId = null;
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
      return getSosResult(alertId) ??
          HikingSosResult(
            status:
                uploaded
                    ? HikingSosStatus.savedToServer
                    : HikingSosStatus.queuedOffline,
            alertId: alertId,
            location: location,
            createdAt: now,
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
    if (alert == null) {
      if (_uploadedSosAlertIds.contains(alertId)) {
        unawaited(refreshSosStatus(alertId: alertId));
        return true;
      }
      return false;
    }
    return _tryUploadSosAlert(alert);
  }

  Future<bool> _tryUploadSosAlert(Map<String, dynamic> alert) async {
    final userId = _remoteGateway.currentUserId;
    if (userId == null || userId != alert['user_id']) return false;
    final alertId = alert['client_alert_id'] as String?;
    if (alertId == null) return false;
    if (_uploadedSosAlertIds.contains(alertId)) return true;
    if (_uploadingSosAlertIds.contains(alertId)) return false;
    _uploadingSosAlertIds.add(alertId);
    try {
      var sessionId = alert['session_id'] as String?;
      if (sessionId != null && sessionId.startsWith('local_')) {
        sessionId = await _ensureRemoteSession(
          sessionId,
        ).timeout(const Duration(seconds: 12));
      }
      if (sessionId == null || sessionId.startsWith('local_')) return false;
      alert['session_id'] = sessionId;
      await _remoteGateway.upsertSosAlert(alert);
      _pendingSosAlerts.removeWhere(
        (queued) => queued['client_alert_id'] == alertId,
      );
      _uploadedSosAlertIds.add(alertId);
      _activeSosAlertId ??= alertId;
      final previous = _sosResultsByAlertId[alertId];
      final fallbackLocation =
          previous?.location ?? _locationFromSosAlert(alert) ?? _latestRealLocation();
      final createdAt =
          previous?.createdAt ??
          DateTime.tryParse(alert['created_at']?.toString() ?? '')?.toLocal();
      _sosResultsByAlertId[alertId] = HikingSosResult(
        status:
            previous != null && previous.isServerStored
                ? previous.status
                : HikingSosStatus.savedToServer,
        alertId: alertId,
        remoteId: previous?.remoteId,
        location: fallbackLocation,
        createdAt: createdAt,
        acknowledgedAt: previous?.acknowledgedAt,
        resolvedAt: previous?.resolvedAt,
      );
      await _persistPendingData();
      await _persistSessionState();
      _subscribeToSosRealtime();
      notifyListeners();
      return true;
    } catch (error) {
      debugPrint('[HikingTracking] SOS upload deferred: $error');
      return false;
    } finally {
      _uploadingSosAlertIds.remove(alertId);
    }
  }

  /// Mengambil status penanganan SOS terbaru dari server/Backoffice
  /// (`open` -> `acknowledged` -> `resolved` / `cancelled`).
  Future<HikingSosResult?> refreshSosStatus({String? alertId}) async {
    final targetAlertId = alertId ?? _activeSosAlertId;
    if (_isDisposed || (targetAlertId == null && _sessionId == null)) {
      return null;
    }
    if (_isRefreshingSosStatus) {
      return targetAlertId != null ? getSosResult(targetAlertId) : activeSosResult;
    }
    _isRefreshingSosStatus = true;
    try {
      final row = await _remoteGateway.fetchSosAlert(
        clientAlertId: targetAlertId,
        sessionId: _sessionId,
      );
      if (row == null) {
        return targetAlertId != null
            ? getSosResult(targetAlertId)
            : activeSosResult;
      }
      return await _applyRemoteSosRow(row);
    } catch (error) {
      debugPrint('[HikingTracking] SOS status refresh deferred: $error');
      return targetAlertId != null
          ? getSosResult(targetAlertId)
          : activeSosResult;
    } finally {
      _isRefreshingSosStatus = false;
    }
  }

  Future<HikingSosResult?> _applyRemoteSosRow(Map<String, dynamic> row) async {
    final clientAlertId =
        row['client_alert_id']?.toString() ??
        _activeSosAlertId ??
        row['id']?.toString();
    if (clientAlertId == null || clientAlertId.isEmpty) return null;

    final previous = _sosResultsByAlertId[clientAlertId];
    final newStatus = parseHikingSosServerStatus(row['status']?.toString());
    final remoteId = row['id']?.toString() ?? previous?.remoteId;
    final location =
        _locationFromSosAlert(row) ?? previous?.location ?? _latestRealLocation();
    final createdAt =
        DateTime.tryParse(row['created_at']?.toString() ?? '')?.toLocal() ??
        previous?.createdAt;
    final acknowledgedAt =
        DateTime.tryParse(row['acknowledged_at']?.toString() ?? '')?.toLocal() ??
        previous?.acknowledgedAt;
    final resolvedAt =
        DateTime.tryParse(row['resolved_at']?.toString() ?? '')?.toLocal() ??
        previous?.resolvedAt;

    final updatedResult = HikingSosResult(
      status: newStatus,
      alertId: clientAlertId,
      remoteId: remoteId,
      location: location,
      createdAt: createdAt,
      acknowledgedAt: acknowledgedAt,
      resolvedAt: resolvedAt,
    );

    _sosResultsByAlertId[clientAlertId] = updatedResult;
    _uploadedSosAlertIds.add(clientAlertId);
    _activeSosAlertId ??= clientAlertId;
    _pendingSosAlerts.removeWhere(
      (queued) => queued['client_alert_id'] == clientAlertId,
    );

    final statusChanged = previous?.status != newStatus;
    if (statusChanged) {
      await _persistPendingData();
      await _persistSessionState();
      if (newStatus == HikingSosStatus.acknowledged &&
          previous?.status != HikingSosStatus.acknowledged) {
        unawaited(
          NotificationService.instance.showLocalNotification(
            title: 'Sinyal SOS Diterima Petugas SAR',
            body:
                'Tim BPBD/MDMC sedang menangani laporan darurat Anda. Tetap tenang di lokasi aman.',
            level: 3,
          ),
        );
      } else if (newStatus == HikingSosStatus.resolved &&
          previous?.status != HikingSosStatus.resolved) {
        unawaited(
          NotificationService.instance.showLocalNotification(
            title: 'Penanganan SOS Selesai',
            body:
                'Petugas SAR telah menandai penanganan sinyal darurat Anda selesai.',
            level: 1,
          ),
        );
      }
    }
    notifyListeners();
    return updatedResult;
  }

  void _subscribeToSosRealtime() {
    if (_isDisposed ||
        _sosRealtimeChannel != null ||
        _remoteGateway is! _SupabaseHikingRemoteGateway) {
      return;
    }
    try {
      final client = (_remoteGateway as _SupabaseHikingRemoteGateway)._client;
      final userId = client?.auth.currentUser?.id;
      if (client == null || userId == null) return;

      final channel = client.channel('mobile_hiking_sos_$userId');
      channel
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'hiking_sos_alerts',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_id',
              value: userId,
            ),
            callback: (payload) {
              if (_isDisposed) return;
              final newRecord = payload.newRecord;
              if (newRecord.isNotEmpty) {
                unawaited(
                  _applyRemoteSosRow(Map<String, dynamic>.from(newRecord)),
                );
              }
            },
          )
          .subscribe();
      _sosRealtimeChannel = channel;
    } catch (e) {
      debugPrint('[HikingTracking] Realtime SOS subscription skipped: $e');
    }
  }

  Future<void> _unsubscribeSosRealtime() async {
    final channel = _sosRealtimeChannel;
    _sosRealtimeChannel = null;
    if (channel == null || _remoteGateway is! _SupabaseHikingRemoteGateway) {
      return;
    }
    try {
      final client = (_remoteGateway as _SupabaseHikingRemoteGateway)._client;
      await client?.removeChannel(channel);
    } catch (_) {}
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
    _isDisposed = true;
    _tickerTimer?.cancel();
    _tickerTimer = null;
    unawaited(_unsubscribeSosRealtime());
    _locationService.removeListener(_locationListener ?? () {});
    _locationService.stopTracking();
    super.dispose();
  }
}
