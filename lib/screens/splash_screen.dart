import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/config/fonts.dart';
import '../config/theme.dart';
import '../config/routes.dart';
import 'onboarding/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Tunggu animasi selesai, lalu putuskan rute berikutnya
    Future.delayed(const Duration(milliseconds: 2800), _navigateNext);
  }

  /// Cek apakah user sudah pernah melewati onboarding.
  /// - Belum pernah → OnboardingScreen
  /// - Sudah → LoginScreen
  Future<void> _navigateNext() async {
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool(kOnboardingDoneKey) ?? false;

    if (!mounted) return;

    if (onboardingDone) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortSide = size.shortestSide;

    // Ukuran logo responsif: 18% sisi terpendek, dibatasi 60–120
    final logoSize = (shortSide * 0.18).clamp(60.0, 120.0);
    final titleSize = (shortSide * 0.026).clamp(11.0, 15.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: SigumiTheme.backgroundGradient,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Spacer(flex: 4),

            // Logo dengan animasi scale + fade
            Image.asset(
              'assets/images/SIGUMI-logo.png',
              height: logoSize,
              fit: BoxFit.contain,
            )
                .animate()
                .fadeIn(duration: 900.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1.0, 1.0),
                  duration: 1000.ms,
                  curve: Curves.easeOutBack,
                ),

            SizedBox(height: logoSize * 0.15),

            // Teks subtitle
            Text(
              'Sistem Informasi Gunung Berapi\nMitigasi Bencana',
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                color: SigumiTheme.primaryBlue.withAlpha(160),
                fontSize: titleSize,
                height: 1.5,
                letterSpacing: 0.3,
              ),
            )
                .animate()
                .fadeIn(delay: 500.ms, duration: 800.ms, curve: Curves.easeOut)
                .moveY(
                  begin: 10,
                  end: 0,
                  delay: 500.ms,
                  duration: 800.ms,
                  curve: Curves.easeOut,
                ),

            const Spacer(flex: 3),

            // Loading indicator
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(
                  SigumiTheme.primaryBlue.withAlpha(100),
                ),
              ),
            ).animate().fadeIn(delay: 1200.ms, duration: 600.ms),

            const SizedBox(height: 12),

            // Versi aplikasi
            Text(
              'v1.0.0',
              style: AppFonts.plusJakartaSans(
                color: SigumiTheme.textSecondary.withAlpha(100),
                fontSize: 11,
              ),
            ).animate().fadeIn(delay: 1400.ms, duration: 600.ms),

            const Spacer(flex: 1),
          ],
        ),
      ),
    );
  }
}
