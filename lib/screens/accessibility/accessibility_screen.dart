import '../../services/localization_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

// ── Helper: tampilkan dialog info aksesibilitas ───────────────
void _showAccessInfo(
  BuildContext context, {
  required String title,
  required String message,
}) {
  HapticFeedback.lightImpact();
  showCupertinoDialog(
    context: context,
    builder: (ctx) => CupertinoAlertDialog(
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontWeight: FontWeight.w700,
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            height: 1.6,
          ),
        ),
      ),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text(
            'Mengerti',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

Future<void> _confirmHighContrastChange({
  required BuildContext context,
  required VolcanoProvider provider,
  required bool enable,
  required bool isHighContrast,
}) async {
  if (enable == provider.highContrast) return;

  final surfaceColor = isHighContrast ? SigumiTheme.hcSurface : Colors.white;
  final primaryText =
      isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
  final secondaryText =
      isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
  final accentColor =
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
  final borderColor =
      isHighContrast ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: surfaceColor,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: borderColor, width: isHighContrast ? 2 : 1),
      ),
      icon: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: accentColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.contrast_rounded, color: accentColor, size: 24),
      ),
      title: Text(
        enable ? 'Aktifkan kontras tinggi?' : 'Matikan kontras tinggi?',
        textAlign: TextAlign.center,
        style: AppFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: primaryText,
        ),
      ),
      content: Text(
        enable
            ? 'Tampilan akan menggunakan latar gelap, teks terang, dan aksen yang lebih tegas agar lebih mudah dibaca.'
            : 'Tampilan akan kembali ke skema warna standar SIGUMI.',
        textAlign: TextAlign.center,
        style: AppFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.5,
          color: secondaryText,
        ),
      ),
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          style: OutlinedButton.styleFrom(
            foregroundColor: primaryText,
            side: BorderSide(color: borderColor, width: isHighContrast ? 2 : 1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: accentColor,
            foregroundColor:
                isHighContrast ? SigumiTheme.hcBackground : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Text(enable ? 'Aktifkan' : 'Matikan'),
        ),
      ],
    ),
  );

  // Terapkan tema setelah route dialog selesai ditutup agar widget dialog
  // tidak ikut dibangun ulang dengan ThemeData yang baru.
  if (confirmed == true) {
    HapticFeedback.mediumImpact();
    provider.setHighContrast(enable);
  }
}

void _showTextSizeDialog({
  required BuildContext context,
  required VolcanoProvider provider,
  required double currentSize,
  required bool isHighContrast,
}) {
  final surfaceColor = isHighContrast ? SigumiTheme.hcSurface : Colors.white;
  final backgroundColor =
      isHighContrast ? SigumiTheme.hcBackground : const Color(0xFFF5F7FA);
  final primaryText =
      isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
  final secondaryText =
      isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
  final accentColor =
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
  final borderColor =
      isHighContrast ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);

  showDialog<void>(
    context: context,
    builder: (dialogContext) {
      var draftSize = currentSize;

      return StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: borderColor,
                  width: isHighContrast ? 2 : 1,
                ),
                boxShadow: isHighContrast
                    ? const []
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Sesuaikan ukuran teks',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.tr('close'),
                          onPressed: () => Navigator.pop(dialogContext),
                          icon: Icon(Icons.close_rounded, color: secondaryText),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Atur ukuran, lihat pratinjau, lalu terapkan jika sudah nyaman.',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.45,
                        color: secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Pratinjau',
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: secondaryText,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: accentColor.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '${(draftSize * 100).round()}%',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: accentColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 140),
                            style: AppFonts.plusJakartaSans(
                              fontSize: 15 * draftSize,
                              height: 1.45,
                              color: primaryText,
                            ),
                            child: Text(context.tr('dynamic_text_example')),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Text(
                          'A',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 13,
                            color: secondaryText,
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: accentColor,
                              thumbColor: accentColor,
                              inactiveTrackColor: borderColor,
                              overlayColor: accentColor.withValues(alpha: 0.12),
                              valueIndicatorColor: accentColor,
                            ),
                            child: Slider(
                              value: draftSize,
                              min: 0.8,
                              max: 1.5,
                              divisions: 14,
                              label: '${(draftSize * 100).round()}%',
                              onChanged: (value) {
                                setDialogState(() => draftSize = value);
                              },
                            ),
                          ),
                        ),
                        Text(
                          'A',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 21,
                            fontWeight: FontWeight.w700,
                            color: primaryText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: primaryText,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(context.tr('cancel')),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              provider.setFontSize(draftSize);
                              Navigator.pop(dialogContext);
                            },
                            style: FilledButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: isHighContrast
                                  ? SigumiTheme.hcBackground
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(context.tr('save')),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Halaman Aksesibilitas Eksklusif SIGUMI.
///
/// Fitur:
/// - Ukuran teks (slider 80%–150%)
/// - Kontras tinggi (hitam/putih WCAG AAA)
/// - Mode buta warna: Normal / Deuteranopia / Protanopia / Tritanopia
/// - Preview badge status MAGMA real-time sesuai mode aktif
class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final isHC = provider.highContrast;
        final cbMode = provider.colorBlindMode;

        final bgColor = isHC ? SigumiTheme.hcBackground : const Color(0xFFF5F7FA);
        final surfaceColor = isHC ? SigumiTheme.hcSurface : Colors.white;
        final primaryText = isHC ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
        final secondaryText = isHC ? SigumiTheme.hcPrimary : const Color(0xFF4B4B5A);
        final tertiaryText = isHC ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
        final borderColor = isHC ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);
        final accentColor = isHC ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
        final borderW = isHC ? 2.0 : 1.0;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: primaryText),
            title: Text(
              context.tr('accessibility'),
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: primaryText,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: Size.fromHeight(borderW),
              child: Container(color: borderColor, height: borderW),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Banner inklusif ──────────────────────────────────────
                _InclusiveBanner(
                  isHC: isHC,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  accentColor: accentColor,
                  borderW: borderW,
                  secondaryText: secondaryText,
                ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.08, end: 0),

                const SizedBox(height: 28),

                // ═══════════════════════════════════════════════
                // BAGIAN 1: TAMPILAN VISUAL
                // ═══════════════════════════════════════════════
                _SectionHeader(
                  title: context.tr('visual_display'),
                  icon: Icons.visibility_outlined,
                  color: tertiaryText,
                ),
                const SizedBox(height: 14),

                // -- Ukuran Teks --
                _AccessCard(
                  isHC: isHC,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  borderW: borderW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.format_size_rounded,
                              color: accentColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.tr('text_size'),
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: primaryText,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Saat ini ${(provider.fontSize * 100).round()}%',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () => _showTextSizeDialog(
                              context: context,
                              provider: provider,
                              currentSize: provider.fontSize,
                              isHighContrast: isHC,
                            ),
                            icon: const Icon(Icons.tune_rounded, size: 16),
                            label: const Text('Ubah'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: accentColor,
                              side: BorderSide(color: borderColor),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isHC ? SigumiTheme.hcBackground : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: borderColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PRATINJAU TEKS',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: tertiaryText,
                              ),
                            ),
                            const SizedBox(height: 6),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 160),
                              style: AppFonts.plusJakartaSans(
                                fontSize: 14 * provider.fontSize,
                                height: 1.4,
                                color: secondaryText,
                              ),
                              child: Text(context.tr('dynamic_text_example')),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 10),

                // -- Kontras Tinggi --
                _AccessCard(
                  isHC: isHC,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  borderW: borderW,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.contrast_rounded, color: accentColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr('contrast'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showAccessInfo(
                                      context,
                                      title: 'Kontras Tinggi',
                                      message:
                                          'Mengubah warna antarmuka ke skema hitam/putih dengan kontras WCAG AAA '
                                          'agar teks dan elemen lebih mudah dibaca oleh pengguna dengan gangguan penglihatan.',
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        CupertinoIcons.info_circle,
                                        size: 16,
                                        color: tertiaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              isHC
                                  ? 'Aktif — hitam/putih WCAG AAA'
                                  : 'Optimalkan keterbacaan warna',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: tertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: provider.highContrast,
                        onChanged: (v) {
                          _confirmHighContrastChange(
                            context: context,
                            provider: provider,
                            enable: v,
                            isHighContrast: isHC,
                          );
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 140.ms),

                const SizedBox(height: 28),

                // ═══════════════════════════════════════════════
                // BAGIAN 2: MODE BUTA WARNA
                // ═══════════════════════════════════════════════
                _SectionHeader(
                  title: context.tr('color_blind_mode'),
                  icon: Icons.palette_outlined,
                  color: tertiaryText,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    context.trText('Sesuaikan warna status MAGMA agar mudah dibaca bagi pengguna dengan gangguan penglihatan warna.'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: tertiaryText,
                      height: 1.5,
                    ),
                  ),
                ),

                _AccessCard(
                  isHC: isHC,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  borderW: borderW,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Dropdown selector ──
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(Icons.palette_outlined, color: accentColor, size: 20),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 1,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mode Warna',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                ),
                                Text(
                                  _colorBlindOptions
                                      .firstWhere((o) => o.value == cbMode,
                                          orElse: () => _colorBlindOptions.first)
                                      .description,
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: tertiaryText,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: Container(
                              decoration: BoxDecoration(
                                color: surfaceColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isHC
                                      ? SigumiTheme.hcBorder
                                      : borderColor,
                                  width: isHC ? 2 : 1,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: cbMode,
                                  isExpanded: true,
                                  dropdownColor: surfaceColor,
                                  borderRadius: BorderRadius.circular(12),
                                  menuWidth: (MediaQuery.sizeOf(context).width - 32)
                                      .clamp(180.0, 240.0)
                                      .toDouble(),
                                  itemHeight: (MediaQuery.textScalerOf(context)
                                              .scale(14) *
                                          2.6 +
                                      12)
                                      .clamp(48.0, 120.0)
                                      .toDouble(),
                                  menuMaxHeight: 280,
                                  icon: Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: primaryText,
                                    size: 22,
                                  ),
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: primaryText,
                                  ),
                                  selectedItemBuilder: (context) {
                                    return _colorBlindOptions.map((opt) {
                                      return Align(
                                        alignment:
                                            AlignmentDirectional.centerStart,
                                        child: Text(
                                          context.trText(opt.label),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: AppFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: primaryText,
                                          ),
                                        ),
                                      );
                                    }).toList();
                                  },
                                  items: _colorBlindOptions.map((opt) {
                                    final isSelected = opt.value == cbMode;
                                    return DropdownMenuItem<String>(
                                      value: opt.value,
                                      child: Row(
                                        children: [
                                          Icon(
                                            opt.icon,
                                            size: 18,
                                            color: accentColor,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              context.trText(opt.label),
                                              maxLines: 2,
                                              softWrap: true,
                                              overflow: TextOverflow.ellipsis,
                                              style: AppFonts.plusJakartaSans(
                                                fontSize: 14,
                                                color: primaryText,
                                              ),
                                            ),
                                          ),
                                          if (isSelected) ...[
                                            const SizedBox(width: 8),
                                            Icon(
                                              Icons.check_rounded,
                                              size: 18,
                                              color: isHC
                                                  ? SigumiTheme.hcSecondary
                                                  : accentColor,
                                            ),
                                          ],
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      HapticFeedback.selectionClick();
                                      provider.setColorBlindMode(value);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // ── Preview badge status MAGMA ──
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isHC
                              ? Colors.white.withValues(alpha: 0.06)
                              : const Color(0xFFF5F7FA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: borderColor, width: borderW),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.trText('Preview Status MAGMA'),
                              style: AppFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: tertiaryText,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [1, 2, 3, 4].map((level) {
                                final color = SigumiTheme.getStatusColor(
                                  level,
                                  highContrast: isHC,
                                  colorBlindMode: cbMode,
                                );
                                final shape = SigumiTheme.getStatusShape(level);
                                final labels = ['Normal', 'Waspada', 'Siaga', 'Awas'];
                                return _StatusPreviewBadge(
                                  level: level,
                                  color: color,
                                  shape: shape,
                                  label: labels[level - 1],
                                  isHC: isHC,
                                  primaryText: primaryText,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),




                const SizedBox(height: 28),

                // ═══════════════════════════════════════════════
                // BAGIAN 3: PANDUAN AUDIO
                // ═══════════════════════════════════════════════
                _SectionHeader(
                  title: context.tr('audio_guide'),
                  icon: Icons.mic_rounded,
                  color: tertiaryText,
                ),
                const SizedBox(height: 14),

                _AccessCard(
                  isHC: isHC,
                  surfaceColor: surfaceColor,
                  borderColor: borderColor,
                  borderW: borderW,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5856D6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          CupertinoIcons.mic_fill,
                          color: Color(0xFF5856D6),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    context.tr('audio_guidance'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: primaryText,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: () => _showAccessInfo(
                                      context,
                                      title: 'Panduan Audio',
                                      message:
                                          'Aktifkan panduan suara interaktif dengan mengucapkan "Halo Sigumi". '
                                          'Fitur ini membantu pengguna tunanetra atau low-vision menavigasi '
                                          'aplikasi dan menerima peringatan bencana secara verbal.',
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(4),
                                      child: Icon(
                                        CupertinoIcons.info_circle,
                                        size: 16,
                                        color: tertiaryText,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              provider.audioGuidance
                                  ? 'Aktif — Ucapkan "Halo Sigumi"'
                                  : 'Nonaktif',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: tertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoSwitch(
                        value: provider.audioGuidance,
                        activeTrackColor: accentColor,
                        onChanged: (val) {
                          HapticFeedback.lightImpact();
                          provider.setAudioGuidance(val);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 260.ms),

                const SizedBox(height: 40),

                // Footer
                Center(
                  child: Text(
                    context.trText('SIGUMI · Aksesibilitas Inklusif'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tertiaryText,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────
// DATA MODEL: Pilihan mode buta warna
// ─────────────────────────────────────────────────────────────

class _ColorBlindOption {
  final String value;
  final String label;
  final String description;
  final IconData icon;
  const _ColorBlindOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
  });
}

const List<_ColorBlindOption> _colorBlindOptions = [
  _ColorBlindOption(
    value: 'normal',
    label: 'Normal',
    description: 'Warna MAGMA standar',
    icon: Icons.visibility_outlined,
  ),
  _ColorBlindOption(
    value: 'deuteranopia',
    label: 'Deuteranopia',
    description: 'Buta warna merah-hijau (paling umum)',
    icon: Icons.remove_red_eye_outlined,
  ),
  _ColorBlindOption(
    value: 'protanopia',
    label: 'Protanopia',
    description: 'Buta warna merah (tidak bisa lihat merah)',
    icon: Icons.blur_circular_outlined,
  ),
  _ColorBlindOption(
    value: 'tritanopia',
    label: 'Tritanopia',
    description: 'Buta warna biru-kuning',
    icon: Icons.invert_colors_outlined,
  ),
];

// ─────────────────────────────────────────────────────────────
// WIDGET: Section header
// ─────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 7),
        Text(
          title.toUpperCase(),
          style: AppFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Kartu aksesibilitas (container wrapper)
// ─────────────────────────────────────────────────────────────

class _AccessCard extends StatelessWidget {
  final Widget child;
  final bool isHC;
  final Color surfaceColor;
  final Color borderColor;
  final double borderW;

  const _AccessCard({
    required this.child,
    required this.isHC,
    required this.surfaceColor,
    required this.borderColor,
    required this.borderW,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: borderW),
        boxShadow: isHC
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Banner inklusif di atas halaman
// ─────────────────────────────────────────────────────────────

class _InclusiveBanner extends StatelessWidget {
  final bool isHC;
  final Color surfaceColor;
  final Color borderColor;
  final Color accentColor;
  final double borderW;
  final Color secondaryText;

  const _InclusiveBanner({
    required this.isHC,
    required this.surfaceColor,
    required this.borderColor,
    required this.accentColor,
    required this.borderW,
    required this.secondaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isHC
            ? SigumiTheme.hcSurface
            : SigumiTheme.primaryBlue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isHC
              ? SigumiTheme.hcBorder
              : SigumiTheme.primaryBlue.withValues(alpha: 0.1),
          width: borderW,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isHC
                  ? SigumiTheme.hcSecondary
                  : SigumiTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.accessibility_new_rounded,
              color: isHC ? SigumiTheme.hcBackground : SigumiTheme.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              context.trText('SIGUMI dirancang inklusif untuk semua pengguna — termasuk tunanetra, buta warna, dan gangguan penglihatan lainnya.'),
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                fontWeight: FontWeight.w500,
                color: secondaryText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// WIDGET: Preview badge satu level status MAGMA
// ─────────────────────────────────────────────────────────────

class _StatusPreviewBadge extends StatelessWidget {
  final int level;
  final Color color;
  final IconData shape;
  final String label;
  final bool isHC;
  final Color primaryText;

  const _StatusPreviewBadge({
    required this.level,
    required this.color,
    required this.shape,
    required this.label,
    required this.isHC,
    required this.primaryText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lingkaran warna + ikon bentuk (dual cue)
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: isHC
                ? Border.all(color: SigumiTheme.hcBorder, width: 2)
                : null,
          ),
          child: Icon(
            shape,
            color: Colors.white,
            size: 22,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: primaryText,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
