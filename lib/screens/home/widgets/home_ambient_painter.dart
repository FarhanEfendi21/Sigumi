import 'package:flutter/material.dart';

/// Background aksen statis untuk Home. Bentuk abstrak menjaga halaman tetap
/// ringan dan tidak bersaing dengan kartu maupun teks di atasnya.
class HomeAmbientBackdropPainter extends CustomPainter {
  const HomeAmbientBackdropPainter();

  static const _blue = Color(0xFF1F6FD2);
  static const _yellow = Color(0xFFFFC928);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawOrb(
      canvas,
      center: Offset(size.width * 0.94, size.height * 0.12),
      radius: size.width * 0.62,
      color: _blue,
      opacity: 0.075,
    );
    _drawOrb(
      canvas,
      center: Offset(-size.width * 0.14, size.height * 0.40),
      radius: size.width * 0.54,
      color: _yellow,
      opacity: 0.065,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 1.05, size.height * 0.69),
      radius: size.width * 0.72,
      color: _blue,
      opacity: 0.050,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.21, size.height * 0.94),
      radius: size.width * 0.46,
      color: _yellow,
      opacity: 0.045,
    );
  }

  @override
  bool shouldRepaint(covariant HomeAmbientBackdropPainter oldDelegate) => false;
}

/// Aksen yang lebih rapat untuk header. Semua warna berhenti transparan agar
/// hierarki teks dan kontrol tetap jelas.
class HomeHeaderAmbientPainter extends CustomPainter {
  const HomeHeaderAmbientPainter();

  static const _blue = Color(0xFF2574D7);
  static const _yellow = Color(0xFFFFC928);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    _drawOrb(
      canvas,
      center: Offset(size.width * 0.92, size.height * 0.10),
      radius: size.width * 0.47,
      color: _blue,
      opacity: 0.14,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.10, size.height * 1.02),
      radius: size.width * 0.44,
      color: _yellow,
      opacity: 0.13,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 1.03, size.height * 0.86),
      radius: size.width * 0.30,
      color: _yellow,
      opacity: 0.075,
    );
  }

  @override
  bool shouldRepaint(covariant HomeHeaderAmbientPainter oldDelegate) => false;
}

void _drawOrb(
  Canvas canvas, {
  required Offset center,
  required double radius,
  required Color color,
  required double opacity,
}) {
  final bounds = Rect.fromCircle(center: center, radius: radius);
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(
        colors: [color.withValues(alpha: opacity), color.withValues(alpha: 0)],
        stops: const [0, 1],
      ).createShader(bounds),
  );
}
