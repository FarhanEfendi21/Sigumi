import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import 'auth_language_selector.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _register() async {
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
              child: Column(
                children: [
                  // Language selector at top right
                  Padding(
                    padding: const EdgeInsets.only(top: 16, right: 28),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: const AuthLanguageSelector()
                          .animate()
                          .fadeIn(duration: 400.ms),
                    ),
                  ),

                  // Scrollable content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        children: [
                          const SizedBox(height: 20),

                          // Logo
                          Image.asset(
                            'assets/images/SIGUMI-logo.png',
                            height: 56,
                            fit: BoxFit.contain,
                          )
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                end: const Offset(1, 1),
                                duration: 500.ms,
                                curve: Curves.elasticOut,
                              ),

                          const SizedBox(height: 18),

                          // Title
                          Text(
                            isEn ? 'Create Account' : 'Daftar Akun Baru',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: SigumiTheme.primaryBlue,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                          const SizedBox(height: 6),

                          Text(
                            isEn
                                ? 'Fill in your details for disaster info personalization'
                                : 'Isi data untuk personalisasi informasi bencana',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              color: SigumiTheme.textSecondary,
                            ),
                          ).animate().fadeIn(delay: 250.ms, duration: 500.ms),

                          const SizedBox(height: 28),

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
                                // Name
                                _label(isEn ? 'Full Name' : 'Nama Lengkap'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _nameController,
                                  hint: isEn
                                      ? 'Enter your full name'
                                      : 'Masukkan nama lengkap',
                                  icon: Icons.person_outline_rounded,
                                ),

                                const SizedBox(height: 18),

                                // Phone
                                _label(isEn ? 'Phone Number' : 'Nomor Telepon'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _phoneController,
                                  hint: isEn
                                      ? 'Enter phone number'
                                      : 'Masukkan nomor telepon',
                                  icon: Icons.phone_outlined,
                                  keyboardType: TextInputType.phone,
                                ),

                                const SizedBox(height: 18),

                                // Password
                                _label(isEn ? 'Password' : 'Kata Sandi'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _passwordController,
                                  hint: isEn
                                      ? 'Create a password'
                                      : 'Buat kata sandi',
                                  icon: Icons.lock_outline_rounded,
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

                                const SizedBox(height: 18),

                                // Age
                                _label(isEn ? 'Age' : 'Usia'),
                                const SizedBox(height: 8),
                                _buildTextField(
                                  controller: _ageController,
                                  hint: isEn
                                      ? 'Age (for AI personalization)'
                                      : 'Usia (untuk personalisasi AI)',
                                  icon: Icons.cake_outlined,
                                  keyboardType: TextInputType.number,
                                ),

                                const SizedBox(height: 24),

                                // Register button with gradient
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
                                      onPressed: _isLoading ? null : _register,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor:
                                            Colors.transparent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
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
                                                  isEn ? 'Register' : 'Daftar',
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
                              .fadeIn(delay: 350.ms, duration: 600.ms)
                              .slideY(begin: 0.15, end: 0, duration: 600.ms),

                          const SizedBox(height: 24),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isEn
                                    ? 'Already have an account? '
                                    : 'Sudah punya akun? ',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: SigumiTheme.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  isEn ? 'Sign In' : 'Masuk',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: SigumiTheme.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 500.ms, duration: 500.ms),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _label(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: SigumiTheme.textPrimary,
      ),
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
