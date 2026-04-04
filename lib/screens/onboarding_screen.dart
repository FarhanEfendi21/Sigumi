import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import '../config/routes.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_StepData> _steps = [
    _StepData(
      emoji: '🌋',
      title: 'Selamat Datang\ndi SIGUMI',
      description:
          'Sistem Informasi Gunung Berapi Mitigasi Bencana. '
          'Informasi akurat dan terpercaya untuk keselamatan Anda.',
      accent: Color(0xFF1B6EB5),
      accentLight: Color(0xFF4A9ADB),
      iconBg: Color(0xFFDCEEFA),
      gradientTop: Color(0xFFF5FAFF),
      gradientBottom: Color(0xFFE3F0FB),
    ),
    _StepData(
      emoji: '🔔',
      title: 'Lihat Status\nGunung',
      description:
          'Di halaman utama, Anda dapat melihat status gunung berapi '
          'dan jarak Anda dari zona bahaya. Status akan diupdate otomatis.',
      accent: Color(0xFFE8760C),
      accentLight: Color(0xFFF5A04D),
      iconBg: Color(0xFFFFF0DD),
      gradientTop: Color(0xFFFFFBF5),
      gradientBottom: Color(0xFFFFF0DD),
    ),
    _StepData(
      emoji: '🗺️',
      title: 'Peta & Lokasi\nAnda',
      description:
          'Klik tombol Peta untuk melihat lokasi gunung berapi dan posisi Anda. '
          'Kami akan membantu Anda menemukan jalur evakuasi terdekat.',
      accent: Color(0xFF2E8B57),
      accentLight: Color(0xFF5BB882),
      iconBg: Color(0xFFDFF5E8),
      gradientTop: Color(0xFFF5FFF8),
      gradientBottom: Color(0xFFDFF5E8),
    ),
    _StepData(
      emoji: '📹',
      title: 'Visual Merapi\nLive',
      description:
          'Lihat kondisi gunung secara langsung melalui kamera live 24/7. '
          'Anda juga bisa melihat foto dan video dokumentasi.',
      accent: Color(0xFFD32F2F),
      accentLight: Color(0xFFEF5A5A),
      iconBg: Color(0xFFFDE0E0),
      gradientTop: Color(0xFFFFF7F7),
      gradientBottom: Color(0xFFFDE0E0),
    ),
    _StepData(
      emoji: '💬',
      title: 'Chatbot AI\n24/7',
      description:
          'Tanyakan apa saja seputar Gunung Merapi — status gunung, '
          'jalur evakuasi, zona bahaya, tips hujan abu, '
          'P3K, hingga nomor darurat.',
      accent: Color(0xFF9C27B0),
      accentLight: Color(0xFFC356D4),
      iconBg: Color(0xFFF3E5F5),
      gradientTop: Color(0xFFFCF5FF),
      gradientBottom: Color(0xFFF3E5F5),
      infoNote:
          'Chatbot ini hanya memberikan informasi, bukan mengambil keputusan. '
          'Untuk keputusan darurat, ikuti arahan resmi BPBD.',
    ),
    _StepData(
      emoji: '📶',
      title: 'Akses Online\n& Offline',
      description:
          'Informasi penting tetap tersedia meskipun tanpa koneksi internet. '
          'Panduan lengkap sebelum, saat, dan setelah erupsi.',
      accent: Color(0xFF1B2E7B),
      accentLight: Color(0xFF4D5FA8),
      iconBg: Color(0xFFD0D5EB),
      gradientTop: Color(0xFFF5F6FC),
      gradientBottom: Color(0xFFD0D5EB),
    ),
  ];

  void _next() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentPage];
    final total = _steps.length;
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final screenW = mq.size.width;
    final isSmall = screenH < 700;
    final bottomPad = math.max(mq.padding.bottom, 16.0);

    // Responsive sizing
    final iconSize = isSmall ? 100.0 : 130.0;
    final iconEmoji = isSmall ? 48.0 : 64.0;
    final titleSize = isSmall ? 24.0 : 28.0;
    final descSize = isSmall ? 14.0 : 15.0;
    final btnHeight = isSmall ? 52.0 : 56.0;
    final hPad = screenW > 500 ? 40.0 : 24.0;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [step.gradientTop, step.gradientBottom],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top Navigation Row (Back & Skip)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: hPad - 8,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _currentPage > 0 ? 1.0 : 0.0,
                      child: InkWell(
                        onTap: _currentPage > 0 ? _back : null,
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 20,
                            color: const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                    // Skip button
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 300),
                      opacity: _currentPage < total - 1 ? 1.0 : 0.0,
                      child: TextButton(
                        onPressed: _currentPage < total - 1 ? _skip : null,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF64748B),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Lewati',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page Content
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final s = _steps[index];
                    return Padding(
                      padding: EdgeInsets.symmetric(horizontal: hPad),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 2),

                          // Clean Illustration Badge
                          Container(
                                width: iconSize,
                                height: iconSize,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: s.accent.withAlpha(20),
                                      blurRadius: 40,
                                      offset: const Offset(0, 16),
                                    ),
                                    BoxShadow(
                                      color: s.iconBg,
                                      blurRadius: 0,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  s.emoji,
                                  style: TextStyle(fontSize: iconEmoji),
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 500.ms, curve: Curves.easeOut)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1, 1),
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              )
                              .then()
                              .shimmer(
                                duration: 1200.ms,
                                color: Colors.white54,
                              ),

                          SizedBox(height: isSmall ? 32 : 44),

                          // Title
                          Text(
                                s.title,
                                textAlign: TextAlign.center,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: titleSize,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  height: 1.25,
                                  letterSpacing: -0.5,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 100.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0, delay: 100.ms),

                          SizedBox(height: isSmall ? 12 : 16),

                          // Description
                          Text(
                                s.description,
                                textAlign: TextAlign.center,
                                style: AppFonts.plusJakartaSans(
                                  fontSize: descSize,
                                  fontWeight: FontWeight.w400,
                                  color: const Color(0xFF64748B),
                                  height: 1.6,
                                ),
                              )
                              .animate()
                              .fadeIn(delay: 200.ms, duration: 400.ms)
                              .slideY(begin: 0.1, end: 0, delay: 200.ms),

                          // Elegant Info Box
                          if (s.infoNote != null) ...[
                            SizedBox(height: isSmall ? 20 : 28),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: s.iconBg.withAlpha(180),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: s.accent.withAlpha(40),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 20,
                                    color: s.accent,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      s.infoNote!,
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF334155),
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ).animate().fadeIn(delay: 300.ms, duration: 400.ms),
                          ],

                          const Spacer(flex: 3),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // Bottom Controls (Dots & Main CTA)
              Container(
                padding: EdgeInsets.fromLTRB(hPad, 16, hPad, bottomPad + 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Dynamic Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final isActive = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isActive ? 32 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                isActive
                                    ? step.accent
                                    : const Color(0xFFCBD5E1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: isSmall ? 24 : 36),

                    // Primary CTA
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      width: double.infinity,
                      height: btnHeight,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: step.accent.withAlpha(50),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _next,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step.accent,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _currentPage < total - 1
                                  ? 'Selanjutnya'
                                  : 'Mulai Sekarang',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            if (_currentPage < total - 1) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Data model ──
class _StepData {
  final String emoji;
  final String title;
  final String description;
  final Color accent;
  final Color accentLight;
  final Color iconBg;
  final Color gradientTop;
  final Color gradientBottom;
  final String? infoNote;

  const _StepData({
    required this.emoji,
    required this.title,
    required this.description,
    required this.accent,
    required this.accentLight,
    required this.iconBg,
    required this.gradientTop,
    required this.gradientBottom,
    this.infoNote,
  });
}

