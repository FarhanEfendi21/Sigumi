import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';

/// Halaman Profil — mengikuti pedoman Apple Human Interface Guidelines (HIG).
///
/// Prinsip yang diterapkan:
/// - Hierarki visual yang jelas (hero → sections → actions)
/// - Grouped list ala iOS (latar belakang, divider inset, corner radius)
/// - Tipografi yang bersih dengan ukuran & weight yang terstruktur
/// - Spacing dan padding yang konsisten (8pt grid)
/// - Warna minimal: hanya aksen primer + abu-abu sistem
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  // ── Konstanta warna ──────────────────────────────────────────────
  static const _bgColor = Color(0xFFF2F2F7); // iOS systemGroupedBackground
  static const _surfaceColor = Colors.white;
  static const _labelPrimary = Color(0xFF1E1E2C); // iOS label
  static const _labelSecondary = Color(0xFF8E8E93); // iOS secondaryLabel
  static const _labelTertiary = Color(0xFFAEAEB2); // iOS tertiaryLabel
  static const _separatorColor = Color(0xFFE5E5EA); // iOS separator
  static const _destructiveRed = Color(0xFFFF3B30); // iOS systemRed

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: _bgColor,
          // Gunakan transparent AppBar ala iOS — judul muncul di body
          appBar: AppBar(
            backgroundColor: _bgColor,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              context.tr('nav_profile'),
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: _labelPrimary,
                fontSize: 18,
              ),
            ),
          ),
          body: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── 1. Hero Profil ─────────────────────────────────
                _ProfileHero(provider: provider)
                    .animate()
                    .fadeIn(duration: 350.ms, curve: Curves.easeOut)
                    .slideY(
                      begin: 0.04,
                      end: 0,
                      duration: 350.ms,
                      curve: Curves.easeOut,
                    ),

                const SizedBox(height: 32),

                // ── 2. Section: Preferensi Akun ────────────────────
                _SectionHeader(label: context.tr('account_pref')),
                _GroupedList(
                  children: [
                    _ListRow(
                      icon: CupertinoIcons.person_alt,
                      iconBg: const Color(0xFF007AFF),
                      title: context.tr('accessibility'),
                      subtitle: context.tr('text_size'),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.accessibility,
                          ),
                    ),
                    _ListDivider(),
                    _ListRow(
                      icon: CupertinoIcons.globe,
                      iconBg: const Color(0xFF34C759),
                      title: context.tr('language'),
                      subtitle: _getLanguageName(provider.language),
                      onTap:
                          () => Navigator.pushNamed(
                            context,
                            AppRoutes.languageSettings,
                          ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── 3. Section: Sistem & Aplikasi ──────────────────
                _SectionHeader(label: context.tr('system_app')),
                _GroupedList(
                  children: [
                    _ListRow(
                      icon: CupertinoIcons.bell,
                      iconBg: const Color(0xFFFF9500),
                      title: context.tr('notification'),
                      subtitle: context.tr('notif_subtitle'),
                      onTap: () {},
                    ),
                    _ListDivider(),
                    _OfflineRow(provider: provider),
                    _ListDivider(),
                    _ListRow(
                      icon: CupertinoIcons.info_circle,
                      iconBg: const Color(0xFF8E8E93),
                      title: context.tr('about_sigumi'),
                      subtitle: context.tr('version'),
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // ── 4. Tombol Keluar ────────────────────────────────
                _GroupedList(
                  children: [_LogoutRow(onTap: () => _confirmLogout(context))],
                ),

                // Spacer untuk bottom nav
                const SizedBox(height: 96),
              ],
            ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
          ),
        );
      },
    );
  }

  // ── Dialog konfirmasi logout ──────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(
              context.tr('logout_confirm_title'),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                context.tr('logout_confirm_msg'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: Text(
                  context.tr('cancel'),
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text(
                  context.tr('logout'),
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () async {
                  try {
                    await context.read<AuthProvider>().logout();
                    if (context.mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Gagal keluar: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
    );
  }

  // ── Dialog tentang SIGUMI ─────────────────────────────────────────
  void _showAbout(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            title: Text(
              context.tr('about_sigumi'),
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            message: Text(
              context.tr('about_desc'),
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.6,
              ),
            ),
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                context.tr('close'),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
    );
  }

  // ── Helper untuk mendapatkan nama bahasa ─────────────────────────
  String _getLanguageName(String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'id':
        return 'Bahasa Indonesia';
      case 'en':
        return 'English';
      case 'jv':
        return 'Basa Jawa';
      case 'ba':
        return 'Basa Bali';
      case 'sa':
        return 'Basa Sasak';
      default:
        return 'Bahasa Indonesia';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HERO PROFIL
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileHero extends StatelessWidget {
  final VolcanoProvider provider;

  const _ProfileHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final name =
        provider.currentUser?.name.isNotEmpty == true
            ? provider.currentUser!.name
            : 'Pengguna SIGUMI';

    final contact =
        provider.currentUser?.phone?.isNotEmpty == true
            ? provider.currentUser!.phone!
            : (provider.currentUser?.email ?? '—');

    // Ambil inisial untuk avatar
    final initials =
        name
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      decoration: BoxDecoration(
        color: SettingsScreen._surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // ── Avatar ──
          _AvatarWidget(initials: initials),
          const SizedBox(width: 16),

          // ── Info nama & kontak ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: SettingsScreen._labelPrimary,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  contact,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: SettingsScreen._labelSecondary,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),

                // ── Badge bahasa ──
                _LanguageBadge(language: provider.language),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widget avatar dengan inisial ─────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  final String initials;

  const _AvatarWidget({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1B3FA0), // sedikit lebih terang dari primaryBlue
            Color(0xFF0D2060), // lebih gelap
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: SigumiTheme.primaryBlue.withAlpha(45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}

// ── Badge bahasa ──────────────────────────────────────────────────────────────
class _LanguageBadge extends StatelessWidget {
  final String language;

  const _LanguageBadge({required this.language});

  @override
  Widget build(BuildContext context) {
    final label = switch (language.toLowerCase()) {
      'en' => '🇬🇧  English',
      'jv' => '☕  Basa Jawa',
      'ba' => '🌴  Basa Bali',
      'sa' => '🏔️  Basa Sasak',
      _ => '🇮🇩  Indonesia',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: SettingsScreen._bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SettingsScreen._labelSecondary,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// KOMPONEN GROUPED LIST (bergaya iOS)
// ══════════════════════════════════════════════════════════════════════════════

/// Header section dengan label huruf besar ala iOS Settings
class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 32, bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: SettingsScreen._labelSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Container berisi satu grup settings berwarna putih dengan corner radius
class _GroupedList extends StatelessWidget {
  final List<Widget> children;

  const _GroupedList({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: SettingsScreen._surfaceColor,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Garis pemisah inset (tidak menyentuh tepi kiri — mengikuti letak ikon)
class _ListDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 0.5,
      indent: 58, // rata dengan teks, setelah ikon 36 + margin 14 + gap 8
      color: SettingsScreen._separatorColor,
    );
  }
}

/// Satu baris setting generik dengan ikon berwarna, judul, subtitle, dan chevron
class _ListRow extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ListRow({
    required this.icon,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: SettingsScreen._separatorColor.withAlpha(60),
        highlightColor: SettingsScreen._bgColor.withAlpha(120),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Ikon dengan latar berwarna (ala iOS Settings)
              _IconBadge(icon: icon, background: iconBg),
              const SizedBox(width: 12),

              // Teks
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: SettingsScreen._labelPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: SettingsScreen._labelSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron navigasi
              const Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: SettingsScreen._labelTertiary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Badge ikon berwarna bulat sudut — identik dengan ikon aplikasi iOS Settings
class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color background;

  const _IconBadge({required this.icon, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: Colors.white, size: 17),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// BARIS KHUSUS
// ══════════════════════════════════════════════════════════════════════════════

/// Baris Data Offline dengan CupertinoSwitch asli
class _OfflineRow extends StatelessWidget {
  final VolcanoProvider provider;

  const _OfflineRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          _IconBadge(
            icon: CupertinoIcons.wifi_slash,
            background: const Color(0xFF5856D6), // iOS purple
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Data Offline',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: SettingsScreen._labelPrimary,
                    letterSpacing: -0.2,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  provider.isOffline
                      ? 'Mode offline aktif'
                      : 'Menggunakan data online',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: SettingsScreen._labelSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          // CupertinoSwitch untuk tampilan yang tumpah/tepat seperti iOS
          CupertinoSwitch(
            value: provider.isOffline,
            activeTrackColor: SigumiTheme.primaryBlue,
            onChanged: (_) => provider.toggleOffline(),
          ),
        ],
      ),
    );
  }
}

/// Baris keluar dengan teks merah tanpa ikon tambahan — simpel dan tegas
class _LogoutRow extends StatelessWidget {
  final VoidCallback onTap;

  const _LogoutRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: SettingsScreen._destructiveRed.withAlpha(20),
        highlightColor: SettingsScreen._destructiveRed.withAlpha(10),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.square_arrow_left,
                size: 19,
                color: SettingsScreen._destructiveRed,
              ),
              SizedBox(width: 8),
              Text(
                'Keluar',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: SettingsScreen._destructiveRed,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
