import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:provider/provider.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/widgets/hiking_map_markers.dart';
import 'package:sigumi/widgets/hiking_point_detail_sheet.dart';

class _FakeMarkerVolcanoProvider extends ChangeNotifier
    implements VolcanoProvider {
  _FakeMarkerVolcanoProvider({
    this.language = 'id',
    this.highContrast = false,
    this.colorBlindMode = 'normal',
  });

  @override
  final String language;

  @override
  final bool highContrast;

  @override
  final String colorBlindMode;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithProviders(
  Widget child, {
  bool highContrast = false,
  String colorBlindMode = 'normal',
  String language = 'id',
  bool disableAnimations = false,
}) {
  return ChangeNotifierProvider<VolcanoProvider>(
    create:
        (_) => _FakeMarkerVolcanoProvider(
          language: language,
          highContrast: highContrast,
          colorBlindMode: colorBlindMode,
        ),
    child: MaterialApp(
      home: Builder(
        builder:
            (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(disableAnimations: disableAnimations),
              child: Scaffold(body: Center(child: child)),
            ),
      ),
    ),
  );
}

const _sampleWaypoints = [
  HikingWaypoint(
    name: 'Gerbang Sembalun',
    shortLabel: 'Gerbang',
    modalTitle: 'Gerbang Sembalun',
    altitude: '1059 MASL',
    elevationMeters: 1059,
    point: LatLng(-8.3585, 116.5280),
    kind: HikingWaypointKind.trailhead,
  ),
  HikingWaypoint(
    name: 'Pos 1 Pemantauan',
    shortLabel: 'Pos 1',
    modalTitle: '1st Post via Sembalun',
    altitude: '1426 MASL',
    elevationMeters: 1426,
    point: LatLng(-8.3750, 116.5180),
    kind: HikingWaypointKind.post,
    badgeNumber: '1',
  ),
  HikingWaypoint(
    name: 'Pos 2 Tengengean',
    shortLabel: 'Pos 2',
    modalTitle: '2nd Post - Tengengean',
    altitude: '1520 MASL',
    elevationMeters: 1520,
    point: LatLng(-8.3880, 116.5050),
    kind: HikingWaypointKind.water,
    badgeNumber: '2',
  ),
  HikingWaypoint(
    name: 'Plawangan Sembalun',
    shortLabel: 'Plawangan',
    modalTitle: 'Plawangan Sembalun',
    altitude: '2639 MASL',
    elevationMeters: 2639,
    point: LatLng(-8.4050, 116.4680),
    kind: HikingWaypointKind.camp,
  ),
  HikingWaypoint(
    name: 'Puncak Rinjani',
    shortLabel: 'Puncak · 3.726m',
    modalTitle: 'Puncak Rinjani',
    altitude: '3726 MASL',
    elevationMeters: 3726,
    point: LatLng(-8.4111, 116.4573),
    kind: HikingWaypointKind.summit,
  ),
  HikingWaypoint(
    name: 'Pura Pasar Agung',
    shortLabel: 'Pura Agung',
    modalTitle: 'Pura Pasar Agung',
    altitude: '1609 MASL',
    elevationMeters: 1609,
    point: LatLng(-8.36866, 115.50317),
    kind: HikingWaypointKind.temple,
  ),
];

void main() {
  group('HikingWaypointMarker', () {
    testWidgets('renders all waypoint kinds and step badges without overflow', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final wp in _sampleWaypoints)
                HikingWaypointMarker(waypoint: wp, onTap: () {}),
            ],
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Gerbang'), findsOneWidget);
      expect(find.text('Pos 1'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Pos 2'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('Plawangan'), findsOneWidget);
      expect(find.text('Puncak · 3.726m'), findsOneWidget);
      expect(find.text('Pura Agung'), findsOneWidget);
    });

    testWidgets('adapts cleanly to high contrast and English language', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapWithProviders(
          HikingWaypointMarker(
            waypoint: _sampleWaypoints[4],
            onTap: () {},
          ),
          highContrast: true,
          language: 'en',
        ),
      );
      await tester.pump();

      expect(find.text('Summit · 3,726m'), findsOneWidget);
    });
  });

  group('HikingPointDetailSheet', () {
    testWidgets(
      'opens waypoint modal card with title, elevation, nearby places, and transitions on tap',
      (tester) async {
        final pos1 = _sampleWaypoints[1];
        LatLng? focusedPoint;

        await tester.pumpWidget(
          _wrapWithProviders(
            Builder(
              builder:
                  (context) => HikingWaypointMarker(
                    waypoint: pos1,
                    onTap: () {
                      showHikingPointDetailSheet(
                        context,
                        initialWaypoint: pos1,
                        waypoints: _sampleWaypoints.sublist(0, 5),
                        userPoint: const LatLng(-8.3800, 116.5100),
                        hasRealGps: true,
                        isTrackingActive: true,
                        isTrackingPaused: false,
                        isOutsideWarning: false,
                        onFocusPoint: (p) => focusedPoint = p,
                      );
                    },
                  ),
            ),
          ),
        );

        await tester.tap(find.byType(HikingWaypointMarker));
        await tester.pumpAndSettle();

        expect(find.text('1st Post via Sembalun'), findsOneWidget);
        expect(find.textContaining('1426 MASL'), findsOneWidget);
        expect(find.text('Titik Terdekat'), findsOneWidget);
        expect(find.text('2nd Post - Tengengean'), findsOneWidget);
        expect(find.text('1520 MASL'), findsOneWidget);
        expect(find.text('Gerbang Sembalun'), findsOneWidget);
        expect(find.text('1059 MASL'), findsOneWidget);
        expect(find.textContaining('+94 meter'), findsOneWidget);
        expect(find.textContaining('-367 meter'), findsOneWidget);

        await tester.tap(find.text('2nd Post - Tengengean'));
        await tester.pumpAndSettle();

        expect(focusedPoint, _sampleWaypoints[2].point);
        expect(find.text('2nd Post - Tengengean'), findsOneWidget);
        expect(find.textContaining('1520 MASL'), findsOneWidget);
      },
    );

    testWidgets(
      'opens user realtime modal card showing live coordinates and nearby points',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithProviders(
            Builder(
              builder:
                  (context) => SizedBox(
                    width: 66,
                    height: 66,
                    child: HikingUserRealtimeMarker(
                      isActive: true,
                      isWarning: false,
                      onTap: () {
                        showHikingPointDetailSheet(
                          context,
                          waypoints: _sampleWaypoints.sublist(0, 5),
                          userPoint: const LatLng(-8.3760, 116.5170),
                          hasRealGps: true,
                          isTrackingActive: true,
                          isTrackingPaused: false,
                          isOutsideWarning: false,
                          gpsAccuracyMeters: 8,
                          recordedDistanceKm: 1.25,
                        );
                      },
                    ),
                  ),
            ),
            disableAnimations: true,
          ),
        );

        await tester.tap(find.byType(HikingUserRealtimeMarker));
        await tester.pumpAndSettle();

        expect(find.text('Posisi Anda Saat Ini'), findsOneWidget);
        expect(find.text('-8.37600, 116.51700'), findsOneWidget);
        expect(find.text('1st Post via Sembalun'), findsOneWidget);
      },
    );
  });

  group('HikingUserRealtimeMarker', () {
    testWidgets('renders active, paused, warning, and reduced-motion states', (
      tester,
    ) async {
      for (final state in const [
        (active: true, paused: false, warning: false, reduce: false),
        (active: false, paused: true, warning: false, reduce: false),
        (active: true, paused: false, warning: true, reduce: false),
        (active: true, paused: false, warning: false, reduce: true),
      ]) {
        var tapped = false;
        await tester.pumpWidget(
          _wrapWithProviders(
            SizedBox(
              width: 66,
              height: 66,
              child: HikingUserRealtimeMarker(
                isActive: state.active,
                isPaused: state.paused,
                isWarning: state.warning,
                onTap: () => tapped = true,
              ),
            ),
            disableAnimations: state.reduce,
          ),
        );
        await tester.pump(const Duration(milliseconds: 200));

        await tester.tap(find.byType(HikingUserRealtimeMarker));
        expect(tapped, isTrue);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  });
}
