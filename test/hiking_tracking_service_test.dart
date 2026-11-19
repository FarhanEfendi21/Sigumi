import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/services/hiking_tracking_service.dart';
import 'package:sigumi/services/location_service.dart';

class FakeLocationService extends ChangeNotifier implements LocationService {
  double _fakeLat = -8.4050;
  double _fakeLng = 116.4680;
  bool _fakeUsingRealGps = true;
  bool _fakeTracking = false;
  DateTime? _fakeLastUpdated = DateTime.now();
  double? _fakeAccuracyMeters = 8.0;
  GpsStatus _fakeGpsStatus = GpsStatus.active;
  String? _fakeError;

  @override
  double get userLat => _fakeLat;

  @override
  double get userLng => _fakeLng;

  @override
  bool get isUsingRealGps => _fakeUsingRealGps;

  @override
  bool get isTracking => _fakeTracking;

  @override
  DateTime? get lastUpdated => _fakeLastUpdated;

  @override
  double? get accuracyMeters => _fakeAccuracyMeters;

  @override
  GpsStatus get gpsStatus => _fakeGpsStatus;

  @override
  String? get locationError => _fakeError;

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
    final updatedAt = _fakeLastUpdated;
    if (!_fakeUsingRealGps || updatedAt == null) return false;
    final age = DateTime.now().difference(updatedAt);
    return age >= const Duration(seconds: -30) &&
        age <= const Duration(minutes: 2);
  }

  @override
  double getDistanceToRegion(String region) {
    final normalizedRegion = region.trim().toLowerCase();
    for (final entry in LocationService.regionCenters.entries) {
      if (entry.key.toLowerCase() == normalizedRegion) {
        return _haversineDistance(
          _fakeLat,
          _fakeLng,
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
      isCoordinateWithinHikingRegion(region, _fakeLat, _fakeLng);

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
    _fakeGpsStatus = GpsStatus.active;
    _fakeLastUpdated ??= DateTime.now();
    notifyListeners();
  }

  @override
  void startTracking({
    int distanceFilterMeters = 50,
    bool hikingTracking = false,
  }) {
    _fakeTracking = true;
  }

  @override
  void stopTracking() {
    _fakeTracking = false;
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
    DateTime? timestamp,
    double? accuracyMeters = 8.0,
    bool realGps = true,
  }) {
    _fakeLat = lat;
    _fakeLng = lng;
    _fakeUsingRealGps = realGps;
    _fakeAccuracyMeters = accuracyMeters;
    _fakeLastUpdated =
        timestamp ??
        (_fakeLastUpdated != null
            ? _fakeLastUpdated!.add(const Duration(seconds: 5))
            : DateTime.now());
    _fakeGpsStatus = GpsStatus.active;
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HikingTrackingService real-time movement & distance', () {
    late FakeLocationService fakeLocation;
    late HikingTrackingService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeLocation = FakeLocationService();
      service = HikingTrackingService(locationService: fakeLocation);
      await service.ensureRestored();
    });

    tearDown(() {
      service.dispose();
    });

    test(
      'records initial GPS point at start and immediately records distance + point on first movement',
      () async {
        final t0 = DateTime.now().subtract(const Duration(seconds: 20));
        fakeLocation.emitFix(
          lat: -8.40500,
          lng: 116.46800,
          timestamp: t0,
          accuracyMeters: 6.0,
        );

        final started = await service.start(region: 'lombok');
        expect(started, isTrue);
        expect(service.isActive, isTrue);
        expect(service.pointsRecorded, 1);
        expect(service.distanceKm, 0.0);
        expect(service.routePoints.length, 1);

        // User moves ~11 meters north on first movement
        final t1 = t0.add(const Duration(seconds: 5));
        fakeLocation.emitFix(
          lat: -8.40490,
          lng: 116.46800,
          timestamp: t1,
          accuracyMeters: 6.0,
        );
        await Future<void>.delayed(Duration.zero);

        expect(service.pointsRecorded, 2);
        expect(service.distanceKm, greaterThan(0.009));
        expect(service.distanceKm, lessThan(0.015));
        expect(service.liveMovementSegment, [
          const LatLng(-8.40500, 116.46800),
          const LatLng(-8.40490, 116.46800),
        ]);

        // Stationary heartbeat at same coordinate preserves liveMovementSegment and does not inflate points
        final t2 = t1.add(const Duration(seconds: 5));
        fakeLocation.emitFix(
          lat: -8.40490,
          lng: 116.46800,
          timestamp: t2,
          accuracyMeters: 6.0,
        );
        await Future<void>.delayed(Duration.zero);

        expect(service.pointsRecorded, 2);
        expect(service.liveMovementSegment.length, 2);
      },
    );

    test(
      'recovers from GPS unavailable without ticker breaking subsequent movement distance',
      () async {
        final t0 = DateTime.now().subtract(const Duration(seconds: 30));
        fakeLocation.emitFix(
          lat: -8.40500,
          lng: 116.46800,
          timestamp: t0,
          accuracyMeters: 8.0,
        );

        await service.start(region: 'lombok');
        expect(service.pointsRecorded, 1);

        // Inaccurate GPS (> 100m) triggers gpsUnavailable
        final t1 = t0.add(const Duration(seconds: 5));
        fakeLocation.emitFix(
          lat: -8.40480,
          lng: 116.46800,
          timestamp: t1,
          accuracyMeters: 150.0,
        );
        await Future<void>.delayed(Duration.zero);
        expect(service.trackingStatus, HikingTrackingStatus.gpsUnavailable);
        expect(service.pointsRecorded, 1);

        // First usable fix after recovery anchors new segment
        final t2 = t1.add(const Duration(seconds: 5));
        fakeLocation.emitFix(
          lat: -8.40450,
          lng: 116.46800,
          timestamp: t2,
          accuracyMeters: 8.0,
        );
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        expect(service.trackingStatus, HikingTrackingStatus.tracking);
        expect(service.pointsRecorded, 2);
        expect(service.distanceKm, 0.0);

        // Next movement after recovery must record distance and liveMovementSegment
        final t3 = t2.add(const Duration(seconds: 5));
        fakeLocation.emitFix(
          lat: -8.40440,
          lng: 116.46800,
          timestamp: t3,
          accuracyMeters: 8.0,
        );
        await Future<void>.delayed(Duration.zero);

        expect(service.pointsRecorded, 3);
        expect(service.distanceKm, greaterThan(0.009));
        expect(service.liveMovementSegment.length, 2);
      },
    );
  });
}

