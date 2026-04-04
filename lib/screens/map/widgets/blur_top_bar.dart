import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';

class BlurTopBar extends StatelessWidget {
  final String title;
  final bool isMapFocused;
  final VoidCallback onToggleFocus;

  const BlurTopBar({
    super.key,
    required this.title,
    required this.isMapFocused,
    required this.onToggleFocus,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          height: MediaQuery.of(context).padding.top + kToolbarHeight,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isMapFocused ? 100 : 180), // Lebih transparan saat fokus
            border: Border(
              bottom: BorderSide(
                color: Colors.black.withAlpha(isMapFocused ? 0 : 20),
                width: 0.5,
              ),
            ),
          ),
          child: Stack(
            children: [
              // Judul Peta tersentralisasi
              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    title,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E1E2C),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              // Tombol Toggle Fokus Map
              Align(
                alignment: Alignment.bottomRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: 8, bottom: 4),
                  child: IconButton(
                    onPressed: onToggleFocus,
                    icon: Icon(
                      isMapFocused ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
                      color: const Color(0xFF1E1E2C),
                      size: 26,
                    ),
                    tooltip: isMapFocused ? 'Keluar Layar Penuh' : 'Lihat Layar Penuh',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

