import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../config/theme.dart';
import '../../providers/volcano_provider.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final isHighContrast = provider.highContrast;
        final bgColor = isHighContrast ? SigumiTheme.hcBackground : Colors.white;
        final surfaceColor = isHighContrast ? SigumiTheme.hcSurface : Colors.white;
        final primaryTextColor = isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF1E1E2C);
        final secondaryTextColor = isHighContrast ? SigumiTheme.hcPrimary : const Color(0xFF4B4B5A);
        final tertiaryTextColor = isHighContrast ? SigumiTheme.hcDivider : const Color(0xFF6B6B78);
        final borderColor = isHighContrast ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB);
        final accentColor = isHighContrast ? SigumiTheme.hcSecondary : SigumiTheme.primaryBlue;
        
        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: surfaceColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: primaryTextColor),
            title: Text(
              'Aksesibilitas Eksklusif',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: primaryTextColor,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(color: borderColor, height: isHighContrast ? 2 : 1),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Info Section ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isHighContrast 
                        ? SigumiTheme.hcSurface 
                        : SigumiTheme.primaryBlue.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isHighContrast 
                          ? SigumiTheme.hcBorder 
                          : SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                      width: isHighContrast ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isHighContrast 
                              ? SigumiTheme.hcSecondary 
                              : SigumiTheme.primaryBlue.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.accessibility_new_rounded,
                          color: isHighContrast 
                              ? SigumiTheme.hcBackground 
                              : SigumiTheme.primaryBlue,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'SIGUMI dirancang inklusif untuk semua pengguna demi keselamatan bersama.',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

                const SizedBox(height: 32),

                // ── Visual Section ──
                _buildSectionHeader(
                  'Tampilan Visual',
                  Icons.visibility_outlined,
                  tertiaryTextColor,
                ),
                const SizedBox(height: 16),

                _SettingsCard(
                  isHighContrast: isHighContrast,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Ukuran Teks',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: primaryTextColor,
                            ),
                          ),
                          Text(
                            '${(provider.fontSize * 100).toInt()}%',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: accentColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Text(
                            'A',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: tertiaryTextColor,
                            ),
                          ),
                          Expanded(
                            child: ShadSlider(
                              initialValue: provider.fontSize,
                              min: 0.8,
                              max: 1.5,
                              onChanged: (v) => provider.setFontSize(v),
                            ),
                          ),
                          Text(
                            'A',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: primaryTextColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Review Teks Dinamis',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14 * provider.fontSize,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 12),

                _SettingsCard(
                  isHighContrast: isHighContrast,
                  child: Row(
                    children: [
                      Icon(
                        Icons.contrast_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kontras Tinggi',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              'Optimalkan keterbacaan warna',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: tertiaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ShadSwitch(
                        value: provider.highContrast,
                        onChanged: (v) => provider.setHighContrast(v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const SizedBox(height: 32),

                // ── Bantuan Suara Section ──
                _buildSectionHeader('Bantuan Suara', Icons.volume_up_outlined, tertiaryTextColor),
                const SizedBox(height: 16),

                _SettingsCard(
                  isHighContrast: isHighContrast,
                  child: Row(
                    children: [
                      Icon(
                        Icons.record_voice_over_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Panduan Audio',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor,
                              ),
                            ),
                            Text(
                              'Narasi otomatis teks penting',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                color: tertiaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ShadSwitch(
                        value: provider.audioGuidance,
                        onChanged: (v) => provider.setAudioGuidance(v),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),

                // ── Sistem Section ──
                _buildSectionHeader('Sistem', Icons.settings_outlined, tertiaryTextColor),
                const SizedBox(height: 16),

                _SettingsCard(
                  isHighContrast: isHighContrast,
                  child: Row(
                    children: [
                      Icon(
                        Icons.language_rounded,
                        color: accentColor,
                        size: 22,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          'Bahasa Aplikasi',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: primaryTextColor,
                          ),
                        ),
                      ),
                      ShadSelect<String>(
                        placeholder: const Text('Pilih Bahasa'),
                        initialValue: provider.language,
                        onChanged: (v) => provider.setLanguage(v!),
                        selectedOptionBuilder: (context, value) {
                          String displayText = 'Indonesia';
                          switch (value.toLowerCase()) {
                            case 'id':
                              displayText = 'Indonesia';
                              break;
                            case 'en':
                              displayText = 'English';
                              break;
                            case 'jv':
                              displayText = 'Basa Jawa';
                              break;
                            case 'ba':
                              displayText = 'Basa Bali';
                              break;
                            case 'sa':
                              displayText = 'Basa Sasak';
                              break;
                          }
                          return Text(
                            displayText,
                            style: AppFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          );
                        },
                        options: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(32, 6, 6, 6),
                            child: Text(
                              'Pilih Bahasa',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B6B78),
                              ),
                            ),
                          ),
                          ShadOption(
                            value: 'id',
                            child: Text(
                              'Bahasa Indonesia',
                              style: AppFonts.plusJakartaSans(),
                            ),
                          ),
                          ShadOption(
                            value: 'en',
                            child: Text(
                              'English',
                              style: AppFonts.plusJakartaSans(),
                            ),
                          ),
                          ShadOption(
                            value: 'jv',
                            child: Text(
                              'Basa Jawa',
                              style: AppFonts.plusJakartaSans(),
                            ),
                          ),
                          ShadOption(
                            value: 'ba',
                            child: Text(
                              'Basa Bali',
                              style: AppFonts.plusJakartaSans(),
                            ),
                          ),
                          ShadOption(
                            value: 'sa',
                            child: Text(
                              'Basa Sasak',
                              style: AppFonts.plusJakartaSans(),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 40),

                // ── Footer ──
                Center(
                  child: Text(
                    'Versi Inklusif 1.0.0',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: tertiaryTextColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: AppFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1.0,
          ),
        ),
      ],
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final Widget child;
  final bool isHighContrast;
  
  const _SettingsCard({
    required this.child, 
    this.isHighContrast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isHighContrast ? SigumiTheme.hcSurface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast ? SigumiTheme.hcBorder : const Color(0xFFE5E7EB),
          width: isHighContrast ? 2 : 1,
        ),
        boxShadow: isHighContrast ? [] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
