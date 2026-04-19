import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: const Color(
            0xFFF8FAFC,
          ), // Modern off-white background
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Profil',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E1E2C),
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Profile header card
                    _buildProfileCard(context, provider),
                    const SizedBox(height: 32),

                    // Group 1: Preferensi
                    _buildSectionHeader('Preferensi Akun'),
                    const SizedBox(height: 12),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: Icons.accessibility_new_rounded,
                        title: 'Aksesibilitas',
                        subtitle: 'Ukuran teks, kontras, audio',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.accessibility,
                            ),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Bahasa',
                        subtitle:
                            provider.language == 'en'
                                ? 'English'
                                : 'Bahasa Indonesia',
                        onTap:
                            () => Navigator.pushNamed(
                              context,
                              AppRoutes.languageSettings,
                            ),
                      ),
                    ]),
                    const SizedBox(height: 28),

                    // Group 2: Sistem & Aplikasi
                    _buildSectionHeader('Sistem & Aplikasi'),
                    const SizedBox(height: 12),
                    _buildSettingsGroup([
                      _SettingsTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notifikasi',
                        subtitle: 'Atur peringatan dini & notifikasi',
                        onTap: () {},
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.cloud_off_rounded,
                        title: 'Data Offline',
                        subtitle:
                            provider.isOffline
                                ? 'Mode offline aktif'
                                : 'Mode online',
                        trailing: Switch(
                          value: provider.isOffline,
                          onChanged: (_) => provider.toggleOffline(),
                          activeThumbColor: Colors.white,
                          activeTrackColor: SigumiTheme.primaryBlue,
                          inactiveTrackColor: Colors.grey.shade300,
                          inactiveThumbColor: Colors.white,
                        ),
                        onTap: () => provider.toggleOffline(),
                      ),
                      _buildDivider(),
                      _SettingsTile(
                        icon: Icons.info_outline_rounded,
                        title: 'Tentang SIGUMI',
                        subtitle: 'Versi 1.0.0',
                        onTap: () => _showAbout(context),
                      ),
                    ]),

                    const SizedBox(height: 48),
                    // Logout Button
                    _buildLogoutButton(context),
                    const SizedBox(height: 80),
                  ],
                )
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, curve: Curves.easeOutQuart),
          ),
        );
      },
    );
  }

  Widget _buildProfileCard(BuildContext context, VolcanoProvider provider) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2E7B).withAlpha(12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: SigumiTheme.primaryBlue.withAlpha(40),
                width: 2,
              ),
            ),
            child: const CircleAvatar(
              radius: 46,
              backgroundColor: SigumiTheme.primaryLight,
              child: Icon(
                Icons.person_rounded,
                size: 48,
                color: SigumiTheme.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Pengguna SIGUMI',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: SigumiTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'pengguna@sigumi.id',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: SigumiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withAlpha(20),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.verified_user_rounded,
                  size: 16,
                  color: SigumiTheme.primaryBlue,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bahasa: ${provider.language == "en" ? "English" : "Indonesia"}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: SigumiTheme.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: Color(0xFF64748B), // Fallback colors for textTertiary
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2E7B).withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF1B2E7B).withAlpha(15)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 64, // Align with text
      color: Colors.grey.withAlpha(30),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder:
                (_) => AlertDialog(
                  backgroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  title: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFF0F0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: Color(0xFFD32F2F),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Keluar Akun',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: SigumiTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  content: const Text(
                    'Apakah Anda yakin ingin keluar dari akun SIGUMI Anda?',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: SigumiTheme.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: SigumiTheme.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pushReplacementNamed(
                          context,
                          AppRoutes.login,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFD32F2F),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                      ),
                      child: const Text(
                        'Ya, Keluar',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        splashColor: const Color(0xFFD32F2F).withAlpha(30),
        highlightColor: const Color(0xFFD32F2F).withAlpha(15),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF0F0),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFD32F2F).withAlpha(30),
              width: 1.5,
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout_rounded, color: Color(0xFFD32F2F), size: 24),
              SizedBox(width: 12),
              Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFFD32F2F),
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              'Tentang SIGUMI',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w800,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'SIGUMI adalah Sistem Informasi Gunung Berapi Mitigasi yang memberikan informasi terpercaya.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: SigumiTheme.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Versi 1.0.0',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700,
                      color: SigumiTheme.primaryBlue,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: SigumiTheme.primaryBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tutup',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: SigumiTheme.primaryBlue, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: SigumiTheme.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: SigumiTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFFCBD5E1), // Slate 300
                  size: 26,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
