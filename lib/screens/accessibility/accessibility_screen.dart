import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

/// Halaman Aksesibilitas Eksklusif SIGUMI.
///
/// Fitur:
/// - Ukuran teks (slider 80%–150%)
/// - Kontras tinggi (hitam/putih WCAG AAA)
/// - Mode buta warna: Normal / Deuteranopia / Protanopia / Tritanopia
/// - Panduan audio
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
              'Aksesibilitas Inklusif',
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
                  title: 'Tampilan Visual',
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ukuran Teks',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primaryText,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${(provider.fontSize * 100).toInt()}%',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: accentColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Text(
                            'A',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: tertiaryText,
                            ),
                          ),
                          Expanded(
                            child: ShadSlider(
                              initialValue: provider.fontSize,
                              min: 0.8,
                              max: 1.5,
                              onChanged: (v) => provider.setFontSize(v),
                            ),
                          ),
                          Text(
                            'A',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14 * provider.fontSize,
                            color: secondaryText,
                          ),
                          child: const Text('Contoh Teks Dinamis SIGUMI'),
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
                            Text(
                              'Kontras Tinggi',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
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
                      ShadSwitch(
                        value: provider.highContrast,
                        onChanged: (v) {
                          HapticFeedback.mediumImpact();
                          provider.setHighContrast(v);
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
                  title: 'Mode Buta Warna',
                  icon: Icons.palette_outlined,
                  color: tertiaryText,
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Sesuaikan warna status MAGMA agar mudah dibaca '
                    'bagi pengguna dengan gangguan penglihatan warna.',
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
                          ShadSelect<String>(
                            placeholder: const Text('Pilih Mode'),
                            initialValue: cbMode,
                            onChanged: (v) {
                              if (v != null) {
                                HapticFeedback.selectionClick();
                                provider.setColorBlindMode(v);
                              }
                            },
                            selectedOptionBuilder: (context, value) {
                              final opt = _colorBlindOptions.firstWhere(
                                (o) => o.value == value,
                                orElse: () => _colorBlindOptions.first,
                              );
                              return Text(
                                opt.label,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              );
                            },
                            options: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
                                child: Text(
                                  'Mode Buta Warna',
                                  style: AppFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B6B78),
                                  ),
                                ),
                              ),
                              ..._colorBlindOptions.map(
                                (opt) => ShadOption(
                                  value: opt.value,
                                  child: Row(
                                    children: [
                                      Icon(opt.icon, size: 16, color: accentColor),
                                      const SizedBox(width: 8),
                                      Text(opt.label, style: AppFonts.plusJakartaSans()),
                                    ],
                                  ),
                                ),
                              ),
                            ],
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
                              'Preview Status MAGMA',
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
                // BAGIAN 3: BANTUAN SUARA
                // ═══════════════════════════════════════════════
                _SectionHeader(
                  title: 'Bantuan Suara',
                  icon: Icons.volume_up_outlined,
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
                          color: accentColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.record_voice_over_rounded,
                          color: accentColor,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panduan Audio',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryText,
                              ),
                            ),
                            Text(
                              'Narasi otomatis teks penting',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: tertiaryText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ShadSwitch(
                        value: provider.audioGuidance,
                        onChanged: (v) {
                          HapticFeedback.mediumImpact();
                          provider.setAudioGuidance(v);
                        },
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 280.ms),


                const SizedBox(height: 40),

                // Footer
                Center(
                  child: Text(
                    'SIGUMI · Aksesibilitas Inklusif',
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
              'SIGUMI dirancang inklusif untuk semua pengguna — '
              'termasuk tunanetra, buta warna, dan gangguan penglihatan lainnya.',
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
