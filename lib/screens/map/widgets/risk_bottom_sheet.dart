import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:sigumi/config/theme.dart';
import '../../../config/routes.dart';

// Semantic Colors for Status
class StatusColor {
  static const safe = Color(0xFF22C55E);   // Green
  static const warning = Color(0xFFF59E0B); // Amber
  static const danger = Color(0xFFEF4444);  // Red
}

class RiskBottomSheet extends StatelessWidget {
  final double distance;
  final String zoneLabel;

  const RiskBottomSheet({
    super.key,
    required this.distance,
    required this.zoneLabel,
  });

  Color get _statusColor {
    if (distance <= 5.0) return StatusColor.danger;
    if (distance <= 15.0) return StatusColor.warning;
    return StatusColor.safe;
  }

  // Radius Progress: Asumsikan max safety reference 20km.
  double get _progress {
    // 0.0 paling bahaya, 1.0 paling aman.
    return (distance / 20.0).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.18, // Hanya menampilkan summary radius progress
      minChildSize: 0.18,
      maxChildSize: 0.50, // Detail expanded
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(20),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const ClampingScrollPhysics(), // Hindari overscroll bounce saat drag sheet
            child: Padding(
              // Tambahkan padding bawah ekstra agar saat ditarik ke atas, 
              // tombol paling bawah tidak menumpuk/tertutup oleh Bottom Navigation Bar
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Drag Handle ──
                  Center(
                    child: Container(
                      width: 48,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  // ── Summary Title ──
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Jarak Keselamatan',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Text(
                        zoneLabel,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // ── Progress Bar Radius ──
                  Stack(
                    children: [
                      Container(
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _progress,
                        child: Container(
                          height: 12,
                          decoration: BoxDecoration(
                            color: _statusColor,
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(
                                color: _statusColor.withAlpha(80),
                                blurRadius: 6,
                              )
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  
                  // Progress markers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _kmLabel('0 km (Pusat)'),
                      _kmLabel('10 km'),
                      _kmLabel('20+ km (Aman)'),
                    ],
                  ),
                  
                  // Spacing antara summary dan CTA (baru terlihat saat expand)
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),
                  
                  // ── CTA Buttons ──
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.evacuation),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: SigumiTheme.primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Lihat Rute Evakuasi',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pushNamed(context, AppRoutes.postDisaster),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        'Posko & Faskes Terdekat',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _kmLabel(String text) {
    return Text(
      text,
      style: AppFonts.plusJakartaSans(
        fontSize: 11,
        color: Colors.grey.shade500,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

