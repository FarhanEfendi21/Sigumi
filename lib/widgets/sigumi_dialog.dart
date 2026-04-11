import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/fonts.dart';
import '../config/theme.dart';

enum SigumiDialogType { success, error, info }

class SigumiDialog extends StatelessWidget {
  final String title;
  final String message;
  final SigumiDialogType type;
  final String? buttonText;
  final VoidCallback? onConfirm;

  const SigumiDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = SigumiDialogType.info,
    this.buttonText,
    this.onConfirm,
  });

  static Future<void> show({
    required BuildContext context,
    required String title,
    required String message,
    SigumiDialogType type = SigumiDialogType.info,
    String? buttonText,
    VoidCallback? onConfirm,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: type != SigumiDialogType.success,
      builder: (context) => SigumiDialog(
        title: title,
        message: message,
        type: type,
        buttonText: buttonText,
        onConfirm: onConfirm,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Color primaryColor;
    IconData icon;

    switch (type) {
      case SigumiDialogType.success:
        primaryColor = Colors.green.shade600;
        icon = Icons.check_circle_outline_rounded;
        break;
      case SigumiDialogType.error:
        primaryColor = Colors.red.shade600;
        icon = Icons.error_outline_rounded;
        break;
      case SigumiDialogType.info:
        primaryColor = SigumiTheme.primaryBlue;
        icon = Icons.info_outline_rounded;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(20),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: primaryColor, size: 48),
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: SigumiTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: SigumiTheme.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (onConfirm != null) onConfirm!();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  buttonText ?? 'Oke',
                  style: AppFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 200.ms).scale(begin: const Offset(0.9, 0.9));
  }
}
