import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../models/hiking_trail.dart';
import '../widgets/hiking_map_markers.dart';

/// Repository pemuat aset jalur pendakian (`assets/trails/*.json`) dengan cache
/// di memori dan fallback ringan agar peta selalu langsung siap tampil.
class HikingTrailRepository {
  HikingTrailRepository({AssetBundle? bundle})
    : _bundle = bundle ?? rootBundle;

  static final HikingTrailRepository instance = HikingTrailRepository();

  static const Map<String, String> _assetPathByRegion = {
    'lombok': 'assets/trails/rinjani_trails.json',
    'bali': 'assets/trails/agung_trails.json',
  };

  final AssetBundle _bundle;
  final Map<String, HikingTrailDataset> _cache = {};

  static String normalizeRegion(String region) {
    final normalized = region.trim().toLowerCase();
    if (normalized.contains('bali') || normalized.contains('agung')) {
      return 'bali';
    }
    return 'lombok';
  }

  /// Mengembalikan dataset tersimpan di cache memori jika sudah dimuat.
  HikingTrailDataset? cachedForRegion(String region) =>
      _cache[normalizeRegion(region)];

  /// Memuat dataset jalur pendakian dari bundle aset JSON.
  Future<HikingTrailDataset> loadForRegion(String region) async {
    final key = normalizeRegion(region);
    final cached = _cache[key];
    if (cached != null) return cached;

    final assetPath = _assetPathByRegion[key];
    if (assetPath == null) {
      return fallbackForRegion(key);
    }

    try {
      final raw = await _bundle.loadString(assetPath);
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final dataset = HikingTrailDataset.fromJson(decoded);
      if (dataset.routes.isNotEmpty) {
        _cache[key] = dataset;
        return dataset;
      }
    } catch (_) {
      // Jatuh ke fallback minimal agar tampilan peta tetap bekerja.
    }
    return fallbackForRegion(key);
  }

  /// Fallback sinkron untuk frame pertama sebelum aset JSON selesai dibaca.
  HikingTrailDataset fallbackForRegion(String region) {
    final key = normalizeRegion(region);
    if (key == 'bali') {
      return const HikingTrailDataset(
        schemaVersion: 1,
        mountainId: 'agung',
        region: 'bali',
        mountainName: 'Gunung Agung',
        summitElevationMeters: 3142,
        defaultRouteId: 'agung_pasar_agung',
        metadata: HikingTrailSourceMetadata(
          source: 'Titik referensi Pasar Agung',
          recordedBy: 'SIGUMI',
          licenseNote: '',
          updatedAt: '',
        ),
        routes: [
          HikingTrailRoute(
            id: 'agung_pasar_agung',
            name: 'Jalur Pasar Agung',
            shortName: 'Pasar Agung',
            totalDistanceKm: 3.02,
            elevationGainMeters: 1533,
            elevationLossMeters: 0,
            center: LatLng(-8.3550, 115.5032),
            defaultZoom: 13.0,
            waypoints: [
              HikingWaypoint(
                id: 'pura_pasar_agung',
                name: 'Pura Pasar Agung',
                shortLabel: 'Pura Agung',
                modalTitle: 'Pura Pasar Agung',
                altitude: '1609 MASL',
                elevationMeters: 1609,
                point: LatLng(-8.36866, 115.50317),
                kind: HikingWaypointKind.temple,
              ),
              HikingWaypoint(
                id: 'agung_summit',
                name: 'Puncak Gunung Agung',
                shortLabel: 'Puncak · 3.142m',
                modalTitle: 'Puncak Gunung Agung',
                altitude: '3142 MASL',
                elevationMeters: 3142,
                point: LatLng(-8.3415, 115.5033),
                kind: HikingWaypointKind.summit,
              ),
            ],
            polyline: [],
          ),
        ],
      );
    }

    return const HikingTrailDataset(
      schemaVersion: 1,
      mountainId: 'rinjani',
      region: 'lombok',
      mountainName: 'Gunung Rinjani',
      summitElevationMeters: 3726,
      defaultRouteId: 'rinjani_sembalun',
      metadata: HikingTrailSourceMetadata(
        source: 'Rekaman GPS lapangan jalur Rinjani',
        recordedBy: 'Rinjani Dawn Adventures',
        sourceUrl: 'https://rinjanidawnadventures.com',
        licenseNote: '',
        updatedAt: '2026-11-19',
      ),
      routes: [
        HikingTrailRoute(
          id: 'rinjani_sembalun',
          name: 'Jalur Sembalun',
          shortName: 'Sembalun',
          totalDistanceKm: 12.9,
          elevationGainMeters: 2811,
          elevationLossMeters: 335,
          center: LatLng(-8.3785, 116.4650),
          defaultZoom: 12.6,
          waypoints: [
            HikingWaypoint(
              id: 'sembalun_gate',
              name: 'Gerbang Sembalun',
              shortLabel: 'Gerbang',
              modalTitle: 'Gerbang Sembalun',
              altitude: '1063 MASL',
              elevationMeters: 1063,
              point: LatLng(-8.34685, 116.49578),
              kind: HikingWaypointKind.trailhead,
              trailKm: 0.0,
            ),
            HikingWaypoint(
              id: 'sembalun_pos1',
              name: 'Pos 1 Pemantauan',
              shortLabel: 'Pos 1',
              modalTitle: '1st Post via Sembalun',
              altitude: '1426 MASL',
              elevationMeters: 1426,
              point: LatLng(-8.36141, 116.47579),
              kind: HikingWaypointKind.post,
              badgeNumber: '1',
              trailKm: 3.28,
            ),
            HikingWaypoint(
              id: 'sembalun_pos2',
              name: 'Pos 2 Tengengean',
              shortLabel: 'Pos 2',
              modalTitle: '2nd Post - Tengengean',
              altitude: '1520 MASL',
              elevationMeters: 1520,
              point: LatLng(-8.36524, 116.46621),
              kind: HikingWaypointKind.water,
              badgeNumber: '2',
              trailKm: 4.68,
            ),
            HikingWaypoint(
              id: 'sembalun_pos3',
              name: 'Pos 3 Pada Balong',
              shortLabel: 'Pos 3',
              modalTitle: '3rd Post - Pada Balong',
              altitude: '1773 MASL',
              elevationMeters: 1773,
              point: LatLng(-8.37608, 116.45794),
              kind: HikingWaypointKind.post,
              badgeNumber: '3',
              trailKm: 6.41,
            ),
            HikingWaypoint(
              id: 'plawangan_sembalun',
              name: 'Plawangan Sembalun',
              shortLabel: 'Plawangan',
              modalTitle: 'Plawangan Sembalun',
              altitude: '2639 MASL',
              elevationMeters: 2639,
              point: LatLng(-8.38613, 116.44264),
              kind: HikingWaypointKind.camp,
              trailKm: 8.64,
            ),
            HikingWaypoint(
              id: 'rinjani_summit',
              name: 'Puncak Rinjani',
              shortLabel: 'Puncak · 3.726m',
              modalTitle: 'Puncak Rinjani',
              altitude: '3726 MASL',
              elevationMeters: 3726,
              point: LatLng(-8.41166, 116.45813),
              kind: HikingWaypointKind.summit,
              trailKm: 12.89,
            ),
          ],
          polyline: [],
        ),
      ],
    );
  }
}
