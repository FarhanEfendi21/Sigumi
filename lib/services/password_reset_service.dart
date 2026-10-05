import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

/// Service untuk fitur reset kata sandi via Edge Function.
///
/// Semua operasi kritis (OTP, hash, perubahan kata sandi) berjalan
/// di server-side (Edge Function). Flutter hanya mengirim/menerima data.
/// Tidak ada service-role key di client.
class PasswordResetService {
  /// Singleton
  static final PasswordResetService _instance =
      PasswordResetService._internal();
  factory PasswordResetService() => _instance;
  PasswordResetService._internal();

  /// URL Edge Function
  static String get _baseUrl =>
      '${SupabaseConfig.url}/functions/v1/password-reset';

  /// Header autentikasi Supabase (anon key)
  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'apikey': SupabaseConfig.anonKey,
      };

  /// Header dengan auth Bearer token (untuk endpoint yang butuh sesi)
  Map<String, String> get _authHeaders {
    final session = Supabase.instance.client.auth.currentSession;
    return {
      ..._headers,
      if (session != null) 'Authorization': 'Bearer ${session.accessToken}',
    };
  }

  // ──────────────────────────────────────────────────────────
  // 1. KIRIM OTP VERIFIKASI EMAIL SAAT PENDAFTARAN
  // ──────────────────────────────────────────────────────────
  /// Kirim kode 6 digit ke [email] sebagai verifikasi pemulihan saat daftar.
  ///
  /// [phone] disertakan untuk konteks (belum ada UUID karena belum terdaftar).
  /// Selalu mengembalikan pesan generik — tidak bocorkan status email.
  Future<PasswordResetResult> initiateRegistrationOtp({
    required String email,
    required String phone,
  }) async {
    return _call({
      'action': 'initiate_registration_otp',
      'email': email,
      'phone': phone,
    });
  }

  // ──────────────────────────────────────────────────────────
  // 2. VERIFIKASI OTP PENDAFTARAN
  // ──────────────────────────────────────────────────────────
  /// Verifikasi kode 6 digit yang dikirim saat pendaftaran.
  ///
  /// Jika berhasil, email akan ditandai verified di profil user.
  Future<PasswordResetResult> verifyRegistrationOtp({
    required String email,
    required String phone,
    required String otp,
  }) async {
    return _call({
      'action': 'verify_registration_otp',
      'email': email,
      'phone': phone,
      'otp': otp,
    });
  }

  /// Membuat akun setelah OTP email diverifikasi. Token terikat ke nomor
  /// telepon di server dan hanya dapat dipakai satu kali.
  Future<PasswordResetResult> completeRegistration({
    required String registrationToken,
    required String phone,
    required String password,
    required String fullName,
    DateTime? dateOfBirth,
  }) async {
    return _call({
      'action': 'complete_registration',
      'registration_token': registrationToken,
      'phone': phone,
      'password': password,
      'full_name': fullName,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
    });
  }

  // ──────────────────────────────────────────────────────────
  // 3. MINTA RESET (dari Login — input nomor telepon)
  // ──────────────────────────────────────────────────────────
  /// Minta reset kata sandi berdasarkan nomor telepon.
  ///
  /// Edge Function mencari email pemulihan terverifikasi secara server-side.
  /// Respons selalu generik — tidak bocorkan apakah nomor terdaftar.
  Future<PasswordResetResult> requestReset({required String phone}) async {
    return _call({
      'action': 'request_reset',
      'phone': phone,
    });
  }

  // ──────────────────────────────────────────────────────────
  // 4. VERIFIKASI OTP RESET → TERBITKAN TIKET
  // ──────────────────────────────────────────────────────────
  /// Verifikasi kode OTP reset dan dapatkan tiket sekali pakai.
  ///
  /// [phone] dipakai untuk lookup user server-side.
  /// Tiket dikembalikan jika OTP valid — dipakai di [setNewPassword].
  Future<PasswordResetResult> verifyResetOtp({
    required String phone,
    required String otp,
  }) async {
    return _call({
      'action': 'verify_reset_otp',
      'phone': phone,
      'otp': otp,
    });
  }

  // ──────────────────────────────────────────────────────────
  // 5. SET KATA SANDI BARU (pakai tiket)
  // ──────────────────────────────────────────────────────────
  /// Ubah kata sandi menggunakan tiket yang diterbitkan setelah OTP valid.
  ///
  /// Tiket bersifat sekali pakai dan kedaluwarsa dalam 10 menit.
  Future<PasswordResetResult> setNewPassword({
    required String resetTicket,
    required String newPassword,
  }) async {
    return _call({
      'action': 'set_new_password',
      'reset_ticket': resetTicket,
      'new_password': newPassword,
    });
  }

  // ──────────────────────────────────────────────────────────
  // 6. UPDATE EMAIL PEMULIHAN (dari Profil — butuh sesi)
  // ──────────────────────────────────────────────────────────
  /// Fase 1: Kirim OTP ke email pemulihan baru.
  Future<PasswordResetResult> initiateEmailChange({
    required String newEmail,
  }) async {
    return _callAuth({
      'action': 'update_recovery_email',
      'phase': 'initiate',
      'new_email': newEmail,
    });
  }

  /// Fase 2: Verifikasi OTP untuk mengkonfirmasi email baru.
  Future<PasswordResetResult> verifyEmailChange({
    required String newEmail,
    required String otp,
  }) async {
    return _callAuth({
      'action': 'update_recovery_email',
      'phase': 'verify',
      'new_email': newEmail,
      'otp': otp,
    });
  }

  // ──────────────────────────────────────────────────────────
  // PRIVATE: HELPERS
  // ──────────────────────────────────────────────────────────

  /// Panggil Edge Function tanpa auth Bearer (untuk publik/reset dari login)
  Future<PasswordResetResult> _call(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      return _parseResponse(response);
    } catch (e) {
      debugPrint('[PasswordResetService] Network error: $e');
      return PasswordResetResult.failure(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Panggil Edge Function dengan auth Bearer (untuk operasi yang butuh sesi)
  Future<PasswordResetResult> _callAuth(Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse(_baseUrl),
            headers: _authHeaders,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 20));

      return _parseResponse(response);
    } catch (e) {
      debugPrint('[PasswordResetService] Network error: $e');
      return PasswordResetResult.failure(
        'Gagal terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  PasswordResetResult _parseResponse(http.Response response) {
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return PasswordResetResult.success(data: data);
      } else {
        final errorMsg =
            data['error'] as String? ?? 'Terjadi kesalahan server.';
        return PasswordResetResult.failure(errorMsg);
      }
    } catch (e) {
      debugPrint('[PasswordResetService] Parse error: $e');
      return PasswordResetResult.failure('Respons server tidak valid.');
    }
  }
}

/// Hasil pemanggilan Edge Function password-reset.
class PasswordResetResult {
  final bool isSuccess;
  final String? errorMessage;
  final Map<String, dynamic>? data;

  const PasswordResetResult._({
    required this.isSuccess,
    this.errorMessage,
    this.data,
  });

  factory PasswordResetResult.success({Map<String, dynamic>? data}) =>
      PasswordResetResult._(isSuccess: true, data: data);

  factory PasswordResetResult.failure(String message) =>
      PasswordResetResult._(isSuccess: false, errorMessage: message);

  /// Tiket reset (hanya ada setelah verifyResetOtp berhasil)
  String? get resetTicket => data?['reset_ticket'] as String?;

  /// Pesan sukses dari server
  String? get message => data?['message'] as String?;

  /// Apakah verifikasi berhasil
  bool get verified => data?['verified'] == true;

  /// Bukti pendaftaran sekali pakai setelah OTP email valid.
  String? get registrationToken => data?['registration_token'] as String?;
}
