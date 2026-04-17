import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/config/fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';

/// Kunci SharedPreferences untuk menandai onboarding sudah selesai.
const String kOnboardingDoneKey = 'onboarding_done';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  /// Bahasa yang dipilih user di halaman ketiga
  String _selectedLang = 'id';

  static const int _totalPages = 3;

  /// Maju ke halaman berikutnya atau selesai onboarding
  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  /// Lewati semua onboarding langsung ke login
  void _skip() {
    _finishOnboarding();
  }

  /// Tandai onboarding selesai di SharedPreferences, lalu navigasi ke login
  Future<void> _finishOnboarding() async {
    // Simpan bahasa yang dipilih user ke provider
    if (mounted) {
      context.read<VolcanoProvider>().setLanguage(_selectedLang);
    }

    // Tandai onboarding sudah selesai
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboardingDoneKey, true);

    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: SigumiTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // ── Header: tombol Skip ──
              _buildHeader(),

              // ── Konten halaman ──
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  children: [
                    _PageIntro(key: const ValueKey(0)),
                    _PageRealtimeStatus(key: const ValueKey(1)),
                    _PageLanguage(
                      key: const ValueKey(2),
                      selectedLang: _selectedLang,
                      onLangChanged: (lang) => setState(() => _selectedLang = lang),
                    ),
                  ],
                ),
              ),

              // ── Footer: indikator + tombol ──
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Header
  // ─────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo kecil
          Row(
            children: [
              Image.asset(
                'assets/images/SIGUMI-logo.png',
                height: 28,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 8),
              Text(
                'SIGUMI',
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: SigumiTheme.primaryBlue,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),

          // Tombol Skip (sembunyikan di halaman terakhir)
          AnimatedOpacity(
            opacity: _currentPage < _totalPages - 1 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: TextButton(
              onPressed: _currentPage < _totalPages - 1 ? _skip : null,
              style: TextButton.styleFrom(
                foregroundColor: SigumiTheme.textSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: Text(
                'Lewati',
                style: AppFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: SigumiTheme.textSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Footer
  // ─────────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 36),
      child: Column(
        children: [
          // Dot indicator
          _DotIndicator(
            total: _totalPages,
            current: _currentPage,
          ),
          const SizedBox(height: 28),

          // Tombol utama
          _buildPrimaryButton(),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton() {
    final isLast = _currentPage == _totalPages - 1;
    final buttonLabel = isLast ? 'Mulai Sekarang' : 'Selanjutnya';
    final buttonIcon = isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              SigumiTheme.primaryBlue,
              Color(0xFF2A3E9A),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: SigumiTheme.primaryBlue.withAlpha(70),
              blurRadius: 18,
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(anim),
                child: child,
              ),
            ),
            child: Row(
              key: ValueKey(buttonLabel),
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  buttonLabel,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(buttonIcon, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// HALAMAN 1 — Intro Aplikasi
// ═══════════════════════════════════════════════
class _PageIntro extends StatelessWidget {
  const _PageIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(flex: 1),

          // Logo utama
          Image.asset(
            'assets/images/SIGUMI-logo.png',
            height: 110,
            fit: BoxFit.contain,
          )
              .animate()
              .fadeIn(duration: 700.ms, curve: Curves.easeOut)
              .scale(
                begin: const Offset(0.6, 0.6),
                end: const Offset(1.0, 1.0),
                duration: 800.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 36),

          // Badge "v1.0"
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: SigumiTheme.accentYellow.withAlpha(40),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: SigumiTheme.accentYellow.withAlpha(120),
                width: 1,
              ),
            ),
            child: Text(
              'v1.0  •  Beta',
              style: AppFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFA07800),
                letterSpacing: 0.5,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 600.ms),

          const SizedBox(height: 20),

          // Judul SIGUMI
          Text(
            'SIGUMI',
            style: AppFonts.plusJakartaSans(
              fontSize: 42,
              fontWeight: FontWeight.w800,
              color: SigumiTheme.primaryBlue,
              letterSpacing: 3,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .moveY(begin: 12, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOut),

          const SizedBox(height: 10),

          // Keterangan singkat
          Text(
            'Sistem Informasi Gunung Berapi\nMitigasi Bencana',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 15,
              color: SigumiTheme.textSecondary,
              height: 1.6,
              letterSpacing: 0.2,
            ),
          )
              .animate()
              .fadeIn(delay: 550.ms, duration: 600.ms)
              .moveY(begin: 8, end: 0, delay: 550.ms, duration: 600.ms, curve: Curves.easeOut),

          const SizedBox(height: 40),

          // Tiga chip fitur utama
          _FeatureChips(),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _FeatureChips extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final chips = [
      (Icons.notifications_active_rounded, 'Peringatan Dini'),
      (Icons.map_rounded, 'Peta Evakuasi'),
      (Icons.school_rounded, 'Edukasi Mitigasi'),
    ];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: chips.asMap().entries.map((entry) {
        final idx = entry.key;
        final chip = entry.value;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(180),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: SigumiTheme.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(chip.$1, size: 15, color: SigumiTheme.primaryBlue),
              const SizedBox(width: 6),
              Text(
                chip.$2,
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: SigumiTheme.textBody,
                ),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(delay: Duration(milliseconds: 700 + idx * 120), duration: 500.ms)
            .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: 700 + idx * 120), duration: 500.ms);
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════
// HALAMAN 2 — Status Gunung Real-Time
// ═══════════════════════════════════════════════
class _PageRealtimeStatus extends StatelessWidget {
  const _PageRealtimeStatus({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Ilustrasi — kartu status gunung
          _StatusIllustration()
              .animate()
              .fadeIn(duration: 700.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1.0, 1.0),
                duration: 700.ms,
                curve: Curves.easeOutCubic,
              ),

          const SizedBox(height: 44),

          // Label kategori
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withAlpha(15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Fitur Utama',
              style: AppFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: SigumiTheme.primaryBlue,
                letterSpacing: 1,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 14),

          // Judul
          Text(
            'Pantau Status\nGunung Berapi',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: SigumiTheme.primaryBlue,
              height: 1.25,
            ),
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 600.ms)
              .moveY(begin: 10, end: 0, delay: 400.ms, duration: 600.ms, curve: Curves.easeOut),

          const SizedBox(height: 14),

          // Deskripsi
          Text(
            'Dapatkan informasi status gunung berapi secara real-time — mulai dari level Normal hingga Awas — langsung dari sumber resmi PVMBG.',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 14,
              color: SigumiTheme.textSecondary,
              height: 1.65,
            ),
          )
              .animate()
              .fadeIn(delay: 520.ms, duration: 600.ms),

          const SizedBox(height: 28),

          // Baris info kecil
          _InfoRow(Icons.bolt_rounded, 'Update otomatis tanpa refresh', delay: 650),
          const SizedBox(height: 10),
          _InfoRow(Icons.place_rounded, 'Deteksi lokasi otomatis', delay: 750),
          const SizedBox(height: 10),
          _InfoRow(Icons.warning_amber_rounded, 'Notifikasi peringatan darurat', delay: 850),

          const Spacer(flex: 2),
        ],
      ),
    );
  }
}

class _StatusIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: SigumiTheme.primaryBlue.withAlpha(18),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: SigumiTheme.divider.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.volcano_rounded,
                  color: SigumiTheme.primaryBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Gunung Merapi',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: SigumiTheme.textBody,
                    ),
                  ),
                  Text(
                    'Yogyakarta, Indonesia',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      color: SigumiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Live badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30).withAlpha(20),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF3B30),
                        shape: BoxShape.circle,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .fadeOut(duration: 800.ms)
                        .then()
                        .fadeIn(duration: 800.ms),
                    const SizedBox(width: 4),
                    Text(
                      'LIVE',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFFF3B30),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Status level
          Row(
            children: [
              // Level meter
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Saat Ini',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 11,
                        color: SigumiTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: SigumiTheme.statusWaspada.withAlpha(25),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: SigumiTheme.statusWaspada.withAlpha(80),
                            ),
                          ),
                          child: Text(
                            'Level II • Waspada',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: SigumiTheme.statusWaspada,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Level bars
              Row(
                children: List.generate(4, (i) {
                  final colors = [
                    SigumiTheme.statusNormal,
                    SigumiTheme.statusWaspada,
                    SigumiTheme.statusSiaga.withAlpha(60),
                    SigumiTheme.statusAwas.withAlpha(40),
                  ];
                  return Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 8,
                    height: 16 + i * 6.0,
                    decoration: BoxDecoration(
                      color: colors[i],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final int delay;

  const _InfoRow(this.icon, this.label, {required this.delay});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: SigumiTheme.primaryBlue.withAlpha(12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: SigumiTheme.primaryBlue),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: AppFonts.plusJakartaSans(
            fontSize: 13,
            color: SigumiTheme.textBody,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 500.ms)
        .slideX(begin: 0.1, end: 0, delay: Duration(milliseconds: delay), duration: 500.ms);
  }
}

// ═══════════════════════════════════════════════
// HALAMAN 3 — Pilih Bahasa
// ═══════════════════════════════════════════════
class _PageLanguage extends StatelessWidget {
  final String selectedLang;
  final ValueChanged<String> onLangChanged;

  const _PageLanguage({
    super.key,
    required this.selectedLang,
    required this.onLangChanged,
  });

  static const _languages = [
    (code: 'id', flag: '🇮🇩', name: 'Bahasa Indonesia', subtitle: 'Gunakan aplikasi dalam Bahasa Indonesia'),
    (code: 'en', flag: '🇬🇧', name: 'English', subtitle: 'Use the app in English'),
    (code: 'jv', flag: '🏝️', name: 'Basa Jawa', subtitle: 'Nggunakake aplikasi nganggo Basa Jawa'),
    (code: 'ban', flag: '🌺', name: 'Basa Bali', subtitle: 'Ngangge aplikasi ring Basa Bali'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        children: [
          const Spacer(flex: 1),

          // Ikon globe
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3A59C7),
                  SigumiTheme.primaryBlue,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: SigumiTheme.primaryBlue.withAlpha(60),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.language_rounded,
              size: 36,
              color: Colors.white,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(
                begin: const Offset(0.5, 0.5),
                end: const Offset(1, 1),
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),

          const SizedBox(height: 22),

          // Judul
          Text(
            'Pilih Bahasa',
            style: AppFonts.plusJakartaSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: SigumiTheme.primaryBlue,
            ),
          )
              .animate()
              .fadeIn(delay: 200.ms, duration: 500.ms)
              .moveY(begin: 8, end: 0, delay: 200.ms, duration: 500.ms),

          const SizedBox(height: 6),

          Text(
            'Pilih bahasa yang ingin Anda gunakan\ndi dalam aplikasi SIGUMI.',
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 13,
              color: SigumiTheme.textSecondary,
              height: 1.5,
            ),
          )
              .animate()
              .fadeIn(delay: 300.ms, duration: 500.ms),

          const SizedBox(height: 28),

          // Kartu bahasa
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _languages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final lang = _languages[index];
                final isSelected = selectedLang == lang.code;
                return _LanguageCard(
                  flag: lang.flag,
                  name: lang.name,
                  subtitle: lang.subtitle,
                  isSelected: isSelected,
                  onTap: () => onLangChanged(lang.code),
                )
                    .animate()
                    .fadeIn(
                      delay: Duration(milliseconds: 400 + index * 90),
                      duration: 450.ms,
                    )
                    .slideX(
                      begin: index.isEven ? -0.08 : 0.08,
                      end: 0,
                      delay: Duration(milliseconds: 400 + index * 90),
                      duration: 450.ms,
                      curve: Curves.easeOutCubic,
                    );
              },
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? SigumiTheme.primaryBlue : SigumiTheme.divider,
            width: isSelected ? 1.8 : 1.0,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: SigumiTheme.primaryBlue.withAlpha(22),
                blurRadius: 16,
                offset: const Offset(0, 6),
              )
            else
              BoxShadow(
                color: Colors.black.withAlpha(7),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
          ],
        ),
        child: Row(
          children: [
            // Emoji bendera
            Text(flag, style: const TextStyle(fontSize: 28)),
            const SizedBox(width: 14),

            // Nama & deskripsi
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? SigumiTheme.primaryBlue
                          : SigumiTheme.textBody,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      color: SigumiTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Radio circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 280),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? SigumiTheme.primaryBlue : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? SigumiTheme.primaryBlue : SigumiTheme.divider,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
// DOT INDICATOR
// ═══════════════════════════════════════════════
class _DotIndicator extends StatelessWidget {
  final int total;
  final int current;

  const _DotIndicator({required this.total, required this.current});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(total, (i) {
        final isActive = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 26 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive
                ? SigumiTheme.primaryBlue
                : SigumiTheme.divider,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
