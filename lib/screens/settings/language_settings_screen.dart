import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme_extensions.dart';
import '../../providers/volcano_provider.dart';
import '../../services/localization_service.dart';

class LanguageSettingsScreen extends StatelessWidget {
  const LanguageSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final currentLanguage = provider.language;

        return Scaffold(
          backgroundColor: context.bgPrimary,
          appBar: AppBar(
            backgroundColor: context.bgSurface,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: context.textPrimary,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              context.tr('choose_language'),
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.textPrimary,
              ),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(context, context.tr('available_languages')),
                const SizedBox(height: 16),
                _LanguageOptionCard(
                      title: context.tr('lang_id'),
                      subtitle: context.tr('lang_id_sub'),
                      flag: '🇮🇩',
                      isSelected: currentLanguage == 'id',
                      onTap: () => provider.setLanguage('id'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 12),
                _LanguageOptionCard(
                      title: 'English',
                      subtitle: context.tr('lang_en_sub'),
                      flag: '🇬🇧',
                      isSelected: currentLanguage == 'en',
                      onTap: () => provider.setLanguage('en'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 50.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 12),
                _LanguageOptionCard(
                      title: context.tr('lang_jv'),
                      subtitle: context.tr('lang_jv_sub'),
                      flag: '☕',
                      isSelected: currentLanguage == 'jv',
                      onTap: () => provider.setLanguage('jv'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 12),
                _LanguageOptionCard(
                      title: context.tr('lang_ba'),
                      subtitle: context.tr('lang_ba_sub'),
                      flag: '🌴',
                      isSelected: currentLanguage == 'ba',
                      onTap: () => provider.setLanguage('ba'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 150.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 12),
                _LanguageOptionCard(
                      title: context.tr('lang_sa'),
                      subtitle: context.tr('lang_sa_sub'),
                      flag: '🏔️',
                      isSelected: currentLanguage == 'sa',
                      onTap: () => provider.setLanguage('sa'),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 200.ms)
                    .slideX(begin: -0.05, end: 0),
                const SizedBox(height: 32),
                _buildInfoNote(context),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: AppFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: context.textTertiary,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildInfoNote(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.accentPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: context.accentPrimary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              context.tr('language_note'),
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                height: 1.5,
                color: context.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _LanguageOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageOptionCard({
    required this.title,
    required this.subtitle,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.bgSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? context.accentPrimary : context.borderColor,
              width: 2,
            ),
            boxShadow: [
              ...context.cardShadow,
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color:
                      isSelected
                          ? context.accentPrimary.withValues(alpha: 0.12)
                          : context.bgSecondary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(flag, style: const TextStyle(fontSize: 28)),
                ),
              ),
              const SizedBox(width: 16),
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
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppFonts.plusJakartaSans(
                        fontSize: 12,
                        color: context.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Checkmark / Radio indicator
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      isSelected ? context.accentPrimary : Colors.transparent,
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
                          Icons.check,
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
      ),
    );
  }
}
