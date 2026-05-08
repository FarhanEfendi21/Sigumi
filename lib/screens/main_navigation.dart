import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/fonts.dart';
import '../config/routes.dart';
import '../providers/volcano_provider.dart';
import '../services/localization_service.dart';
import 'home/home_screen.dart';
import 'map/map_screen.dart';
import 'report/report_screen.dart';
import 'chatbot/chatbot_screen.dart';
import 'settings/settings_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  // Lazy-load tabs: only build when first visited
  final Set<int> _loadedTabs = {0}; // Home is always loaded

  // Tab yang membutuhkan auth (index: 2=Lapor, 3=Chatbot)
  // Tab 4 (Profil) tetap bisa dibuka oleh guest — isinya guest view
  static const Set<int> _authRequiredTabs = {2, 3};

  Widget _buildTab(int index) {
    if (!_loadedTabs.contains(index)) {
      return const SizedBox.shrink();
    }

    switch (index) {
      case 0:
        return const HomeScreen();
      case 1:
        return const MapScreen();
      case 2:
        return const ReportScreen();
      case 3:
        return const ChatbotScreen();
      case 4:
        return const SettingsScreen();
      default:
        return const SizedBox.shrink();
    }
  }

  void _onTabTap(int index) {
    final isGuest = context.read<VolcanoProvider>().isGuest;

    if (isGuest && _authRequiredTabs.contains(index)) {
      _showLoginPrompt(index);
      return;
    }

    setState(() {
      _loadedTabs.add(index);
      _currentIndex = index;
    });
  }

  void _showLoginPrompt(int targetTabIndex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LoginPromptSheet(
        targetTabIndex: targetTabIndex,
        onLoginSuccess: () {
          // Setelah login sukses, navigasi ke tab yang dicoba
          if (mounted) {
            setState(() {
              _loadedTabs.add(targetTabIndex);
              _currentIndex = targetTabIndex;
            });
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final isGuest = provider.isGuest;

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (_currentIndex != 0) {
              setState(() => _currentIndex = 0);
            } else {
              exit(0);
            }
          },
          child: Scaffold(
            extendBody: true,
            body: IndexedStack(
              index: _currentIndex,
              children: List.generate(5, _buildTab),
            ),
            bottomNavigationBar: _ModernBottomNav(
              currentIndex: _currentIndex,
              isGuest: isGuest,
              onTap: _onTabTap,
            ),
          ),
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// LOGIN PROMPT BOTTOM SHEET
// ══════════════════════════════════════════════════════════════════

class _LoginPromptSheet extends StatelessWidget {
  final int targetTabIndex;
  final VoidCallback onLoginSuccess;

  const _LoginPromptSheet({
    required this.targetTabIndex,
    required this.onLoginSuccess,
  });

  static const Map<int, _LockedTabInfo> _tabInfo = {
    2: _LockedTabInfo(
      icon: Icons.edit_note_rounded,
      label: 'Laporan',
      desc: 'Laporkan kejadian di sekitar Anda dan bantu komunitas tetap aman.',
    ),
    3: _LockedTabInfo(
      icon: Icons.chat_bubble_rounded,
      label: 'Chatbot AI',
      desc: 'Tanya jawab seputar kebencanaan dengan asisten AI Sigumi.',
    ),
    4: _LockedTabInfo(
      icon: Icons.person_rounded,
      label: 'Profil',
      desc: 'Kelola akun, preferensi bahasa, dan aksesibilitas Anda.',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final info = _tabInfo[targetTabIndex]!;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 16, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),

          // Icon dengan glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: SigumiTheme.primaryBlue, size: 34),
          )
              .animate()
              .scale(
                begin: const Offset(0.7, 0.7),
                duration: 400.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(),

          const SizedBox(height: 16),

          // Lock badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: Colors.orange.shade700),
                const SizedBox(width: 5),
                Text(
                  'Perlu Login',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms),

          const SizedBox(height: 14),

          // Title
          Text(
            info.label,
            style: AppFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A1A),
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 8),

          // Description
          Text(
            info.desc,
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 28),

          // Tombol Masuk (primary)
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
                onPressed: () async {
                  Navigator.pop(context); // tutup sheet
                  // Push login, tunggu hasilnya
                  await Navigator.pushNamed(context, AppRoutes.login);
                  // Cek apakah login berhasil
                  if (context.mounted) {
                    final isAuth =
                        context.read<VolcanoProvider>().isAuthenticated;
                    if (isAuth) onLoginSuccess();
                  }
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
                  'Masuk ke Akun',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 12),

          // Tombol Daftar (secondary)
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await Navigator.pushNamed(context, AppRoutes.register);
                if (context.mounted) {
                  final isAuth =
                      context.read<VolcanoProvider>().isAuthenticated;
                  if (isAuth) onLoginSuccess();
                }
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
                'Buat Akun Baru',
                style: AppFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),

          const SizedBox(height: 8),

          // Lanjut sebagai tamu
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Lanjut sebagai Tamu',
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.grey.shade500,
              ),
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

class _LockedTabInfo {
  final IconData icon;
  final String label;
  final String desc;
  const _LockedTabInfo({
    required this.icon,
    required this.label,
    required this.desc,
  });
}

// ══════════════════════════════════════════════════════════════════
// BOTTOM NAV
// ══════════════════════════════════════════════════════════════════

class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final bool isGuest;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({
    required this.currentIndex,
    required this.isGuest,
    required this.onTap,
  });

  static const List<_NavItem> _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'nav_home'),
    _NavItem(Icons.map_outlined, Icons.map_rounded, 'nav_map'),
    _NavItem(Icons.edit_note_rounded, Icons.edit_note_rounded, 'nav_report'),
    _NavItem(
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
      'nav_chatbot',
    ),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'nav_profile'),
  ];

  static const Set<int> _authRequired = {2, 3};

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: SigumiTheme.primaryBlue.withAlpha(18),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withAlpha(10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(color: SigumiTheme.divider.withAlpha(60)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final isSelected = currentIndex == index;
            final isLocked = isGuest && _authRequired.contains(index);

            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                behavior: HitTestBehavior.opaque,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon dengan lock badge overlay jika perlu
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSelected ? 16 : 8,
                              vertical: isSelected ? 6 : 4,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? SigumiTheme.primaryBlue.withAlpha(20)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: isSelected ? 24 : 22,
                              color: isLocked
                                  ? SigumiTheme.textSecondary.withAlpha(140)
                                  : isSelected
                                      ? SigumiTheme.primaryBlue
                                      : SigumiTheme.textSecondary,
                            ),
                          ),
                          // Lock badge kecil
                          if (isLocked)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade400,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontSize: isSelected ? 11 : 10,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: isLocked
                              ? SigumiTheme.textSecondary.withAlpha(140)
                              : isSelected
                                  ? SigumiTheme.primaryBlue
                                  : SigumiTheme.textSecondary,
                        ),
                        child: Consumer<VolcanoProvider>(
                          builder: (ctx, prov, _) => Text(
                            LocalizationService.translate(
                              item.label,
                              prov.language,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(this.icon, this.activeIcon, this.label);
}
