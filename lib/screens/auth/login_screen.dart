import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../services/supabase_service.dart';
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
  String? _errorMessage;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (phone.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'No telepon dan password wajib diisi');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await SupabaseService.login(
      noTelepon: phone,
      password: password,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      context.read<VolcanoProvider>().setUser(result['user']);
      Navigator.pushReplacementNamed(context, AppRoutes.main);
    } else {
      setState(() => _errorMessage = result['message']);
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Language selector
                const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: AuthLanguageSelector(),
                  ),
                ),

                const SizedBox(height: 32),

                // Logo & judul
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: SigumiTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.landscape, color: Colors.white, size: 40),
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 16),
                      Text('Masuk ke SIGUMI',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.w700, color: SigumiTheme.primaryBlue)),
                      const SizedBox(height: 6),
                      Text('Sistem Informasi Gunung Api & Mitigasi',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: SigumiTheme.textSecondary)),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 40),

                // Form card
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 20, offset: const Offset(0, 4)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // No telepon
                      Text('No. Telepon', style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SigumiTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          hintText: 'Contoh: 08123456789',
                          prefixIcon: Icon(Icons.phone_outlined, size: 20),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Password
                      Text('Password', style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SigumiTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Masukkan password',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                        onFieldSubmitted: (_) => _login(),
                      ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: SigumiTheme.statusAwas.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: SigumiTheme.statusAwas.withAlpha(60)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 16, color: SigumiTheme.statusAwas),
                              const SizedBox(width: 8),
                              Expanded(child: Text(_errorMessage!,
                                  style: TextStyle(fontSize: 12, color: SigumiTheme.statusAwas))),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Tombol login
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Masuk'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 20),

                // Link ke register
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Belum punya akun? ',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SigumiTheme.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.register),
                        child: Text('Daftar sekarang',
                            style: GoogleFonts.plusJakartaSans(
                                fontSize: 13, fontWeight: FontWeight.w700, color: SigumiTheme.primaryBlue)),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}