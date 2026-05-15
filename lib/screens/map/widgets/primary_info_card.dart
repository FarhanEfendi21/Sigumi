import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:sigumi/config/theme_extensions.dart';
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.borderColor, 
          width: context.borderWidth
        ),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Status Zona ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ikon Status
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _statusColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  distance <= 10.0 ? Icons.warning_amber_rounded : Icons.gpp_good_rounded,
                  color: _statusColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              // Teks Status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _statusText,
                      key: ValueKey<String>(_statusText),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: _statusColor,
                        letterSpacing: -0.5,
                      ),
                    ).animate().fade().slideX(begin: -0.05),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: context.bgSecondary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level $zoneLevel',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          Container(
            height: context.borderWidth,
            color: context.dividerColor,
          ),
          const SizedBox(height: 16),
          
          // ── Body: Jarak & Deskripsi (Subtle) ──
          
          // Jarak
          Row(
            children: [
              Icon(
                Icons.location_on_outlined, 
                size: 18, 
                color: context.textTertiary
              ),
              const SizedBox(width: 10),
              Text(
                'Jarak ke gunung:',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: context.textTertiary,
                ),
              ),
              const Spacer(),
              Text(
                '${distance.toStringAsFixed(1)} km',
                key: ValueKey<String>(distance.toStringAsFixed(1)),
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: context.textSecondary,
                ),
              ).animate().fade(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Deskripsi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded, 
                size: 18, 
                color: context.textTertiary
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _descriptionText,
                  key: ValueKey<String>(_descriptionText),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    color: context.textTertiary,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ).animate().fade().slideY(begin: 0.1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

