import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/supabase_config.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../widgets/sigumi_dialog.dart';
import '../../services/localization_service.dart';
import 'package:flutter/services.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  DateTime? _selectedDateOfBirth;

  // Inline validation errors per field
  String? _nameError;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Tampilkan date picker untuk tanggal lahir
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Pilih Tanggal Lahir',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      locale: const Locale('id', 'ID'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: SigumiTheme.primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: SigumiTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDateOfBirth = picked);
    }
  }

  /// Validasi semua field, return true jika valid
  bool _validate() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    bool valid = true;

    setState(() {
      _nameError = name.isEmpty ? 'Nama lengkap harus diisi.' : null;
      _phoneError = phone.isEmpty ? 'Nomor telepon harus diisi.' : null;
      _passwordError = password.isEmpty
          ? 'Kata sandi harus diisi.'
          : password.length < 6
              ? 'Kata sandi minimal 6 karakter.'
              : null;
    });

    if (_nameError != null || _phoneError != null || _passwordError != null) {
      valid = false;
    }
    return valid;
  }

  void _register() async {
    HapticFeedback.lightImpact();
    if (!_validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    final provider = context.read<VolcanoProvider>();

    // Jika Supabase belum dikonfigurasi, mode demo
    if (!SupabaseConfig.isConfigured) {
      Navigator.pushReplacementNamed(context, AppRoutes.main);
      return;
    }

    final success = await provider.register(
      phone: phone,
      password: password,
      fullName: name,
      dateOfBirth: _selectedDateOfBirth,
    );

    if (!mounted) return;

    if (success) {
      // Tampilkan dialog sukses sebelum pindah ke Login
      SigumiDialog.show(
        context: context,
        title: context.tr('reg_success_title'),
        message: context.tr('reg_success_msg'),
        type: SigumiDialogType.success,
        buttonText: context.tr('login_now'),
        onConfirm: () {
          // Pindah ke halaman Login (pop current register screen)
          Navigator.pop(context);
        },
      );
    } else if (provider.authError != null) {
      _showError(provider.authError!);
      provider.clearAuthError();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    SigumiDialog.show(
      context: context,
      title: context.tr('reg_fail_title'),
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
              child: Column(
                children: [
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
                            context.tr('register_title'),
                            style: AppFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: SigumiTheme.primaryBlue,
                            ),
                          ).animate().fadeIn(delay: 150.ms, duration: 500.ms),

                          const SizedBox(height: 6),

                          Text(
                            context.tr('register_subtitle'),
                            textAlign: TextAlign.center,
                            style: AppFonts.plusJakartaSans(
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
                                    // Name
                                    _label(context.tr('name')),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _nameController,
                                      hint: context.tr('name_hint'),
                                      icon: Icons.person_outline_rounded,
                                      errorText: _nameError,
                                    ),

                                    const SizedBox(height: 18),

                                    // Phone
                                    _label(context.tr('phone_number')),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _phoneController,
                                      hint: context.tr('phone_hint'),
                                      icon: Icons.phone_outlined,
                                      keyboardType: TextInputType.phone,
                                      errorText: _phoneError,
                                    ),

                                    const SizedBox(height: 18),

                                    // Password
                                    _label(context.tr('password')),
                                    const SizedBox(height: 8),
                                    _buildTextField(
                                      controller: _passwordController,
                                      hint: context.tr('password_hint'),
                                      icon: Icons.lock_outline_rounded,
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

                                    const SizedBox(height: 18),

                                    // Date of Birth (Date Picker)
                                    _label(context.tr('date_of_birth')),
                                    const SizedBox(height: 4),
                                    Text(
                                      context.tr('dob_ai_note'),
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: SigumiTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    GestureDetector(
                                      onTap: _pickDateOfBirth,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 14,
                                        ),
                                        decoration: BoxDecoration(
                                          color: SigumiTheme.background,
                                          borderRadius: BorderRadius.circular(14),
                                          border: Border.all(color: SigumiTheme.divider),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              Icons.cake_outlined,
                                              color: SigumiTheme.primaryBlue.withAlpha(150),
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              _selectedDateOfBirth != null
                                                  ? DateFormat('dd MMMM yyyy', 'id').format(_selectedDateOfBirth!)
                                                  : context.tr('dob_hint'),
                                              style: AppFonts.plusJakartaSans(
                                                fontSize: 14,
                                                color: _selectedDateOfBirth != null
                                                    ? SigumiTheme.textBody
                                                    : SigumiTheme.textSecondary,
                                              ),
                                            ),
                                            const Spacer(),
                                            Icon(
                                              Icons.calendar_today_outlined,
                                              size: 18,
                                              color: SigumiTheme.textSecondary,
                                            ),
                                          ],
                                        ),
                                      ),
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
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
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
                                          onPressed:
                                              isLoading ? null : _register,
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
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Text(
                                                        context.tr('register_btn'),
                                                        style:
                                                            AppFonts.plusJakartaSans(
                                                              fontSize: 16,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
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
                              .fadeIn(delay: 350.ms, duration: 600.ms)
                              .slideY(begin: 0.15, end: 0, duration: 600.ms),

                          const SizedBox(height: 24),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                context.tr('already_have_account'),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: SigumiTheme.textSecondary,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Text(
                                  context.tr('login'),
                                  style: AppFonts.plusJakartaSans(
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
      style: AppFonts.plusJakartaSans(
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

