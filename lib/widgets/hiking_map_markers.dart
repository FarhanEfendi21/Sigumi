import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../config/theme_extensions.dart';
import '../services/localization_service.dart';

/// Kategori semantik titik pos jalur pendakian agar setiap marker punya
/// identitas bentuk, warna, dan ikon vektor yang mudah dibedakan di peta.
enum HikingWaypointKind {
  /// Gerbang awal pendakian (mis. Gerbang Sembalun).
  trailhead,

  /// Pura / gerbang suci awal pendakian (mis. Pura Pasar Agung).
  temple,

  /// Pos pemantauan atau shelter jalur.
  post,

  /// Pos sumber mata air (mis. Pos 2 Tengengean).
  water,

  /// Area camp atau pelawangan kawah (mis. Plawangan Sembalun).
  camp,

  /// Puncak gunung berapi.
  summit,
}

/// Data titik waypoint jalur pendakian untuk ditampilkan di peta real-time.
class HikingWaypoint {
  const HikingWaypoint({
    this.id,
    required this.name,
    required this.shortLabel,
    required this.modalTitle,
    required this.altitude,
    required this.elevationMeters,
    required this.point,
    required this.kind,
    this.badgeNumber,
    this.trailKm,
    this.description,
  });

  final String? id;
  final String name;
  final String shortLabel;
  final String modalTitle;
  final String altitude;
  final int elevationMeters;
  final LatLng point;
  final HikingWaypointKind kind;
  final String? badgeNumber;

  /// Jarak kumulatif (km) sepanjang polyline jalur aktif untuk menghitung
  /// jarak tempuh riil antar pos di modal detail.
  final double? trailKm;

  /// Keterangan ringkas titik pos (shelter, mata air, camp, dll.).
  final String? description;
}

class HikingWaypointVisualSpec {
  const HikingWaypointVisualSpec({
    required this.gradient,
    required this.accent,
  });

  final List<Color> gradient;
  final Color accent;
}

HikingWaypointVisualSpec resolveHikingWaypointSpec(
  BuildContext context,
  HikingWaypointKind kind,
) {
  if (context.isHighContrast) {
    final accent =
        kind == HikingWaypointKind.summit
            ? context.accentSecondary
            : context.accentPrimary;
    return HikingWaypointVisualSpec(
      gradient: [context.bgSurface, context.bgPrimary],
      accent: accent,
    );
  }

  switch (kind) {
    case HikingWaypointKind.trailhead:
      final primary = context.adaptUiColor(const Color(0xFF10B981));
      final secondary = context.adaptUiColor(const Color(0xFF047857));
      return HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: primary,
      );
    case HikingWaypointKind.temple:
      const primary = Color(0xFFF59E0B);
      const secondary = Color(0xFFB45309);
      return const HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: primary,
      );
    case HikingWaypointKind.post:
      final primary = context.adaptUiColor(const Color(0xFF14B8A6));
      final secondary = context.adaptUiColor(const Color(0xFF0F766E));
      return HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: primary,
      );
    case HikingWaypointKind.water:
      const primary = Color(0xFF0EA5E9);
      const secondary = Color(0xFF0369A1);
      return const HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: primary,
      );
    case HikingWaypointKind.camp:
      const primary = Color(0xFF6366F1);
      const secondary = Color(0xFF4338CA);
      return const HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: primary,
      );
    case HikingWaypointKind.summit:
      const primary = Color(0xFFFB923C);
      const secondary = Color(0xFFEA580C);
      return const HikingWaypointVisualSpec(
        gradient: [primary, secondary],
        accent: secondary,
      );
  }
}

/// Marker pin modern berbentuk teardrop + label kapsul mengambang + titik jangkar
/// untuk setiap titik pos jalur pendakian di peta real-time.
class HikingWaypointMarker extends StatelessWidget {
  const HikingWaypointMarker({
    super.key,
    required this.waypoint,
    required this.onTap,
  });

  final HikingWaypoint waypoint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final isSummit = waypoint.kind == HikingWaypointKind.summit;
    final spec = resolveHikingWaypointSpec(context, waypoint.kind);
    final pinWidth = isSummit ? 31.0 : 27.0;
    final pinHeight = isSummit ? 37.0 : 32.0;
    final headRadius = (pinWidth / 2) - 1.8;
    final headCenterY = headRadius + 1.8;
    final glyphSize = isSummit ? 15.5 : 13.5;

    final pillBg = isHC ? context.bgSurface : const Color(0xEB0F172A);
    final pillBorder =
        isHC ? spec.accent : Colors.white.withAlpha(55);
    final pillTextColor = isHC ? context.textPrimary : Colors.white;
    final pinBorderColor = isHC ? spec.accent : Colors.white;
    final glyphColor = isHC ? spec.accent : Colors.white;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Semantics(
        button: true,
        label:
            '${context.trText(waypoint.name)}, ${context.trText(waypoint.altitude)}',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Kapsul label modern di atas pin agar tidak menutupi jalur di bawahnya
            Container(
              constraints: BoxConstraints(maxWidth: isSummit ? 104 : 88),
              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
              decoration: BoxDecoration(
                color: pillBg,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: pillBorder,
                  width: isHC ? 1.2 : 0.9,
                ),
                boxShadow:
                    isHC
                        ? null
                        : [
                          BoxShadow(
                            color: Colors.black.withAlpha(55),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5.5,
                    height: 5.5,
                    decoration: BoxDecoration(
                      color: spec.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.trText(waypoint.shortLabel),
                        maxLines: 1,
                        softWrap: false,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.15,
                          color: pillTextColor,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.5),

            // Pin teardrop bergradien dengan ikon vektor kustom
            SizedBox(
              width: pinWidth + 8,
              height: pinHeight + 4,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.topCenter,
                children: [
                  if (isSummit && !isHC)
                    Positioned(
                      top: headCenterY - (pinWidth * 0.62),
                      child: Container(
                        width: pinWidth * 1.24,
                        height: pinWidth * 1.24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: spec.accent.withAlpha(55),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 2,
                    child: SizedBox(
                      width: pinWidth,
                      height: pinHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          CustomPaint(
                            size: Size(pinWidth, pinHeight),
                            painter: _TeardropPinPainter(
                              gradientColors: spec.gradient,
                              borderColor: pinBorderColor,
                              shadowColor:
                                  isHC
                                      ? Colors.transparent
                                      : spec.accent.withAlpha(110),
                              isHighContrast: isHC,
                            ),
                          ),
                          Positioned(
                            top: headCenterY - (glyphSize / 2),
                            left: 0,
                            right: 0,
                            child: Center(
                              child: CustomPaint(
                                size: Size(glyphSize, glyphSize),
                                painter: _WaypointGlyphPainter(
                                  kind: waypoint.kind,
                                  color: glyphColor,
                                ),
                              ),
                            ),
                          ),
                          if (waypoint.badgeNumber != null)
                            Positioned(
                              top: -2.5,
                              right: -3.5,
                              child: Container(
                                width: 13,
                                height: 13,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isHC ? context.bgPrimary : Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: spec.accent,
                                    width: 1.4,
                                  ),
                                  boxShadow:
                                      isHC
                                          ? null
                                          : [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(45),
                                              blurRadius: 3,
                                            ),
                                          ],
                                ),
                                child: Text(
                                  waypoint.badgeNumber!,
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w800,
                                    color:
                                        isHC
                                            ? context.textPrimary
                                            : spec.gradient.last,
                                    height: 1.0,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Titik jangkar di dasar pin tepat menyentuh koordinat jalur
            Container(
              width: 8,
              height: 8,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: spec.accent.withAlpha(isHC ? 90 : 75),
              ),
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: spec.accent,
                  border: Border.all(
                    color: isHC ? context.bgPrimary : Colors.white,
                    width: 0.9,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge ikon vektor titik pos untuk dipakai di header modal card & daftar terdekat
/// agar konsisten dengan marker peta.
class HikingWaypointBadge extends StatelessWidget {
  const HikingWaypointBadge({
    super.key,
    required this.waypoint,
    this.size = 44,
  });

  final HikingWaypoint waypoint;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final spec = resolveHikingWaypointSpec(context, waypoint.kind);
    final glyphSize = size * 0.48;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.3),
            color:
                isHC
                    ? context.bgPrimary
                    : spec.accent.withAlpha(24),
            border: Border.all(
              color:
                  isHC
                      ? spec.accent
                      : spec.accent.withAlpha(75),
              width: isHC ? 1.5 : 1.0,
            ),
          ),
          child: CustomPaint(
            size: Size(glyphSize, glyphSize),
            painter: _WaypointGlyphPainter(
              kind: waypoint.kind,
              color: isHC ? spec.accent : spec.gradient.last,
            ),
          ),
        ),
        if (waypoint.badgeNumber != null)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isHC ? context.bgPrimary : context.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(color: spec.accent, width: 1.4),
              ),
              child: Text(
                waypoint.badgeNumber!,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: isHC ? context.textPrimary : spec.gradient.last,
                  height: 1.0,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Badge ikon vektor posisi pengguna real-time untuk header modal card.
class HikingUserBadge extends StatelessWidget {
  const HikingUserBadge({
    super.key,
    required this.isActive,
    required this.isPaused,
    required this.isWarning,
    this.size = 44,
  });

  final bool isActive;
  final bool isPaused;
  final bool isWarning;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final accent =
        isHC
            ? (isWarning ? context.errorColor : context.accentPrimary)
            : isWarning
            ? const Color(0xFFDC2626)
            : isPaused
            ? const Color(0xFF64748B)
            : const Color(0xFF2563EB);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isHC ? context.bgPrimary : accent.withAlpha(24),
        border: Border.all(
          color: isHC ? accent : accent.withAlpha(80),
          width: isHC ? 1.5 : 1.0,
        ),
      ),
      child: CustomPaint(
        size: Size(size * 0.44, size * 0.44),
        painter: _UserNavigationGlyphPainter(color: accent),
      ),
    );
  }
}

/// Marker posisi real-time pendaki dengan desain GPS radar beacon modern:
/// dua gelombang sonar bertingkat saat aktif, puck navigasi bergradien,
/// ikon kompas vektor, dan titik indikator status langsung.
class HikingUserRealtimeMarker extends StatefulWidget {
  const HikingUserRealtimeMarker({
    super.key,
    required this.isActive,
    required this.isWarning,
    this.isPaused = false,
    this.onTap,
  });

  final bool isActive;
  final bool isWarning;
  final bool isPaused;
  final VoidCallback? onTap;

  @override
  State<HikingUserRealtimeMarker> createState() =>
      _HikingUserRealtimeMarkerState();
}

class _HikingUserRealtimeMarkerState extends State<HikingUserRealtimeMarker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant HikingUserRealtimeMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive ||
        oldWidget.isPaused != widget.isPaused) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    final shouldAnimate = !context.reduceMotion && !widget.isPaused;
    if (shouldAnimate) {
      if (!_pulseController.isAnimating) {
        _pulseController.repeat();
      }
    } else if (_pulseController.isAnimating) {
      _pulseController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildSonarRing(
    double progress,
    Color ringColor, {
    required double minDiameter,
    required double maxDiameter,
    required int maxAlpha,
  }) {
    final curved = Curves.easeOutCubic.transform(progress);
    final diameter = minDiameter + (curved * (maxDiameter - minDiameter));
    final alpha = ((1.0 - curved) * maxAlpha).round().clamp(0, 255);

    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withAlpha((alpha * 0.45).round()),
        border: Border.all(
          color: ringColor.withAlpha(alpha),
          width: 1.4,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHC = context.isHighContrast;
    final Color primaryColor;
    final Color secondaryColor;
    final Color statusDotColor;

    if (isHC) {
      primaryColor =
          widget.isWarning ? context.errorColor : context.accentPrimary;
      secondaryColor = primaryColor;
      statusDotColor =
          widget.isWarning ? context.errorColor : context.accentSecondary;
    } else if (widget.isWarning) {
      primaryColor = const Color(0xFFF97316);
      secondaryColor = const Color(0xFFDC2626);
      statusDotColor = const Color(0xFFEF4444);
    } else if (widget.isPaused) {
      primaryColor = const Color(0xFF64748B);
      secondaryColor = const Color(0xFF334155);
      statusDotColor = const Color(0xFFF59E0B);
    } else {
      primaryColor = const Color(0xFF3B82F6);
      secondaryColor = const Color(0xFF06B6D4);
      statusDotColor = const Color(0xFF22C55E);
    }

    final borderColor = isHC ? context.bgPrimary : Colors.white;
    final glyphColor = isHC ? context.bgPrimary : Colors.white;
    final reduceMotion = context.reduceMotion;

    final corePuck = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Kerah frosted lembut agar puck kontras di atas peta topografi
        Container(
          width: 35,
          height: 35,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: (isHC ? primaryColor : Colors.white).withAlpha(
              isHC ? 40 : 155,
            ),
          ),
        ),
        // Puck utama bergradien
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, secondaryColor],
            ),
            border: Border.all(color: borderColor, width: 2.5),
            boxShadow:
                isHC
                    ? null
                    : [
                      BoxShadow(
                        color: primaryColor.withAlpha(125),
                        blurRadius: 12,
                        spreadRadius: 1,
                        offset: const Offset(0, 2),
                      ),
                      BoxShadow(
                        color: Colors.black.withAlpha(55),
                        blurRadius: 4,
                        offset: const Offset(0, 1.5),
                      ),
                    ],
          ),
          child: Center(
            child: CustomPaint(
              size: const Size(14, 14),
              painter: _UserNavigationGlyphPainter(color: glyphColor),
            ),
          ),
        ),
        // Titik status live / peringatan / jeda di sudut kanan atas puck
        if (widget.isActive || widget.isWarning || widget.isPaused)
          Positioned(
            top: 2,
            right: 2,
            child: Container(
              width: 8.5,
              height: 8.5,
              decoration: BoxDecoration(
                color: statusDotColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 1.4),
              ),
            ),
          ),
      ],
    );

    final content = AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        if (reduceMotion || widget.isPaused) {
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withAlpha(24),
                  border: Border.all(
                    color: primaryColor.withAlpha(70),
                    width: 1.0,
                  ),
                ),
              ),
              child!,
            ],
          );
        }

        final t1 = _pulseController.value;
        final t2 = (t1 + 0.5) % 1.0;
        final maxRadius = widget.isActive ? 62.0 : 48.0;
        final maxAlpha = widget.isActive ? 115 : 65;

        return Stack(
          alignment: Alignment.center,
          children: [
            _buildSonarRing(
              t1,
              primaryColor,
              minDiameter: 30,
              maxDiameter: maxRadius,
              maxAlpha: maxAlpha,
            ),
            if (widget.isActive)
              _buildSonarRing(
                t2,
                secondaryColor,
                minDiameter: 30,
                maxDiameter: maxRadius,
                maxAlpha: (maxAlpha * 0.85).round(),
              ),
            child!,
          ],
        );
      },
      child: corePuck,
    );

    if (widget.onTap == null) return content;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: Semantics(
        button: true,
        label: context.trText('Lokasi saya'),
        child: content,
      ),
    );
  }
}

class _TeardropPinPainter extends CustomPainter {
  const _TeardropPinPainter({
    required this.gradientColors,
    required this.borderColor,
    required this.shadowColor,
    required this.isHighContrast,
  });

  final List<Color> gradientColors;
  final Color borderColor;
  final Color shadowColor;
  final bool isHighContrast;

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final r = (size.width / 2) - 1.8;
    final cy = r + 1.8;
    final tipY = size.height - 1.8;

    const lowerAngle = 0.16 * math.pi;
    final cosA = math.cos(lowerAngle);
    final sinA = math.sin(lowerAngle);
    final rightX = cx + (r * cosA);
    final leftX = cx - (r * cosA);
    final lowerY = cy + (r * sinA);

    final path =
        Path()
          ..arcTo(
            Rect.fromCircle(center: Offset(cx, cy), radius: r),
            math.pi * 0.84,
            math.pi * 1.32,
            true,
          )
          ..cubicTo(
            rightX - (r * 0.24 * sinA),
            lowerY + (r * 0.44 * cosA),
            cx + (r * 0.16),
            tipY - 2.4,
            cx,
            tipY,
          )
          ..cubicTo(
            cx - (r * 0.16),
            tipY - 2.4,
            leftX + (r * 0.24 * sinA),
            lowerY + (r * 0.44 * cosA),
            leftX,
            lowerY,
          )
          ..close();

    if (!isHighContrast && shadowColor != Colors.transparent) {
      final shadowPaint =
          Paint()
            ..color = shadowColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.6);
      canvas.drawPath(path.shift(const Offset(0, 1.8)), shadowPaint);
    }

    final fillPaint =
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(path, fillPaint);

    // Kilau halus pada tepi atas untuk efek kedalaman modern
    if (!isHighContrast) {
      final sheenPaint =
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2
            ..strokeCap = StrokeCap.round
            ..color = Colors.white.withAlpha(90);
      canvas.drawArc(
        Rect.fromCircle(center: Offset(cx, cy), radius: r - 2.2),
        -math.pi * 0.78,
        math.pi * 0.56,
        false,
        sheenPaint,
      );
    }

    final borderPaint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = isHighContrast ? 1.8 : 1.7
          ..strokeJoin = StrokeJoin.round
          ..color = borderColor;
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _TeardropPinPainter oldDelegate) =>
      oldDelegate.borderColor != borderColor ||
      oldDelegate.shadowColor != shadowColor ||
      oldDelegate.isHighContrast != isHighContrast ||
      oldDelegate.gradientColors.first != gradientColors.first ||
      oldDelegate.gradientColors.last != gradientColors.last;
}

class _WaypointGlyphPainter extends CustomPainter {
  const _WaypointGlyphPainter({
    required this.kind,
    required this.color,
  });

  final HikingWaypointKind kind;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    final fill =
        Paint()
          ..style = PaintingStyle.fill
          ..color = color;
    final softFill =
        Paint()
          ..style = PaintingStyle.fill
          ..color = color.withAlpha(75);
    final stroke =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.9 * sx
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = color;

    switch (kind) {
      case HikingWaypointKind.summit:
        // Puncak kembar gunung + bendera puncak
        final mountain =
            Path()
              ..moveTo(2.5 * sx, 19.5 * sy)
              ..lineTo(9.5 * sx, 7.2 * sy)
              ..lineTo(13.8 * sx, 14.2 * sy)
              ..lineTo(16.8 * sx, 10.2 * sy)
              ..lineTo(21.5 * sx, 19.5 * sy)
              ..close();
        canvas.drawPath(mountain, softFill);
        canvas.drawPath(mountain, stroke);

        canvas.drawLine(p(9.5, 7.2), p(9.5, 2.2), stroke);
        final flag =
            Path()
              ..moveTo(9.5 * sx, 2.2 * sy)
              ..lineTo(15.2 * sx, 4.1 * sy)
              ..lineTo(9.5 * sx, 6.0 * sy)
              ..close();
        canvas.drawPath(flag, fill);

      case HikingWaypointKind.camp:
        // Tenda pendakian A-frame + bintang malam
        final tent =
            Path()
              ..moveTo(3.8 * sx, 19.2 * sy)
              ..lineTo(12.0 * sx, 6.8 * sy)
              ..lineTo(20.2 * sx, 19.2 * sy)
              ..close();
        canvas.drawPath(tent, softFill);
        canvas.drawPath(tent, stroke);

        // Ujung tiang silang di puncak tenda
        canvas.drawLine(p(10.5, 4.6), p(12.0, 6.8), stroke);
        canvas.drawLine(p(13.5, 4.6), p(12.0, 6.8), stroke);

        // Pintu tenda
        final door =
            Path()
              ..moveTo(9.3 * sx, 19.2 * sy)
              ..lineTo(12.0 * sx, 13.0 * sy)
              ..lineTo(14.7 * sx, 19.2 * sy)
              ..close();
        canvas.drawPath(door, fill);

        // Bintang camp di sudut atas
        canvas.drawCircle(p(18.8, 6.0), 1.4 * sx, fill);

      case HikingWaypointKind.water:
        // Tetesan air jernih + riak mata air
        final drop =
            Path()
              ..moveTo(12.0 * sx, 2.8 * sy)
              ..cubicTo(
                15.6 * sx,
                7.6 * sy,
                17.6 * sx,
                10.6 * sy,
                17.6 * sx,
                13.4 * sy,
              )
              ..cubicTo(
                17.6 * sx,
                16.4 * sy,
                15.1 * sx,
                18.2 * sy,
                12.0 * sx,
                18.2 * sy,
              )
              ..cubicTo(
                8.9 * sx,
                18.2 * sy,
                6.4 * sx,
                16.4 * sy,
                6.4 * sx,
                13.4 * sy,
              )
              ..cubicTo(
                6.4 * sx,
                10.6 * sy,
                8.4 * sx,
                7.6 * sy,
                12.0 * sx,
                2.8 * sy,
              )
              ..close();
        canvas.drawPath(drop, fill);

        final ripple =
            Path()
              ..moveTo(5.6 * sx, 20.4 * sy)
              ..quadraticBezierTo(12.0 * sx, 22.3 * sy, 18.4 * sx, 20.4 * sy);
        canvas.drawPath(
          ripple,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8 * sx
            ..strokeCap = StrokeCap.round
            ..color = color.withAlpha(220),
        );

      case HikingWaypointKind.post:
        // Shelter / pondok pos pemantauan
        final body =
            Path()
              ..moveTo(6.0 * sx, 10.6 * sy)
              ..lineTo(6.0 * sx, 19.4 * sy)
              ..lineTo(18.0 * sx, 19.4 * sy)
              ..lineTo(18.0 * sx, 10.6 * sy)
              ..lineTo(12.0 * sx, 5.4 * sy)
              ..close();
        canvas.drawPath(body, softFill);
        canvas.drawPath(body, stroke);

        final roof =
            Path()
              ..moveTo(3.0 * sx, 11.4 * sy)
              ..lineTo(12.0 * sx, 4.4 * sy)
              ..lineTo(21.0 * sx, 11.4 * sy);
        canvas.drawPath(
          roof,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.2 * sx
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round
            ..color = color,
        );

        canvas.drawRRect(
          RRect.fromLTRBAndCorners(
            10.0 * sx,
            13.4 * sy,
            14.0 * sx,
            19.4 * sy,
            topLeft: Radius.circular(1.6 * sx),
            topRight: Radius.circular(1.6 * sx),
          ),
          fill,
        );

      case HikingWaypointKind.trailhead:
        // Gapura gerbang pendakian + jejak jalur masuk
        final arch =
            Path()
              ..moveTo(5.2 * sx, 19.4 * sy)
              ..lineTo(5.2 * sx, 10.2 * sy)
              ..cubicTo(
                5.2 * sx,
                4.2 * sy,
                18.8 * sx,
                4.2 * sy,
                18.8 * sx,
                10.2 * sy,
              )
              ..lineTo(18.8 * sx, 19.4 * sy);
        canvas.drawPath(
          arch,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.1 * sx
            ..strokeCap = StrokeCap.round
            ..color = color,
        );

        final trail =
            Path()
              ..moveTo(9.8 * sx, 19.6 * sy)
              ..cubicTo(
                8.8 * sx,
                16.2 * sy,
                14.8 * sx,
                15.4 * sy,
                13.2 * sx,
                11.4 * sy,
              );
        canvas.drawPath(trail, stroke);
        canvas.drawCircle(p(12.0, 4.4), 1.5 * sx, fill);

      case HikingWaypointKind.temple:
        // Candi Bentar (gerbang belah khas Bali) untuk Pura Pasar Agung
        final leftTower =
            Path()
              ..moveTo(3.5 * sx, 19.4 * sy)
              ..lineTo(10.2 * sx, 19.4 * sy)
              ..lineTo(10.2 * sx, 5.8 * sy)
              ..lineTo(8.3 * sx, 3.6 * sy)
              ..lineTo(6.6 * sx, 7.8 * sy)
              ..lineTo(5.2 * sx, 11.4 * sy)
              ..lineTo(4.1 * sx, 15.2 * sy)
              ..close();
        final rightTower =
            Path()
              ..moveTo(20.5 * sx, 19.4 * sy)
              ..lineTo(13.8 * sx, 19.4 * sy)
              ..lineTo(13.8 * sx, 5.8 * sy)
              ..lineTo(15.7 * sx, 3.6 * sy)
              ..lineTo(17.4 * sx, 7.8 * sy)
              ..lineTo(18.8 * sx, 11.4 * sy)
              ..lineTo(19.9 * sx, 15.2 * sy)
              ..close();
        canvas.drawPath(leftTower, fill);
        canvas.drawPath(rightTower, fill);
        canvas.drawLine(p(2.5, 19.4), p(21.5, 19.4), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _WaypointGlyphPainter oldDelegate) =>
      oldDelegate.kind != kind || oldDelegate.color != color;
}

class _UserNavigationGlyphPainter extends CustomPainter {
  const _UserNavigationGlyphPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / 24.0;
    final sy = size.height / 24.0;

    final chevron =
        Path()
          ..moveTo(12.0 * sx, 3.4 * sy)
          ..lineTo(19.6 * sx, 19.2 * sy)
          ..lineTo(12.0 * sx, 15.6 * sy)
          ..lineTo(4.4 * sx, 19.2 * sy)
          ..close();

    canvas.drawPath(
      chevron,
      Paint()
        ..style = PaintingStyle.fill
        ..color = color,
    );
    canvas.drawPath(
      chevron,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4 * sx
        ..strokeJoin = StrokeJoin.round
        ..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _UserNavigationGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}
