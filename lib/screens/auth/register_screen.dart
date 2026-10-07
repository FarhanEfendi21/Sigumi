import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:sigumi/config/fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/theme_extensions.dart';
import '../../config/routes.dart';
import '../../providers/volcano_provider.dart';
import '../../widgets/sigumi_dialog.dart';
import '../../services/localization_service.dart';
import 'package:flutter/services.dart';
import '../../services/password_reset_service.dart';
import 'register_otp_screen.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailController = TextEditingController(); // Email pemulihan
  bool _obscurePassword = true;
  DateTime? _selectedDateOfBirth;

  // State verifikasi email pemulihan
  bool _isEmailVerified = false;
  String? _registrationToken;
  String? _verifiedPhone;
  bool _isSendingOtp = false;
  String? _emailError;

  // Inline validation errors per field
  String? _nameError;
  String? _phoneError;
  String? _passwordError;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  /// Tampilkan date picker untuk tanggal lahir
  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final language = context.read<VolcanoProvider>().language;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: context.trSafe('select_birth_date'),
      cancelText: context.trSafe('cancel'),
      confirmText: context.trSafe('select'),
      locale: Locale(language == 'id' ? 'id' : 'en'),
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
    final email = _emailController.text.trim();
    bool valid = true;

    setState(() {
      _nameError = name.isEmpty ? context.trTextSafe('Nama lengkap harus diisi.') : null;
      _phoneError = phone.isEmpty ? context.trTextSafe('Nomor telepon harus diisi.') : null;
      _passwordError = password.isEmpty
          ? context.trTextSafe('Kata sandi harus diisi.')
          : password.length < 6
              ? context.trTextSafe('Kata sandi minimal 6 karakter.')
              : null;
      // Validasi email pemulihan
      if (email.isEmpty) {
        _emailError = 'Email pemulihan harus diisi.';
      } else if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        _emailError = 'Format email tidak valid.';
      } else if (!_isEmailVerified) {
        _emailError = 'Email pemulihan harus diverifikasi terlebih dahulu.';
      } else {
        _emailError = null;
      }
    });

    if (_nameError != null || _phoneError != null || _passwordError != null || _emailError != null) {
      valid = false;
    }
    return valid;
  }

  /// Kirim OTP ke email pemulihan dan buka layar verifikasi
  Future<void> _sendAndVerifyEmail() async {
    final email = _emailController.text.trim();
    final phone = _phoneController.text.trim();

    // Validasi email dan telepon sebelum kirim
    setState(() {
      _emailError = email.isEmpty
          ? 'Email pemulihan harus diisi.'
          : !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)
              ? 'Format email tidak valid.'
              : null;
    });
    if (_emailError != null) return;

    if (phone.isEmpty) {
      setState(() => _phoneError = 'Isi nomor telepon sebelum verifikasi email.');
      return;
    }

    setState(() => _isSendingOtp = true);

    try {
      // Kirim OTP ke email
      final sendResult = await PasswordResetService().initiateRegistrationOtp(
        email: email,
        phone: phone,
      );

      if (!mounted) return;
      // Buka layar OTP sekalipun respons kirim tidak terkonfirmasi. Server
      // mungkin sudah mengirim email sebelum koneksi client terputus; pengguna
      // tetap perlu bisa memasukkan kode yang sudah diterima atau kirim ulang.
      final registrationToken = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          settings: RouteSettings(
            name: AppRoutes.registerOtp,
            arguments: {
              'email': email,
              'phone': phone,
              if (!sendResult.isSuccess)
                'initialError': sendResult.errorMessage ??
                    'Pengiriman kode belum terkonfirmasi. Periksa inbox; jika kode belum masuk, kirim ulang dari layar ini.',
            },
          ),
          builder: (_) => const RegisterOtpScreen(),
        ),
      );

      if (!mounted) return;

      if (registrationToken != null && registrationToken.isNotEmpty) {
        setState(() {
          _isEmailVerified = true;
          _registrationToken = registrationToken;
          _verifiedPhone = phone;
          _emailError = null;
        });
      }
    } catch (e) {
      debugPrint('[RegisterScreen] Could not open registration OTP screen: $e');
      if (mounted) {
        setState(() => _emailError =
            'Layar verifikasi tidak dapat dibuka. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _register() async {
    HapticFeedback.lightImpact();
    if (!_validate()) return;

    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();
    final registrationToken = _registrationToken;

    if (registrationToken == null || _verifiedPhone != phone) {
      setState(() {
        _isEmailVerified = false;
        _registrationToken = null;
        _verifiedPhone = null;
        _emailError = 'Verifikasi kembali email setelah nomor telepon diubah.';
      });
      return;
    }

    final provider = context.read<VolcanoProvider>();

    final success = await provider.register(
      phone: phone,
      password: password,
      fullName: name,
      registrationToken: registrationToken,
      dateOfBirth: _selectedDateOfBirth,
    );

    if (!mounted) return;

    if (success) {
      // Email pemulihan disimpan oleh trigger database setelah server membuat
      // akun dengan bukti verifikasi sekali pakai.
      // Tampilkan dialog sukses sebelum pindah ke Login
      // Gunakan read (bukan watch) karena dipanggil di luar build()
      final lang = context.read<VolcanoProvider>().language;
      SigumiDialog.show(
        context: context,
        title: LocalizationService.translate('reg_success_title', lang),
        message: LocalizationService.translate('reg_success_msg', lang),
        type: SigumiDialogType.success,
        buttonText: LocalizationService.translate('login_now', lang),
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
    final lang = context.read<VolcanoProvider>().language;
    SigumiDialog.show(
      context: context,
      title: LocalizationService.translate('reg_fail_title', lang),
      message: message,
      type: SigumiDialogType.error,
    );
  }

  void _clearNameErrorWhenValid(String value) {
    if (_nameError != null && value.trim().isNotEmpty) {
      setState(() => _nameError = null);
    }
  }

  void _clearPhoneErrorWhenValid(String value) {
    if (_phoneError != null && value.trim().isNotEmpty ||
        (_verifiedPhone != null && value.trim() != _verifiedPhone)) {
      setState(() {
        if (_phoneError != null && value.trim().isNotEmpty) _phoneError = null;
        _isEmailVerified = false;
        _registrationToken = null;
        _verifiedPhone = null;
      });
    }
  }

  void _clearPasswordErrorWhenValid(String value) {
    if (_passwordError != null && value.trim().length >= 6) {
      setState(() => _passwordError = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<VolcanoProvider, String>(
      selector: (_, provider) => provider.language,
      builder: (context, language, _) {
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
                                      onChanged: _clearNameErrorWhenValid,
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
                                      onChanged: _clearPhoneErrorWhenValid,
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
                                      onChanged: _clearPasswordErrorWhenValid,
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
                                                  ? DateFormat('dd MMMM yyyy', language == 'id' ? 'id' : 'en').format(_selectedDateOfBirth!)
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

                                    const SizedBox(height: 18),

                                    // ── Email Pemulihan ──────────────────
                                    Row(
                                      children: [
                                        _label('Email Pemulihan'),
                                        const SizedBox(width: 8),
                                        if (_isEmailVerified)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.adaptUiColor(const Color(0xFF10B981))
                                                  .withAlpha(20),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                              border: Border.all(
                                                color: context.adaptUiColor(const Color(0xFF10B981))
                                                    .withAlpha(60),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.verified_rounded,
                                                  size: 11,
                                                  color: context.adaptUiColor(const Color(0xFF10B981)),
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  'Terverifikasi',
                                                  style: AppFonts
                                                      .plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w600,
                                                    color:
                                                        context.adaptUiColor(const Color(0xFF10B981)),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Hanya untuk pemulihan kata sandi, bukan untuk login.',
                                      style: AppFonts.plusJakartaSans(
                                        fontSize: 11,
                                        color: SigumiTheme.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildEmailField(),

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
                                        child: Selector<VolcanoProvider, bool>(
                                          selector: (_, provider) =>
                                              provider.isAuthLoading,
                                          builder: (context, isLoading, _) {
                                            return ElevatedButton(
                                              onPressed: isLoading ? null : _register,
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
                                              child: isLoading
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
                                                          context.tr('register_btn'),
                                                          style: AppFonts.plusJakartaSans(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 8),
                                                        const Icon(
                                                          Icons.arrow_forward_rounded,
                                                          size: 20,
                                                        ),
                                                      ],
                                                    ),
                                            );
                                          },
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

  /// Field email pemulihan dengan tombol "Verifikasi" di dalam suffixIcon
  Widget _buildEmailField() {
    final hasError = _emailError != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _isEmailVerified
                ? context.adaptUiColor(const Color(0xFF10B981)).withAlpha(10)
                : hasError
                    ? Colors.red.shade50
                    : SigumiTheme.background,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _isEmailVerified
                  ? context.adaptUiColor(const Color(0xFF10B981)).withAlpha(80)
                  : hasError
                      ? Colors.red.shade400
                      : SigumiTheme.divider,
              width: (_isEmailVerified || hasError) ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isEmailVerified,
                  onChanged: (_) {
                    if (_emailError != null || _isEmailVerified) {
                      setState(() {
                        _emailError = null;
                        // Jika email diubah setelah verifikasi, reset status
                        _isEmailVerified = false;
                        _registrationToken = null;
                        _verifiedPhone = null;
                      });
                    }
                  },
                  style: AppFonts.plusJakartaSans(
                    color: SigumiTheme.textBody,
                    fontSize: 14,
                  ),
                  cursorColor: SigumiTheme.primaryBlue,
                  decoration: InputDecoration(
                    hintText: 'contoh@email.com',
                    hintStyle: AppFonts.plusJakartaSans(
                      color: SigumiTheme.textSecondary,
                      fontSize: 13,
                    ),
                    prefixIcon: Icon(
                      Icons.email_outlined,
                      color: _isEmailVerified
                          ? context.adaptUiColor(const Color(0xFF10B981))
                          : hasError
                              ? Colors.red.shade400
                              : SigumiTheme.primaryBlue.withAlpha(150),
                      size: 20,
                    ),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              // Tombol Verifikasi
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _isSendingOtp
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: SigumiTheme.primaryBlue,
                        ),
                      )
                    : TextButton(
                        onPressed:
                            _isEmailVerified ? null : _sendAndVerifyEmail,
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          backgroundColor: _isEmailVerified
                              ? context.adaptUiColor(const Color(0xFF10B981)).withAlpha(20)
                              : SigumiTheme.primaryBlue.withAlpha(15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _isEmailVerified ? 'Terverifikasi' : 'Verifikasi',
                          style: AppFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isEmailVerified
                                ? context.adaptUiColor(const Color(0xFF10B981))
                                : SigumiTheme.primaryBlue,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Row(
              children: [
                Icon(Icons.error_outline, size: 14, color: Colors.red.shade600),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _emailError!,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 200.ms).slideY(begin: -0.3, end: 0),
      ],
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
            keyboardType: keyboardType,
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
}
