import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

class SupabaseService {
  static final _client = Supabase.instance.client;

  // ── Register ──────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String nama,
    required String noTelepon,
    required DateTime tanggalLahir,
    required String password,
  }) async {
    try {
      final response = await _client.rpc('register_user', params: {
        'p_nama': nama,
        'p_no_telepon': noTelepon,
        'p_tanggal_lahir': tanggalLahir.toIso8601String().split('T').first,
        'p_password': password,
      });

      if (response is Map && response.containsKey('error')) {
        return {'success': false, 'message': response['error']};
      }

      final user = _mapToUserModel(response);
      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ── Login ─────────────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String noTelepon,
    required String password,
  }) async {
    try {
      final response = await _client.rpc('login_user', params: {
        'p_no_telepon': noTelepon,
        'p_password': password,
      });

      if (response is Map && response.containsKey('error')) {
        return {'success': false, 'message': response['error']};
      }

      final user = _mapToUserModel(response);
      return {'success': true, 'user': user};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  // ── Helper ────────────────────────────────────────────────────────────────
  static UserModel _mapToUserModel(Map<String, dynamic> data) {
    final tglLahir = DateTime.tryParse(data['tanggal_lahir'] ?? '');
    final usia = tglLahir != null ? _hitungUsia(tglLahir) : null;

    return UserModel(
      id: data['id'] ?? '',
      name: data['nama_pengguna'] ?? '',
      email: data['no_telepon'] ?? '',
      age: usia,
    );
  }

  static int _hitungUsia(DateTime tanggalLahir) {
    final now = DateTime.now();
    int usia = now.year - tanggalLahir.year;
    if (now.month < tanggalLahir.month ||
        (now.month == tanggalLahir.month && now.day < tanggalLahir.day)) {
      usia--;
    }
    return usia;
  }
}