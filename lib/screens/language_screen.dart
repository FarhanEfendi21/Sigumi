import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/theme_extensions.dart';
import '../config/routes.dart';
import '../providers/volcano_provider.dart';
import '../services/localization_service.dart';

class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  String _selected = 'en';

  void _proceed() {
    context.read<VolcanoProvider>().setLanguage(_selected);
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgPrimary,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: context.isHighContrast
            ? BoxDecoration(color: context.bgPrimary)
            : SigumiTheme.backgroundGradient,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Globe icon
                Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: context.accentPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        size: 44,
                        color: context.accentPrimary,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .scale(
                      begin: const Offset(0.5, 0.5),
                      end: const Offset(1, 1),
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                const SizedBox(height: 28),

                // Title
                Text(
                  context.tr('choose_language'),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: context.accentPrimary,
                  ),
                ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                const SizedBox(height: 6),

                Text(
                  context.tr('choose_language'),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 15,
                    color: context.textSecondary,
                  ),
                ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                const SizedBox(height: 40),

                // Language cards
                _LanguageCard(
                      flag: '🇬🇧',
                      title: 'English',
                      subtitle: context.tr('lang_en_sub'),
                      isSelected: _selected == 'en',
                      onTap: () => setState(() => _selected = 'en'),
                    )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                _LanguageCard(
                      flag: '🇮🇩',
                      title: context.tr('lang_id'),
                      subtitle: context.tr('lang_id_sub'),
                      isSelected: _selected == 'id',
                      onTap: () => setState(() => _selected = 'id'),
                    )
                    .animate()
                    .fadeIn(delay: 420.ms, duration: 500.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                _LanguageCard(
                      flag: '☕',
                      title: context.tr('lang_jv'),
                      subtitle: context.tr('lang_jv_sub'),
                      isSelected: _selected == 'jv',
                      onTap: () => setState(() => _selected = 'jv'),
                    )
                    .animate()
                    .fadeIn(delay: 490.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),

                const SizedBox(height: 12),

                _LanguageCard(
                      flag: '🌴',
                      title: context.tr('lang_ba'),
                      subtitle: context.tr('lang_ba_sub'),
                      isSelected: _selected == 'ba',
                      onTap: () => setState(() => _selected = 'ba'),
                    )
                    .animate()
                    .fadeIn(delay: 560.ms, duration: 500.ms)
                    .slideX(begin: 0.1, end: 0),

                const SizedBox(height: 12),

                _LanguageCard(
                      flag: '🏔️',
                      title: context.tr('lang_sa'),
                      subtitle: context.tr('lang_sa_sub'),
                      isSelected: _selected == 'sa',
                      onTap: () => setState(() => _selected = 'sa'),
                    )
                    .animate()
                    .fadeIn(delay: 630.ms, duration: 500.ms)
                    .slideX(begin: -0.1, end: 0),

                const Spacer(flex: 2),

                // Continue button
                SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: context.isHighContrast ? null : const LinearGradient(
                            colors: [
                              SigumiTheme.primaryBlue,
                              Color(0xFF2A3E9A),
                            ],
                          ),
                          color: context.isHighContrast
                              ? context.accentPrimary
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: SigumiTheme.primaryBlue.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _proceed,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: context.isHighContrast
                                ? context.bgPrimary
                                : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _selected == 'en' ? context.tr('continue') : context.tr('continue'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                        ),
                      ),
                    )
                    .animate()
                    .fadeIn(delay: 550.ms, duration: 500.ms)
                    .slideY(begin: 0.2, end: 0),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String flag;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.flag,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? context.accentPrimary : context.borderColor,
            width: context.borderWidth,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: SigumiTheme.primaryBlue.withAlpha(25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            else
              BoxShadow(
                color: Colors.black.withAlpha(8),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Row(
          children: [
            // Flag
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color:
                          isSelected
                              ? context.accentPrimary
                              : context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            // Checkmark
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color:
                    isSelected ? context.accentPrimary : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected
                          ? context.accentPrimary
                          : context.borderColor,
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? Icon(
                        Icons.check_rounded,
                        color: context.isHighContrast
                            ? context.bgPrimary
                            : Colors.white,
                        size: 16,
                      )
                      : null,
            ),
          ],
        ),
      ),
    );
  }
}
