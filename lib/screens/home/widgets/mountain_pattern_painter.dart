import 'package:flutter/material.dart';

/// Draws a quiet, layered volcano silhouette behind the home header.
class MountainPatternPainter extends CustomPainter {
  final Color nearColor;
  final Color farColor;
  final Color highlightColor;

  const MountainPatternPainter({
    required this.nearColor,
    required this.farColor,
    required this.highlightColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final width = size.width;
    final height = size.height;

    // A soft sun adds a little depth without competing with the header text.
    final sunCenter = Offset(width * 0.82, height * 0.27);
    canvas.drawCircle(
      sunCenter,
      height * 0.105,
      Paint()..color = highlightColor.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      sunCenter,
      height * 0.14,
      Paint()
        ..color = farColor.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Distant ridges sit low and stay pale to create atmospheric depth.
    final distantRidge = Path()
      ..moveTo(0, height * 0.78)
      ..cubicTo(
        width * 0.16,
        height * 0.70,
        width * 0.19,
        height * 0.55,
        width * 0.34,
        height * 0.62,
      )
      ..cubicTo(
        width * 0.48,
        height * 0.70,
        width * 0.54,
        height * 0.56,
        width * 0.68,
        height * 0.61,
      )
      ..cubicTo(
        width * 0.82,
        height * 0.66,
        width * 0.89,
        height * 0.72,
        width,
        height * 0.65,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(
      distantRidge,
      Paint()..color = farColor.withValues(alpha: 0.19),
    );

    // One clean stratovolcano profile anchors the composition.
    final volcano = Path()
      ..moveTo(0, height * 0.88)
      ..cubicTo(
        width * 0.22,
        height * 0.83,
        width * 0.34,
        height * 0.66,
        width * 0.48,
        height * 0.55,
      )
      ..cubicTo(
        width * 0.56,
        height * 0.49,
        width * 0.60,
        height * 0.39,
        width * 0.67,
        height * 0.35,
      )
      ..cubicTo(
        width * 0.75,
        height * 0.43,
        width * 0.80,
        height * 0.65,
        width,
        height * 0.78,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(
      volcano,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            nearColor.withValues(alpha: 0.18),
            nearColor.withValues(alpha: 0.08),
          ],
        ).createShader(Rect.fromLTWH(0, height * 0.35, width, height * 0.65)),
    );

    // A faint ridge highlight gives the slope definition without a snowcap.
    final ridgeLine = Path()
      ..moveTo(width * 0.48, height * 0.55)
      ..cubicTo(
        width * 0.56,
        height * 0.49,
        width * 0.60,
        height * 0.39,
        width * 0.67,
        height * 0.35,
      )
      ..cubicTo(
        width * 0.74,
        height * 0.43,
        width * 0.79,
        height * 0.61,
        width * 0.86,
        height * 0.69,
      );
    canvas.drawPath(
      ridgeLine,
      Paint()
        ..color = highlightColor.withValues(alpha: 0.36)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1
        ..strokeCap = StrokeCap.round,
    );

    // A foreground foothill softly blends the illustration into the card.
    final foreground = Path()
      ..moveTo(0, height * 0.91)
      ..cubicTo(
        width * 0.20,
        height * 0.82,
        width * 0.37,
        height * 0.88,
        width * 0.53,
        height * 0.92,
      )
      ..cubicTo(
        width * 0.70,
        height * 0.96,
        width * 0.84,
        height * 0.83,
        width,
        height * 0.88,
      )
      ..lineTo(width, height)
      ..lineTo(0, height)
      ..close();
    canvas.drawPath(
      foreground,
      Paint()..color = highlightColor.withValues(alpha: 0.16),
    );
  }

  @override
  bool shouldRepaint(MountainPatternPainter oldDelegate) =>
      oldDelegate.nearColor != nearColor ||
      oldDelegate.farColor != farColor ||
      oldDelegate.highlightColor != highlightColor;
}

/// A subtle repeating mountain landscape that carries the home page theme
/// through the full scrollable background, including the spaces between cards.
class MountainWallpaperPainter extends CustomPainter {
  final Color color;

  const MountainWallpaperPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final sceneHeight = (size.width * 0.58).clamp(180.0, 260.0).toDouble();
    final sceneStep = sceneHeight * 1.05;
    final sceneCount = (size.height / sceneStep).ceil() + 1;

    for (var index = 0; index < sceneCount; index++) {
      final top = (index * sceneStep + sceneHeight * 0.18).toDouble();
      final peakX = size.width * (index.isEven ? 0.66 : 0.38);

      final distant = Path()
        ..moveTo(0, top + sceneHeight * 0.67)
        ..cubicTo(
          size.width * 0.22,
          top + sceneHeight * 0.62,
          size.width * 0.30,
          top + sceneHeight * 0.42,
          size.width * 0.47,
          top + sceneHeight * 0.53,
        )
        ..cubicTo(
          size.width * 0.65,
          top + sceneHeight * 0.64,
          size.width * 0.82,
          top + sceneHeight * 0.56,
          size.width,
          top + sceneHeight * 0.60,
        )
        ..lineTo(size.width, top + sceneHeight)
        ..lineTo(0, top + sceneHeight)
        ..close();
      canvas.drawPath(
        distant,
        Paint()..color = color.withValues(alpha: 0.06),
      );

      final mountain = Path()
        ..moveTo(0, top + sceneHeight * 0.88)
        ..cubicTo(
          peakX - size.width * 0.24,
          top + sceneHeight * 0.84,
          peakX - size.width * 0.13,
          top + sceneHeight * 0.48,
          peakX,
          top + sceneHeight * 0.26,
        )
        ..cubicTo(
          peakX + size.width * 0.12,
          top + sceneHeight * 0.42,
          peakX + size.width * 0.20,
          top + sceneHeight * 0.78,
          size.width,
          top + sceneHeight * 0.86,
        )
        ..lineTo(size.width, top + sceneHeight)
        ..lineTo(0, top + sceneHeight)
        ..close();
      canvas.drawPath(
        mountain,
        Paint()..color = color.withValues(alpha: 0.12),
      );

      final ridge = Path()
        ..moveTo(peakX - size.width * 0.13, top + sceneHeight * 0.48)
        ..cubicTo(
          peakX - size.width * 0.05,
          top + sceneHeight * 0.39,
          peakX - size.width * 0.04,
          top + sceneHeight * 0.30,
          peakX,
          top + sceneHeight * 0.26,
        )
        ..cubicTo(
          peakX + size.width * 0.12,
          top + sceneHeight * 0.42,
          peakX + size.width * 0.20,
          top + sceneHeight * 0.78,
          size.width,
          top + sceneHeight * 0.86,
        );
      canvas.drawPath(
        ridge,
        Paint()
          ..color = color.withValues(alpha: 0.20)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(MountainWallpaperPainter oldDelegate) =>
      oldDelegate.color != color;
}
