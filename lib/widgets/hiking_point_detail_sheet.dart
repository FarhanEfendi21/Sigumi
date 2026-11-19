import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:url_launcher/url_launcher.dart';

import '../config/fonts.dart';
import '../config/theme_extensions.dart';
import '../models/hiking_trail.dart';
import '../services/localization_service.dart';
import 'hiking_map_markers.dart';

/// Menampilkan modal card minimalis dan modern saat pengguna mengetuk titik pos
/// atau marker posisi real-time pada peta pendakian.
Future<void> showHikingPointDetailSheet(
  BuildContext context, {
  HikingWaypoint? initialWaypoint,
  required List<HikingWaypoint> waypoints,
  required LatLng userPoint,
  required bool hasRealGps,
  required bool isTrackingActive,
  required bool isTrackingPaused,
  required bool isOutsideWarning,
  double? gpsAccuracyMeters,
  double? recordedDistanceKm,
  HikingTrailSourceMetadata? sourceMetadata,
  ValueChanged<LatLng>? onFocusPoint,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder:
        (_) => _HikingPointDetailSheet(
          initialWaypoint: initialWaypoint,
          waypoints: waypoints,
          userPoint: userPoint,
          hasRealGps: hasRealGps,
          isTrackingActive: isTrackingActive,
          isTrackingPaused: isTrackingPaused,
          isOutsideWarning: isOutsideWarning,
          gpsAccuracyMeters: gpsAccuracyMeters,
          recordedDistanceKm: recordedDistanceKm,
          sourceMetadata: sourceMetadata,
          onFocusPoint: onFocusPoint,
        ),
  );
}

class _HikingPointDetailSheet extends StatefulWidget {
  const _HikingPointDetailSheet({
    required this.initialWaypoint,
    required this.waypoints,
    required this.userPoint,
    required this.hasRealGps,
    required this.isTrackingActive,
    required this.isTrackingPaused,
    required this.isOutsideWarning,
    this.gpsAccuracyMeters,
    this.recordedDistanceKm,
    this.sourceMetadata,
    this.onFocusPoint,
  });

  final HikingWaypoint? initialWaypoint;
  final List<HikingWaypoint> waypoints;
  final LatLng userPoint;
  final bool hasRealGps;
  final bool isTrackingActive;
  final bool isTrackingPaused;
  final bool isOutsideWarning;
  final double? gpsAccuracyMeters;
  final double? recordedDistanceKm;
  final HikingTrailSourceMetadata? sourceMetadata;
  final ValueChanged<LatLng>? onFocusPoint;

  @override
  State<_HikingPointDetailSheet> createState() =>
      _HikingPointDetailSheetState();
}

class _HikingPointDetailSheetState extends State<_HikingPointDetailSheet> {
  late HikingWaypoint? _selectedWaypoint;

  @override
  void initState() {
    super.initState();
    _selectedWaypoint = widget.initialWaypoint;
  }

  void _selectWaypoint(HikingWaypoint waypoint) {
    setState(() => _selectedWaypoint = waypoint);
    widget.onFocusPoint?.call(waypoint.point);
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.74;
    final activeWaypoint = _selectedWaypoint;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border:
            isHC
                ? Border(top: BorderSide(color: context.borderColor, width: 1.5))
                : null,
        boxShadow:
            isHC
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withAlpha(32),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.viewPaddingOf(context).bottom + 20,
              ),
              child: AnimatedSwitcher(
                duration:
                    context.reduceMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 200),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child:
                    activeWaypoint != null
                        ? _WaypointDetailBody(
                          key: ValueKey('wp_${activeWaypoint.name}'),
                          waypoint: activeWaypoint,
                          allWaypoints: widget.waypoints,
                          userPoint: widget.userPoint,
                          hasRealGps: widget.hasRealGps,
                          sourceMetadata: widget.sourceMetadata,
                          onSelectWaypoint: _selectWaypoint,
                          onFocusMap: () {
                            widget.onFocusPoint?.call(activeWaypoint.point);
                            Navigator.of(context).pop();
                          },
                        )
                        : _UserPointDetailBody(
                          key: const ValueKey('user_realtime'),
                          waypoints: widget.waypoints,
                          userPoint: widget.userPoint,
                          hasRealGps: widget.hasRealGps,
                          isTrackingActive: widget.isTrackingActive,
                          isTrackingPaused: widget.isTrackingPaused,
                          isOutsideWarning: widget.isOutsideWarning,
                          gpsAccuracyMeters: widget.gpsAccuracyMeters,
                          recordedDistanceKm: widget.recordedDistanceKm,
                          sourceMetadata: widget.sourceMetadata,
                          onSelectWaypoint: _selectWaypoint,
                          onFocusMap: () {
                            widget.onFocusPoint?.call(widget.userPoint);
                            Navigator.of(context).pop();
                          },
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaypointDetailBody extends StatelessWidget {
  const _WaypointDetailBody({
    super.key,
    required this.waypoint,
    required this.allWaypoints,
    required this.userPoint,
    required this.hasRealGps,
    required this.sourceMetadata,
    required this.onSelectWaypoint,
    required this.onFocusMap,
  });

  final HikingWaypoint waypoint;
  final List<HikingWaypoint> allWaypoints;
  final LatLng userPoint;
  final bool hasRealGps;
  final HikingTrailSourceMetadata? sourceMetadata;
  final ValueChanged<HikingWaypoint> onSelectWaypoint;
  final VoidCallback onFocusMap;

  @override
  Widget build(BuildContext context) {
    final spec = resolveHikingWaypointSpec(context, waypoint.kind);
    final categoryLabel = _waypointCategoryLabel(context, waypoint.kind);
    final userDistanceMeters = const Distance().as(
      LengthUnit.Meter,
      userPoint,
      waypoint.point,
    );
    final nearby = _nearestWaypoints(
      origin: waypoint.point,
      originWaypoint: waypoint,
      candidates: allWaypoints.where((w) => w.name != waypoint.name).toList(),
    );
    final desc = waypoint.description?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: spec.accent,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.trText(waypoint.modalTitle),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      height: 1.18,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    hasRealGps
                        ? '${context.trText(waypoint.altitude)}  ·  ${_formatDistance(userDistanceMeters)} ${context.trText('dari Anda')}'
                        : context.trText(waypoint.altitude),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            HikingWaypointBadge(waypoint: waypoint, size: 46),
          ],
        ),
        if (desc.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            context.trText(desc),
            style: AppFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        _CoordinateActionStrip(
          coordinatesText:
              '${waypoint.point.latitude.toStringAsFixed(5)}, ${waypoint.point.longitude.toStringAsFixed(5)}',
          onFocusMap: onFocusMap,
        ),
        if (nearby.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            context.trText('Titik Terdekat'),
            style: AppFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < nearby.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _NearbyPlaceCard(
              target: nearby[i].waypoint,
              distanceMeters: nearby[i].distanceMeters,
              elevationDeltaMeters:
                  nearby[i].waypoint.elevationMeters - waypoint.elevationMeters,
              onTap: () => onSelectWaypoint(nearby[i].waypoint),
            ),
          ],
        ],
        if (sourceMetadata != null &&
            sourceMetadata!.displayLabel.isNotEmpty) ...[
          const SizedBox(height: 16),
          HikingTrailSourceAttribution(metadata: sourceMetadata!),
        ],
      ],
    );
  }
}

class _UserPointDetailBody extends StatelessWidget {
  const _UserPointDetailBody({
    super.key,
    required this.waypoints,
    required this.userPoint,
    required this.hasRealGps,
    required this.isTrackingActive,
    required this.isTrackingPaused,
    required this.isOutsideWarning,
    required this.gpsAccuracyMeters,
    required this.recordedDistanceKm,
    required this.sourceMetadata,
    required this.onSelectWaypoint,
    required this.onFocusMap,
  });

  final List<HikingWaypoint> waypoints;
  final LatLng userPoint;
  final bool hasRealGps;
  final bool isTrackingActive;
  final bool isTrackingPaused;
  final bool isOutsideWarning;
  final double? gpsAccuracyMeters;
  final double? recordedDistanceKm;
  final HikingTrailSourceMetadata? sourceMetadata;
  final ValueChanged<HikingWaypoint> onSelectWaypoint;
  final VoidCallback onFocusMap;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final statusColor =
        isOutsideWarning
            ? context.errorColor
            : isTrackingPaused
            ? context.warningColor
            : isHC
            ? context.accentPrimary
            : const Color(0xFF2563EB);
    final categoryLabel =
        isOutsideWarning
            ? context.trText('DI LUAR RADIUS')
            : isTrackingPaused
            ? context.trText('TRACKING DIJEDA')
            : isTrackingActive
            ? context.trText('POSISI REAL-TIME')
            : context.trText('LOKASI GPS');
    final accuracyText =
        gpsAccuracyMeters != null
            ? '±${gpsAccuracyMeters!.round()} m'
            : hasRealGps
            ? context.trText('Sinyal GPS aktif')
            : context.trText('Menunggu GPS terbaru');
    final distanceSummary =
        recordedDistanceKm != null && recordedDistanceKm! > 0
            ? '${recordedDistanceKm!.toStringAsFixed(2)} km ${context.trText('ditempuh')}'
            : accuracyText;

    final nearby = _nearestWaypoints(
      origin: userPoint,
      candidates: waypoints,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryLabel,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: statusColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.trText('Posisi Anda Saat Ini'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.45,
                      height: 1.18,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    distanceSummary,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: context.textSecondary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            HikingUserBadge(
              isActive: isTrackingActive,
              isPaused: isTrackingPaused,
              isWarning: isOutsideWarning,
              size: 46,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _CoordinateActionStrip(
          coordinatesText:
              '${userPoint.latitude.toStringAsFixed(5)}, ${userPoint.longitude.toStringAsFixed(5)}',
          onFocusMap: onFocusMap,
        ),
        if (nearby.isNotEmpty) ...[
          const SizedBox(height: 22),
          Text(
            context.trText('Titik Terdekat'),
            style: AppFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: context.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < nearby.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _NearbyPlaceCard(
              target: nearby[i].waypoint,
              distanceMeters: nearby[i].distanceMeters,
              elevationDeltaMeters: null,
              onTap: () => onSelectWaypoint(nearby[i].waypoint),
            ),
          ],
        ],
        if (sourceMetadata != null &&
            sourceMetadata!.displayLabel.isNotEmpty) ...[
          const SizedBox(height: 16),
          HikingTrailSourceAttribution(metadata: sourceMetadata!),
        ],
      ],
    );
  }
}

class _CoordinateActionStrip extends StatelessWidget {
  const _CoordinateActionStrip({
    required this.coordinatesText,
    required this.onFocusMap,
  });

  final String coordinatesText;
  final VoidCallback onFocusMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.trText('Koordinat'),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: context.textTertiary,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  coordinatesText,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: context.textPrimary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onFocusMap,
            style: TextButton.styleFrom(
              foregroundColor: context.accentPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            icon: const Icon(Icons.center_focus_strong_rounded, size: 15),
            label: Text(
              context.trText('Pusatkan Peta'),
              style: AppFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: context.accentPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NearbyPlaceCard extends StatelessWidget {
  const _NearbyPlaceCard({
    required this.target,
    required this.distanceMeters,
    required this.elevationDeltaMeters,
    required this.onTap,
  });

  final HikingWaypoint target;
  final double distanceMeters;
  final int? elevationDeltaMeters;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final distanceLabel = _formatDistance(distanceMeters);
    final etaLabel = _formatHikingDuration(
      context,
      distanceMeters: distanceMeters,
      elevationDeltaMeters: elevationDeltaMeters ?? 0,
    );
    final delta = elevationDeltaMeters;
    final gainColor =
        delta != null && delta > 0
            ? context.adaptUiColor(const Color(0xFF059669))
            : context.textSecondary;

    return Material(
      color: context.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: context.borderColor,
              width: context.borderWidth,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText(target.modalTitle),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.trText(target.altitude),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: context.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${context.trText('Jarak')}: $distanceLabel, $etaLabel',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    if (delta != null) ...[
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: context.textSecondary,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                          children: [
                            TextSpan(text: '${context.trText('Beda Elevasi')}: '),
                            TextSpan(
                              text:
                                  '${delta >= 0 ? '+' : ''}$delta ${context.trText('meter')}',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: gainColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              HikingWaypointBadge(waypoint: target, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}

class _NearbyCandidate {
  const _NearbyCandidate({
    required this.waypoint,
    required this.distanceMeters,
  });

  final HikingWaypoint waypoint;
  final double distanceMeters;
}

List<_NearbyCandidate> _nearestWaypoints({
  required LatLng origin,
  HikingWaypoint? originWaypoint,
  required List<HikingWaypoint> candidates,
  int limit = 3,
}) {
  const calc = Distance();
  final sorted =
      candidates
          .map(
            (w) => _NearbyCandidate(
              waypoint: w,
              distanceMeters:
                  originWaypoint != null
                      ? HikingTrailRoute.distanceBetweenWaypointsMeters(
                        originWaypoint,
                        w,
                      )
                      : calc.as(LengthUnit.Meter, origin, w.point),
            ),
          )
          .toList()
        ..sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return sorted.take(limit).toList();
}

/// Modal minimalis untuk memilih jalur pendakian aktif pada peta (mis. Sembalun,
/// Senaru, atau Lintas Senaru–Sembalun).
Future<HikingTrailRoute?> showHikingTrailRoutePicker(
  BuildContext context, {
  required HikingTrailDataset dataset,
  required String selectedRouteId,
}) {
  return showModalBottomSheet<HikingTrailRoute>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final isHC = sheetContext.isHighContrast;
      return Container(
        decoration: BoxDecoration(
          color: sheetContext.bgSurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border:
              isHC
                  ? Border(
                    top: BorderSide(
                      color: sheetContext.borderColor,
                      width: 1.5,
                    ),
                  )
                  : null,
        ),
        padding: EdgeInsets.fromLTRB(
          20,
          10,
          20,
          MediaQuery.viewPaddingOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: sheetContext.dividerColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              sheetContext.trText('Pilih Jalur Pendakian'),
              style: AppFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: sheetContext.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sheetContext.trText(dataset.mountainName),
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: sheetContext.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            for (var i = 0; i < dataset.routes.length; i++) ...[
              if (i > 0) const SizedBox(height: 10),
              _RouteOptionCard(
                route: dataset.routes[i],
                isSelected: dataset.routes[i].id == selectedRouteId,
                onTap: () => Navigator.of(sheetContext).pop(dataset.routes[i]),
              ),
            ],
            if (dataset.metadata.displayLabel.isNotEmpty) ...[
              const SizedBox(height: 14),
              HikingTrailSourceAttribution(
                metadata: dataset.metadata,
                prefixLabel: 'Sumber jalur',
              ),
            ],
          ],
        ),
      );
    },
  );
}

/// Keterangan ringkas sumber data titik & jalur pendakian (selaras gaya
/// tautan atribusi `Sumber: BMKG` di kartu cuaca).
class HikingTrailSourceAttribution extends StatelessWidget {
  const HikingTrailSourceAttribution({
    super.key,
    required this.metadata,
    this.prefixLabel = 'Sumber titik jalur',
  });

  final HikingTrailSourceMetadata metadata;
  final String prefixLabel;

  Future<void> _openSourceUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return;
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Tetap aman jika perangkat tidak punya browser eksternal.
    }
  }

  @override
  Widget build(BuildContext context) {
    final label = metadata.displayLabel;
    if (label.isEmpty) return const SizedBox.shrink();

    final url = metadata.sourceUrl;
    final prefix = context.trText(prefixLabel);

    if (url == null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 12,
            color: context.textTertiary,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              '$prefix: $label',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w500,
                color: context.textTertiary,
              ),
            ),
          ),
        ],
      );
    }

    return Semantics(
      link: true,
      label: '${context.trText('Buka sumber data jalur pendakian')}: $label',
      child: Tooltip(
        message: context.trText('Buka sumber data jalur pendakian'),
        child: InkWell(
          onTap: () => unawaited(_openSourceUrl(url)),
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.open_in_new_rounded,
                  size: 11.5,
                  color: context.accentPrimary,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text.rich(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    TextSpan(
                      style: AppFonts.plusJakartaSans(
                        fontSize: 10.5,
                        color: context.textSecondary,
                      ),
                      children: [
                        TextSpan(text: '$prefix: '),
                        TextSpan(
                          text: label,
                          style: TextStyle(
                            color: context.accentPrimary,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                            decorationColor: context.accentPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RouteOptionCard extends StatelessWidget {
  const _RouteOptionCard({
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  final HikingTrailRoute route;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.successColor;
    return Material(
      color: isSelected ? context.bgSecondary : context.bgSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected ? accent : context.borderColor,
              width: isSelected ? 1.5 : context.borderWidth,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText(route.name),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${route.totalDistanceKm.toStringAsFixed(1)} km · +${route.elevationGainMeters} m · ${route.waypoints.length} ${context.trText('titik')}',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 20,
                color: isSelected ? accent : context.textTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }
  return '${meters.round()} m';
}

String _formatHikingDuration(
  BuildContext context, {
  required double distanceMeters,
  required int elevationDeltaMeters,
}) {
  final distanceKm = distanceMeters / 1000.0;
  // Estimasi Naismith jalur gunung: 2.8 km/jam + kompensasi tanjakan/turunan
  final baseHours = distanceKm / 2.8;
  final slopeHours =
      elevationDeltaMeters > 0
          ? elevationDeltaMeters / 350.0
          : elevationDeltaMeters.abs() / 700.0;
  final totalMinutes = ((baseHours + slopeHours) * 60).round().clamp(1, 999);
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours == 0) {
    return '$minutes ${context.trText('menit')}';
  }
  if (minutes == 0) {
    return '$hours ${context.trText('jam')}';
  }
  return '$hours ${context.trText('jam')} $minutes ${context.trText('menit')}';
}

String _waypointCategoryLabel(BuildContext context, HikingWaypointKind kind) {
  switch (kind) {
    case HikingWaypointKind.trailhead:
      return context.trText('GERBANG JALUR');
    case HikingWaypointKind.temple:
      return context.trText('PURA & GERBANG');
    case HikingWaypointKind.post:
      return context.trText('POS PENDAKIAN');
    case HikingWaypointKind.water:
      return context.trText('SUMBER MATA AIR');
    case HikingWaypointKind.camp:
      return context.trText('AREA CAMP KAWAH');
    case HikingWaypointKind.summit:
      return context.trText('PUNCAK GUNUNG');
  }
}
