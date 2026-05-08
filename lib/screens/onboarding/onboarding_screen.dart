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
      imagePath: 'assets/onboarding/onboarding 1.png',
    ),
    OnboardingData(
      title: 'Status Real-time',
      description:
          'Dapatkan pemantauan aktivitas gunung berapi secara langsung dan instan berkat integrasi data MAGMA.',
      icon: Icons.sensors_rounded,
      color: SigumiTheme.accentYellow,
      imagePath: 'assets/onboarding/onboarding 2.png',
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
    Navigator.pushReplacementNamed(context, AppRoutes.main);
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
                  onPageChanged:
                      (index) => setState(() => _currentPage = index),
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
                          onTapDown:
                              (_) => setState(() => _isButtonPressed = true),
                          onTapUp:
                              (_) => setState(() => _isButtonPressed = false),
                          onTapCancel:
                              () => setState(() => _isButtonPressed = false),
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
                                  shadowColor: SigumiTheme.primaryBlue
                                      .withAlpha(100),
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
                        )
                        .animate(
                          target: _currentPage == _pages.length - 1 ? 1 : 0,
                        )
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
        color:
            isActive
                ? SigumiTheme.primaryBlue
                : SigumiTheme.primaryBlue.withAlpha(50),
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
  final String? imagePath;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.imagePath,
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
                  color: Colors.white.withAlpha(51),
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
                data.imagePath != null
                    ? Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                          maxHeight: MediaQuery.of(context).size.height * 0.35,
                        ),
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: data.color.withAlpha(20),
                              blurRadius: 40,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Image.asset(
                          data.imagePath!,
                          fit: BoxFit.contain,
                        ),
                      )
                        .animate()
                        .scale(duration: 800.ms, curve: Curves.elasticOut)
                        .fadeIn()
                    : Container(
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
                        child: Icon(data.icon, size: 80, color: data.color),
                      )
                        .animate()
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

    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Visual Icon (Clean and minimal)
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: data.color.withAlpha(20),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Icon(data.icon, size: 48, color: data.color),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 32),

              // Title
              Text(
                data.title,
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SigumiTheme.primaryBlue,
                  height: 1.2,
                ),
              ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 16),

              // Description
              Text(
                data.description,
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                  fontSize: 16,
                  color: SigumiTheme.textBody.withAlpha(180),
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0),

              const SizedBox(height: 48),

              // Language List
              Column(
                children: [
                  _LangCard(
                    title: 'Bahasa Indonesia',
                    code: 'id',
                    isSelected: provider.language == 'id',
                  ),
                  const SizedBox(height: 12),
                  _LangCard(
                    title: 'English (US)',
                    code: 'en',
                    isSelected: provider.language == 'en',
                  ),
                  const SizedBox(height: 12),
                  _LangCard(
                    title: 'Basa Jawa',
                    code: 'jv',
                    isSelected: provider.language == 'jv',
                  ),
                  const SizedBox(height: 12),
                  _LangCard(
                    title: 'Basa Bali',
                    code: 'ba',
                    isSelected: provider.language == 'ba',
                  ),
                  const SizedBox(height: 12),
                  _LangCard(
                    title: 'Basa Sasak',
                    code: 'sa',
                    isSelected: provider.language == 'sa',
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatefulWidget {
  final String title;
  final String code;
  final bool isSelected;

  const _LangCard({
    required this.title,
    required this.code,
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
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: widget.isSelected 
                ? SigumiTheme.primaryBlue.withAlpha(15) 
                : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isSelected
                  ? SigumiTheme.primaryBlue
                  : SigumiTheme.divider.withAlpha(40),
              width: widget.isSelected ? 2.0 : 1.0,
            ),
            boxShadow: [
              if (!widget.isSelected)
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                widget.title,
                style: AppFonts.plusJakartaSans(
                  fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: widget.isSelected ? SigumiTheme.primaryBlue : SigumiTheme.textPrimary,
                  fontSize: 16,
                ),
              ),
              Icon(
                widget.isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: widget.isSelected ? SigumiTheme.primaryBlue : SigumiTheme.textSecondary.withAlpha(100),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

