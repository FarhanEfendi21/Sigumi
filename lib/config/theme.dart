import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SigumiTheme {
  // Brand Colors (from Figma mockup)
  static const Color primaryBlue = Color(0xFF1B2E7B);     // Navy blue - logo, headings, buttons
  static const Color primaryDark = Color(0xFF0F1E5C);     // Darker navy
  static const Color primaryLight = Color(0xFFD0D5EB);    // Light blue tint
  static const Color accentYellow = Color(0xFFFFD623);    // Gold/yellow accent ("GU" in logo)
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1B2E7B);     // Navy for headings
  static const Color textBody = Color(0xFF3A3A3A);        // Dark gray for body text
  static const Color textSecondary = Color(0xFF8E8E93);   // Placeholder gray
  static const Color divider = Color(0xFFE5E5EA);

  // Gradient Colors (from Figma background)
  static const Color gradientTopLeft = Color(0xFFB8C4E9); // Lavender blue
  static const Color gradientTopRight = Color(0xFFD5DBF0);// Light lavender
  static const Color gradientBottomLeft = Color(0xFFFFF9C4); // Light cream yellow
  static const Color gradientBottomRight = Color(0xFFFFF3B0);// Warm cream
  static const Color gradientMid = Color(0xFFE8EBF5);    // Mid lavender

  // Keep legacy alias for backward compat in other screens
  static const Color accent = accentYellow;

  // Status Colors
  static const Color statusNormal = Color(0xFF4CAF50);
  static const Color statusWaspada = Color(0xFFFFC107);
  static const Color statusSiaga = Color(0xFFFF9800);
  static const Color statusAwas = Color(0xFFF44336);

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
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryBlue,
        primary: primaryBlue,
        secondary: accentYellow,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        headlineLarge: GoogleFonts.plusJakartaSans(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: textBody,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: textSecondary,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
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
        titleTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: white,
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
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: divider.withAlpha(128)),
        ),
        color: surface,
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
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        hintStyle: GoogleFonts.plusJakartaSans(
          color: textSecondary,
          fontSize: 14,
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
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

  static Color getStatusColor(int level) {
    switch (level) {
      case 1:
        return statusNormal;
      case 2:
        return statusWaspada;
      case 3:
        return statusSiaga;
      case 4:
        return statusAwas;
      default:
        return statusNormal;
    }
  }

  static String getStatusLabel(int level) {
    switch (level) {
      case 1:
        return 'Normal';
      case 2:
        return 'Waspada';
      case 3:
        return 'Siaga';
      case 4:
        return 'Awas';
      default:
        return 'Normal';
    }
  }
}
