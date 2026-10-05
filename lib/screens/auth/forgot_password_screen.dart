import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/password_reset_service.dart';

/// Layar pertama alur reset kata sandi: input nomor telepon.
///
/// Sesuai PRD §5.2:
/// - Pengguna memasukkan nomor telepon.
/// - Backend mencari email pemulihan secara server-side.
/// - UI selalu menampilkan respons generik (tidak bocorkan status akun).
class ForgotPasswordScreen extends StatefulWidget {
  /// Jika true, dibuka dari dalam app (sudah login) via Profil.
  /// Jika false, dibuka dari halaman Login.
  final bool fromProfile;

  const ForgotPasswordScreen({super.key, this.fromProfile = false});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _phoneController = TextEditingController();
  String? _phoneError;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  bool _validate() {
    final phone = _phoneController.text.trim();
    setState(() {
      _phoneError = phone.isEmpty
          ? 'Nomor telepon harus diisi.'
          : null;
    });
    return _phoneError == null;
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    if (!_validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = _phoneController.text.trim();
      await PasswordResetService().requestReset(phone: phone);

      if (!mounted) return;

      // Selalu tampilkan pesan generik — baik sukses maupun tidak ada akun
      // Ini sesuai PRD FR-06: tidak membedakan apakah akun ada atau tidak
      Navigator.pushNamed(
        context,
        AppRoutes.resetOtpVerification,
        arguments: {
          'phone': phone,
          'fromProfile': widget.fromProfile,
        },
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: SigumiTheme.backgroundGradient,
        child: SafeArea(
          child: Column(
            children: [
              // AppBar custom
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 20,
                      ),
                      color: SigumiTheme.textPrimary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Ikon
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              SigumiTheme.primaryBlue,
                              Color(0xFF2A3E9A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: SigumiTheme.primaryBlue.withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 24),

                      // Judul
                      Text(
                        'Lupa Kata Sandi?',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: SigumiTheme.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Masukkan nomor telepon yang terdaftar. '
                        'Jika akun memiliki email pemulihan terverifikasi, '
                        'instruksi akan dikirimkan.',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          color: SigumiTheme.textSecondary,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

                      const SizedBox(height: 32),

                      // Form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: SigumiTheme.primaryBlue.withAlpha(18),
                              blurRadius: 32,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Nomor Telepon',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildPhoneField(),
                            const SizedBox(height: 24),
                            _buildSubmitButton(),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 500.ms)
                          .slideY(begin: 0.12, end: 0, duration: 500.ms),

                      const SizedBox(height: 24),

                      // Info keamanan
                      _buildSecurityNote(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneField() {
    final hasError = _phoneError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: hasError ? Colors.red.shade50 : SigumiTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasError ? Colors.red.shade400 : SigumiTheme.divider,
              width: hasError ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            onChanged: (_) {
              if (_phoneError != null) setState(() => _phoneError = null);
            },
            style: AppFonts.plusJakartaSans(
              color: SigumiTheme.textBody,
              fontSize: 14,
            ),
            cursorColor: SigumiTheme.primaryBlue,
            decoration: InputDecoration(
              hintText: 'Contoh: 081234567890',
              hintStyle: AppFonts.plusJakartaSans(
                color: SigumiTheme.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                Icons.phone_outlined,
                color: hasError
                    ? Colors.red.shade400
                    : SigumiTheme.primaryBlue.withAlpha(150),
                size: 20,
              ),
              filled: false,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Text(
                  _phoneError!,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
              color: SigumiTheme.primaryBlue.withAlpha(80),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Kirim Kode Verifikasi',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.send_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSecurityNote() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SigumiTheme.primaryBlue.withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: SigumiTheme.primaryBlue.withAlpha(30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            size: 18,
            color: SigumiTheme.primaryBlue.withAlpha(180),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Email pemulihan digunakan hanya untuk verifikasi. '
              'SIGUMI tidak pernah meminta kata sandi atau kode OTP melalui telepon.',
              style: AppFonts.plusJakartaSans(
                fontSize: 12,
                color: SigumiTheme.textSecondary,
                height: 1.55,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms, duration: 400.ms);
  }
}
