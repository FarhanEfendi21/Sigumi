import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/education_model.dart';

/// Repository untuk mengambil data edukasi dari tabel `public.educations`.
class EducationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Ambil artikel edukasi umum dari Supabase,
  /// difilter berdasarkan kolom `lokasi` (case-insensitive).
  ///
  /// Jika [lokasi] null atau kosong, ambil semua data.
  Future<List<EducationItem>> fetchGeneralEducations({
    String? lokasi,
  }) async {
    try {
      final List<dynamic> response;

      if (lokasi != null && lokasi.isNotEmpty) {
        response = await _client
            .from('educations')
            .select()
            .ilike('lokasi', '%$lokasi%')
            .order('created_at', ascending: false);
      } else {
        response = await _client
            .from('educations')
            .select()
            .order('created_at', ascending: false);
      }

      return response
          .map((json) => EducationItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EducationRepository] Error fetching educations: $e');
      return [];
    }
  }
}
