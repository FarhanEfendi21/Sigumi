import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../config/fonts.dart';
import '../config/routes.dart';
import '../config/theme_extensions.dart';
import '../providers/volcano_provider.dart';
import '../providers/assistant_provider.dart';
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
  bool _assistantInitialized = false;

  // Lazy-load tabs: only build when first visited
  final Set<int> _loadedTabs = {0}; // Home is always loaded

  // Tab yang membutuhkan auth (index: 2=Lapor, 3=Chatbot)
  // Tab 4 (Profil) tetap bisa dibuka oleh guest — isinya guest view
  static const Set<int> _authRequiredTabs = {2, 3};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initAssistantIfNeeded();
  }

  /// Inisialisasi Global Voice Assistant.
  /// Dipanggil sekali saat MainNavigation pertama kali dimuat.
  void _initAssistantIfNeeded() {
    if (_assistantInitialized) return;
    _assistantInitialized = true;

    final volcanoProvider = context.read<VolcanoProvider>();
    final assistantProvider = context.read<GlobalAssistantProvider>();

    // Jalankan init di frame berikutnya agar context sudah fully built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      assistantProvider.initAssistant(
        language: volcanoProvider.language,
      );
      debugPrint('[MainNav] 🎤 Global Voice Assistant initialized!');
    });
  }

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
    HapticFeedback.lightImpact();
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
          // Setelah login sukses, kembali ke home (index 0)
          if (mounted) {
            setState(() {
              _loadedTabs.add(0);
              _currentIndex = 0;
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
            body: Stack(
              children: [
                // Main content
                IndexedStack(
                  index: _currentIndex,
                  children: List.generate(5, _buildTab),
                ),

                // ── Voice Assistant Status Indicator ──
                // Titik kecil di pojok kanan atas menunjukkan status asisten.
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 12,
                  child: Consumer<GlobalAssistantProvider>(
                    builder: (ctx, assistant, _) {
                      if (assistant.state == AssistantState.disabled) {
                        return const SizedBox.shrink();
                      }

                      Color dotColor;
                      String tooltip;
                      switch (assistant.state) {
                        case AssistantState.idle:
                          dotColor = Colors.green;
                          tooltip = 'Voice Assistant aktif — ucapkan "Halo Sigumi"';
                          break;
                        case AssistantState.listeningCommand:
                          dotColor = Colors.blue;
                          tooltip = 'Mendengarkan perintah...';
                          break;
                        case AssistantState.processing:
                          dotColor = Colors.orange;
                          tooltip = 'Memproses...';
                          break;
                        case AssistantState.speaking:
                          dotColor = Colors.purple;
                          tooltip = 'Sedang berbicara...';
                          break;
                        default:
                          dotColor = Colors.grey;
                          tooltip = 'Assistant nonaktif';
                      }

                      return Tooltip(
                        message: tooltip,
                        child: GestureDetector(
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tooltip),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: dotColor.withAlpha(120),
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          )
                              .animate(
                                onPlay: (c) => c.repeat(reverse: true),
                              )
                              .scaleXY(
                                begin: 1.0,
                                end: 1.3,
                                duration: 1500.ms,
                                curve: Curves.easeInOut,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
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
      decoration: BoxDecoration(
        color: context.bgPrimary,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: context.borderColor,
          width: context.borderWidth,
        ),
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
              color: context.dividerColor,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 24),

          // Icon dengan glow
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: context.accentPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(info.icon, color: context.accentPrimary, size: 34),
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
              color: context.warningColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.warningColor,
                width: context.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.lock_rounded, size: 13, color: context.warningColor),
                const SizedBox(width: 5),
                Text(
                  'Perlu Login',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: context.warningColor,
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
              color: context.textPrimary,
            ),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 8),

          // Description
          Text(
            info.desc,
            textAlign: TextAlign.center,
            style: AppFonts.plusJakartaSans(
              fontSize: 14,
              color: context.textSecondary,
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
                gradient: context.isHighContrast ? null : const LinearGradient(
                  colors: [SigumiTheme.primaryBlue, Color(0xFF2A3E9A)],
                ),
                color: context.isHighContrast ? context.accentPrimary : null,
                borderRadius: BorderRadius.circular(16),
                border: context.isHighContrast ? Border.all(
                  color: context.borderColor,
                  width: context.borderWidth,
                ) : null,
                boxShadow: context.cardShadow,
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
                  foregroundColor: context.isHighContrast ? context.bgPrimary : Colors.white,
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
                foregroundColor: context.accentPrimary,
                side: BorderSide(
                  color: context.borderColor,
                  width: context.borderWidth,
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
                color: context.textTertiary,
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
          color: context.bgSurface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: context.cardShadow,
          border: Border.all(
            color: context.borderColor,
            width: context.borderWidth,
          ),
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
                                  ? context.accentPrimary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              isSelected ? item.activeIcon : item.icon,
                              size: isSelected ? 24 : 22,
                              color: isLocked
                                  ? context.textTertiary
                                  : isSelected
                                      ? context.accentPrimary
                                      : context.textSecondary,
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
                                  color: context.warningColor,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: context.bgSurface,
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
                              ? context.textTertiary
                              : isSelected
                                  ? context.accentPrimary
                                  : context.textSecondary,
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
