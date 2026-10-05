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

    // Keep the brand wash continuous across the full home viewport. The hues
    // stay close to the scaffold neutral so cards and text remain prominent.
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFF0F4FB),
            Color(0xFFF4F6FA),
            Color(0xFFFAF7EF),
            Color(0xFFF5F7FA),
          ],
          stops: [0, 0.38, 0.78, 1],
        ).createShader(bounds),
    );

    _drawOrb(
      canvas,
      center: Offset(size.width * 0.98, size.height * 0.08),
      radius: size.width * 0.88,
      color: _blue,
      opacity: 0.13,
    );
    _drawOrb(
      canvas,
      center: Offset(-size.width * 0.08, size.height * 0.98),
      radius: size.width * 0.82,
      color: _yellow,
      opacity: 0.12,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 1.05, size.height * 0.69),
      radius: size.width * 0.72,
      color: _blue,
      opacity: 0.035,
    );
    _drawOrb(
      canvas,
      center: Offset(size.width * 0.21, size.height * 0.94),
      radius: size.width * 0.46,
      color: _yellow,
      opacity: 0.03,
    );
  }

  @override
  bool shouldRepaint(covariant HomeAmbientBackdropPainter oldDelegate) => false;
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
