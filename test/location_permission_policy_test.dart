import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/config/theme.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/services/location_service.dart';
import 'package:sigumi/widgets/location_disclosure_dialog.dart';

class _MockGeolocatorPlatform extends GeolocatorPlatform {
  LocationPermission permission = LocationPermission.denied;
  bool serviceEnabled = true;
  int requestPermissionCalls = 0;
  int streamSubscriptions = 0;
  int streamCancellations = 0;
  StreamController<Position>? activeController;

  Position get _samplePosition => Position(
    longitude: 110.3695,
    latitude: -7.7956,
    timestamp: DateTime.now(),
    accuracy: 10,
    altitude: 100,
    altitudeAccuracy: 5,
    heading: 0,
    headingAccuracy: 1,
    speed: 0,
    speedAccuracy: 1,
  );

  @override
  Future<LocationPermission> checkPermission() async => permission;

  @override
  Future<LocationPermission> requestPermission() async {
    requestPermissionCalls++;
    return permission;
  }

  @override
  Future<bool> isLocationServiceEnabled() async => serviceEnabled;

  @override
  Future<Position> getCurrentPosition({
    LocationSettings? locationSettings,
  }) async => _samplePosition;

  @override
  Future<Position?> getLastKnownPosition({
    bool forceLocationManager = false,
  }) async => _samplePosition;

  @override
  Stream<Position> getPositionStream({LocationSettings? locationSettings}) {
    streamSubscriptions++;
    activeController = StreamController<Position>(
      onCancel: () {
        streamCancellations++;
      },
    );
    return activeController!.stream;
  }
}

class _StubVolcanoProvider extends ChangeNotifier implements VolcanoProvider {
  _StubVolcanoProvider(this._language);

  final String _language;

  @override
  String get language => _language;

  @override
  bool get highContrast => false;

  @override
  double get fontSize => 1.0;

  @override
  String get colorBlindMode => 'normal';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidManifest location permissions policy', () {
    test('does not declare ACCESS_BACKGROUND_LOCATION and keeps foreground location service', () {
      final manifestFile = File('android/app/src/main/AndroidManifest.xml');
      expect(manifestFile.existsSync(), isTrue);

      final content = manifestFile.readAsStringSync();
      expect(content, isNot(contains('ACCESS_BACKGROUND_LOCATION')));
      expect(content, contains('android.permission.ACCESS_FINE_LOCATION'));
      expect(content, contains('android.permission.ACCESS_COARSE_LOCATION'));
      expect(content, contains('android.permission.FOREGROUND_SERVICE'));
      expect(content, contains('android.permission.FOREGROUND_SERVICE_LOCATION'));
      expect(
        content,
        isNot(contains('com.dexterous.flutterlocalnotifications.ForegroundService')),
      );
    });
  });

  group('LocationService foreground-only lifecycle & consent guard', () {
    late GeolocatorPlatform originalPlatform;
    late _MockGeolocatorPlatform mockGeolocator;
    late LocationService locationService;

    setUp(() {
      originalPlatform = GeolocatorPlatform.instance;
      mockGeolocator = _MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocator;
      locationService = LocationService();
      locationService.stopTracking();
    });

    tearDown(() {
      locationService.stopTracking();
      GeolocatorPlatform.instance = originalPlatform;
    });

    test('initialize(requestPermission: false) does not trigger OS permission prompt when denied', () async {
      mockGeolocator.permission = LocationPermission.denied;

      await locationService.initialize(requestPermission: false);

      expect(mockGeolocator.requestPermissionCalls, 0);
      expect(locationService.gpsStatus, GpsStatus.denied);
      expect(locationService.locationError, isNull);
    });

    test('pauses regular foreground tracking in background and resumes on foreground', () async {
      mockGeolocator.permission = LocationPermission.whileInUse;
      await locationService.initialize();
      expect(locationService.gpsStatus, GpsStatus.active);

      locationService.startTracking(distanceFilterMeters: 25);
      expect(locationService.isTracking, isTrue);
      expect(locationService.isHikingTracking, isFalse);
      expect(mockGeolocator.streamSubscriptions, 1);

      locationService.pauseForegroundTrackingForBackground();
      expect(locationService.isTracking, isFalse);
      expect(locationService.isPausedForBackground, isTrue);
      expect(mockGeolocator.streamCancellations, 1);

      locationService.resumeForegroundTrackingFromBackground();
      expect(locationService.isTracking, isTrue);
      expect(locationService.isPausedForBackground, isFalse);
      expect(mockGeolocator.streamSubscriptions, 2);
    });

    test('does not pause active hiking tracking (Foreground Service) when app goes to background', () async {
      mockGeolocator.permission = LocationPermission.whileInUse;
      await locationService.initialize();

      locationService.startTracking(
        distanceFilterMeters: 5,
        hikingTracking: true,
      );
      expect(locationService.isTracking, isTrue);
      expect(locationService.isHikingTracking, isTrue);

      locationService.pauseForegroundTrackingForBackground();

      expect(locationService.isTracking, isTrue);
      expect(locationService.isHikingTracking, isTrue);
      expect(locationService.isPausedForBackground, isFalse);
      expect(mockGeolocator.streamCancellations, 0);
    });
  });

  group('LocationDisclosureDialog', () {
    late GeolocatorPlatform originalPlatform;
    late _MockGeolocatorPlatform mockGeolocator;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      originalPlatform = GeolocatorPlatform.instance;
      mockGeolocator = _MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocator;
    });

    tearDown(() {
      GeolocatorPlatform.instance = originalPlatform;
    });

    Widget wrapWithProviders({
      required Widget child,
      String language = 'en',
    }) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<VolcanoProvider>(
            create: (_) => _StubVolcanoProvider(language),
          ),
        ],
        child: MaterialApp(
          theme: SigumiTheme.lightTheme,
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('shows English disclosure when denied and respects Decline then forceShowIfDenied', (tester) async {
      mockGeolocator.permission = LocationPermission.denied;
      final locationService = LocationService();
      bool? firstResult;
      bool? secondResult;
      bool? thirdResult;

      await tester.pumpWidget(
        wrapWithProviders(
          language: 'en',
          child: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  key: const ValueKey('trigger-auto'),
                  onPressed: () async {
                    firstResult =
                        await LocationDisclosureDialog.ensurePermissionConsent(
                          context,
                          locationService,
                        );
                  },
                  child: const Text('Auto'),
                ),
                ElevatedButton(
                  key: const ValueKey('trigger-auto-again'),
                  onPressed: () async {
                    secondResult =
                        await LocationDisclosureDialog.ensurePermissionConsent(
                          context,
                          locationService,
                        );
                  },
                  child: const Text('AutoAgain'),
                ),
                ElevatedButton(
                  key: const ValueKey('trigger-forced'),
                  onPressed: () async {
                    thirdResult =
                        await LocationDisclosureDialog.ensurePermissionConsent(
                          context,
                          locationService,
                          forceShowIfDenied: true,
                        );
                  },
                  child: const Text('Forced'),
                ),
              ],
            ),
          ),
        ),
      );

      // 1. First automatic trigger shows English disclosure dialog
      await tester.tap(find.byKey(const ValueKey('trigger-auto')));
      await tester.pumpAndSettle();

      expect(find.text('Allow Location Access'), findsOneWidget);
      expect(find.text('Not Now'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      // Tap "Not Now"
      await tester.tap(find.byKey(const ValueKey('location-disclosure-decline')));
      await tester.pumpAndSettle();
      expect(firstResult, isFalse);

      // 2. Subsequent automatic trigger respects dismissal without nagging
      await tester.tap(find.byKey(const ValueKey('trigger-auto-again')));
      await tester.pumpAndSettle();
      expect(find.text('Allow Location Access'), findsNothing);
      expect(secondResult, isFalse);

      // 3. Explicit user action (forceShowIfDenied: true) shows disclosure again
      await tester.tap(find.byKey(const ValueKey('trigger-forced')));
      await tester.pumpAndSettle();
      expect(find.text('Allow Location Access'), findsOneWidget);

      // Tap "Continue"
      await tester.tap(find.byKey(const ValueKey('location-disclosure-allow')));
      await tester.pumpAndSettle();
      expect(thirdResult, isTrue);
    });

    testWidgets('skips disclosure when permission is already whileInUse', (tester) async {
      mockGeolocator.permission = LocationPermission.whileInUse;
      final locationService = LocationService();
      bool? consentResult;

      await tester.pumpWidget(
        wrapWithProviders(
          language: 'id',
          child: Builder(
            builder: (context) => ElevatedButton(
              key: const ValueKey('trigger'),
              onPressed: () async {
                consentResult =
                    await LocationDisclosureDialog.ensurePermissionConsent(
                      context,
                      locationService,
                    );
              },
              child: const Text('Go'),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('trigger')));
      await tester.pumpAndSettle();

      expect(find.byType(LocationDisclosureDialog), findsNothing);
      expect(consentResult, isTrue);
    });
  });
}
