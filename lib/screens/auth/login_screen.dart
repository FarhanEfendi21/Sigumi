import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../widgets/sigumi_dialog.dart';
import '../../services/localization_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  // Inline validation errors per field
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Validasi semua field, return true jika valid
  bool _validate() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    bool valid = true;

    setState(() {
      _phoneError = phone.isEmpty ? 'Nomor telepon harus diisi.' : null;
      _passwordError = password.isEmpty
          ? 'Kata sandi harus diisi.'
          : password.length < 6
              ? 'Kata sandi minimal 6 karakter.'
              : null;
    });

    if (_phoneError != null || _passwordError != null) valid = false;
    return valid;
  }

  void _login() async {
    if (!_validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final provider = context.read<VolcanoProvider>();

    // Jika Supabase belum dikonfigurasi, gunakan mode demo
    if (!SupabaseConfig.isConfigured) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
      return;
    }

    final success = await provider.login(
      phone: phone,
      password: password,
    );

    if (!mounted) return;

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else if (provider.authError != null) {
      _showError(provider.authError!);
      provider.clearAuthError();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    SigumiDialog.show(
      context: context,
      title: 'Gagal Masuk',
      message: message,
      type: SigumiDialogType.error,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final isLoading = provider.isAuthLoading;

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: SigumiTheme.backgroundGradient,
            child: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        const Spacer(flex: 2),

                        // Logo
                        Image.asset(
                              'assets/images/SIGUMI-logo.png',
                              height: 72,
                              fit: BoxFit.contain,
                            )
                            .animate()
                            .fadeIn(duration: 600.ms)
                            .scale(
                              begin: const Offset(0.6, 0.6),
                              end: const Offset(1, 1),
                              duration: 600.ms,
                              curve: Curves.elasticOut,
                            ),

                        const SizedBox(height: 24),

                        // Title
                        Text(
                          context.tr('welcome_back'),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: SigumiTheme.primaryBlue,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        const SizedBox(height: 6),

                        Text(
                          context.tr('sign_in'),
                          style: AppFonts.plusJakartaSans(
                            fontSize: 14,
                            color: SigumiTheme.textSecondary,
                          ),
                        ).animate().fadeIn(delay: 300.ms, duration: 500.ms),

                        const SizedBox(height: 36),

                        // Card form
                        Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: SigumiTheme.primaryBlue.withAlpha(
                                      18,
                                    ),
                                    blurRadius: 32,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Phone field
                                  Text(
                                    context.tr('phone_number'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: SigumiTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _phoneController,
                                    hint: context.tr('phone_hint'),
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    errorText: _phoneError,
                                  ),

                                  const SizedBox(height: 20),

                                  // Password field
                                  Text(
                                    context.tr('password'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: SigumiTheme.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  _buildTextField(
                                    controller: _passwordController,
                                    hint: context.tr('password_hint'),
                                    icon: Icons.lock_outline,
                                    obscure: _obscurePassword,
                                    errorText: _passwordError,
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                        color: SigumiTheme.textSecondary,
                                        size: 20,
                                      ),
                                      onPressed:
                                          () => setState(
                                            () =>
                                                _obscurePassword =
                                                    !_obscurePassword,
                                          ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Forgot password
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {},
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 32),
                                      ),
                                      child: Text(
                                        context.tr('forgot_password'),
                                        style: AppFonts.plusJakartaSans(
                                          color: SigumiTheme.primaryBlue,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  // Login button with gradient
                                  SizedBox(
                                    width: double.infinity,
                                    height: 52,
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            SigumiTheme.primaryBlue,
                                            Color(0xFF2A3E9A),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: SigumiTheme.primaryBlue
                                                .withAlpha(80),
                                            blurRadius: 16,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: isLoading ? null : _login,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                        ),
                                        child:
                                            isLoading
                                                ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                      CircularProgressIndicator(
                                                        strokeWidth: 2.5,
                                                        color: Colors.white,
                                                      ),
                                                )
                                                : Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Text(
                                                      context.tr('login'),
                                                      style:
                                                          AppFonts.plusJakartaSans(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    const Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .animate()
                            .fadeIn(delay: 400.ms, duration: 600.ms)
                            .slideY(begin: 0.15, end: 0, duration: 600.ms),

                        const Spacer(flex: 1),

                        // Supabase config warning (hanya tampil saat development)
                        if (!SupabaseConfig.isConfigured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.amber.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    context.tr('loading'),
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 800.ms),
                        
                        if (!SupabaseConfig.isConfigured) const SizedBox(height: 12),

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              context.tr('dont_have_account'),
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                color: SigumiTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap:
                                  () => Navigator.pushNamed(
                                    context,
                                    AppRoutes.register,
                                  ),
                              child: Text(
                                context.tr('sign_up'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: SigumiTheme.primaryBlue,
                                ),
                              ),
                            ),
                          ],
                        ).animate().fadeIn(delay: 600.ms, duration: 500.ms),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    String? errorText,
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
            keyboardType: keyboardType,
            obscureText: obscure,
            onChanged: (_) {
              // Hapus error saat user mulai mengetik
              if (hasError) setState(() {});
            },
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
}

