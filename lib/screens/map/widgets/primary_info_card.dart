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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15), // subtle shadow
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
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
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Level $zoneLevel',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          
          // ── Body: Jarak & Deskripsi (Subtle) ──
          
          // Jarak
          Row(
            children: [
              Icon(Icons.location_on_outlined, size: 18, color: Colors.grey.shade400),
              const SizedBox(width: 10),
              Text(
                'Jarak ke gunung:',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade500,
                ),
              ),
              const Spacer(),
              Text(
                '${distance.toStringAsFixed(1)} km',
                key: ValueKey<String>(distance.toStringAsFixed(1)),
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ).animate().fade(),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Deskripsi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Colors.grey.shade400),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _descriptionText,
                  key: ValueKey<String>(_descriptionText),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.grey.shade600,
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

