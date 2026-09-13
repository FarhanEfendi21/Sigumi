import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/globals.dart';

/// Overlay banner notifikasi in-app dengan hierarki tipografi clean & minimalis.
class InAppNotification {
  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show({
    required String title,
    required String body,
    int level = 2,
    String? volcanoName,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 6),
  }) {
    final overlayState = globalNavigatorKey.currentState?.overlay;
    if (overlayState == null) return;

    _dismissTimer?.cancel();
    _currentEntry?.remove();
    _currentEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _InAppNotificationBanner(
        title: title,
        body: body,
        level: level,
        volcanoName: volcanoName,
        onTap: () {
          _removeEntry();
          onTap?.call();
        },
        onDismiss: () {
          _removeEntry();
        },
      ),
    );

    _currentEntry = entry;
    overlayState.insert(entry);

    _dismissTimer = Timer(duration, () {
      _removeEntry();
    });
  }

  static void _removeEntry() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    _currentEntry?.remove();
    _currentEntry = null;
  }
}

class _InAppNotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final int level;
  final String? volcanoName;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.level,
    this.volcanoName,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  State<_InAppNotificationBanner> createState() =>
      _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<_InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  ({Color accent, Color bgBadge, Color textBadge, String roman, String label})
      _getLevelTokens(int level) {
    switch (level) {
      case 4:
        return (
          accent: const Color(0xFFDC2626),
          bgBadge: const Color(0xFFFEF2F2),
          textBadge: const Color(0xFFB91C1C),
          roman: 'IV',
          label: 'AWAS',
        );
      case 3:
        return (
          accent: const Color(0xFFEA580C),
          bgBadge: const Color(0xFFFFF7ED),
          textBadge: const Color(0xFFC2410C),
          roman: 'III',
          label: 'SIAGA',
        );
      case 2:
        return (
          accent: const Color(0xFFD97706),
          bgBadge: const Color(0xFFFFFBEB),
          textBadge: const Color(0xFFB45309),
          roman: 'II',
          label: 'WASPADA',
        );
      default:
        return (
          accent: const Color(0xFF059669),
          bgBadge: const Color(0xFFECFDF5),
          textBadge: const Color(0xFF047857),
          roman: 'I',
          label: 'NORMAL',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = _getLevelTokens(widget.level);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Dismissible(
                key: const ValueKey('in_app_notification_banner'),
                direction: DismissDirection.up,
                onDismissed: (_) => widget.onDismiss(),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 520),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0x0F000000),
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                          BoxShadow(
                            color: tokens.accent.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Accent line indikator status
                            Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: tokens.accent,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                            // Konten teks
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Row 1: Metadata Badge & Source
                                    Row(
                                      children: [
                                        // Badge Status
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2.5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: tokens.bgBadge,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            tokens.label,
                                            style:
                                                GoogleFonts.plusJakartaSans(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w700,
                                              color: tokens.textBadge,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          'LEVEL ${tokens.roman}',
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF64748B),
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          'Realtime',
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w500,
                                            color: const Color(0xFF94A3B8),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        InkWell(
                                          onTap: _handleDismiss,
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: const Padding(
                                            padding: EdgeInsets.all(2),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    // Row 2: Headline / Nama Gunung
                                    Text(
                                      widget.title,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF0F172A),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    // Row 3: Body Direksi Mitigasi
                                    Text(
                                      widget.body,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        color: const Color(0xFF475569),
                                        height: 1.35,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
