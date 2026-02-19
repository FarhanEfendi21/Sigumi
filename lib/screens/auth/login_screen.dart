import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import 'auth_language_selector.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.main);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VolcanoProvider>(
      builder: (context, provider, _) {
        final isEn = provider.language == 'en';

        return Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: SigumiTheme.backgroundGradient,
            child: SafeArea(
              child: SingleChildScrollView(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      children: [
                        const SizedBox(height: 16),

                        // Language selector at top right
                        Align(
                          alignment: Alignment.centerRight,
                          child: const AuthLanguageSelector()
                              .animate()
                              .fadeIn(duration: 400.ms),
                        ),

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
                          isEn ? 'Welcome Back' : 'Selamat Datang',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: SigumiTheme.primaryBlue,
                          ),
                        ).animate().fadeIn(delay: 200.ms, duration: 500.ms),

                        const SizedBox(height: 6),

                        Text(
                          isEn
                              ? 'Sign in to your SIGUMI account'
                              : 'Masuk ke akun SIGUMI Anda',
                          style: GoogleFonts.plusJakartaSans(
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
                                color: SigumiTheme.primaryBlue.withAlpha(18),
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
                                isEn ? 'Phone Number' : 'Nomor Telepon',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SigumiTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _phoneController,
                                hint: isEn
                                    ? 'Enter phone number'
                                    : 'Masukkan nomor telepon',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                              ),

                              const SizedBox(height: 20),

                              // Password field
                              Text(
                                isEn ? 'Password' : 'Kata Sandi',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: SigumiTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _passwordController,
                                hint: isEn
                                    ? 'Enter password'
                                    : 'Masukkan kata sandi',
                                icon: Icons.lock_outline,
                                obscure: _obscurePassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: SigumiTheme.textSecondary,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(
                                      () => _obscurePassword = !_obscurePassword),
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
                                    isEn
                                        ? 'Forgot Password?'
                                        : 'Lupa Kata Sandi?',
                                    style: GoogleFonts.plusJakartaSans(
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
                                        color:
                                            SigumiTheme.primaryBlue.withAlpha(80),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
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
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                isEn ? 'Sign In' : 'Masuk',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              const Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20),
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

                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              isEn
                                  ? 'Don\'t have an account? '
                                  : 'Belum punya akun? ',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                color: SigumiTheme.textSecondary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  Navigator.pushNamed(context, AppRoutes.register),
                              child: Text(
                                isEn ? 'Register Now' : 'Daftar Sekarang',
                                style: GoogleFonts.plusJakartaSans(
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
  }) {
    return Container(
      decoration: BoxDecoration(
        color: SigumiTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SigumiTheme.divider),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.plusJakartaSans(
            color: SigumiTheme.textBody, fontSize: 14),
        cursorColor: SigumiTheme.primaryBlue,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.plusJakartaSans(
            color: SigumiTheme.textSecondary,
            fontSize: 13,
          ),
          prefixIcon:
              Icon(icon, color: SigumiTheme.primaryBlue.withAlpha(150), size: 20),
          suffixIcon: suffixIcon,
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}
