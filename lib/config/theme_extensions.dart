import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/volcano_provider.dart';
import 'theme.dart';

/// Extension untuk akses theme colors yang adaptive terhadap high contrast
/// dan mode simulasi buta warna (colorBlindMode).
extension ThemeContextExtension on BuildContext {
  bool get isHighContrast => watch<VolcanoProvider>().highContrast;

  /// Resolve hard-coded brand colors without losing the current palette.
  Color contrastColor(Color standard, {Color? highContrast}) =>
      isHighContrast ? (highContrast ?? SigumiTheme.hcPrimary) : standard;

  // Background colors
  Color get bgPrimary =>
      isHighContrast ? SigumiTheme.hcBackground : Colors.white;
  Color get bgSecondary =>
      isHighContrast ? SigumiTheme.hcSurface : SigumiTheme.background;
  Color get bgSurface =>
      isHighContrast ? SigumiTheme.hcSurface : SigumiTheme.surface;

  // Text colors
  Color get textPrimary =>
      isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
  Color get textSecondary =>
      isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF4B4B5A);
  Color get textTertiary =>
      isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
  Color get textLabel =>
      isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF8E8E93);

  // Accent colors
  Color get accentPrimary =>
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
  Color get accentSecondary =>
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.accentYellow;

  // Border & divider
  Color get borderColor =>
      isHighContrast ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);
  Color get dividerColor =>
      isHighContrast ? SigumiTheme.hcDivider : SigumiTheme.divider;
  double get borderWidth => isHighContrast ? 2.0 : 1.0;

  // ── Aksesibilitas buta warna ──
  /// Mode aktif: 'normal' | 'deuteranopia' | 'protanopia' | 'tritanopia'
  String get colorBlindMode => watch<VolcanoProvider>().colorBlindMode;

  /// Ganti warna hijau pada elemen UI dengan biru yang lebih mudah dibedakan
  /// pada Deuteranopia. Pemanggil memilih elemen UI secara eksplisit agar
  /// foto, ilustrasi, dan media tidak ikut berubah.
  Color adaptUiColor(Color color) {
    // Baca tanpa listen: perubahan preferensi sudah membangun ulang app lewat
    // Consumer provider di SigumiApp. Ini menghindari dependensi Provider
    // tambahan pada setiap widget kecil yang hanya perlu memetakan satu warna.
    final provider = Provider.of<VolcanoProvider>(this, listen: false);
    if (provider.colorBlindMode != 'deuteranopia') return color;

    final hsl = HSLColor.fromColor(color);
    if (hsl.hue < 70 || hsl.hue > 165 || hsl.saturation < 0.12) return color;

    if (provider.highContrast) {
      return SigumiTheme.cbdHighContrastNormal.withValues(alpha: color.a);
    }

    final saturation = hsl.saturation < 0.45 ? 0.45 : hsl.saturation;
    return HSLColor.fromAHSL(
      color.a,
      210,
      saturation,
      hsl.lightness,
    ).toColor();
  }

  /// Warna status MAGMA — mempertimbangkan highContrast DAN colorBlindMode.
  Color statusColor(int level) => adaptUiColor(SigumiTheme.getStatusColor(
        level,
        highContrast: isHighContrast,
        colorBlindMode: colorBlindMode,
      ));

  /// Ikon bentuk status — non-warna, untuk tunanetra buta warna.
  /// Selalu gunakan bersama statusColor() sebagai akses ganda.
  IconData statusShape(int level) => SigumiTheme.getStatusShape(level);

  // Semantic colors
  Color get successColor =>
      adaptUiColor(isHighContrast ? SigumiTheme.hcStatusNormal : Colors.green.shade600);
  Color get warningColor =>
      isHighContrast ? SigumiTheme.hcStatusWaspada : Colors.orange.shade600;
  Color get errorColor =>
      isHighContrast ? SigumiTheme.hcStatusAwas : Colors.red.shade600;
  Color get infoColor =>
      isHighContrast ? const Color(0xFF00BFFF) : Colors.blue.shade600;

  // Shadows (disabled in high contrast — tidak dibutuhkan di mode HC)
  List<BoxShadow> get cardShadow => isHighContrast
      ? []
      : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ];

  // Overlay colors
  Color overlayLight(double opacity) => isHighContrast
      ? SigumiTheme.hcPrimary.withValues(alpha: opacity)
      : Colors.white.withValues(alpha: opacity);

  Color overlayDark(double opacity) => isHighContrast
      ? SigumiTheme.hcBackground.withValues(alpha: opacity)
      : Colors.black.withValues(alpha: opacity);
}
