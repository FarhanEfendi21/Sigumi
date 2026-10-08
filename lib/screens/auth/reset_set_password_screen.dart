import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/password_reset_service.dart';
import '../../widgets/sigumi_dialog.dart';

/// Layar terakhir alur reset: input kata sandi baru.
///
/// Sesuai PRD §5.3:
/// - Pengguna mengisi kata sandi baru + konfirmasi.
/// - Backend memvalidasi tiket dan kebijakan kata sandi.
/// - Setelah sukses: navigasi ke Login.
/// - Kata sandi lama tidak lagi bekerja setelah reset.
class ResetSetPasswordScreen extends StatefulWidget {
  const ResetSetPasswordScreen({super.key});

  @override
  State<ResetSetPasswordScreen> createState() => _ResetSetPasswordScreenState();
}

class _ResetSetPasswordScreenState extends State<ResetSetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  String? _passwordError;
  String? _confirmError;

  late String _resetTicket;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _resetTicket = (args?['reset_ticket'] as String?) ?? '';
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  bool _validate() {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    setState(() {
      _passwordError = password.isEmpty
          ? 'Kata sandi harus diisi.'
          : password.length < 6
              ? 'Kata sandi minimal 6 karakter.'
              : null;

      _confirmError = confirm.isEmpty
          ? 'Konfirmasi kata sandi harus diisi.'
          : confirm != password
              ? 'Kata sandi tidak sama.'
              : null;
    });

    return _passwordError == null && _confirmError == null;
  }

  Future<void> _submit() async {
    HapticFeedback.lightImpact();
    if (!_validate()) return;

    if (_resetTicket.isEmpty) {
      _showError('Sesi reset tidak valid. Ulangi proses dari awal.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await PasswordResetService().setNewPassword(
        resetTicket: _resetTicket,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      if (result.isSuccess) {
        await SigumiDialog.show(
          context: context,
          title: 'Kata Sandi Berhasil Diubah',
          message:
              'Kata sandi Anda telah berhasil diperbarui. '
              'Silakan masuk menggunakan kata sandi baru.',
          type: SigumiDialogType.success,
          buttonText: 'Masuk Sekarang',
          onConfirm: () {
            // Pop semua screen reset dan kembali ke Login
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRoutes.login,
              (route) => false,
            );
          },
        );
      } else {
        _showError(result.errorMessage ?? 'Gagal memperbarui kata sandi.');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    SigumiDialog.show(
      context: context,
      title: 'Gagal Memperbarui Kata Sandi',
      message: message,
      type: SigumiDialogType.error,
    );
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
              // AppBar
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        size: 24,
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
                            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF8B5CF6).withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.key_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ).animate().fadeIn(duration: 500.ms).scale(
                            begin: const Offset(0.7, 0.7),
                            end: const Offset(1, 1),
                            curve: Curves.elasticOut,
                          ),

                      const SizedBox(height: 24),

                      Text(
                        'Buat Kata Sandi Baru',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: SigumiTheme.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Buat kata sandi baru yang kuat dan mudah diingat. '
                        'Minimal 6 karakter.',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          color: SigumiTheme.textSecondary,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 150.ms),

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
                            // Kata sandi baru
                            Text(
                              'Kata Sandi Baru',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _passwordController,
                              hint: 'Minimal 6 karakter',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscurePassword,
                              errorText: _passwordError,
                              onChanged: (_) {
                                if (_passwordError != null) {
                                  setState(() => _passwordError = null);
                                }
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: SigumiTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Konfirmasi
                            Text(
                              'Konfirmasi Kata Sandi',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _confirmController,
                              hint: 'Ulangi kata sandi baru',
                              icon: Icons.lock_outline_rounded,
                              obscure: _obscureConfirm,
                              errorText: _confirmError,
                              onChanged: (_) {
                                if (_confirmError != null) {
                                  setState(() => _confirmError = null);
                                }
                              },
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: SigumiTheme.textSecondary,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscureConfirm = !_obscureConfirm,
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Tombol simpan
                            _buildSubmitButton(),
                          ],
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 250.ms, duration: 500.ms)
                          .slideY(begin: 0.12, end: 0, duration: 500.ms),

                      const SizedBox(height: 24),

                      // Tips keamanan
                      _buildSecurityTips(),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
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
            controller: controller,
            obscureText: obscure,
            onChanged: onChanged,
            style: AppFonts.plusJakartaSans(
              color: SigumiTheme.textBody,
              fontSize: 14,
            ),
            cursorColor: SigumiTheme.primaryBlue,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppFonts.plusJakartaSans(
                color: SigumiTheme.textSecondary,
                fontSize: 13,
              ),
              prefixIcon: Icon(
                icon,
                color: hasError
                    ? Colors.red.shade400
                    : SigumiTheme.primaryBlue.withAlpha(150),
                size: 20,
              ),
              suffixIcon: suffixIcon,
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
                  errorText,
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
            colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF8B5CF6).withAlpha(80),
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
                      'Simpan Kata Sandi Baru',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.save_rounded, size: 18),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildSecurityTips() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF8B5CF6).withAlpha(12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF8B5CF6).withAlpha(30),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                size: 16,
                color: Color(0xFF8B5CF6),
              ),
              const SizedBox(width: 8),
              Text(
                'Tips Kata Sandi Aman',
                style: AppFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6D28D9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...[
            'Gunakan minimal 6 karakter',
            'Kombinasikan huruf, angka, dan simbol',
            'Hindari kata sandi yang mudah ditebak',
          ].map(
            (tip) => Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const SizedBox(width: 4),
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF8B5CF6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    tip,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: SigumiTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
