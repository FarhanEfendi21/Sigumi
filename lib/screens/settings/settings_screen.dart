import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/routes.dart';
import '../../config/theme_extensions.dart';
import '../../providers/volcano_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/localization_service.dart';
import 'package:flutter/services.dart';
import '../../services/vibration_alert_service.dart';
import '../../services/notification_service.dart';

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
  static const _labelPrimary = Color(0xFF1E1E2C); // iOS label
  static const _labelSecondary = Color(0xFF8E8E93); // iOS secondaryLabel
  static const _labelTertiary = Color(0xFFAEAEB2); // iOS tertiaryLabel

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        // ── Guest Mode: tampilkan halaman khusus ──────────────────
        if (provider.isGuest) {
          return const _GuestProfileView();
        }

        return Scaffold(
          backgroundColor: context.bgSecondary,
          // Gunakan transparent AppBar ala iOS — judul muncul di body
          appBar: AppBar(
            backgroundColor: context.bgSecondary,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            title: Text(
              context.tr('nav_profile'),
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                color: context.textPrimary,
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

                // ── 2. Section: Keamanan Akun ───────────────────────
                _SectionHeader(label: context.tr('account_security')),
                _GroupedList(
                  children: [
                    _ListRow(
                      icon: CupertinoIcons.lock,
                      iconBg: const Color(0xFFFF9500),
                      title: context.tr('reset_password'),
                      subtitle: context.tr('reset_password_subtitle'),
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.forgotPassword,
                        arguments: {'fromProfile': true},
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

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
                    _ListRow(
                      icon: CupertinoIcons.globe,
                      iconBg: context.adaptUiColor(const Color(0xFF34C759)),
                      title: context.tr('language'),
                      subtitle: _getLanguageName(context, provider.language),
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
                    const _NotificationRow(),
                    _ListDivider(),
                    const _VibrationAlertRow(),
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

                // Ruang gulir melewati navbar (tinggi 72 + padding 16) dengan
                // jarak ekstra 24 px, sekaligus mengikuti inset bawah perangkat.
                SizedBox(height: 112 + MediaQuery.paddingOf(context).bottom),
              ],
            ).animate().fadeIn(duration: 300.ms, curve: Curves.easeOut),
          ),
        );
      },
    );
  }

  // ── Dialog konfirmasi logout ──────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    // Gunakan read (bukan watch) karena dipanggil di luar build()
    final lang = context.read<VolcanoProvider>().language;
    final confirmTitle = LocalizationService.translate('logout_confirm_title', lang);
    final confirmMsg = LocalizationService.translate('logout_confirm_msg', lang);
    final cancelLabel = LocalizationService.translate('cancel', lang);
    final logoutLabel = LocalizationService.translate('logout', lang);

    showCupertinoDialog(
      context: context,
      builder:
          (_) => CupertinoAlertDialog(
            title: Text(
              confirmTitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                confirmMsg,
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
                  cancelLabel,
                  style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                ),
                onPressed: () => Navigator.pop(context),
              ),
              CupertinoDialogAction(
                isDestructiveAction: true,
                child: Text(
                  logoutLabel,
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
                        SnackBar(content: Text('${context.trSafe('logout_failed')}$e')),
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
    // Gunakan read (bukan watch) karena dipanggil di luar build()
    final lang = context.read<VolcanoProvider>().language;
    final aboutTitle = LocalizationService.translate('about_sigumi', lang);
    final aboutDesc = LocalizationService.translate('about_desc', lang);
    final closeLabel = LocalizationService.translate('close', lang);

    showCupertinoModalPopup(
      context: context,
      builder:
          (_) => CupertinoActionSheet(
            title: Text(
              aboutTitle,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
            message: Text(
              aboutDesc,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                height: 1.6,
              ),
            ),
            cancelButton: CupertinoActionSheetAction(
              child: Text(
                closeLabel,
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
  String _getLanguageName(BuildContext context, String languageCode) {
    switch (languageCode.toLowerCase()) {
      case 'id':
        return context.tr('lang_id');
      case 'en':
        return 'English';
      case 'jv':
        return context.tr('lang_jv');
      case 'ba':
        return context.tr('lang_ba');
      case 'sa':
        return context.tr('lang_sa');
      default:
        return context.tr('lang_id');
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HERO PROFIL (Minimalist — Apple Human Interface Guidelines)
// ══════════════════════════════════════════════════════════════════════════════

class _ProfileHero extends StatelessWidget {
  final VolcanoProvider provider;

  const _ProfileHero({required this.provider});

  @override
  Widget build(BuildContext context) {
    final user = provider.currentUser;

    // 1. Nama Pengguna (Apple HIG: Large Title / Title 2)
    final name =
        user?.name.isNotEmpty == true ? user!.name : 'Pengguna SIGUMI';

    // 2. Nomor Telepon yang digunakan (Apple HIG: Subheadline)
    final phone =
        user?.phone?.isNotEmpty == true
            ? user!.phone!
            : (user?.email.isNotEmpty == true
                ? user!.email
                : 'Nomor belum ditambahkan');

    // 3. Lokasi yang ia pilih (Apple HIG: Inset Grouped Cell Value)
    // Utamakan provider.selectedRegion sebagai single source of truth real-time
    final selectedLocation = provider.selectedRegion.isNotEmpty
        ? provider.selectedRegion
        : (user?.region?.isNotEmpty == true
            ? user!.region!
            : 'Yogyakarta');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Identitas Utama: Nama Pengguna & Nomor Telepon ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: context.textPrimary,
                    letterSpacing: -0.5,
                    height: 1.25,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Text(
                  phone,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: context.textSecondary,
                    letterSpacing: -0.2,
                  ),
                ),
              ],
            ),
          ),

          // ── Apple Hairline Inset Divider ──
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Container(
              height: context.borderWidth,
              color: context.borderColor,
            ),
          ),

          // ── Baris Lokasi yang Dipilih (Real-time & Interaktif) ──
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _showRegionPicker(context),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(16),
              ),
              splashColor: context.dividerColor.withValues(alpha: 0.3),
              highlightColor: context.bgSecondary.withValues(alpha: 0.5),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.location_fill,
                      size: 16,
                      color: context.accentPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.trText('Lokasi Terpilih'),
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      selectedLocation,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      CupertinoIcons.chevron_right,
                      size: 14,
                      color: context.textTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRegionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        final regions = [
          {
            'name': 'Yogyakarta',
            'volcano': 'Gunung Merapi',
            'icon': Icons.landscape_rounded,
          },
          {
            'name': 'Bali',
            'volcano': 'Gunung Agung',
            'icon': Icons.terrain_rounded,
          },
          {
            'name': 'Lombok',
            'volcano': 'Gunung Rinjani',
            'icon': Icons.filter_hdr_rounded,
          },
        ];

        return Container(
          decoration: BoxDecoration(
            color: ctx.bgSurface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            border: Border.all(
              color: ctx.borderColor,
              width: ctx.borderWidth,
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ctx.textTertiary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Text(
                ctx.trText('Pilih Lokasi Pemantauan'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: ctx.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                ctx.trText('Pilih wilayah gunung api yang ingin dipantau'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: ctx.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...regions.map((item) {
                final name = item['name'] as String;
                final volcano = item['volcano'] as String;
                final icon = item['icon'] as IconData;
                final isSelected = provider.selectedRegion == name;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? ctx.accentPrimary.withValues(alpha: 0.08)
                        : ctx.bgSecondary,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? ctx.accentPrimary
                          : ctx.borderColor,
                      width: isSelected ? 1.5 : ctx.borderWidth,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        provider.setRegion(name);
                        Navigator.pop(ctx);
                      },
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              icon,
                              size: 22,
                              color: isSelected
                                  ? ctx.accentPrimary
                                  : ctx.textSecondary,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? ctx.accentPrimary
                                          : ctx.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    volcano,
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12,
                                      color: ctx.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                CupertinoIcons.checkmark_alt_circle_fill,
                                size: 22,
                                color: ctx.accentPrimary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
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
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.textSecondary,
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
        color: context.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
        boxShadow: context.cardShadow,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Garis pemisah inset (tidak menyentuh tepi kiri — mengikuti letak ikon)
class _ListDivider extends StatelessWidget {
  const _ListDivider();
  
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: context.borderWidth,
      indent: 58, // rata dengan teks, setelah ikon 36 + margin 14 + gap 8
      color: context.dividerColor,
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
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        splashColor: context.dividerColor.withValues(alpha: 0.3),
        highlightColor: context.bgSecondary.withValues(alpha: 0.5),
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
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: context.textPrimary,
                        letterSpacing: -0.2,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: context.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron navigasi
              Icon(
                CupertinoIcons.chevron_right,
                size: 16,
                color: context.textTertiary,
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

/// Baris toggle notifikasi sistem & mitigasi bencana secara real-time
class _NotificationRow extends StatefulWidget {
  const _NotificationRow();

  @override
  State<_NotificationRow> createState() => _NotificationRowState();
}

class _NotificationRowState extends State<_NotificationRow> {
  bool _isEnabled = NotificationService.instance.isEnabled;

  @override
  void initState() {
    super.initState();
    NotificationService.instance.isEnabledNotifier.addListener(_onServiceChange);
  }

  @override
  void dispose() {
    NotificationService.instance.isEnabledNotifier.removeListener(_onServiceChange);
    super.dispose();
  }

  void _onServiceChange() {
    if (mounted) {
      setState(() {
        _isEnabled = NotificationService.instance.isEnabled;
      });
    }
  }

  void _showNotificationInfo() {
    HapticFeedback.lightImpact();
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text(
              'Notifikasi Mitigasi',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Menerima peringatan dini kenaikan level aktivitas gunung api dan arahan mitigasi kebencanaan secara langsung.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _isEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: _IconBadge(
              icon: _isEnabled
                  ? CupertinoIcons.bell_fill
                  : CupertinoIcons.bell_slash_fill,
              background: _isEnabled
                  ? const Color(0xFFFF9500) // iOS orange
                  : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedOpacity(
              opacity: _isEnabled ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.tr('notification'),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isEnabled
                                ? context.textPrimary
                                : context.textTertiary,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showNotificationInfo,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.info_circle,
                              size: 16,
                              color: context.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEnabled ? 'Aktif' : context.tr('disabled'),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight:
                          _isEnabled ? FontWeight.w500 : FontWeight.w400,
                      color: _isEnabled
                          ? const Color(0xFFFF9500)
                          : context.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CupertinoSwitch(
            value: _isEnabled,
            activeTrackColor: const Color(0xFFFF9500),
            onChanged: (val) async {
              HapticFeedback.lightImpact();
              await NotificationService.instance.setEnabled(val);
              if (mounted) setState(() => _isEnabled = val);
            },
          ),
        ],
      ),
    );
  }
}

/// Baris toggle peringatan getar saat radius 5 km dari puncak
class _VibrationAlertRow extends StatefulWidget {
  const _VibrationAlertRow();

  @override
  State<_VibrationAlertRow> createState() => _VibrationAlertRowState();
}

class _VibrationAlertRowState extends State<_VibrationAlertRow> {
  bool _isEnabled = VibrationAlertService().isEnabled;

  void _showVibrationInfo() {
    HapticFeedback.lightImpact();
    showCupertinoDialog(
      context: context,
      builder:
          (ctx) => CupertinoAlertDialog(
            title: const Text(
              'Peringatan Getar',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            content: const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Ponsel akan bergetar otomatis saat kamu berada sekitar 5 km dari puncak sebagai tanda peringatan dini.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text(
                  'Mengerti',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          AnimatedOpacity(
            opacity: _isEnabled ? 1.0 : 0.5,
            duration: const Duration(milliseconds: 200),
            child: _IconBadge(
              icon: CupertinoIcons.waveform,
              background: _isEnabled
                  ? const Color(0xFFFF3B30)
                  : const Color(0xFF8E8E93),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedOpacity(
              opacity: _isEnabled ? 1.0 : 0.45,
              duration: const Duration(milliseconds: 200),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          context.trText('Peringatan Getar'),
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: _isEnabled
                                ? context.textPrimary
                                : context.textTertiary,
                            letterSpacing: -0.2,
                            height: 1.3,
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _showVibrationInfo,
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              CupertinoIcons.info_circle,
                              size: 16,
                              color: context.textTertiary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isEnabled
                        ? context.tr('vibration_enabled')
                        : context.tr('disabled'),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight:
                          _isEnabled ? FontWeight.w500 : FontWeight.w400,
                      color: _isEnabled
                          ? const Color(0xFFFF3B30)
                          : context.textTertiary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CupertinoSwitch(
            value: _isEnabled,
            activeTrackColor: const Color(0xFFFF3B30),
            onChanged: (val) async {
              HapticFeedback.lightImpact();
              await VibrationAlertService().setEnabled(val);
              setState(() => _isEnabled = val);
              // Test getar singkat saat toggle ON
              if (val) {
                await VibrationAlertService().testVibration();
              }
            },
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
        onTap: () {
          HapticFeedback.heavyImpact();
          onTap();
        },
        splashColor: context.errorColor.withValues(alpha: 0.1),
        highlightColor: context.errorColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                CupertinoIcons.square_arrow_left,
                size: 19,
                color: context.errorColor,
              ),
              const SizedBox(width: 8),
              Text(
                context.tr('logout'),
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: context.errorColor,
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

// ══════════════════════════════════════════════════════════════════════════════
// GUEST PROFILE VIEW
// Ditampilkan di tab Profil saat pengguna belum login (Guest Mode)
// ══════════════════════════════════════════════════════════════════════════════

class _GuestProfileView extends StatelessWidget {
  const _GuestProfileView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        backgroundColor: context.bgSecondary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          context.tr('nav_profile'),
          style: AppFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            color: context.textPrimary,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 32),

              // ── Avatar Placeholder ──────────────────────────────────
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.bgSurface,
                  border: Border.all(
                    color: context.accentPrimary.withValues(alpha: 0.3),
                    width: context.borderWidth,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.person_crop_circle,
                  size: 60,
                  color: context.accentPrimary.withValues(alpha: 0.5),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.8, 0.8),
                    duration: 400.ms,
                    curve: Curves.easeOutBack,
                  )
                  .fadeIn(),

              const SizedBox(height: 16),

              // ── Label Guest ─────────────────────────────────────────
              Text(
                context.trText('Mode Tamu'),
                style: AppFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: context.textPrimary,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 8),

              Text(
                context.trText('Anda sedang menjelajahi SIGUMI sebagai tamu tanpa akun.'),
                textAlign: TextAlign.center,
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  color: context.textSecondary,
                  height: 1.6,
                ),
              ).animate().fadeIn(delay: 150.ms),

              const SizedBox(height: 32),

              // ── Card Manfaat Login ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.bgSurface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: context.borderColor,
                    width: context.borderWidth,
                  ),
                  boxShadow: context.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.trText('Dengan akun, Anda bisa:'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SettingsScreen._labelSecondary,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ...[
                      (Icons.edit_note_rounded, 'Kirim Laporan Bencana',
                          'Laporkan kejadian di sekitar Anda'),
                      (Icons.chat_bubble_rounded, 'Tanya Chatbot AI Sigumi',
                          'Dapatkan jawaban seputar kebencanaan'),
                      (Icons.tune_rounded, 'Simpan Preferensi',
                          'Bahasa, aksesibilitas, & notifikasi'),
                      (Icons.history_rounded, 'Riwayat Laporan',
                          'Pantau laporan yang pernah Anda buat'),
                    ].map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: SigumiTheme.primaryBlue.withAlpha(12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                item.$1,
                                size: 17,
                                color: SigumiTheme.primaryBlue,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    context.trText(item.$2),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: SettingsScreen._labelPrimary,
                                    ),
                                  ),
                                  Text(
                                    context.trText(item.$3),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 12,
                                      color: SettingsScreen._labelSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

              const SizedBox(height: 28),

              // ── Tombol Masuk ────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [SigumiTheme.primaryBlue, Color(0xFF2A3E9A)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: SigumiTheme.primaryBlue.withAlpha(70),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.pushNamed(context, AppRoutes.login);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded, size: 20),
                    label: Text(
                      context.tr('login_to_account'),
                      style: AppFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 12),

              // ── Tombol Daftar ───────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pushNamed(context, AppRoutes.register);
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SigumiTheme.primaryBlue,
                    side: BorderSide(
                      color: SigumiTheme.primaryBlue.withAlpha(100),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
                  label: Text(
                    context.tr('create_new_account'),
                    style: AppFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.15, end: 0),

              const SizedBox(height: 32),

              // ── Label versi ─────────────────────────────────────────
              Text(
                context.trText('SIGUMI v1.0.0'),
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  color: SettingsScreen._labelTertiary,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
    );
  }
}

