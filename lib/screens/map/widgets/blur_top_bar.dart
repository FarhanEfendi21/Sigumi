import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:sigumi/config/theme_extensions.dart';

class BlurTopBar extends StatelessWidget {
  final String title;
  final bool isMapFocused;
  final VoidCallback? onToggleFocus;
  final VoidCallback? onBack;

  const BlurTopBar({
    super.key,
    required this.title,
    required this.isMapFocused,
    this.onToggleFocus,
    this.onBack,
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
            color: context.bgPrimary.withAlpha(isMapFocused ? 100 : 180), // Lebih transparan saat fokus
            border: Border(
              bottom: BorderSide(
                color: context.dividerColor.withAlpha(isMapFocused ? 0 : 128),
                width: context.borderWidth,
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
                      color: context.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ),
              // Tombol Kembali
              if (onBack != null)
                Align(
                  alignment: Alignment.bottomLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: IconButton(
                      onPressed: onBack,
                      icon: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: context.textPrimary,
                        size: 20,
                      ),
                      tooltip: 'Kembali',
                    ),
                  ),
                ),
              // Tombol Toggle Fokus Map
              if (onToggleFocus != null)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8, bottom: 4),
                    child: IconButton(
                      onPressed: onToggleFocus,
                      icon: Icon(
                        isMapFocused
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded,
                        color: context.textPrimary,
                        size: 26,
                      ),
                      tooltip:
                          isMapFocused ? 'Keluar Layar Penuh' : 'Lihat Layar Penuh',
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

