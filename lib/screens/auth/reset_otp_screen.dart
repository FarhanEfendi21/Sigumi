import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../config/fonts.dart';
import '../../config/theme.dart';
import '../../config/routes.dart';
import '../../services/password_reset_service.dart';

/// Layar verifikasi OTP 6 digit untuk alur reset kata sandi.
///
/// Sesuai PRD §5.3:
/// - Pengguna memasukkan kode 6 digit.
/// - Backend memvalidasi dan menerbitkan tiket reset sekali pakai.
/// - Kode salah/kedaluwarsa/replay tidak mengubah kata sandi.
/// - UI menampilkan sisa percobaan & cooldown kirim ulang.
class ResetOtpScreen extends StatefulWidget {
  const ResetOtpScreen({super.key});

  @override
  State<ResetOtpScreen> createState() => _ResetOtpScreenState();
}

class _ResetOtpScreenState extends State<ResetOtpScreen> {
  // 6 input digit terpisah
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  bool _isVerifying = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCooldown = 0; // detik tersisa
  Timer? _cooldownTimer;

  late String _phone;
  late bool _fromProfile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    _phone = (args?['phone'] as String?) ?? '';
    _fromProfile = (args?['fromProfile'] as bool?) ?? false;
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otp => _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isEmpty) {
      // Backspace — pindah ke field sebelumnya
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
      }
      return;
    }

    // Jika ada paste 6 digit sekaligus
    if (value.length == 6) {
      for (int i = 0; i < 6; i++) {
        _controllers[i].text = value[i];
      }
      _focusNodes[5].requestFocus();
      _verify();
      return;
    }

    // Satu digit — lanjut ke field berikutnya
    _controllers[index].text = value[value.length - 1];
    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      _verify();
    }

    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  Future<void> _verify() async {
    final otp = _otp;
    if (otp.length < 6) {
      setState(() => _errorMessage = 'Masukkan 6 digit kode verifikasi.');
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final result = await PasswordResetService().verifyResetOtp(
        phone: _phone,
        otp: otp,
      );

      if (!mounted) return;

      if (result.isSuccess && result.verified) {
        final ticket = result.resetTicket;
        if (ticket == null) {
          setState(
            () => _errorMessage = 'Verifikasi gagal. Coba lagi.',
          );
          return;
        }
        // Navigasi ke layar set kata sandi baru
        Navigator.pushReplacementNamed(
          context,
          AppRoutes.resetSetPassword,
          arguments: {
            'reset_ticket': ticket,
            'from_profile': _fromProfile,
          },
        );
      } else {
        _clearOtp();
        setState(() {
          _errorMessage =
              result.errorMessage ?? 'Kode tidak valid. Coba lagi.';
        });
        HapticFeedback.heavyImpact();
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  Future<void> _resend() async {
    if (_resendCooldown > 0 || _isResending) return;

    setState(() => _isResending = true);

    try {
      await PasswordResetService().requestReset(phone: _phone);
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
        _startCooldown();
      }
    }
  }

  void _startCooldown() {
    setState(() => _resendCooldown = 60);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_resendCooldown > 0) {
          _resendCooldown--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  void _clearOtp() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
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
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF10B981).withAlpha(80),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.mark_email_read_rounded,
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
                        'Cek Email Anda',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: SigumiTheme.textPrimary,
                        ),
                      ).animate().fadeIn(delay: 100.ms),

                      const SizedBox(height: 8),

                      Text(
                        'Jika akun Anda memiliki email pemulihan terverifikasi, '
                        'kode 6 digit telah dikirimkan.\n\n'
                        'Periksa folder Inbox dan Spam.',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 14,
                          color: SigumiTheme.textSecondary,
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 32),

                      // OTP input
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
                          children: [
                            Text(
                              'Kode Verifikasi',
                              style: AppFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: SigumiTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // 6 kotak OTP
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: List.generate(
                                6,
                                (i) => _buildOtpBox(i),
                              ),
                            ),

                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.red.shade200,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 16,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        _errorMessage!,
                                        style: AppFonts.plusJakartaSans(
                                          fontSize: 13,
                                          color: Colors.red.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(duration: 200.ms).shake(
                                    duration: 400.ms,
                                    hz: 4,
                                    offset: const Offset(4, 0),
                                  ),
                            ],

                            const SizedBox(height: 24),

                            // Tombol verifikasi
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
                                  onPressed: _isVerifying ? null : _verify,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: _isVerifying
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
                                              'Verifikasi Kode',
                                              style: AppFonts.plusJakartaSans(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.check_circle_outline,
                                              size: 18,
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
                          .fadeIn(delay: 250.ms, duration: 500.ms)
                          .slideY(begin: 0.12, end: 0, duration: 500.ms),

                      const SizedBox(height: 24),

                      // Kirim ulang
                      _buildResendSection(),
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

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 44,
      height: 52,
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 6, // Allow paste
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: AppFonts.plusJakartaSans(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: SigumiTheme.textPrimary,
        ),
        cursorColor: SigumiTheme.primaryBlue,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: SigumiTheme.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SigumiTheme.divider),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: SigumiTheme.divider),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: SigumiTheme.primaryBlue,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onDigitChanged(index, value),
        onTap: () {
          _controllers[index].selection = TextSelection(
            baseOffset: 0,
            extentOffset: _controllers[index].text.length,
          );
        },
      ),
    );
  }

  Widget _buildResendSection() {
    return Center(
      child: Column(
        children: [
          Text(
            'Tidak menerima kode?',
            style: AppFonts.plusJakartaSans(
              fontSize: 13,
              color: SigumiTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          if (_resendCooldown > 0)
            Text(
              'Kirim ulang dalam $_resendCooldown detik',
              style: AppFonts.plusJakartaSans(
                fontSize: 13,
                color: SigumiTheme.textSecondary,
              ),
            )
          else
            GestureDetector(
              onTap: _isResending ? null : _resend,
              child: _isResending
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: SigumiTheme.primaryBlue,
                      ),
                    )
                  : Text(
                      'Kirim ulang kode',
                      style: AppFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: SigumiTheme.primaryBlue,
                      ),
                    ),
            ),
          const SizedBox(height: 16),
          Text(
            'Kode berlaku selama 10 menit.',
            style: AppFonts.plusJakartaSans(
              fontSize: 11,
              color: SigumiTheme.textSecondary,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
