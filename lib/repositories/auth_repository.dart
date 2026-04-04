import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository untuk semua operasi autentikasi Supabase.
///
/// Strategi Auth:
/// Karena Supabase Phone Auth membutuhkan SMS provider (Twilio/Vonage),
/// kita menggunakan **email sintetis** dari nomor telepon sebagai identifier.
/// Contoh: 081234567890 → 6281234567890@sigumi.app
///
/// UX tetap sama — user input nomor telepon + kata sandi.
/// Nomor telepon asli disimpan di metadata + tabel profiles.
class AuthRepository {
  /// Singleton instance
  static final AuthRepository _instance = AuthRepository._internal();
  factory AuthRepository() => _instance;
  AuthRepository._internal();

  /// Domain email sintetis
  static const String _emailDomain = 'sigumi.app';

  /// Akses Supabase client
  SupabaseClient get _client => Supabase.instance.client;

  /// Akses GoTrue auth
  GoTrueClient get _auth => _client.auth;

  /// User yang sedang login (null jika belum login)
  User? get currentUser => _auth.currentUser;

  /// Session aktif
  Session? get currentSession => _auth.currentSession;

  /// Apakah user sudah login
  bool get isLoggedIn => currentUser != null;

  /// Stream auth state changes (untuk reactive UI)
  Stream<AuthState> get onAuthStateChange => _auth.onAuthStateChange;

  /// ──────────────────────────────────────────────
  /// REGISTER — Nomor Telepon + Kata Sandi
  /// ──────────────────────────────────────────────
  ///
  /// [phone] format: '+6281234567890' (sudah dinormalisasi)
  /// [password] minimal 6 karakter
  /// [fullName] nama lengkap untuk personalisasi
  /// [dateOfBirth] tanggal lahir untuk personalisasi AI
  ///
  /// Internally: phone → email sintetis (6281234567890@sigumi.app)
  Future<AuthResponse> register({
    required String phone,
    required String password,
    required String fullName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final syntheticEmail = _phoneToEmail(phone);

      final response = await _auth.signUp(
        email: syntheticEmail,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'date_of_birth': dateOfBirth?.toIso8601String().split('T').first,
        },
      );
      return response;
    } on AuthException catch (e) {
      throw AuthRepositoryException(
        message: _translateAuthError(e.message),
        originalError: e,
      );
    } catch (e) {
      throw AuthRepositoryException(
        message: 'Terjadi kesalahan saat mendaftar. Coba lagi.',
        originalError: e,
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// LOGIN — Nomor Telepon + Kata Sandi
  /// ──────────────────────────────────────────────
  /// Internally: phone → email sintetis, lalu signInWithPassword
  Future<AuthResponse> login({
    required String phone,
    required String password,
  }) async {
    try {
      final syntheticEmail = _phoneToEmail(phone);

      final response = await _auth.signInWithPassword(
        email: syntheticEmail,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw AuthRepositoryException(
        message: _translateAuthError(e.message),
        originalError: e,
      );
    } catch (e) {
      throw AuthRepositoryException(
        message: 'Terjadi kesalahan saat masuk. Coba lagi.',
        originalError: e,
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// LOGOUT
  /// ──────────────────────────────────────────────
  Future<void> logout() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw AuthRepositoryException(
        message: 'Gagal keluar. Coba lagi.',
        originalError: e,
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// UPDATE PROFIL
  /// ──────────────────────────────────────────────
  /// Update metadata user (nama, dll) di auth.users
  Future<void> updateProfile({
    String? fullName,
    DateTime? dateOfBirth,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (fullName != null) data['full_name'] = fullName;
      if (dateOfBirth != null) {
        data['date_of_birth'] = dateOfBirth.toIso8601String().split('T').first;
      }

      if (data.isNotEmpty) {
        await _auth.updateUser(UserAttributes(data: data));
      }
    } catch (e) {
      throw AuthRepositoryException(
        message: 'Gagal memperbarui profil.',
        originalError: e,
      );
    }
  }

  /// ──────────────────────────────────────────────
  /// GET PROFILE DATA dari tabel profiles
  /// ──────────────────────────────────────────────
  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;

    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }

  /// ──────────────────────────────────────────────
  /// UPDATE PROFILE TABLE
  /// ──────────────────────────────────────────────
  Future<void> updateProfileTable({
    String? language,
    String? region,
    bool? audioGuidance,
    double? fontSize,
    bool? highContrast,
  }) async {
    if (currentUser == null) return;

    try {
      final data = <String, dynamic>{};
      if (language != null) data['language'] = language;
      if (region != null) data['region'] = region;
      if (audioGuidance != null) data['audio_guidance'] = audioGuidance;
      if (fontSize != null) data['font_size'] = fontSize;
      if (highContrast != null) data['high_contrast'] = highContrast;

      if (data.isNotEmpty) {
        await _client
            .from('profiles')
            .update(data)
            .eq('id', currentUser!.id);
      }
    } catch (e) {
      throw AuthRepositoryException(
        message: 'Gagal memperbarui pengaturan profil.',
        originalError: e,
      );
    }
  }

  /// Normalisasi nomor telepon ke format internasional
  /// Input: '081234567890' → Output: '+6281234567890'
  static String normalizePhone(String phone) {
    String cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.startsWith('0')) {
      cleaned = '+62${cleaned.substring(1)}';
    } else if (cleaned.startsWith('62')) {
      cleaned = '+$cleaned';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+62$cleaned';
    }
    return cleaned;
  }

  /// Konversi nomor telepon ke email sintetis
  /// '+6281234567890' → '6281234567890@sigumi.app'
  /// Ini digunakan sebagai identifier di Supabase Auth
  /// tanpa membutuhkan SMS provider.
  String _phoneToEmail(String phone) {
    // Hapus karakter '+' dan spasi
    final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
    return '$digits@$_emailDomain';
  }

  /// Terjemahkan error auth ke Bahasa Indonesia
  String _translateAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_credentials')) {
      return 'Nomor telepon atau kata sandi salah.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('already been registered') ||
        lower.contains('already exists')) {
      return 'Nomor telepon sudah terdaftar. Silakan masuk.';
    }
    if (lower.contains('password') && lower.contains('short')) {
      return 'Kata sandi terlalu pendek (minimal 6 karakter).';
    }
    if (lower.contains('phone') && lower.contains('invalid')) {
      return 'Format nomor telepon tidak valid.';
    }
    if (lower.contains('email') && lower.contains('invalid')) {
      return 'Format nomor telepon tidak valid.';
    }
    if (lower.contains('network') || lower.contains('connection')) {
      return 'Tidak ada koneksi internet. Periksa jaringan Anda.';
    }
    if (lower.contains('rate limit') || lower.contains('too many')) {
      return 'Terlalu banyak percobaan. Tunggu beberapa saat.';
    }
    if (lower.contains('email not confirmed')) {
      // Ini terjadi jika email confirmations aktif — kita bisa abaikan
      return 'Akun berhasil dibuat! Silakan masuk.';
    }
    return 'Terjadi kesalahan: $message';
  }
}

/// Exception khusus untuk error auth
class AuthRepositoryException implements Exception {
  final String message;
  final dynamic originalError;

  AuthRepositoryException({
    required this.message,
    this.originalError,
  });

  @override
  String toString() => 'AuthRepositoryException: $message';
}
