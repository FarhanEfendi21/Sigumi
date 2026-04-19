import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

// Semantic Colors for Status
class StatusColor {
  static const safe = Color(0xFF22C55E);   // Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const danger = Color(0xFFEF4444);  // Red
}

class PrimaryInfoCard extends StatelessWidget {
  final double distance;
  final int zoneLevel;

  const PrimaryInfoCard({
    super.key,
    required this.distance,
    required this.zoneLevel,
  });

  String get _statusText {
    if (distance <= 5.0) return 'Zona Bahaya';
    if (distance <= 10.0) return 'Zona Waspada';
    if (distance <= 15.0) return 'Zona Perhatian';
    return 'Zona Aman';
  }

  Color get _statusColor {
    if (distance <= 5.0) return StatusColor.danger;
    if (distance <= 15.0) return StatusColor.warning;
    return StatusColor.safe;
  }
  
  String get _descriptionText {
    if (distance <= 5.0) return 'Bahaya! Segera cari titik evakuasi yang aman.';
    if (distance <= 10.0) return 'Peringatan siaga! Zona rawan terdampak.';
    if (distance <= 15.0) return 'Berpotensi terkena dampak sekunder, tetap waspada.';
    return 'Kamu berada di zona aman, tetap pantau kondisi.';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _statusColor.withAlpha(40), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withAlpha(25), // 0.10 opacity shadow soft
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
             color: Colors.black.withAlpha(10), // secondary shadow context
             blurRadius: 8,
             offset: const Offset(0, 2),
             spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Jarak Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_on_rounded, size: 14, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        key: ValueKey<String>(distance.toStringAsFixed(1)), // animates when distance changes
                        style: AppFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ).animate().fade().scale(),
                    ],
                  ),
                ),
                const Spacer(),
                // Level Info
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level $zoneLevel',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: _statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Status Teks Besar
            Text(
              _statusText,
              key: ValueKey<String>(_statusText),
              style: AppFonts.plusJakartaSans(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: _statusColor,
              ),
            ).animate().slideX(begin: -0.1).fade(),
            const SizedBox(height: 6),
            // Logic Description
            Text(
              _descriptionText,
              key: ValueKey<String>(_descriptionText),
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ).animate().slideX(begin: -0.1).fade(),
          ],
        ),
      ),
    );
  }
}

