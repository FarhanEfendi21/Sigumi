import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../config/fonts.dart';
import '../../../config/theme_extensions.dart';
import '../../../services/vibration_alert_service.dart';

/// Modal peringatan getar darurat yang muncul saat pengguna berada
/// dalam radius 5 km dari puncak gunung berapi.
///
/// Mengikuti Apple Human Interface Guidelines (HIG):
/// - Tipografi terstruktur (Title 2, Subhead, Inset values)
/// - Inset grouped detail card dengan visual hierarchy bersih
/// - Aksen warna merah Apple HIG (System Red) yang tegas & elegan
/// - Pulsing icon halo yang subtle & modern
/// - Tombol aksi rounded dengan haptic feedback
class VibrationAlertModal extends StatefulWidget {
  final String volcanoName;
  final double distanceKm;

  const VibrationAlertModal({
    super.key,
    required this.volcanoName,
    required this.distanceKm,
  });

  @override
  State<VibrationAlertModal> createState() => _VibrationAlertModalState();
}

class _VibrationAlertModalState extends State<VibrationAlertModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Warna aksen Apple HIG System Red
  static const Color _appleRed = Color(0xFFFF3B30);

  @override
  void initState() {
    super.initState();

    // Pulse animation halus untuk halo ikon peringatan
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _dismiss() {
    HapticFeedback.mediumImpact();
    VibrationAlertService().stopAlert();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Non-dismissible: wajib tekan tombol matikan
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: _buildModalCard(context),
        ),
      ),
    );
  }

  Widget _buildModalCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 36,
            offset: const Offset(0, 16),
            spreadRadius: -4,
          ),
          BoxShadow(
            color: _appleRed.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── 1. Ikon Peringatan dengan Halo Pulse (Apple HIG Style) ──
              _buildPulsingIcon(),

              const SizedBox(height: 18),

              // ── 2. Tag Kategori / Zona ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _appleRed.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, _) {
                        return Opacity(
                          opacity: 0.4 + (_pulseAnimation.value * 0.6),
                          child: Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: _appleRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ZONA BAHAYA ERUPSI',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: _appleRed,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 10),

              // ── 3. Judul & Subtitle ──
              Text(
                'Radius Bahaya Puncak',
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.textPrimary,
                  letterSpacing: -0.4,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Perangkat bergetar karena Anda terdeteksi berada dalam jarak kritis dari kawah aktif.',
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: context.textSecondary,
                  height: 1.45,
                ),
              ),

              const SizedBox(height: 18),

              // ── 4. Inset Grouped Info Card (Apple HIG Inset Cell) ──
              _buildDetailCard(context),

              const SizedBox(height: 20),

              // ── 5. Tombol Matikan Alarm (Apple HIG Primary Destructive Action) ──
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _appleRed.withValues(alpha: 0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: _dismiss,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _appleRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    icon: const Icon(
                      CupertinoIcons.bell_slash_fill,
                      size: 20,
                      color: Colors.white,
                    ),
                    label: Text(
                      'Matikan Alarm Getar',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.1,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── 6. Petunjuk Penutup (UX Text Baru) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.info_circle_fill,
                    size: 13,
                    color: context.textTertiary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Harap selalu berhati-hati dan utamakan keselamatan Anda.',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: context.textTertiary,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).animate().scale(
          begin: const Offset(0.92, 0.92),
          end: const Offset(1.0, 1.0),
          duration: 260.ms,
          curve: Curves.easeOutCubic,
        ).fadeIn(duration: 200.ms);
  }

  /// Ikon animasi pulse dengan visual hierarchy bersih
  Widget _buildPulsingIcon() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) {
        final pulse = _pulseAnimation.value;
        return Stack(
          alignment: Alignment.center,
          children: [
            // Outermost pulsing halo
            Container(
              width: 84 + (pulse * 18),
              height: 84 + (pulse * 18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appleRed.withValues(alpha: 0.04 * (1.0 - (pulse * 0.5))),
              ),
            ),
            // Outer halo
            Container(
              width: 72 + (pulse * 12),
              height: 72 + (pulse * 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appleRed.withValues(alpha: 0.08 * (1.0 - pulse)),
              ),
            ),
            // Inner halo
            Container(
              width: 60 + (pulse * 6),
              height: 60 + (pulse * 6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _appleRed.withValues(alpha: 0.12 * (1.0 - (pulse * 0.8))),
              ),
            ),
            // Inner icon container
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: _appleRed.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _appleRed.withValues(alpha: 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _appleRed.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_triangle_fill,
                color: _appleRed,
                size: 30,
              ),
            ),
          ],
        );
      },
    );
  }

  /// Inset detail card bergaya Apple HIG
  Widget _buildDetailCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.bgSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        children: [
          // Baris 1: Nama Gunung
          _buildInfoRow(
            context,
            icon: Icons.landscape_rounded,
            iconColor: const Color(0xFFE65100),
            label: 'Gunung',
            value: widget.volcanoName,
            isBold: true,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: context.borderWidth,
              color: context.dividerColor,
            ),
          ),

          // Baris 2: Jarak Realtime
          _buildInfoRow(
            context,
            icon: CupertinoIcons.location_north_fill,
            iconColor: _appleRed,
            label: 'Jarak Terdeteksi',
            valueWidget: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _appleRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${widget.distanceKm.toStringAsFixed(1)} km',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _appleRed,
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(
              height: 1,
              thickness: context.borderWidth,
              color: context.dividerColor,
            ),
          ),

          // Baris 3: Zona Bahaya
          _buildInfoRow(
            context,
            icon: CupertinoIcons.shield_lefthalf_fill,
            iconColor: const Color(0xFFFF9500),
            label: 'Tingkat Bahaya',
            value: 'KRB III (Kritis)',
            valueColor: _appleRed,
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    String? value,
    Widget? valueWidget,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 15, color: iconColor),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.textSecondary,
          ),
        ),
        const Spacer(),
        if (valueWidget != null)
          valueWidget
        else if (value != null)
          Text(
            value,
            style: AppFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              color: valueColor ?? context.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
      ],
    );
  }
}

/// Helper untuk menampilkan VibrationAlertModal dari mana saja
/// menggunakan `GlobalKey<NavigatorState>`.
void showVibrationAlertModal({
  required BuildContext context,
  required String volcanoName,
  required double distanceKm,
}) {
  // Pastikan tidak ada dialog ganda
  if (ModalRoute.of(context) is DialogRoute) return;

  showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => VibrationAlertModal(
      volcanoName: volcanoName,
      distanceKm: distanceKm,
    ),
  );
}
