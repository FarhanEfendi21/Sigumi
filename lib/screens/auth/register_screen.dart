import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../services/supabase_service.dart';
import 'auth_language_selector.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  DateTime? _tanggalLahir;
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _pilihTanggalLahir() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: SigumiTheme.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _tanggalLahir = picked);
  }

  Future<void> _register() async {
    final nama = _namaController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    if (nama.isEmpty || phone.isEmpty || password.isEmpty || _tanggalLahir == null) {
      setState(() => _errorMessage = 'Semua field wajib diisi');
      return;
    }

    if (password.length < 6) {
      setState(() => _errorMessage = 'Password minimal 6 karakter');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await SupabaseService.register(
      nama: nama,
      noTelepon: phone,
      tanggalLahir: _tanggalLahir!,
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

  String _formatTanggal(DateTime dt) {
    const bulan = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
                        'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
    return '${dt.day} ${bulan[dt.month]} ${dt.year}';
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

                const SizedBox(height: 24),

                // Judul
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72, height: 72,
                        decoration: BoxDecoration(
                          color: SigumiTheme.primaryBlue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.person_add_outlined, color: Colors.white, size: 38),
                      ).animate().fadeIn().scale(),
                      const SizedBox(height: 16),
                      Text('Buat Akun Baru',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 24, fontWeight: FontWeight.w700, color: SigumiTheme.primaryBlue)),
                      const SizedBox(height: 6),
                      Text('Daftar untuk menggunakan SIGUMI',
                          style: GoogleFonts.plusJakartaSans(
                              fontSize: 13, color: SigumiTheme.textSecondary)),
                    ],
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

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

                      // Nama pengguna
                      Text('Nama Pengguna', style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SigumiTheme.textPrimary)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _namaController,
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                          hintText: 'Masukkan nama lengkap',
                          prefixIcon: Icon(Icons.person_outline, size: 20),
                        ),
                      ),

                      const SizedBox(height: 20),

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

                      // Tanggal lahir
                      Text('Tanggal Lahir', style: GoogleFonts.plusJakartaSans(
                          fontSize: 13, fontWeight: FontWeight.w600, color: SigumiTheme.textPrimary)),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pilihTanggalLahir,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: _tanggalLahir != null
                                  ? SigumiTheme.primaryBlue
                                  : SigumiTheme.divider,
                              width: _tanggalLahir != null ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_outlined,
                                  size: 20,
                                  color: _tanggalLahir != null
                                      ? SigumiTheme.primaryBlue
                                      : SigumiTheme.textSecondary),
                              const SizedBox(width: 12),
                              Text(
                                _tanggalLahir != null
                                    ? _formatTanggal(_tanggalLahir!)
                                    : 'Pilih tanggal lahir',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  color: _tanggalLahir != null
                                      ? SigumiTheme.textPrimary
                                      : SigumiTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
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
                          hintText: 'Minimal 6 karakter',
                          prefixIcon: const Icon(Icons.lock_outline, size: 20),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined, size: 20),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
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

                      // Tombol register
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          child: _isLoading
                              ? const SizedBox(width: 20, height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Daftar Sekarang'),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                const SizedBox(height: 20),

                // Link ke login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Sudah punya akun? ',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: SigumiTheme.textSecondary)),
                      GestureDetector(
                        onTap: () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text('Masuk',
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