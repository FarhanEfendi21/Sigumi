import 'package:flutter/material.dart';
import 'dart:io';
import '../config/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (_currentIndex != 0) {
          // Jika tidak di home, kembali ke home
          setState(() => _currentIndex = 0);
        } else {
          // Jika sudah di home, exit app
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
          onTap: (index) {
            setState(() {
              _loadedTabs.add(index);
              _currentIndex = index;
            });
          },
        ),
      ),
    );
  }
}

class _ModernBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(Icons.home_outlined, Icons.home_rounded, 'Beranda'),
    _NavItem(Icons.map_outlined, Icons.map_rounded, 'Peta'),
    _NavItem(Icons.edit_note_rounded, Icons.edit_note_rounded, 'Lapor'),
    _NavItem(
      Icons.chat_bubble_outline_rounded,
      Icons.chat_bubble_rounded,
      'Chatbot',
    ),
    _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

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
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        padding: EdgeInsets.symmetric(
                          horizontal: isSelected ? 16 : 8,
                          vertical: isSelected ? 6 : 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? SigumiTheme.primaryBlue.withAlpha(20)
                                  : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          size: isSelected ? 24 : 22,
                          color:
                              isSelected
                                  ? SigumiTheme.primaryBlue
                                  : SigumiTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 250),
                        style: TextStyle(
                          fontSize: isSelected ? 11 : 10,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                          color:
                              isSelected
                                  ? SigumiTheme.primaryBlue
                                  : SigumiTheme.textSecondary,
                        ),
                        child: Text(item.label),
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
