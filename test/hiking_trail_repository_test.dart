import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:sigumi/models/hiking_trail.dart';
import 'package:sigumi/services/hiking_trail_repository.dart';
import 'package:sigumi/services/location_service.dart';

class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(bytes);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) {
    return File(key).readAsString();
  }
}

void main() {
  group('HikingTrailRepository & trail JSON assets', () {
    late HikingTrailRepository repo;

    setUp(() {
      repo = HikingTrailRepository(bundle: _FileAssetBundle());
    });

    test('loads Rinjani trail asset with 3 non-commercial routes and polylines', () async {
      final dataset = await repo.loadForRegion('lombok');

      expect(dataset.mountainId, 'rinjani');
      expect(dataset.defaultRouteId, 'rinjani_sembalun');
      expect(dataset.metadata.recordedBy, 'Rinjani Dawn Adventures');
      expect(dataset.metadata.displayLabel, 'Rinjani Dawn Adventures');
      expect(
        dataset.metadata.sourceUrl,
        'https://rinjanidawnadventures.com',
      );
      expect(dataset.routes.map((r) => r.id), [
        'rinjani_sembalun',
        'rinjani_senaru',
        'rinjani_lintas',
      ]);

      final rinjaniCenter = LatLng(
        LocationService.regionCenters['Lombok']!['lat']!,
        LocationService.regionCenters['Lombok']!['lng']!,
      );
      const distance = Distance();

      for (final route in dataset.routes) {
        expect(route.hasTrackPolyline, isTrue);
        expect(route.polyline.length, greaterThan(50));
        expect(route.waypoints, isNotEmpty);
        for (final wp in route.waypoints) {
          expect(wp.name.toLowerCase(), isNot(contains('rda office')));
          final kmFromCenter =
              distance.as(LengthUnit.Meter, rinjaniCenter, wp.point) / 1000.0;
          expect(
            kmFromCenter,
            lessThanOrEqualTo(LocationService.hikingTrackingRadiusKm),
            reason: '${wp.name} harus berada dalam geofence 15 km',
          );
        }
      }
    });

    test('computes real along-track distance between Sembalun waypoints', () async {
      final dataset = await repo.loadForRegion('lombok');
      final sembalun = dataset.routeById('rinjani_sembalun')!;

      final gate = sembalun.waypoints.firstWhere((w) => w.id == 'sembalun_gate');
      final pos1 = sembalun.waypoints.firstWhere((w) => w.id == 'sembalun_pos1');
      final pos2 = sembalun.waypoints.firstWhere((w) => w.id == 'sembalun_pos2');

      expect(pos1.modalTitle, '1st Post via Sembalun');
      expect(pos1.elevationMeters, 1426);

      final pos1ToGateKm =
          HikingTrailRoute.distanceBetweenWaypointsMeters(pos1, gate) / 1000.0;
      final pos1ToPos2Km =
          HikingTrailRoute.distanceBetweenWaypointsMeters(pos1, pos2) / 1000.0;

      expect(pos1ToGateKm, closeTo(3.28, 0.1));
      expect(pos1ToPos2Km, closeTo(1.40, 0.1));

      final distToTrail = sembalun.distanceToTrailMeters(pos1.point);
      expect(distToTrail, isNotNull);
      expect(distToTrail!, lessThan(30));
    });

    test('loads Gunung Agung trail asset cleanly', () async {
      final dataset = await repo.loadForRegion('bali');

      expect(dataset.mountainId, 'agung');
      expect(dataset.routes, hasLength(1));
      expect(dataset.routes.first.id, 'agung_pasar_agung');
      expect(dataset.routes.first.waypoints, hasLength(2));
      expect(dataset.routes.first.hasTrackPolyline, isFalse);
    });
  });
}
