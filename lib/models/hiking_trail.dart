import 'dart:math' as math;

import 'package:latlong2/latlong.dart' hide Path;

import '../widgets/hiking_map_markers.dart';

/// Metadata sumber dan catatan lisensi dataset jalur pendakian.
class HikingTrailSourceMetadata {
  const HikingTrailSourceMetadata({
    required this.source,
    required this.recordedBy,
    required this.licenseNote,
    required this.updatedAt,
    this.sourceUrl,
  });

  final String source;
  final String recordedBy;
  final String licenseNote;
  final String updatedAt;
  final String? sourceUrl;

  /// Nama ringkas penyedia data untuk ditampilkan sebagai atribusi UI.
  String get displayLabel =>
      recordedBy.trim().isNotEmpty ? recordedBy.trim() : source.trim();

  factory HikingTrailSourceMetadata.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['source_url']?.toString().trim();
    return HikingTrailSourceMetadata(
      source: json['source']?.toString() ?? '',
      recordedBy: json['recorded_by']?.toString() ?? '',
      licenseNote: json['license_note']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '',
      sourceUrl: (rawUrl != null && rawUrl.isNotEmpty) ? rawUrl : null,
    );
  }
}

/// Satu rute jalur pendakian lengkap (waypoint terurut + polyline jalur riil).
class HikingTrailRoute {
  const HikingTrailRoute({
    required this.id,
    required this.name,
    required this.shortName,
    required this.totalDistanceKm,
    required this.elevationGainMeters,
    required this.elevationLossMeters,
    required this.center,
    required this.defaultZoom,
    required this.waypoints,
    required this.polyline,
    this.elevations = const [],
  });

  final String id;
  final String name;
  final String shortName;
  final double totalDistanceKm;
  final int elevationGainMeters;
  final int elevationLossMeters;
  final LatLng center;
  final double defaultZoom;
  final List<HikingWaypoint> waypoints;
  final List<LatLng> polyline;
  final List<double> elevations;

  bool get hasTrackPolyline => polyline.length >= 2;

  /// Menghitung jarak terdekat (meter) dari posisi GPS [point] ke segmen garis
  /// jalur terdekat. Mengembalikan `null` jika rute belum memiliki polyline.
  double? distanceToTrailMeters(LatLng point) {
    if (polyline.length < 2) return null;
    var minDist = double.infinity;
    for (var i = 1; i < polyline.length; i++) {
      final d = _pointToSegmentMeters(point, polyline[i - 1], polyline[i]);
      if (d < minDist) minDist = d;
    }
    return minDist.isFinite ? minDist : null;
  }

  /// Jarak riil antar dua pos sepanjang jalur (jika `trailKm` tersedia),
  /// atau fallback ke jarak geodesik Haversine.
  static double distanceBetweenWaypointsMeters(
    HikingWaypoint origin,
    HikingWaypoint target,
  ) {
    final a = origin.trailKm;
    final b = target.trailKm;
    if (a != null && b != null) {
      return (b - a).abs() * 1000.0;
    }
    return const Distance().as(LengthUnit.Meter, origin.point, target.point);
  }

  factory HikingTrailRoute.fromJson(Map<String, dynamic> json) {
    final centerMap =
        json['center'] is Map
            ? Map<String, dynamic>.from(json['center'] as Map)
            : const <String, dynamic>{};
    final rawWaypoints = json['waypoints'] as List? ?? const [];
    final rawPolyline = json['polyline'] as List? ?? const [];

    final polyline = <LatLng>[];
    final elevations = <double>[];
    for (final item in rawPolyline) {
      if (item is List && item.length >= 2) {
        final lat = (item[0] as num?)?.toDouble();
        final lng = (item[1] as num?)?.toDouble();
        if (lat != null && lng != null) {
          polyline.add(LatLng(lat, lng));
          elevations.add(
            item.length >= 3 ? ((item[2] as num?)?.toDouble() ?? 0.0) : 0.0,
          );
        }
      }
    }

    final waypoints =
        rawWaypoints
            .whereType<Map>()
            .map(
              (row) => _waypointFromJson(Map<String, dynamic>.from(row)),
            )
            .toList();

    final fallbackCenter =
        waypoints.isNotEmpty
            ? waypoints.first.point
            : const LatLng(-8.4111, 116.4573);

    return HikingTrailRoute(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      shortName:
          json['short_name']?.toString() ?? json['name']?.toString() ?? '',
      totalDistanceKm: (json['total_distance_km'] as num?)?.toDouble() ?? 0.0,
      elevationGainMeters: (json['elevation_gain_m'] as num?)?.round() ?? 0,
      elevationLossMeters: (json['elevation_loss_m'] as num?)?.round() ?? 0,
      center: LatLng(
        (centerMap['lat'] as num?)?.toDouble() ?? fallbackCenter.latitude,
        (centerMap['lng'] as num?)?.toDouble() ?? fallbackCenter.longitude,
      ),
      defaultZoom: (json['default_zoom'] as num?)?.toDouble() ?? 12.5,
      waypoints: waypoints,
      polyline: polyline,
      elevations: elevations,
    );
  }
}

/// Kumpulan seluruh jalur pendakian untuk satu gunung / wilayah.
class HikingTrailDataset {
  const HikingTrailDataset({
    required this.schemaVersion,
    required this.mountainId,
    required this.region,
    required this.mountainName,
    required this.summitElevationMeters,
    required this.defaultRouteId,
    required this.metadata,
    required this.routes,
  });

  final int schemaVersion;
  final String mountainId;
  final String region;
  final String mountainName;
  final int summitElevationMeters;
  final String defaultRouteId;
  final HikingTrailSourceMetadata metadata;
  final List<HikingTrailRoute> routes;

  HikingTrailRoute? routeById(String? routeId) {
    if (routes.isEmpty) return null;
    if (routeId != null) {
      for (final route in routes) {
        if (route.id == routeId) return route;
      }
    }
    for (final route in routes) {
      if (route.id == defaultRouteId) return route;
    }
    return routes.first;
  }

  factory HikingTrailDataset.fromJson(Map<String, dynamic> json) {
    final metaMap =
        json['metadata'] is Map
            ? Map<String, dynamic>.from(json['metadata'] as Map)
            : const <String, dynamic>{};
    final rawRoutes = json['routes'] as List? ?? const [];

    return HikingTrailDataset(
      schemaVersion: (json['schema_version'] as num?)?.toInt() ?? 1,
      mountainId: json['mountain_id']?.toString() ?? '',
      region: json['region']?.toString() ?? '',
      mountainName: json['mountain_name']?.toString() ?? '',
      summitElevationMeters: (json['summit_elevation_m'] as num?)?.round() ?? 0,
      defaultRouteId: json['default_route_id']?.toString() ?? '',
      metadata: HikingTrailSourceMetadata.fromJson(metaMap),
      routes:
          rawRoutes
              .whereType<Map>()
              .map(
                (row) => HikingTrailRoute.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(),
    );
  }
}

HikingWaypoint _waypointFromJson(Map<String, dynamic> json) {
  final elevation = (json['elevation_m'] as num?)?.round() ?? 0;
  final name = json['name']?.toString() ?? '';
  return HikingWaypoint(
    id: json['id']?.toString(),
    name: name,
    shortLabel: json['short_label']?.toString() ?? name,
    modalTitle: json['modal_title']?.toString() ?? name,
    altitude: json['altitude']?.toString() ?? '$elevation MASL',
    elevationMeters: elevation,
    point: LatLng(
      (json['lat'] as num?)?.toDouble() ?? 0.0,
      (json['lng'] as num?)?.toDouble() ?? 0.0,
    ),
    kind: _parseWaypointKind(json['kind']?.toString()),
    badgeNumber: json['badge_number']?.toString(),
    trailKm: (json['trail_km'] as num?)?.toDouble(),
    description: json['description']?.toString(),
  );
}

HikingWaypointKind _parseWaypointKind(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'trailhead':
      return HikingWaypointKind.trailhead;
    case 'temple':
      return HikingWaypointKind.temple;
    case 'water':
      return HikingWaypointKind.water;
    case 'camp':
      return HikingWaypointKind.camp;
    case 'summit':
      return HikingWaypointKind.summit;
    case 'post':
    default:
      return HikingWaypointKind.post;
  }
}

double _pointToSegmentMeters(LatLng p, LatLng a, LatLng b) {
  final cosLat = math.cos(a.latitude * math.pi / 180.0);
  const metersPerLat = 111320.0;
  final metersPerLng = 111320.0 * cosLat;
  final px = (p.longitude - a.longitude) * metersPerLng;
  final py = (p.latitude - a.latitude) * metersPerLat;
  final bx = (b.longitude - a.longitude) * metersPerLng;
  final by = (b.latitude - a.latitude) * metersPerLat;
  final len2 = bx * bx + by * by;
  if (len2 < 1e-9) return math.sqrt(px * px + py * py);
  final t = ((px * bx + py * by) / len2).clamp(0.0, 1.0);
  final dx = px - t * bx;
  final dy = py - t * by;
  return math.sqrt(dx * dx + dy * dy);
}
