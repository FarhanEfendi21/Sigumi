import 'dart:ui' show lerpDouble;
import 'package:flutter/material.dart';
import 'fonts.dart';

class SigumiTheme {
  // Brand Colors (from Figma mockup)
  static const Color primaryBlue = Color(
    0xFF1B2E7B,
  ); // Navy blue - logo, headings, buttons
  static const Color primaryDark = Color(0xFF0F1E5C); // Darker navy
  static const Color primaryLight = Color(0xFFD0D5EB); // Light blue tint
  static const Color accentYellow = Color(
    0xFFFFD623,
  ); // Gold/yellow accent ("GU" in logo)
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2E7B); // Navy for headings
  static const Color textBody = Color(0xFF3A3A3A); // Dark gray for body text
  static const Color textSecondary = Color(
    0xFF5C5E6B,
  ); // Accessible muted gray (>= 5.9:1 on light surfaces)
  static const Color inkPrimary = Color(0xFF1E1E2C); // Crisp Swiss editorial ink
  static const Color inkSecondary = Color(0xFF4B4B5A); // Body copy ink
  static const Color borderSubtle = Color(0xFFD8DCE6); // Hairline rule
  static const Color borderControl = Color(
    0xFF767A8C,
  ); // Interactive control outline (>= 4.0:1 non-text contrast)
  static const Color divider = Color(0xFFE5E5EA);

  // Gradient Colors (from Figma background)
  static const Color gradientTopLeft = Color(0xFFB8C4E9); // Lavender blue
  static const Color gradientTopRight = Color(0xFFD5DBF0); // Light lavender
  static const Color gradientBottomLeft = Color(
    0xFFFFF9C4,
  ); // Light cream yellow
  static const Color gradientBottomRight = Color(0xFFFFF3B0); // Warm cream
  static const Color gradientMid = Color(0xFFE8EBF5); // Mid lavender

  // Keep legacy alias for backward compat in other screens
  static const Color accent = accentYellow;

  // Status Colors — sesuai peta resmi MAGMA Indonesia (magma.esdm.go.id)
  static const Color statusNormal = Color(0xFF00A550);   // Hijau MAGMA
  static const Color statusWaspada = Color(0xFFFFD700);  // Kuning MAGMA
  static const Color statusSiaga = Color(0xFFFF6600);    // Oranye MAGMA
  static const Color statusAwas = Color(0xFFDD0000);     // Merah MAGMA

  // ── High Contrast Mode Colors (WCAG AAA compliant) ──
  static const Color hcBackground = Color(0xFF000000); // Pure black
  static const Color hcSurface = Color(0xFF1A1A1A); // Dark gray surface
  static const Color hcPrimary = Color(0xFFFFFFFF); // Pure white text
  static const Color hcSecondary = Color(0xFFFFD600); // Bright yellow accent
  static const Color hcBorder = Color(0xFFFFFFFF); // White borders
  static const Color hcDivider = Color(0xFFAAAAAA); // Light gray — min 7:1 on black (AAA)

  // High contrast status colors — MAGMA Indonesia — semua ≥ 4.5:1 on black (WCAG AA)
  static const Color hcStatusNormal  = Color(0xFF00FF66); // Hijau — 11.3:1 ✅
  static const Color hcStatusWaspada = Color(0xFFFFEE00); // Kuning — 19.6:1 ✅
  static const Color hcStatusSiaga  = Color(0xFFFF8800);  // Oranye — 5.5:1 ✅
  static const Color hcStatusAwas   = Color(0xFFFF5555);  // Merah terang — 5.1:1 ✅ (was #FF1100 = 3.4:1 ❌)

  // ── Buta Warna: Deuteranopia-safe (merah-hijau) ──
  // Gunakan biru & oranye alih-alih hijau & merah
  static const Color cbdNormal  = Color(0xFF0077BB); // Biru solid — aman bagi semua tipe
  static const Color cbdHighContrastNormal = Color(0xFF66CCFF); // Cyan terang di atas hitam
  static const Color cbdWaspada = Color(0xFFFFCC00); // Kuning emas
  static const Color cbdSiaga  = Color(0xFFEE7700);  // Oranye tua
  static const Color cbdAwas   = Color(0xFFCC3311);  // Coklat-merah aman

  // ── Buta Warna: Protanopia-safe (buta merah) ──
  static const Color cbpNormal  = Color(0xFF0099CC); // Cyan biru
  static const Color cbpWaspada = Color(0xFFFFEE33); // Kuning cerah
  static const Color cbpSiaga  = Color(0xFFFF8844);  // Kuning-oranye
  static const Color cbpAwas   = Color(0xFF8833BB);  // Ungu — aman bagi protanopia

  // ── Buta Warna: Tritanopia-safe (buta biru-kuning) ──
  static const Color cbtNormal  = Color(0xFF009966); // Hijau zamrud
  static const Color cbtWaspada = Color(0xFFFF4444); // Merah-oranye
  static const Color cbtSiaga  = Color(0xFFCC0033);  // Merah tua
  static const Color cbtAwas   = Color(0xFF990033);  // Merah gelap

  // Zone Colors
  static const Color zoneDanger = Color(0x40F44336);
  static const Color zoneWarning = Color(0x40FF9800);
  static const Color zoneCaution = Color(0x40FFC107);
  static const Color zoneSafe = Color(0x404CAF50);

  // Figma-style background gradient decoration
  static BoxDecoration get backgroundGradient => const BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        gradientTopLeft,
        gradientMid,
        Color(0xFFF0EFF5),
        gradientBottomLeft,
      ],
      stops: [0.0, 0.35, 0.65, 1.0],
    ),
  );

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentYellow,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      focusColor: primaryBlue.withValues(alpha: 0.14),
      hoverColor: primaryBlue.withValues(alpha: 0.05),
      highlightColor: primaryBlue.withValues(alpha: 0.08),
      splashColor: primaryBlue.withValues(alpha: 0.10),
      extensions: const <ThemeExtension<dynamic>>[SigumiTokens.light],
      textTheme: const TextTheme().copyWith(
        displaySmall: AppFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: inkPrimary,
          height: 1.15,
          letterSpacing: -0.6,
        ),
        headlineLarge: AppFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: AppFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: AppFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: AppFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: AppFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textBody,
        ),
        bodyMedium: AppFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: AppFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: white,
        ),
        labelMedium: AppFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 0.8,
        ),
        labelSmall: AppFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textSecondary,
          letterSpacing: 1.4,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          minimumSize: const Size(48, 48),
          textStyle: AppFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: inkPrimary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: borderControl, width: 1),
          textStyle: AppFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryBlue,
        foregroundColor: white,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 2,
        shadowColor: primaryBlue.withAlpha(40),
        titleTextStyle: AppFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: white,
          letterSpacing: 0.3,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          textStyle: AppFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: primaryBlue.withAlpha(14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: divider.withAlpha(60)),
        ),
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: AppFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
        ),
        labelStyle: AppFonts.plusJakartaSans(
          color: textPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: white,
        selectedItemColor: primaryBlue,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
    );
  }

  static ThemeData get highContrastTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: AppFonts.family,
      colorScheme: ColorScheme.fromSeed(
        seedColor: hcSecondary,
        primary: hcPrimary,
        secondary: hcSecondary,
        surface: hcSurface,
        brightness: Brightness.dark,
        onPrimary: hcBackground,
        onSecondary: hcBackground,
        onSurface: hcPrimary,
        error: hcStatusAwas,
        onError: hcBackground,
        inverseSurface: hcPrimary,
        onInverseSurface: hcBackground,
      ),
      scaffoldBackgroundColor: hcBackground,
      focusColor: hcSecondary.withValues(alpha: 0.28),
      hoverColor: hcSecondary.withValues(alpha: 0.14),
      highlightColor: hcSecondary.withValues(alpha: 0.20),
      splashColor: hcSecondary.withValues(alpha: 0.24),
      extensions: const <ThemeExtension<dynamic>>[SigumiTokens.highContrast],
      // Jadikan Theme normal sebagai baseline agar struktur seluruh TextStyle
      // (termasuk style yang tidak dioverride di bawah) tetap sama saat Flutter
      // menginterpolasi ThemeData pada perpindahan mode kontras.
      textTheme: lightTheme.textTheme.copyWith(
        displaySmall: AppFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w800,
          color: hcPrimary,
          height: 1.15,
          letterSpacing: -0.6,
        ),
        headlineLarge: AppFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: hcPrimary,
        ),
        headlineMedium: AppFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: hcPrimary,
        ),
        titleLarge: AppFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: hcPrimary,
        ),
        titleMedium: AppFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: hcPrimary,
        ),
        bodyLarge: AppFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: hcPrimary,
        ),
        bodyMedium: AppFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: hcPrimary,
        ),
        labelLarge: AppFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: hcBackground,
        ),
        labelMedium: AppFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: hcDivider,
          letterSpacing: 0.8,
        ),
        labelSmall: AppFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: hcDivider,
          letterSpacing: 1.4,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: hcSurface,
        foregroundColor: hcPrimary,
        elevation: 0,
        centerTitle: true,
        scrolledUnderElevation: 0,
        shadowColor: Colors.transparent,
        titleTextStyle: AppFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: hcPrimary,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: hcPrimary),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: hcSecondary,
          minimumSize: const Size(48, 48),
          textStyle: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hcSecondary,
          minimumSize: const Size(48, 48),
          side: const BorderSide(color: hcBorder, width: 2),
          textStyle: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      iconButtonTheme: const IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(hcPrimary),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hcBackground
              : hcPrimary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hcSecondary
              : hcSurface,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(hcBorder),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hcSecondary
              : hcBackground,
        ),
        checkColor: const WidgetStatePropertyAll(hcBackground),
        side: const BorderSide(color: hcBorder, width: 2),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? hcSecondary
              : hcPrimary,
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: hcSecondary,
        inactiveTrackColor: hcDivider,
        thumbColor: hcPrimary,
        overlayColor: Color(0x33FFD600),
        valueIndicatorColor: hcSecondary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: hcSecondary,
          foregroundColor: hcBackground,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: const BorderSide(color: hcBorder, width: 2),
          ),
          textStyle: AppFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: hcBorder, width: 2),
        ),
        color: hcSurface,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: hcSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: hcBorder, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: hcBorder, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(color: hcSecondary, width: 3),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        hintStyle: AppFonts.plusJakartaSans(
          color: hcDivider,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelStyle: AppFonts.plusJakartaSans(
          color: hcPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: hcSurface,
        selectedItemColor: hcSecondary,
        unselectedItemColor: hcDivider,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: hcSurface,
        indicatorColor: hcSecondary,
        iconTheme: const WidgetStatePropertyAll(
          IconThemeData(color: hcPrimary),
        ),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(color: hcPrimary, fontWeight: FontWeight.w700),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: hcSurface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: hcBorder, width: 2),
        ),
        titleTextStyle: AppFonts.plusJakartaSans(
          color: hcPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: AppFonts.plusJakartaSans(
          color: hcPrimary,
          fontSize: 14,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: hcSurface,
        modalBackgroundColor: hcSurface,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: hcPrimary,
      ),
      listTileTheme: const ListTileThemeData(
        tileColor: hcSurface,
        textColor: hcPrimary,
        iconColor: hcPrimary,
        selectedColor: hcSecondary,
      ),
      tabBarTheme: const TabBarThemeData(
        labelColor: hcPrimary,
        unselectedLabelColor: hcDivider,
        indicatorColor: hcSecondary,
        dividerColor: hcDivider,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: hcSurface,
        selectedColor: hcSecondary,
        checkmarkColor: hcBackground,
        labelStyle: AppFonts.plusJakartaSans(
          color: hcPrimary,
          fontWeight: FontWeight.w700,
        ),
        side: const BorderSide(color: hcBorder, width: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: hcSecondary,
        foregroundColor: hcBackground,
        shape: CircleBorder(side: BorderSide(color: hcBorder, width: 2)),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: hcSecondary,
        linearTrackColor: hcSurface,
        circularTrackColor: hcSurface,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: hcSecondary,
        selectionColor: Color(0x66FFD600),
        selectionHandleColor: hcSecondary,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: hcSurface,
          border: Border.all(color: hcBorder, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: AppFonts.plusJakartaSans(
          color: hcPrimary,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: hcSurface,
        contentTextStyle: AppFonts.plusJakartaSans(color: hcPrimary),
        actionTextColor: hcSecondary,
        behavior: SnackBarBehavior.floating,
        showCloseIcon: true,
        closeIconColor: hcPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: hcBorder, width: 2),
        ),
      ),
      popupMenuTheme: const PopupMenuThemeData(
        color: hcSurface,
        textStyle: TextStyle(color: hcPrimary),
        shape: RoundedRectangleBorder(
          side: BorderSide(color: hcBorder, width: 2),
        ),
      ),
      dividerColor: hcDivider,
      iconTheme: const IconThemeData(color: hcPrimary),
    );
  }

  /// Kembalikan warna status MAGMA sesuai mode aksesibilitas aktif.
  /// [colorBlindMode]: 'normal' | 'deuteranopia' | 'protanopia' | 'tritanopia'
  static Color getStatusColor(
    int level, {
    bool highContrast = false,
    String colorBlindMode = 'normal',
  }) {
    if (highContrast) {
      switch (level) {
        case 1:
          return colorBlindMode == 'deuteranopia'
              ? cbdHighContrastNormal
              : hcStatusNormal;
        case 2: return hcStatusWaspada;
        case 3: return hcStatusSiaga;
        case 4: return hcStatusAwas;
        default:
          return colorBlindMode == 'deuteranopia'
              ? cbdHighContrastNormal
              : hcStatusNormal;
      }
    }

    switch (colorBlindMode) {
      case 'deuteranopia':
        switch (level) {
          case 1: return cbdNormal;
          case 2: return cbdWaspada;
          case 3: return cbdSiaga;
          case 4: return cbdAwas;
          default: return cbdNormal;
        }
      case 'protanopia':
        switch (level) {
          case 1: return cbpNormal;
          case 2: return cbpWaspada;
          case 3: return cbpSiaga;
          case 4: return cbpAwas;
          default: return cbpNormal;
        }
      case 'tritanopia':
        switch (level) {
          case 1: return cbtNormal;
          case 2: return cbtWaspada;
          case 3: return cbtSiaga;
          case 4: return cbtAwas;
          default: return cbtNormal;
        }
      default:
        switch (level) {
          case 1: return statusNormal;
          case 2: return statusWaspada;
          case 3: return statusSiaga;
          case 4: return statusAwas;
          default: return statusNormal;
        }
    }
  }

  /// Kembalikan ikon bentuk unik per level status — untuk aksesibilitas non-warna.
  /// Memastikan info status dapat dibaca tanpa bergantung warna.
  static IconData getStatusShape(int level) {
    // ignore: import_of_legacy_library_into_null_safe
    switch (level) {
      case 1: return Icons.check_circle_outline;   // ● lingkaran ✓
      case 2: return Icons.warning_amber_outlined;  // ⚠ segitiga
      case 3: return Icons.error_outline;           // ⊗ lingkaran-seru
      case 4: return Icons.dangerous_outlined;       // ☠ bahaya
      default: return Icons.check_circle_outline;
    }
  }

  static String getStatusLabel(int level) {
    switch (level) {
      case 1:
        return 'Level I • Normal';
      case 2:
        return 'Level II • Waspada';
      case 3:
        return 'Level III • Siaga';
      case 4:
        return 'Level IV • Awas';
      default:
        return 'Level I • Normal';
    }
  }
}

/// Token semantik desain SIGUMI yang terintegrasi ke ThemeData.extensions.
/// Menyediakan skala warna, tipografi, spasi (4/8dp grid), radius, elevasi/garis,
/// serta status interaksi & durasi gerak untuk mode normal dan kontras tinggi.
@immutable
class SigumiTokens extends ThemeExtension<SigumiTokens> {
  // ── Semantic Colors ──
  final Color canvasBg;
  final Color subtleSurface;
  final Color inkPrimary;
  final Color inkSecondary;
  final Color inkMuted;
  final Color accentPrimary;
  final Color onAccent;
  final Color borderSubtle;
  final Color borderControl;
  final Color borderStrong;
  final Color focusRing;
  final Color hoverFill;
  final Color pressedFill;
  final Color selectedFill;
  final Color disabledFill;
  final Color disabledInk;
  final Color artworkPlateBg;
  final Color artworkPlateInk;
  final Color ambientHighlightBlue;
  final Color ambientHighlightYellow;

  // ── Semantic Typography ──
  final TextStyle displayHeadline;
  final TextStyle sectionTitle;
  final TextStyle cardTitle;
  final TextStyle bodyRegular;
  final TextStyle bodyCompact;
  final TextStyle overlineIndex;
  final TextStyle watermarkIndex;
  final TextStyle buttonLabel;

  // ── Spacing & Sizing Scale (4dp / 8dp grid) ──
  final double spaceXs;
  final double spaceSm;
  final double spaceMd;
  final double spaceLg;
  final double spaceXl;
  final double space2xl;
  final double space3xl;
  final double contentMaxWidth;
  final double iconSm;
  final double iconMd;
  final double iconLg;
  final double iconHero;
  final double ctaHeight;

  // ── Radius Scale (Minimalism & Swiss Style) ──
  final double radiusNone;
  final double radiusXs;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final double radiusPill;

  // ── Shadows & Hairlines ──
  final List<BoxShadow> flatShadow;
  final List<BoxShadow> subtleShadow;
  final List<BoxShadow> ctaShadow;
  final double hairlineWidth;
  final double selectedBorderWidth;
  final double focusRingWidth;

  // ── Interaction & Motion ──
  final double minTouchTarget;
  final Duration motionFast;
  final Duration motionMedium;
  final Duration motionPage;
  final Curve motionCurve;

  const SigumiTokens({
    required this.canvasBg,
    required this.subtleSurface,
    required this.inkPrimary,
    required this.inkSecondary,
    required this.inkMuted,
    required this.accentPrimary,
    required this.onAccent,
    required this.borderSubtle,
    required this.borderControl,
    required this.borderStrong,
    required this.focusRing,
    required this.hoverFill,
    required this.pressedFill,
    required this.selectedFill,
    required this.disabledFill,
    required this.disabledInk,
    required this.artworkPlateBg,
    required this.artworkPlateInk,
    required this.ambientHighlightBlue,
    required this.ambientHighlightYellow,
    required this.displayHeadline,
    required this.sectionTitle,
    required this.cardTitle,
    required this.bodyRegular,
    required this.bodyCompact,
    required this.overlineIndex,
    required this.watermarkIndex,
    required this.buttonLabel,
    required this.spaceXs,
    required this.spaceSm,
    required this.spaceMd,
    required this.spaceLg,
    required this.spaceXl,
    required this.space2xl,
    required this.space3xl,
    required this.contentMaxWidth,
    required this.iconSm,
    required this.iconMd,
    required this.iconLg,
    required this.iconHero,
    required this.ctaHeight,
    required this.radiusNone,
    required this.radiusXs,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.radiusPill,
    required this.flatShadow,
    required this.subtleShadow,
    required this.ctaShadow,
    required this.hairlineWidth,
    required this.selectedBorderWidth,
    required this.focusRingWidth,
    required this.minTouchTarget,
    required this.motionFast,
    required this.motionMedium,
    required this.motionPage,
    required this.motionCurve,
  });

  static const SigumiTokens light = SigumiTokens(
    canvasBg: SigumiTheme.white,
    subtleSurface: SigumiTheme.background,
    inkPrimary: SigumiTheme.inkPrimary,
    inkSecondary: SigumiTheme.inkSecondary,
    inkMuted: SigumiTheme.textSecondary,
    accentPrimary: SigumiTheme.primaryBlue,
    onAccent: SigumiTheme.white,
    borderSubtle: SigumiTheme.borderSubtle,
    borderControl: SigumiTheme.borderControl,
    borderStrong: SigumiTheme.primaryBlue,
    focusRing: SigumiTheme.primaryBlue,
    hoverFill: Color(0x0D1B2E7B),
    pressedFill: Color(0x1A1B2E7B),
    selectedFill: Color(0x0F1B2E7B),
    disabledFill: Color(0xFFEEF0F5),
    disabledInk: Color(0xFF6B6E7B),
    artworkPlateBg: Colors.transparent,
    artworkPlateInk: SigumiTheme.primaryBlue,
    ambientHighlightBlue: Color(0xFF1F6FD2),
    ambientHighlightYellow: Color(0xFFFFC928),
    displayHeadline: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: SigumiTheme.inkPrimary,
      height: 1.12,
      letterSpacing: -0.8,
    ),
    sectionTitle: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.inkPrimary,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    cardTitle: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.inkPrimary,
      height: 1.25,
      letterSpacing: -0.1,
    ),
    bodyRegular: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 15,
      fontWeight: FontWeight.w400,
      color: SigumiTheme.inkSecondary,
      height: 1.55,
    ),
    bodyCompact: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: SigumiTheme.textSecondary,
      height: 1.4,
    ),
    overlineIndex: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.textSecondary,
      height: 1.2,
      letterSpacing: 1.4,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    watermarkIndex: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 84,
      fontWeight: FontWeight.w800,
      color: Color(0x0F1B2E7B),
      height: 0.9,
      letterSpacing: -3.0,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    buttonLabel: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.white,
      height: 1.2,
      letterSpacing: 0.2,
    ),
    spaceXs: 4.0,
    spaceSm: 8.0,
    spaceMd: 12.0,
    spaceLg: 16.0,
    spaceXl: 24.0,
    space2xl: 32.0,
    space3xl: 48.0,
    contentMaxWidth: 560.0,
    iconSm: 16.0,
    iconMd: 20.0,
    iconLg: 24.0,
    iconHero: 56.0,
    ctaHeight: 54.0,
    radiusNone: 0.0,
    radiusXs: 2.0,
    radiusSm: 8.0,
    radiusMd: 12.0,
    radiusLg: 16.0,
    radiusPill: 28.0,
    flatShadow: <BoxShadow>[],
    subtleShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x0B1B2E7B),
        blurRadius: 20,
        offset: Offset(0, 6),
      ),
    ],
    ctaShadow: <BoxShadow>[
      BoxShadow(
        color: Color(0x2E1B2E7B),
        blurRadius: 18,
        offset: Offset(0, 8),
      ),
    ],
    hairlineWidth: 1.0,
    selectedBorderWidth: 2.0,
    focusRingWidth: 2.5,
    minTouchTarget: 48.0,
    motionFast: Duration(milliseconds: 150),
    motionMedium: Duration(milliseconds: 260),
    motionPage: Duration(milliseconds: 520),
    motionCurve: Curves.easeOutCubic,
  );

  static const SigumiTokens highContrast = SigumiTokens(
    canvasBg: SigumiTheme.hcBackground,
    subtleSurface: SigumiTheme.hcSurface,
    inkPrimary: SigumiTheme.hcPrimary,
    inkSecondary: SigumiTheme.hcPrimary,
    inkMuted: SigumiTheme.hcDivider,
    accentPrimary: SigumiTheme.hcSecondary,
    onAccent: SigumiTheme.hcBackground,
    borderSubtle: SigumiTheme.hcBorder,
    borderControl: SigumiTheme.hcBorder,
    borderStrong: SigumiTheme.hcSecondary,
    focusRing: SigumiTheme.hcSecondary,
    hoverFill: Color(0x24FFD600),
    pressedFill: Color(0x3DFFD600),
    selectedFill: SigumiTheme.hcSurface,
    disabledFill: SigumiTheme.hcSurface,
    disabledInk: SigumiTheme.hcDivider,
    artworkPlateBg: SigumiTheme.white,
    artworkPlateInk: SigumiTheme.inkPrimary,
    ambientHighlightBlue: Colors.transparent,
    ambientHighlightYellow: Colors.transparent,
    displayHeadline: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 30,
      fontWeight: FontWeight.w800,
      color: SigumiTheme.hcPrimary,
      height: 1.12,
      letterSpacing: -0.8,
    ),
    sectionTitle: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.hcPrimary,
      height: 1.2,
      letterSpacing: -0.3,
    ),
    cardTitle: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.hcPrimary,
      height: 1.25,
      letterSpacing: -0.1,
    ),
    bodyRegular: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: SigumiTheme.hcPrimary,
      height: 1.55,
    ),
    bodyCompact: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: SigumiTheme.hcDivider,
      height: 1.4,
    ),
    overlineIndex: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.hcDivider,
      height: 1.2,
      letterSpacing: 1.4,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    watermarkIndex: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 84,
      fontWeight: FontWeight.w800,
      color: Color(0x1FFFFFFF),
      height: 0.9,
      letterSpacing: -3.0,
      fontFeatures: [FontFeature.tabularFigures()],
    ),
    buttonLabel: TextStyle(
      fontFamily: AppFonts.family,
      fontSize: 15,
      fontWeight: FontWeight.w700,
      color: SigumiTheme.hcBackground,
      height: 1.2,
      letterSpacing: 0.2,
    ),
    spaceXs: 4.0,
    spaceSm: 8.0,
    spaceMd: 12.0,
    spaceLg: 16.0,
    spaceXl: 24.0,
    space2xl: 32.0,
    space3xl: 48.0,
    contentMaxWidth: 560.0,
    iconSm: 16.0,
    iconMd: 20.0,
    iconLg: 24.0,
    iconHero: 56.0,
    ctaHeight: 54.0,
    radiusNone: 0.0,
    radiusXs: 2.0,
    radiusSm: 8.0,
    radiusMd: 12.0,
    radiusLg: 16.0,
    radiusPill: 28.0,
    flatShadow: <BoxShadow>[],
    subtleShadow: <BoxShadow>[],
    ctaShadow: <BoxShadow>[],
    hairlineWidth: 2.0,
    selectedBorderWidth: 2.5,
    focusRingWidth: 3.0,
    minTouchTarget: 48.0,
    motionFast: Duration(milliseconds: 150),
    motionMedium: Duration(milliseconds: 260),
    motionPage: Duration(milliseconds: 520),
    motionCurve: Curves.easeOutCubic,
  );

  @override
  SigumiTokens copyWith({
    Color? canvasBg,
    Color? subtleSurface,
    Color? inkPrimary,
    Color? inkSecondary,
    Color? inkMuted,
    Color? accentPrimary,
    Color? onAccent,
    Color? borderSubtle,
    Color? borderControl,
    Color? borderStrong,
    Color? focusRing,
    Color? hoverFill,
    Color? pressedFill,
    Color? selectedFill,
    Color? disabledFill,
    Color? disabledInk,
    Color? artworkPlateBg,
    Color? artworkPlateInk,
    Color? ambientHighlightBlue,
    Color? ambientHighlightYellow,
    TextStyle? displayHeadline,
    TextStyle? sectionTitle,
    TextStyle? cardTitle,
    TextStyle? bodyRegular,
    TextStyle? bodyCompact,
    TextStyle? overlineIndex,
    TextStyle? watermarkIndex,
    TextStyle? buttonLabel,
    double? spaceXs,
    double? spaceSm,
    double? spaceMd,
    double? spaceLg,
    double? spaceXl,
    double? space2xl,
    double? space3xl,
    double? contentMaxWidth,
    double? iconSm,
    double? iconMd,
    double? iconLg,
    double? iconHero,
    double? ctaHeight,
    double? radiusNone,
    double? radiusXs,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    double? radiusPill,
    List<BoxShadow>? flatShadow,
    List<BoxShadow>? subtleShadow,
    List<BoxShadow>? ctaShadow,
    double? hairlineWidth,
    double? selectedBorderWidth,
    double? focusRingWidth,
    double? minTouchTarget,
    Duration? motionFast,
    Duration? motionMedium,
    Duration? motionPage,
    Curve? motionCurve,
  }) {
    return SigumiTokens(
      canvasBg: canvasBg ?? this.canvasBg,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      inkPrimary: inkPrimary ?? this.inkPrimary,
      inkSecondary: inkSecondary ?? this.inkSecondary,
      inkMuted: inkMuted ?? this.inkMuted,
      accentPrimary: accentPrimary ?? this.accentPrimary,
      onAccent: onAccent ?? this.onAccent,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      borderControl: borderControl ?? this.borderControl,
      borderStrong: borderStrong ?? this.borderStrong,
      focusRing: focusRing ?? this.focusRing,
      hoverFill: hoverFill ?? this.hoverFill,
      pressedFill: pressedFill ?? this.pressedFill,
      selectedFill: selectedFill ?? this.selectedFill,
      disabledFill: disabledFill ?? this.disabledFill,
      disabledInk: disabledInk ?? this.disabledInk,
      artworkPlateBg: artworkPlateBg ?? this.artworkPlateBg,
      artworkPlateInk: artworkPlateInk ?? this.artworkPlateInk,
      ambientHighlightBlue: ambientHighlightBlue ?? this.ambientHighlightBlue,
      ambientHighlightYellow:
          ambientHighlightYellow ?? this.ambientHighlightYellow,
      displayHeadline: displayHeadline ?? this.displayHeadline,
      sectionTitle: sectionTitle ?? this.sectionTitle,
      cardTitle: cardTitle ?? this.cardTitle,
      bodyRegular: bodyRegular ?? this.bodyRegular,
      bodyCompact: bodyCompact ?? this.bodyCompact,
      overlineIndex: overlineIndex ?? this.overlineIndex,
      watermarkIndex: watermarkIndex ?? this.watermarkIndex,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      spaceXs: spaceXs ?? this.spaceXs,
      spaceSm: spaceSm ?? this.spaceSm,
      spaceMd: spaceMd ?? this.spaceMd,
      spaceLg: spaceLg ?? this.spaceLg,
      spaceXl: spaceXl ?? this.spaceXl,
      space2xl: space2xl ?? this.space2xl,
      space3xl: space3xl ?? this.space3xl,
      contentMaxWidth: contentMaxWidth ?? this.contentMaxWidth,
      iconSm: iconSm ?? this.iconSm,
      iconMd: iconMd ?? this.iconMd,
      iconLg: iconLg ?? this.iconLg,
      iconHero: iconHero ?? this.iconHero,
      ctaHeight: ctaHeight ?? this.ctaHeight,
      radiusNone: radiusNone ?? this.radiusNone,
      radiusXs: radiusXs ?? this.radiusXs,
      radiusSm: radiusSm ?? this.radiusSm,
      radiusMd: radiusMd ?? this.radiusMd,
      radiusLg: radiusLg ?? this.radiusLg,
      radiusPill: radiusPill ?? this.radiusPill,
      flatShadow: flatShadow ?? this.flatShadow,
      subtleShadow: subtleShadow ?? this.subtleShadow,
      ctaShadow: ctaShadow ?? this.ctaShadow,
      hairlineWidth: hairlineWidth ?? this.hairlineWidth,
      selectedBorderWidth: selectedBorderWidth ?? this.selectedBorderWidth,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      minTouchTarget: minTouchTarget ?? this.minTouchTarget,
      motionFast: motionFast ?? this.motionFast,
      motionMedium: motionMedium ?? this.motionMedium,
      motionPage: motionPage ?? this.motionPage,
      motionCurve: motionCurve ?? this.motionCurve,
    );
  }

  @override
  SigumiTokens lerp(covariant ThemeExtension<SigumiTokens>? other, double t) {
    if (other is! SigumiTokens) return this;
    return SigumiTokens(
      canvasBg: Color.lerp(canvasBg, other.canvasBg, t) ?? canvasBg,
      subtleSurface:
          Color.lerp(subtleSurface, other.subtleSurface, t) ?? subtleSurface,
      inkPrimary: Color.lerp(inkPrimary, other.inkPrimary, t) ?? inkPrimary,
      inkSecondary:
          Color.lerp(inkSecondary, other.inkSecondary, t) ?? inkSecondary,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t) ?? inkMuted,
      accentPrimary:
          Color.lerp(accentPrimary, other.accentPrimary, t) ?? accentPrimary,
      onAccent: Color.lerp(onAccent, other.onAccent, t) ?? onAccent,
      borderSubtle:
          Color.lerp(borderSubtle, other.borderSubtle, t) ?? borderSubtle,
      borderControl:
          Color.lerp(borderControl, other.borderControl, t) ?? borderControl,
      borderStrong:
          Color.lerp(borderStrong, other.borderStrong, t) ?? borderStrong,
      focusRing: Color.lerp(focusRing, other.focusRing, t) ?? focusRing,
      hoverFill: Color.lerp(hoverFill, other.hoverFill, t) ?? hoverFill,
      pressedFill: Color.lerp(pressedFill, other.pressedFill, t) ?? pressedFill,
      selectedFill:
          Color.lerp(selectedFill, other.selectedFill, t) ?? selectedFill,
      disabledFill:
          Color.lerp(disabledFill, other.disabledFill, t) ?? disabledFill,
      disabledInk:
          Color.lerp(disabledInk, other.disabledInk, t) ?? disabledInk,
      artworkPlateBg:
          Color.lerp(artworkPlateBg, other.artworkPlateBg, t) ?? artworkPlateBg,
      artworkPlateInk:
          Color.lerp(artworkPlateInk, other.artworkPlateInk, t) ??
          artworkPlateInk,
      ambientHighlightBlue:
          Color.lerp(ambientHighlightBlue, other.ambientHighlightBlue, t) ??
          ambientHighlightBlue,
      ambientHighlightYellow:
          Color.lerp(ambientHighlightYellow, other.ambientHighlightYellow, t) ??
          ambientHighlightYellow,
      displayHeadline:
          TextStyle.lerp(displayHeadline, other.displayHeadline, t) ??
          displayHeadline,
      sectionTitle:
          TextStyle.lerp(sectionTitle, other.sectionTitle, t) ?? sectionTitle,
      cardTitle: TextStyle.lerp(cardTitle, other.cardTitle, t) ?? cardTitle,
      bodyRegular:
          TextStyle.lerp(bodyRegular, other.bodyRegular, t) ?? bodyRegular,
      bodyCompact:
          TextStyle.lerp(bodyCompact, other.bodyCompact, t) ?? bodyCompact,
      overlineIndex:
          TextStyle.lerp(overlineIndex, other.overlineIndex, t) ??
          overlineIndex,
      watermarkIndex:
          TextStyle.lerp(watermarkIndex, other.watermarkIndex, t) ??
          watermarkIndex,
      buttonLabel:
          TextStyle.lerp(buttonLabel, other.buttonLabel, t) ?? buttonLabel,
      spaceXs: lerpDouble(spaceXs, other.spaceXs, t) ?? spaceXs,
      spaceSm: lerpDouble(spaceSm, other.spaceSm, t) ?? spaceSm,
      spaceMd: lerpDouble(spaceMd, other.spaceMd, t) ?? spaceMd,
      spaceLg: lerpDouble(spaceLg, other.spaceLg, t) ?? spaceLg,
      spaceXl: lerpDouble(spaceXl, other.spaceXl, t) ?? spaceXl,
      space2xl: lerpDouble(space2xl, other.space2xl, t) ?? space2xl,
      space3xl: lerpDouble(space3xl, other.space3xl, t) ?? space3xl,
      contentMaxWidth:
          lerpDouble(contentMaxWidth, other.contentMaxWidth, t) ??
          contentMaxWidth,
      iconSm: lerpDouble(iconSm, other.iconSm, t) ?? iconSm,
      iconMd: lerpDouble(iconMd, other.iconMd, t) ?? iconMd,
      iconLg: lerpDouble(iconLg, other.iconLg, t) ?? iconLg,
      iconHero: lerpDouble(iconHero, other.iconHero, t) ?? iconHero,
      ctaHeight: lerpDouble(ctaHeight, other.ctaHeight, t) ?? ctaHeight,
      radiusNone: lerpDouble(radiusNone, other.radiusNone, t) ?? radiusNone,
      radiusXs: lerpDouble(radiusXs, other.radiusXs, t) ?? radiusXs,
      radiusSm: lerpDouble(radiusSm, other.radiusSm, t) ?? radiusSm,
      radiusMd: lerpDouble(radiusMd, other.radiusMd, t) ?? radiusMd,
      radiusLg: lerpDouble(radiusLg, other.radiusLg, t) ?? radiusLg,
      radiusPill: lerpDouble(radiusPill, other.radiusPill, t) ?? radiusPill,
      flatShadow: t < 0.5 ? flatShadow : other.flatShadow,
      subtleShadow: t < 0.5 ? subtleShadow : other.subtleShadow,
      ctaShadow: t < 0.5 ? ctaShadow : other.ctaShadow,
      hairlineWidth:
          lerpDouble(hairlineWidth, other.hairlineWidth, t) ?? hairlineWidth,
      selectedBorderWidth:
          lerpDouble(selectedBorderWidth, other.selectedBorderWidth, t) ??
          selectedBorderWidth,
      focusRingWidth:
          lerpDouble(focusRingWidth, other.focusRingWidth, t) ?? focusRingWidth,
      minTouchTarget:
          lerpDouble(minTouchTarget, other.minTouchTarget, t) ?? minTouchTarget,
      motionFast: t < 0.5 ? motionFast : other.motionFast,
      motionMedium: t < 0.5 ? motionMedium : other.motionMedium,
      motionPage: t < 0.5 ? motionPage : other.motionPage,
      motionCurve: t < 0.5 ? motionCurve : other.motionCurve,
    );
  }
}
