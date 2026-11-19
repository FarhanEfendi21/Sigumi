import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/fonts.dart';
import '../config/theme_extensions.dart';
import '../services/localization_service.dart';
import '../services/location_service.dart';

/// Dialog penjelasan in-app sebelum meminta izin lokasi sistem (foreground).
///
/// Menampilkan alasan penggunaan lokasi secara transparan dan meminta
/// persetujuan pengguna terlebih dahulu sebelum dialog sistem Android/iOS muncul.
class LocationDisclosureDialog extends StatelessWidget {
  const LocationDisclosureDialog({super.key});

  static const String dismissedPrefKey =
      'location_disclosure_home_dismissed_v1';

  /// Memastikan pengguna sudah melihat penjelasan & menyetujui permintaan izin
  /// lokasi sebelum memanggil `Geolocator.requestPermission()`.
  ///
  /// - Jika izin sudah diberikan (`whileInUse` / `always`) → return `true` tanpa dialog.
  /// - Jika `deniedForever` → return `true` (OS tidak akan memunculkan dialog;
  ///   `LocationService` akan menampilkan status pengaturan).
  /// - Jika `denied`:
  ///   - Jika `forceShowIfDenied == false` dan pengguna sebelumnya memilih
  ///     "Nanti Saja", langsung return `false` tanpa mengganggu ulang.
  ///   - Selain itu tampilkan dialog dan simpan pilihan jika ditunda.
  static Future<bool> ensurePermissionConsent(
    BuildContext context,
    LocationService locationService, {
    bool forceShowIfDenied = false,
  }) async {
    final permission = await locationService.checkPermissionStatus();
    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always ||
        permission == LocationPermission.deniedForever) {
      return true;
    }

    SharedPreferences? prefs;
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (_) {
      prefs = null;
    }

    if (!forceShowIfDenied && (prefs?.getBool(dismissedPrefKey) ?? false)) {
      return false;
    }

    if (!context.mounted) return false;

    final accepted = await show(context);
    if (accepted) {
      await prefs?.remove(dismissedPrefKey);
      return true;
    }

    await prefs?.setBool(dismissedPrefKey, true);
    return false;
  }

  static Future<bool> show(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const LocationDisclosureDialog(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final accent = context.accentPrimary;
    final surface = context.bgSurface;
    final primaryText = context.textPrimary;
    final secondaryText = context.textSecondary;
    final primaryButtonFg =
        context.isHighContrast ? context.bgPrimary : Colors.white;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: context.borderColor,
              width: context.borderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(24),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color:
                                context.isHighContrast
                                    ? context.bgSecondary
                                    : accent.withAlpha(22),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  context.isHighContrast
                                      ? context.borderColor
                                      : accent.withAlpha(50),
                              width: context.borderWidth,
                            ),
                          ),
                          child: Icon(
                            Icons.location_on_rounded,
                            color: accent,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        context.tr('location_disclosure_title'),
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: primaryText,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        context.tr('location_disclosure_intro'),
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 13,
                          color: secondaryText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _DisclosureBullet(
                        icon: Icons.explore_outlined,
                        text: context.tr('location_disclosure_bullet_region'),
                      ),
                      const SizedBox(height: 8),
                      _DisclosureBullet(
                        icon: Icons.shield_outlined,
                        text: context.tr('location_disclosure_bullet_risk'),
                      ),
                      const SizedBox(height: 8),
                      _DisclosureBullet(
                        icon: Icons.hiking_rounded,
                        text: context.tr('location_disclosure_bullet_hiking'),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.bgSecondary,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: context.borderColor,
                            width: context.borderWidth,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.verified_user_outlined,
                              size: 16,
                              color: secondaryText,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                context.tr('location_disclosure_note'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 11.5,
                                  color: secondaryText,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: const ValueKey('location-disclosure-decline'),
                      onPressed: () => Navigator.of(context).pop(false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: primaryText,
                        minimumSize: const Size(0, 48),
                        side: BorderSide(
                          color: context.borderColor,
                          width: context.borderWidth,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        context.tr('location_disclosure_decline'),
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: secondaryText,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: const ValueKey('location-disclosure-allow'),
                      onPressed: () => Navigator.of(context).pop(true),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: primaryButtonFg,
                        minimumSize: const Size(0, 48),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        context.tr('location_disclosure_allow'),
                        textAlign: TextAlign.center,
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: primaryButtonFg,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DisclosureBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DisclosureBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final accent = context.accentPrimary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color:
                context.isHighContrast
                    ? context.bgSecondary
                    : accent.withAlpha(18),
            borderRadius: BorderRadius.circular(9),
            border:
                context.isHighContrast
                    ? Border.all(
                      color: context.borderColor,
                      width: context.borderWidth,
                    )
                    : null,
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              text,
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: context.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
