import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
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
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  void _back() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
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
    final bottomPad = math.max(mq.padding.bottom, 12.0);

    // Responsive sizing
    final iconSize = isSmall ? 90.0 : 120.0;
    final iconEmoji = isSmall ? 44.0 : 56.0;
    final iconRadius = isSmall ? 24.0 : 30.0;
    final titleSize = isSmall ? 22.0 : 26.0;
    final descSize = isSmall ? 13.0 : 15.0;
    final btnHeight = isSmall ? 48.0 : 54.0;
    final hPad = screenW > 500 ? 48.0 : 28.0;

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
              SizedBox(height: isSmall ? 16 : 24),

              // ── Progress bar ──
              Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: SizedBox(
                  height: 5,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(180),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        AnimatedFractionallySizedBox(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          widthFactor: (_currentPage + 1) / total,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [step.accent, step.accentLight],
                              ),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: total,
                  itemBuilder: (context, index) {
                    final s = _steps[index];
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        return SingleChildScrollView(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(height: isSmall ? 24 : 48),

                                // ── Floating icon ──
                                Container(
                                  width: iconSize,
                                  height: iconSize,
                                  decoration: BoxDecoration(
                                    color: s.iconBg,
                                    borderRadius:
                                        BorderRadius.circular(iconRadius),
                                    boxShadow: [
                                      BoxShadow(
                                        color: s.accent.withAlpha(25),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12),
                                        spreadRadius: 4,
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
                                    .fadeIn(duration: 400.ms)
                                    .scale(
                                      begin: const Offset(0.6, 0.6),
                                      end: const Offset(1, 1),
                                      duration: 600.ms,
                                      curve: Curves.elasticOut,
                                    )
                                    .then()
                                    .moveY(
                                      begin: 0,
                                      end: -6,
                                      duration: 2000.ms,
                                      curve: Curves.easeInOut,
                                    )
                                    .then()
                                    .moveY(
                                      begin: -6,
                                      end: 0,
                                      duration: 2000.ms,
                                      curve: Curves.easeInOut,
                                    ),

                                SizedBox(height: isSmall ? 24 : 36),

                                // ── Title ──
                                Text(
                                  s.title,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: titleSize,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A1A2E),
                                    height: 1.15,
                                    letterSpacing: -0.3,
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 120.ms, duration: 400.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      delay: 120.ms,
                                      duration: 400.ms,
                                      curve: Curves.easeOutCubic,
                                    ),

                                SizedBox(height: isSmall ? 10 : 16),

                                // ── Description ──
                                ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(maxWidth: 340),
                                  child: Text(
                                    s.description,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: descSize,
                                      fontWeight: FontWeight.w400,
                                      color: const Color(0xFF6B6B78),
                                      height: 1.6,
                                    ),
                                  ),
                                )
                                    .animate()
                                    .fadeIn(delay: 220.ms, duration: 400.ms)
                                    .slideY(
                                      begin: 0.15,
                                      end: 0,
                                      delay: 220.ms,
                                      duration: 400.ms,
                                      curve: Curves.easeOutCubic,
                                    ),

                                // ── Info card ──
                                if (s.infoNote != null) ...[
                                  const SizedBox(height: 20),
                                  Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: s.accent.withAlpha(35),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: s.accent.withAlpha(10),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('⚠️',
                                            style: TextStyle(fontSize: 14)),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: RichText(
                                            text: TextSpan(
                                              style:
                                                  GoogleFonts.plusJakartaSans(
                                                fontSize: 12,
                                                color:
                                                    const Color(0xFF4A4A4A),
                                                height: 1.5,
                                              ),
                                              children: [
                                                TextSpan(
                                                  text: 'Penting: ',
                                                  style: GoogleFonts
                                                      .plusJakartaSans(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w700,
                                                    color: s.accent,
                                                    height: 1.5,
                                                  ),
                                                ),
                                                TextSpan(text: s.infoNote),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                      .animate()
                                      .fadeIn(delay: 320.ms, duration: 400.ms),
                                ],

                                SizedBox(height: isSmall ? 24 : 48),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // ── Bottom controls ──
              Container(
                padding: EdgeInsets.fromLTRB(hPad, 6, hPad, bottomPad),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      step.gradientBottom.withAlpha(0),
                      step.gradientBottom,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Primary button
                    SizedBox(
                      width: double.infinity,
                      height: btnHeight,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 400),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [step.accent, step.accentLight],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: step.accent.withAlpha(50),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _next,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _currentPage < _steps.length - 1
                                    ? 'Lanjut'
                                    : 'Mulai Sekarang',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.arrow_forward_rounded,
                                  size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Back button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _currentPage > 0 ? 1.0 : 0.0,
                        child: TextButton(
                          onPressed: _currentPage > 0 ? _back : null,
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF6B6B78),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_back_rounded, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                'Kembali',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        final isActive = _currentPage == i;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: isActive ? 28 : 8,
                          height: 6,
                          decoration: BoxDecoration(
                            gradient: isActive
                                ? LinearGradient(
                                    colors: [step.accent, step.accentLight])
                                : null,
                            color: isActive ? null : const Color(0xFFD4D4D8),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        );
                      }),
                    ),

                    SizedBox(height: isSmall ? 6 : 10),
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
