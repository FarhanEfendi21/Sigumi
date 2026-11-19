import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/models/chat_message.dart';
import 'package:sigumi/models/hiking_sos.dart';
import 'package:sigumi/services/chatbot_engine.dart';
import 'package:sigumi/services/cloud_llm_service.dart';
import 'package:sigumi/services/hiking_tracking_service.dart';
import 'package:sigumi/services/location_service.dart';

class StressFakeLocationService extends ChangeNotifier
    implements LocationService {
  double _lat = -8.4050;
  double _lng = 116.4680;
  bool _usingRealGps = true;
  bool _tracking = false;
  DateTime? _lastUpdated = DateTime.now();
  double? _accuracyMeters = 6.0;
  GpsStatus _gpsStatus = GpsStatus.active;
  String? _error;

  @override
  double get userLat => _lat;

  @override
  double get userLng => _lng;

  @override
  bool get isUsingRealGps => _usingRealGps;

  @override
  bool get isTracking => _tracking;

  @override
  DateTime? get lastUpdated => _lastUpdated;

  @override
  double? get accuracyMeters => _accuracyMeters;

  @override
  GpsStatus get gpsStatus => _gpsStatus;

  @override
  String? get locationError => _error;

  @override
  bool get isRetrying => false;

  @override
  String? get nearestVolcanoId => 'rinjani_001';

  @override
  String get nearestVolcanoName => 'Gunung Rinjani';

  @override
  String get activeVolcanoName => 'Gunung Rinjani';

  @override
  double get distanceFromVolcano => getDistanceToRegion('lombok');

  @override
  int get zoneLevel => 2;

  @override
  String get zoneLabel => 'Zona Perhatian';

  @override
  int get volcanoStatusLevel => 1;

  @override
  String? get detectedRegion => 'Lombok';

  @override
  bool get isRegionAutoDetected => true;

  @override
  String get distanceLabel => '';

  @override
  Map<String, double> get allVolcanoDistances => {
    'Yogyakarta': getDistanceToRegion('Yogyakarta'),
    'Bali': getDistanceToRegion('Bali'),
    'Lombok': getDistanceToRegion('Lombok'),
  };

  @override
  bool get hasFreshRealPosition {
    final updatedAt = _lastUpdated;
    if (!_usingRealGps || updatedAt == null) return false;
    final age = DateTime.now().difference(updatedAt);
    return age >= const Duration(seconds: -300) &&
        age <= const Duration(minutes: 2);
  }

  @override
  double getDistanceToRegion(String region) {
    final normalizedRegion = region.trim().toLowerCase();
    for (final entry in LocationService.regionCenters.entries) {
      if (entry.key.toLowerCase() == normalizedRegion) {
        return _haversineDistance(
          _lat,
          _lng,
          entry.value['lat']!,
          entry.value['lng']!,
        );
      }
    }
    return 0;
  }

  @override
  bool isWithinHikingRegion(String region) =>
      hasFreshRealPosition &&
      isCoordinateWithinHikingRegion(region, _lat, _lng);

  @override
  bool isCoordinateWithinHikingRegion(
    String region,
    double latitude,
    double longitude,
  ) {
    final normalizedRegion = region.trim().toLowerCase();
    for (final entry in LocationService.regionCenters.entries) {
      if (entry.key.toLowerCase() == normalizedRegion) {
        return _haversineDistance(
              latitude,
              longitude,
              entry.value['lat']!,
              entry.value['lng']!,
            ) <=
            LocationService.hikingTrackingRadiusKm;
      }
    }
    return false;
  }

  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadius = 6371.0;
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  @override
  String getClosestRegion() => 'Lombok';

  @override
  String? detectRegion() => 'Lombok';

  @override
  Future<void> initialize() async {
    _gpsStatus = GpsStatus.active;
    _lastUpdated ??= DateTime.now();
    notifyListeners();
  }

  @override
  void startTracking({
    int distanceFilterMeters = 50,
    bool hikingTracking = false,
  }) {
    _tracking = true;
  }

  @override
  void stopTracking() {
    _tracking = false;
  }

  @override
  Future<void> retryTracking() async {}

  @override
  void clearLocationError() {}

  @override
  void setActiveVolcano({
    required double lat,
    required double lng,
    required String name,
  }) {}

  @override
  Future<void> setManualLocation(double lat, double lng) async {}

  @override
  Future<void> refreshLocation() async {}

  void emitFix({
    required double lat,
    required double lng,
    required DateTime timestamp,
    double? accuracyMeters = 6.0,
    bool realGps = true,
  }) {
    _lat = lat;
    _lng = lng;
    _usingRealGps = realGps;
    _accuracyMeters = accuracyMeters;
    _lastUpdated = timestamp;
    _gpsStatus = GpsStatus.active;
    notifyListeners();
  }
}

/// Simulasi backend Supabase untuk menguji antrean offline, kegagalan jaringan parsial,
/// batching, dan idempotensi/deduplikasi tanpa mengirim data ke produksi/petugas SAR nyata.
class SimulatedRemoteGateway implements HikingRemoteGateway {
  SimulatedRemoteGateway({this.userId = 'synthetic_user_001'});

  String? userId;
  bool isOnline = false;
  int failAfterBatchCount = -1;
  Duration simulatedLatency = Duration.zero;

  int sessionInsertCalls = 0;
  int sessionUpsertCalls = 0;
  int sessionUpdateCalls = 0;
  int pointBatchUpsertCalls = 0;
  int sosUpsertCalls = 0;
  int duplicatePointsPrevented = 0;
  int duplicateSosPrevented = 0;

  final Map<String, Map<String, dynamic>> sessionsById = {};
  final Map<String, String> remoteIdByClientSessionId = {};
  final Map<String, Map<String, dynamic>> trackPointsByClientId = {};
  final Map<String, Map<String, dynamic>> sosAlertsByClientId = {};

  @override
  String? get currentUserId => userId;

  Future<void> _maybeDelayAndCheckOnline() async {
    if (simulatedLatency > Duration.zero) {
      await Future<void>.delayed(simulatedLatency);
    }
    if (!isOnline) {
      throw StateError('Simulated network offline');
    }
  }

  @override
  Future<Map<String, dynamic>?> insertSession(
    Map<String, dynamic> payload,
  ) async {
    sessionInsertCalls++;
    await _maybeDelayAndCheckOnline();
    final remoteId = 'remote_session_${sessionsById.length + 1}';
    final row = {
      ...payload,
      'id': remoteId,
      'started_at':
          payload['started_at'] ?? DateTime.now().toUtc().toIso8601String(),
    };
    sessionsById[remoteId] = row;
    return row;
  }

  @override
  Future<String?> upsertSessionByClientId(Map<String, dynamic> payload) async {
    sessionUpsertCalls++;
    await _maybeDelayAndCheckOnline();
    final clientSessionId = payload['client_session_id'] as String;
    final existingRemoteId = remoteIdByClientSessionId[clientSessionId];
    if (existingRemoteId != null) {
      sessionsById[existingRemoteId] = {
        ...?sessionsById[existingRemoteId],
        ...payload,
        'id': existingRemoteId,
      };
      return existingRemoteId;
    }
    final remoteId = 'remote_session_${sessionsById.length + 1}';
    remoteIdByClientSessionId[clientSessionId] = remoteId;
    sessionsById[remoteId] = {...payload, 'id': remoteId};
    return remoteId;
  }

  @override
  Future<void> updateSession(
    String sessionId,
    Map<String, dynamic> payload,
  ) async {
    sessionUpdateCalls++;
    await _maybeDelayAndCheckOnline();
    sessionsById[sessionId] = {
      ...?sessionsById[sessionId],
      ...payload,
      'id': sessionId,
    };
  }

  @override
  Future<void> upsertTrackPointsBatch(List<Map<String, dynamic>> points) async {
    await _maybeDelayAndCheckOnline();
    if (failAfterBatchCount >= 0 &&
        pointBatchUpsertCalls >= failAfterBatchCount) {
      throw StateError('Simulated connection drop mid-sync');
    }
    pointBatchUpsertCalls++;
    for (final point in points) {
      final clientPointId = point['client_point_id'] as String;
      if (trackPointsByClientId.containsKey(clientPointId)) {
        duplicatePointsPrevented++;
      } else {
        trackPointsByClientId[clientPointId] = Map<String, dynamic>.from(point);
      }
    }
  }

  @override
  Future<void> upsertSosAlert(Map<String, dynamic> alert) async {
    sosUpsertCalls++;
    await _maybeDelayAndCheckOnline();
    final clientAlertId = alert['client_alert_id'] as String;
    if (sosAlertsByClientId.containsKey(clientAlertId)) {
      duplicateSosPrevented++;
    } else {
      sosAlertsByClientId[clientAlertId] = {
        ...alert,
        'id': 'remote_sos_${sosAlertsByClientId.length + 1}',
      };
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchSosAlert({
    String? clientAlertId,
    String? sessionId,
  }) async {
    await _maybeDelayAndCheckOnline();
    if (clientAlertId != null && sosAlertsByClientId.containsKey(clientAlertId)) {
      return Map<String, dynamic>.from(sosAlertsByClientId[clientAlertId]!);
    }
    if (sessionId != null) {
      for (final alert in sosAlertsByClientId.values.toList().reversed) {
        if (alert['session_id'] == sessionId) {
          return Map<String, dynamic>.from(alert);
        }
      }
    }
    return null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SIGUMI Mobile Stress & Resilience Suite', () {
    test(
      'P0 Stress 1: 1.440 titik GPS offline (simulasi 2 jam pendakian), restart aplikasi, koneksi putus di tengah sinkronisasi, lalu pulih penuh (0 data hilang, 0 duplikat)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final fakeLocation = StressFakeLocationService();
        final gateway = SimulatedRemoteGateway()..isOnline = false;

        var service = HikingTrackingService(
          locationService: fakeLocation,
          remoteGateway: gateway,
        );
        await service.ensureRestored();

        final baseTime = DateTime.now().subtract(const Duration(minutes: 1));
        fakeLocation.emitFix(
          lat: -8.40500,
          lng: 116.46800,
          timestamp: baseTime,
          accuracyMeters: 5.0,
        );

        final started = await service.start(region: 'lombok');
        expect(started, isTrue);
        expect(service.sessionId, startsWith('local_'));
        expect(service.pointsRecorded, 1);

        // Simulasikan 1.439 pergerakan berikutnya (total 1.440 titik = 2 jam @ 5 detik)
        const totalTargetPoints = 1440;
        final recordWatch = Stopwatch()..start();
        for (var i = 1; i < totalTargetPoints; i++) {
          // Bergerak ~2 meter zig-zag di dalam area radius Rinjani (< 15 km)
          final latOffset = (i % 200) * 0.00002;
          final lngOffset = ((i ~/ 200) % 200) * 0.00002;
          fakeLocation.emitFix(
            lat: -8.40500 + latOffset,
            lng: 116.46800 + lngOffset,
            timestamp: baseTime.add(Duration(microseconds: i * 100)),
            accuracyMeters: 5.0,
          );
        }
        await Future<void>.delayed(const Duration(milliseconds: 50));
        recordWatch.stop();

        expect(service.pointsRecorded, totalTargetPoints);
        expect(service.pendingPointsCount, totalTargetPoints);
        expect(service.distanceKm, greaterThan(2.5));

        // Simulasikan aplikasi di-force close lalu dibuka kembali (cold start restore)
        service.dispose();
        final restoredService = HikingTrackingService(
          locationService: fakeLocation,
          remoteGateway: gateway,
        );
        await restoredService.ensureRestored();

        expect(restoredService.isActive, isTrue);
        expect(restoredService.pointsRecorded, totalTargetPoints);
        expect(restoredService.pendingPointsCount, totalTargetPoints);
        expect(restoredService.routePoints.length, totalTargetPoints);

        // Fase 1 pemulihan jaringan: koneksi hidup tapi putus setelah 4 batch (400 titik)
        gateway
          ..isOnline = true
          ..failAfterBatchCount = 4;
        await restoredService.flushPendingData();

        expect(gateway.trackPointsByClientId.length, 400);
        expect(
          restoredService.pendingPointsCount,
          totalTargetPoints - 400,
          reason:
              'Titik yang belum terkirim tidak boleh hilang saat jaringan putus di tengah batch',
        );

        // Fase 2 pemulihan jaringan: koneksi stabil, kuras sisa antrean + uji idempotensi
        gateway.failAfterBatchCount = -1;
        final drainWatch = Stopwatch()..start();
        await restoredService.flushPendingData();
        drainWatch.stop();

        expect(restoredService.pendingPointsCount, 0);
        expect(
          gateway.trackPointsByClientId.length,
          totalTargetPoints,
          reason: 'Target P0: 0 data hilang dari 1.440 titik unik',
        );
        expect(
          gateway.duplicatePointsPrevented,
          0,
          reason: 'Target P0: 0 titik duplikat dikirim ulang dari antrean',
        );
        // 1.440 titik dengan batch 100 hanya butuh 15 panggilan batch upsert (4 di fase 1 + 11 di fase 2)
        expect(gateway.pointBatchUpsertCalls, 15);

        debugPrint(
          '[Stress Metric] 1.440 titik GPS direkam dalam ${recordWatch.elapsedMilliseconds} ms, '
          'dikuras ke server dalam ${drainWatch.elapsedMilliseconds} ms (${gateway.pointBatchUpsertCalls} batch requests).',
        );

        restoredService.dispose();
      },
    );

    test(
      'P0 Stress 2: Rapid-tap 50x tombol SOS saat offline & 20x retry konkuren saat online menghasilkan tepat 1 alert unik (0 duplikat)',
      () async {
        SharedPreferences.setMockInitialValues({});
        final fakeLocation = StressFakeLocationService();
        final gateway =
            SimulatedRemoteGateway()
              ..isOnline = false
              ..simulatedLatency = const Duration(milliseconds: 10);

        final service = HikingTrackingService(
          locationService: fakeLocation,
          remoteGateway: gateway,
        );
        await service.ensureRestored();

        final t0 = DateTime.now().subtract(const Duration(seconds: 20));
        fakeLocation.emitFix(
          lat: -8.40500,
          lng: 116.46800,
          timestamp: t0,
          accuracyMeters: 6.0,
        );
        await service.start(region: 'lombok');

        // Simulasikan pengguna panik menekan tombol SOS 50 kali berturut-turut/konkuren saat offline
        final offlineResults = await Future.wait(
          List.generate(50, (_) => service.sendSos()),
        );

        // Semua respons saat offline wajib jujur (queuedOffline, BUKAN savedToServer)
        for (final res in offlineResults) {
          expect(res.status, HikingSosStatus.queuedOffline);
        }
        expect(
          service.pendingSosCount,
          1,
          reason: '50 tap SOS pada sesi yang sama hanya boleh membuat 1 antrean SOS',
        );
        final alertId = offlineResults.firstWhere((r) => r.alertId != null).alertId!;
        expect(service.isSosPending(alertId), isTrue);
        expect(service.wasSosUploaded(alertId), isFalse);

        // Koneksi pulih: jalankan 20 retry + flush secara bersamaan
        gateway.isOnline = true;
        await Future.wait([
          ...List.generate(15, (_) => service.retryPendingSos(alertId)),
          ...List.generate(5, (_) => service.flushPendingData()),
        ]);

        expect(service.pendingSosCount, 0);
        expect(service.isSosPending(alertId), isFalse);
        expect(service.wasSosUploaded(alertId), isTrue);
        expect(
          gateway.sosAlertsByClientId.length,
          1,
          reason: 'Target P0: Tepat 1 alert SOS unik di server (0 alert duplikat)',
        );
        expect(gateway.duplicateSosPrevented, 0);
        expect(service.activeSosStatus, HikingSosStatus.savedToServer);

        // Simulasikan petugas BPBD/MDMC di Backoffice mengonfirmasi penanganan (acknowledged)
        final ackAt = DateTime.now().toUtc().toIso8601String();
        gateway.sosAlertsByClientId[alertId]!['status'] = 'acknowledged';
        gateway.sosAlertsByClientId[alertId]!['acknowledged_at'] = ackAt;

        // Saat panel SOS dibuka kembali (sendSos) atau refreshSosStatus dipanggil:
        // tidak membuat alert baru, melainkan menyinkronkan status 'acknowledged'
        final ackResult = await service.sendSos();
        expect(ackResult.status, HikingSosStatus.acknowledged);
        expect(ackResult.acknowledgedAt, isNotNull);
        expect(gateway.sosAlertsByClientId.length, 1);

        // Simulasikan petugas Backoffice menyelesaikan penanganan (resolved)
        final resolvedAt = DateTime.now().toUtc().toIso8601String();
        gateway.sosAlertsByClientId[alertId]!['status'] = 'resolved';
        gateway.sosAlertsByClientId[alertId]!['resolved_at'] = resolvedAt;

        final resolvedResult = await service.refreshSosStatus(alertId: alertId);
        expect(resolvedResult?.status, HikingSosStatus.resolved);
        expect(resolvedResult?.resolvedAt, isNotNull);
        expect(service.hasActiveSos, isFalse);

        service.dispose();
      },
    );

    test(
      'P0 Stress 3: Fluktuasi sinyal GPS ekstrem (akurasi buruk, timestamp mundur, keluar-masuk batas radius) menjaga integritas jarak',
      () async {
        SharedPreferences.setMockInitialValues({});
        final fakeLocation = StressFakeLocationService();
        final gateway = SimulatedRemoteGateway()..isOnline = true;

        final service = HikingTrackingService(
          locationService: fakeLocation,
          remoteGateway: gateway,
        );
        await service.ensureRestored();

        var t = DateTime.now().subtract(const Duration(seconds: 30));
        fakeLocation.emitFix(
          lat: -8.40500,
          lng: 116.46800,
          timestamp: t,
          accuracyMeters: 6.0,
        );
        await service.start(region: 'lombok');
        expect(service.pointsRecorded, 1);

        // 1. Gerak normal 10 langkah (~11m per langkah)
        for (var i = 1; i <= 10; i++) {
          t = t.add(const Duration(microseconds: 500));
          fakeLocation.emitFix(
            lat: -8.40500 + (i * 0.00010),
            lng: 116.46800,
            timestamp: t,
            accuracyMeters: 6.0,
          );
        }
        await Future<void>.delayed(Duration.zero);
        final validDistanceAfter10Steps = service.distanceKm;
        expect(service.pointsRecorded, 11);
        expect(validDistanceAfter10Steps, greaterThan(0.10));

        // 2. Serangan 100 sinyal GPS rusak (akurasi > 100m & lonjakan koordinat jauh)
        for (var i = 0; i < 100; i++) {
          t = t.add(const Duration(microseconds: 500));
          fakeLocation.emitFix(
            lat: -8.35000 + (i * 0.001),
            lng: 116.50000,
            timestamp: t,
            accuracyMeters: 250.0, // Buruk (> 100m)
          );
        }
        await Future<void>.delayed(Duration.zero);
        expect(service.trackingStatus, HikingTrackingStatus.gpsUnavailable);
        expect(
          service.distanceKm,
          validDistanceAfter10Steps,
          reason: 'Sinyal GPS tidak akurat tidak boleh menambah jarak pendakian',
        );

        // 3. Sinyal pulih di titik baru -> anchor segmen baru tanpa melompatkan jarak dari titik sebelum hilang sinyal
        t = t.add(const Duration(microseconds: 500));
        fakeLocation.emitFix(
          lat: -8.40200,
          lng: 116.46800,
          timestamp: t,
          accuracyMeters: 6.0,
        );
        await Future<void>.delayed(Duration.zero);
        expect(service.trackingStatus, HikingTrackingStatus.tracking);
        expect(service.distanceKm, closeTo(validDistanceAfter10Steps, 0.0001));

        // 4. Timestamp mundur (out-of-order OS location buffer) sebanyak 50 kali harus diabaikan
        final pointsBeforeStale = service.pointsRecorded;
        for (var i = 1; i <= 50; i++) {
          fakeLocation.emitFix(
            lat: -8.40100 - (i * 0.0001),
            lng: 116.46800,
            timestamp: t.subtract(Duration(seconds: i)),
            accuracyMeters: 5.0,
          );
        }
        await Future<void>.delayed(Duration.zero);
        expect(service.pointsRecorded, pointsBeforeStale);

        // 5. Keluar area radius (> 15 km dari Rinjani) 3x berturut-turut -> masuk outsideGrace, lalu kembali masuk 2x -> pulih
        for (var i = 0; i < 3; i++) {
          t = t.add(const Duration(microseconds: 500));
          fakeLocation.emitFix(
            lat: -8.60000, // > 20 km dari Rinjani
            lng: 116.46800,
            timestamp: t,
            accuracyMeters: 6.0,
          );
        }
        await Future<void>.delayed(Duration.zero);
        expect(service.trackingStatus, HikingTrackingStatus.outsideGrace);

        for (var i = 0; i < 2; i++) {
          t = t.add(const Duration(microseconds: 500));
          fakeLocation.emitFix(
            lat: -8.40200 + (i * 0.0001),
            lng: 116.46800,
            timestamp: t,
            accuracyMeters: 6.0,
          );
        }
        await Future<void>.delayed(Duration.zero);
        expect(service.trackingStatus, HikingTrackingStatus.tracking);

        service.dispose();
      },
    );

    test(
      'P1 Stress 4: LocationService singleton tahan terhadap dispose() berulang dan 1.000 kalkulasi batas zona risiko',
      () async {
        final locationService = LocationService();
        var notificationCount = 0;
        void listener() => notificationCount++;

        locationService.addListener(listener);
        // Pastikan pemanggilan dispose() pada singleton tidak merusak ChangeNotifier
        locationService.dispose();

        // Uji 1.000 perpindahan koordinat melintasi batas radius 5km, 10km, 15km, 40km
        for (var i = 0; i < 1000; i++) {
          final offsetDeg = (i % 50) * 0.01; // 0 km s/d ~55 km
          await locationService.setManualLocation(
            -7.5407 + offsetDeg,
            110.4457,
          );
          final dist = locationService.distanceFromVolcano;
          final level = locationService.zoneLevel;
          if (dist <= 5.0) {
            expect(level, 4);
          } else if (dist <= 10.0) {
            expect(level, 3);
          } else if (dist <= 15.0) {
            expect(level, 2);
          } else {
            expect(level, 1);
          }
        }

        expect(notificationCount, greaterThanOrEqualTo(1000));
        locationService.removeListener(listener);
      },
    );

    test(
      'P2 Stress 5: 25 request Chatbot konkuren (5 bahasa x 5 kondisi server: sukses, HTTP 503, JSON rusak, kosong, timeout) selalu aman & fallback jujur',
      () async {
        var requestCounter = 0;
        final mockHttpClient = MockClient((http.Request request) async {
          final current = ++requestCounter;
          final mode = current % 5;
          switch (mode) {
            case 0:
              // Sukses normal
              return http.Response(
                jsonEncode({
                  'model': 'sigumi-finetuned',
                  'message': {
                    'role': 'assistant',
                    'content':
                        'Panduan resmi mitigasi hujan abu: gunakan masker N95 dan tetap di dalam ruangan.',
                  },
                  'done': true,
                }),
                200,
                headers: {'content-type': 'application/json; charset=utf-8'},
              );
            case 1:
              // Server overload HTTP 503
              return http.Response('Service Unavailable', 503);
            case 2:
              // JSON rusak / terpotong dari reverse proxy
              return http.Response('{invalid_json: true', 200);
            case 3:
              // Payload kosong
              return http.Response(
                jsonEncode({
                  'model': 'sigumi-finetuned',
                  'message': {'role': 'assistant', 'content': '   '},
                }),
                200,
              );
            default:
              // Timeout simulasi
              await Future<void>.delayed(const Duration(milliseconds: 120));
              return http.Response('Gateway Timeout', 504);
          }
        });

        CloudLlmService.init(
          baseUrl: 'https://staging-ollama.sigumi.test',
          modelName: 'sigumi-finetuned',
          user: 'test_user',
          pass: 'test_pass',
          httpClient: mockHttpClient,
          defaultTimeout: const Duration(milliseconds: 40),
          retryDelay: Duration.zero,
        );

        const languages = ['id', 'en', 'jv', 'ba', 'sas'];
        final futures = <Future<ChatMessage>>[];

        for (var i = 0; i < 25; i++) {
          final lang = languages[i % languages.length];
          futures.add(
            ChatbotEngine.processMessage(
              'Bagaimana cara menghadapi hujan abu dan jalur evakuasi?',
              appLanguage: lang,
              hasInternetOverride: true,
            ),
          );
        }

        final responses = await Future.wait(futures);
        expect(responses.length, 25);

        var cloudSuccessCount = 0;
        var localFallbackCount = 0;

        for (final msg in responses) {
          expect(msg.content.trim(), isNotEmpty);
          if (msg.responseSource == ResponseSource.cloud) {
            cloudSuccessCount++;
            expect(msg.intentId, 'cloud_llm');
          } else {
            // Saat server gagal/timeout, wajib menggunakan localFallback dan TIDAK mengklaim berasal dari cloud
            expect(msg.responseSource, ResponseSource.localFallback);
            expect(msg.intentId, isNot('error_connection'));
            localFallbackCount++;
          }
        }

        expect(cloudSuccessCount, greaterThan(0));
        expect(localFallbackCount, greaterThan(0));
        expect(cloudSuccessCount + localFallbackCount, 25);
      },
    );
  });
}

