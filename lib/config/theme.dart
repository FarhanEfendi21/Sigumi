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
  static const Color textSecondary = Color(0xFF8E8E93); // Placeholder gray
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
      textTheme: const TextTheme().copyWith(
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
      // Jadikan Theme normal sebagai baseline agar struktur seluruh TextStyle
      // (termasuk style yang tidak dioverride di bawah) tetap sama saat Flutter
      // menginterpolasi ThemeData pada perpindahan mode kontras.
      textTheme: lightTheme.textTheme.copyWith(
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
          textStyle: AppFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: hcSecondary,
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
