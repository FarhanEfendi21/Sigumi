import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isButtonPressed = false;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: 'Selamat Datang di SIGUMI',
      description:
          'Sistem Informasi Gunung Berapi & Mitigasi Bencana yang membantu Anda tetap aman dan terinformasi.',
      icon: Icons.volcano_rounded,
      color: SigumiTheme.primaryBlue,
    ),
    OnboardingData(
      title: 'Status Real-time',
      description:
          'Dapatkan pemantauan aktivitas gunung berapi secara langsung dan instan berkat integrasi data MAGMA.',
      icon: Icons.sensors_rounded,
      color: SigumiTheme.accentYellow,
    ),
    OnboardingData(
      title: 'Pilih Bahasa Anda',
      description:
          'SIGUMI mendukung berbagai bahasa daerah untuk memudahkan akses informasi bagi semua kalangan.',
      icon: Icons.translate_rounded,
      color: SigumiTheme.primaryBlue,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNext() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _finishOnboarding() {
    context.read<VolcanoProvider>().completeOnboarding();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: SigumiTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // Skip button
              if (_currentPage < _pages.length - 1)
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: _finishOnboarding,
                    child: Text(
                      'Lewati',
                      style: AppFonts.plusJakartaSans(
                        color: SigumiTheme.primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(duration: 400.ms)
              else
                const SizedBox(height: 48),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    if (index == 2) {
                      return _LanguageSelectionPage(data: _pages[index]);
                    }
                    return _OnboardingPage(data: _pages[index]);
                  },
                ),
              ),

              // Bottom section
              Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    // Indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (index) => _buildIndicator(index),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next/Mulai Button
                    GestureDetector(
                      onTapDown: (_) => setState(() => _isButtonPressed = true),
                      onTapUp: (_) => setState(() => _isButtonPressed = false),
                      onTapCancel: () => setState(() => _isButtonPressed = false),
                      child: AnimatedScale(
                        scale: _isButtonPressed ? 0.97 : 1,
                        duration: const Duration(milliseconds: 100),
                        child: SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _onNext,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: SigumiTheme.primaryBlue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 8,
                              shadowColor: SigumiTheme.primaryBlue.withAlpha(100),
                            ),
                            child: Text(
                              _currentPage == _pages.length - 1
                                  ? 'Mulai Sekarang'
                                  : 'Lanjutkan',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ).animate(target: _currentPage == _pages.length - 1 ? 1 : 0)
                     .shimmer(delay: 2.seconds, duration: 1.5.seconds),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIndicator(int index) {
    bool isActive = _currentPage == index;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 6,
      width: isActive ? 20 : 6,
      decoration: BoxDecoration(
        color: isActive ? SigumiTheme.primaryBlue : SigumiTheme.primaryBlue.withAlpha(50),
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class _OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle Layer Decoration
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withAlpha(50),
                  Colors.white.withAlpha(10),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.2),
                  blurRadius: 40,
                  spreadRadius: -10,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Visual Element
                Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: data.color.withAlpha(30),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Icon(
                    data.icon,
                    size: 80,
                    color: data.color,
                  ),
                ).animate()
                 .scale(duration: 800.ms, curve: Curves.elasticOut)
                 .fadeIn()
                 .shake(delay: 1.seconds, hz: 2, offset: const Offset(2, 2)),

                const SizedBox(height: 48),

                // Text content
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: SigumiTheme.primaryBlue,
                    height: 1.2,
                  ),
                ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

                const SizedBox(height: 16),

                Text(
                  data.description,
                  textAlign: TextAlign.center,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 16,
                    color: SigumiTheme.textBody.withAlpha(180),
                    height: 1.6,
                  ),
                ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageSelectionPage extends StatelessWidget {
  final OnboardingData data;

  const _LanguageSelectionPage({required this.data});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VolcanoProvider>();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withAlpha(50),
              Colors.white.withAlpha(10),
            ],
          ),
          borderRadius: BorderRadius.circular(40),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withOpacity(0.2),
              blurRadius: 40,
              spreadRadius: -10,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data.title,
              style: AppFonts.plusJakartaSans(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: SigumiTheme.primaryBlue,
              ),
            ).animate().fadeIn().moveY(begin: -20, end: 0),
            
            const SizedBox(height: 12),
            
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: SigumiTheme.textSecondary,
              ),
            ).animate().fadeIn(delay: 100.ms),
            
            const SizedBox(height: 32),
            
            // Language Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _LangCard(
                  title: 'Indonesia',
                  subtitle: 'Bahasa Indonesia',
                  code: 'id',
                  flag: '🇮🇩',
                  isSelected: provider.language == 'id',
                ),
                _LangCard(
                  title: 'English',
                  subtitle: 'English (US)',
                  code: 'en',
                  flag: '🇺🇸',
                  isSelected: provider.language == 'en',
                ),
                _LangCard(
                  title: 'Jawa',
                  subtitle: 'Basa Jawa',
                  code: 'jv',
                  flag: '🏯', 
                  isSelected: provider.language == 'jv',
                ),
                _LangCard(
                  title: 'Bali',
                  subtitle: 'Basa Bali',
                  code: 'bal',
                  flag: '🏝️', 
                  isSelected: provider.language == 'bal',
                ),
              ],
            ).animate().fadeIn(delay: 300.ms).scale(begin: const Offset(0.9, 0.9)),
          ],
        ),
      ),
    );
  }
}

class _LangCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final String code;
  final String flag;
  final bool isSelected;

  const _LangCard({
    required this.title,
    required this.subtitle,
    required this.code,
    required this.flag,
    required this.isSelected,
  });

  @override
  State<_LangCard> createState() => _LangCardState();
}

class _LangCardState extends State<_LangCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: () => context.read<VolcanoProvider>().setLanguage(widget.code),
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          decoration: BoxDecoration(
            color: widget.isSelected ? SigumiTheme.primaryBlue : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.isSelected
                  ? SigumiTheme.primaryBlue
                  : SigumiTheme.divider.withAlpha(100),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.isSelected
                    ? SigumiTheme.primaryBlue.withAlpha(80)
                    : Colors.black.withAlpha(20),
                blurRadius: widget.isSelected ? 20 : 10,
                spreadRadius: widget.isSelected ? 2 : 0,
                offset: widget.isSelected ? const Offset(0, 10) : const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(widget.flag, style: const TextStyle(fontSize: 32)),
              const SizedBox(height: 8),
              Text(
                widget.title,
                style: AppFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  color: widget.isSelected ? Colors.white : SigumiTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              Text(
                widget.subtitle,
                style: AppFonts.plusJakartaSans(
                  fontWeight: FontWeight.w400,
                  color: widget.isSelected
                      ? Colors.white.withAlpha(200)
                      : SigumiTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
