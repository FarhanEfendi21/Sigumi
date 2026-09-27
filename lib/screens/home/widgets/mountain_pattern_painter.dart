import 'package:flutter/material.dart';

/// Painter gunung minimalist & clean untuk background header HomeScreen.
/// Terinspirasi dari siluet stratovolcano (seperti Merapi / Semeru) dengan
/// sentuhan estetika vektor modern: layer bertingkat, kontur halus,
/// dan aksen salju/kawah minimalis.
class MountainPatternPainter extends CustomPainter {
  final Color nearColor;
  final Color farColor;
  final Color snowColor;

  const MountainPatternPainter({
    required this.nearColor,
    required this.farColor,
    required this.snowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // ── 0. Aksen Minimalis: Lingkaran Matahari / Halo Pudar ──────
    final sunCenter = Offset(w * 0.72, h * 0.25);
    final sunRadius = w * 0.16;

    final sunPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(sunCenter, sunRadius, sunPaint);

    final sunRingPaint = Paint()
      ..color = farColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(sunCenter, sunRadius * 1.35, sunRingPaint);

    // ── 1. Layer Gunung Jauh (Distant Ridges) ────────────────────
    // Siluet gunung berjarak dengan kurva alami
    final farPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          farColor.withValues(alpha: 0.65),
          farColor.withValues(alpha: 0.25),
        ],
      ).createShader(Rect.fromLTWH(0, h * 0.25, w, h * 0.75))
      ..style = PaintingStyle.fill;

    final farPath = Path();
    farPath.moveTo(0, h);
    farPath.lineTo(0, h * 0.60);
    // Lereng kiri puncak pertama (puncak jauh kiri)
    farPath.quadraticBezierTo(w * 0.10, h * 0.58, w * 0.20, h * 0.38);
    // Puncak kiri dan lembah
    farPath.quadraticBezierTo(w * 0.28, h * 0.52, w * 0.38, h * 0.55);
    // Menanjak ke puncak jauh tengah-kanan
    farPath.quadraticBezierTo(w * 0.48, h * 0.45, w * 0.56, h * 0.32);
    // Turun ke kanan
    farPath.quadraticBezierTo(w * 0.68, h * 0.48, w * 0.82, h * 0.58);
    farPath.quadraticBezierTo(w * 0.92, h * 0.62, w, h * 0.55);
    farPath.lineTo(w, h);
    farPath.close();
    canvas.drawPath(farPath, farPaint);

    // ── 2. Layer Gunung Utama (Iconic Stratovolcano Merapi) ───────
    // Puncak utama: (w * 0.64, h * 0.22)
    final mainPeakX = w * 0.64;
    final mainPeakY = h * 0.22;

    // Sisi kiri (terkena cahaya lembut)
    final mainLeftPaint = Paint()
      ..color = nearColor.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;

    final mainLeftPath = Path();
    mainLeftPath.moveTo(0, h);
    mainLeftPath.lineTo(0, h * 0.78);
    // Kurva eksponensial lereng stratovolcano kiri
    mainLeftPath.quadraticBezierTo(w * 0.25, h * 0.72, w * 0.45, h * 0.46);
    mainLeftPath.quadraticBezierTo(w * 0.56, h * 0.30, mainPeakX, mainPeakY);
    // Garis punggungan tengah (ridge) turun ke dasar
    mainLeftPath.quadraticBezierTo(w * 0.61, h * 0.55, w * 0.58, h);
    mainLeftPath.close();
    canvas.drawPath(mainLeftPath, mainLeftPaint);

    // Sisi kanan (bayangan lembut lereng)
    final mainRightPaint = Paint()
      ..color = nearColor.withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;

    final mainRightPath = Path();
    mainRightPath.moveTo(mainPeakX, mainPeakY);
    // Lereng kanan curam khas kawah aktif
    mainRightPath.quadraticBezierTo(w * 0.74, h * 0.34, w * 0.85, h * 0.56);
    mainRightPath.quadraticBezierTo(w * 0.94, h * 0.70, w, h * 0.76);
    mainRightPath.lineTo(w, h);
    mainRightPath.lineTo(w * 0.58, h);
    mainRightPath.quadraticBezierTo(w * 0.61, h * 0.55, mainPeakX, mainPeakY);
    mainRightPath.close();
    canvas.drawPath(mainRightPath, mainRightPaint);

    // Garis punggungan gunung (ridge highlight)
    final ridgePaint = Paint()
      ..color = snowColor.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final ridgePath = Path();
    ridgePath.moveTo(mainPeakX, mainPeakY);
    ridgePath.quadraticBezierTo(w * 0.61, h * 0.55, w * 0.58, h);
    canvas.drawPath(ridgePath, ridgePaint);

    // ── 3. Tudung Salju / Puncak Kawah Minimalis (Cap) ───────────
    final snowPaint = Paint()
      ..color = snowColor.withValues(alpha: 0.85)
      ..style = PaintingStyle.fill;

    final snowPath = Path();
    snowPath.moveTo(mainPeakX, mainPeakY);
    snowPath.lineTo(mainPeakX - w * 0.05, mainPeakY + h * 0.07);
    snowPath.lineTo(mainPeakX - w * 0.02, mainPeakY + h * 0.06);
    snowPath.lineTo(mainPeakX, mainPeakY + h * 0.08);
    snowPath.lineTo(mainPeakX + w * 0.025, mainPeakY + h * 0.06);
    snowPath.lineTo(mainPeakX + w * 0.045, mainPeakY + h * 0.075);
    snowPath.close();
    canvas.drawPath(snowPath, snowPaint);

    // Puncak kecil kedua (puncak kiri)
    final p2x = w * 0.20;
    final p2y = h * 0.38;
    final snow2Path = Path();
    snow2Path.moveTo(p2x, p2y);
    snow2Path.lineTo(p2x - w * 0.03, p2y + h * 0.045);
    snow2Path.lineTo(p2x, p2y + h * 0.05);
    snow2Path.lineTo(p2x + w * 0.03, p2y + h * 0.045);
    snow2Path.close();
    canvas.drawPath(snow2Path, snowPaint);

    // ── 4. Layer Bukit Depan (Foreground Foothills) ──────────────
    // Bukit halus di bagian bawah yang mempercantik transisi
    final hillPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    final hillPath = Path();
    hillPath.moveTo(0, h);
    hillPath.lineTo(0, h * 0.88);
    hillPath.quadraticBezierTo(w * 0.22, h * 0.80, w * 0.44, h * 0.87);
    hillPath.quadraticBezierTo(w * 0.68, h * 0.94, w * 0.88, h * 0.83);
    hillPath.quadraticBezierTo(w * 0.96, h * 0.80, w, h * 0.84);
    hillPath.lineTo(w, h);
    hillPath.close();
    canvas.drawPath(hillPath, hillPaint);
  }

  @override
  bool shouldRepaint(MountainPatternPainter oldDelegate) =>
      oldDelegate.nearColor != nearColor ||
      oldDelegate.farColor != farColor ||
      oldDelegate.snowColor != snowColor;
}
