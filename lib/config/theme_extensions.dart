import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/volcano_provider.dart';
import 'theme.dart';

/// Extension untuk akses theme colors yang adaptive terhadap high contrast
/// dan mode simulasi buta warna (colorBlindMode).
extension ThemeContextExtension on BuildContext {
  bool get isHighContrast => watch<VolcanoProvider>().highContrast;

  /// Token desain semantik aktif (dari ThemeData.extensions dengan fallback aman).
  SigumiTokens get tokens =>
      Theme.of(this).extension<SigumiTokens>() ??
      (isHighContrast ? SigumiTokens.highContrast : SigumiTokens.light);

  /// Menghormati preferensi reduced-motion atau navigasi aksesibilitas sistem.
  bool get reduceMotion {
    final mq = MediaQuery.maybeOf(this);
    if (mq == null) return false;
    return mq.disableAnimations || mq.accessibleNavigation;
  }

  /// Gutter horizontal responsif berbasis skala spasi (4/8dp grid).
  double get pageGutter {
    final width = MediaQuery.sizeOf(this).width;
    final t = tokens;
    if (width < 380) return t.spaceLg; // 16dp di layar sangat kecil
    if (width >= 600) return t.space2xl; // 32dp di tablet/wide
    return t.spaceXl; // 24dp standar Swiss mobile
  }

  /// Resolve hard-coded brand colors without losing the current palette.
  Color contrastColor(Color standard, {Color? highContrast}) =>
      isHighContrast ? (highContrast ?? SigumiTheme.hcPrimary) : standard;

  // Background colors
  Color get bgPrimary =>
      isHighContrast ? SigumiTheme.hcBackground : SigumiTheme.white;
  Color get bgSecondary =>
      isHighContrast ? SigumiTheme.hcSurface : SigumiTheme.background;
  Color get bgSurface =>
      isHighContrast ? SigumiTheme.hcSurface : SigumiTheme.surface;

  // Text colors
  Color get textPrimary =>
      isHighContrast ? SigumiTheme.hcPrimary : SigumiTheme.inkPrimary;
  Color get textSecondary =>
      isHighContrast ? SigumiTheme.hcPrimary : SigumiTheme.inkSecondary;
  Color get textTertiary =>
      isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
  Color get textLabel =>
      isHighContrast ? SigumiTheme.hcDivider : SigumiTheme.textSecondary;

  // Accent colors
  Color get accentPrimary =>
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
  Color get accentSecondary =>
      isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.accentYellow;
  Color get onAccentPrimary =>
      isHighContrast ? SigumiTheme.hcBackground : SigumiTheme.white;

  // Border & divider
  Color get borderColor =>
      isHighContrast ? SigumiTheme.hcBorder : SigumiTheme.borderSubtle;
  Color get controlBorderColor =>
      isHighContrast ? SigumiTheme.hcBorder : SigumiTheme.borderControl;
  Color get dividerColor =>
      isHighContrast ? SigumiTheme.hcDivider : SigumiTheme.divider;
  double get borderWidth => tokens.hairlineWidth;

  // Button Styles (Minimalism & Swiss Style — terhubung ke semantic tokens)
  ButtonStyle get swissPrimaryButtonStyle {
    final t = tokens;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledFill;
        if (states.contains(WidgetState.pressed)) {
          return isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryDark;
        }
        return t.accentPrimary;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledInk;
        return t.onAccent;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return t.onAccent.withValues(alpha: 0.14);
        if (states.contains(WidgetState.hovered)) return t.onAccent.withValues(alpha: 0.08);
        if (states.contains(WidgetState.focused)) return t.onAccent.withValues(alpha: 0.12);
        return null;
      }),
      elevation: const WidgetStatePropertyAll(0),
      shadowColor: const WidgetStatePropertyAll(Colors.transparent),
      minimumSize: WidgetStatePropertyAll(Size(t.minTouchTarget, t.minTouchTarget)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: t.spaceXl, vertical: t.spaceMd),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusPill),
        ),
      ),
      textStyle: WidgetStatePropertyAll(t.buttonLabel),
    );
  }

  ButtonStyle get swissSecondaryButtonStyle {
    final t = tokens;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledFill;
        if (states.contains(WidgetState.pressed)) return t.pressedFill;
        if (states.contains(WidgetState.hovered)) return t.hoverFill;
        return t.subtleSurface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledInk;
        return t.inkPrimary;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: t.focusRing, width: t.focusRingWidth);
        }
        return isHighContrast
            ? BorderSide(color: t.borderControl, width: t.hairlineWidth)
            : BorderSide.none;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return t.pressedFill;
        if (states.contains(WidgetState.hovered)) return t.hoverFill;
        if (states.contains(WidgetState.focused)) return t.hoverFill;
        return null;
      }),
      elevation: const WidgetStatePropertyAll(0),
      minimumSize: WidgetStatePropertyAll(Size(t.minTouchTarget, t.minTouchTarget)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: t.spaceMd, vertical: t.spaceMd),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusPill),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        t.buttonLabel.copyWith(color: t.inkPrimary),
      ),
    );
  }

  ButtonStyle get swissTextButtonStyle {
    final t = tokens;
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledFill;
        if (states.contains(WidgetState.pressed)) return t.pressedFill;
        if (states.contains(WidgetState.hovered)) return t.hoverFill;
        return t.subtleSurface;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) return t.disabledInk;
        return isHighContrast ? t.accentPrimary : t.inkSecondary;
      }),
      overlayColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.pressed)) return t.pressedFill;
        if (states.contains(WidgetState.hovered)) return t.hoverFill;
        if (states.contains(WidgetState.focused)) return t.hoverFill;
        return null;
      }),
      side: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.focused)) {
          return BorderSide(color: t.focusRing, width: t.focusRingWidth);
        }
        return isHighContrast
            ? BorderSide(color: t.borderControl, width: t.hairlineWidth)
            : BorderSide.none;
      }),
      minimumSize: WidgetStatePropertyAll(Size(t.minTouchTarget, t.minTouchTarget)),
      padding: WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: t.spaceLg, vertical: t.spaceSm),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(t.radiusPill),
        ),
      ),
      textStyle: WidgetStatePropertyAll(
        t.buttonLabel.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
          color: isHighContrast ? t.accentPrimary : t.inkSecondary,
        ),
      ),
    );
  }

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
