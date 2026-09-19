import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/education_model.dart';

/// Repository untuk mengambil data edukasi dari tabel `public.educations`.
class EducationRepository {
  SupabaseClient get _client => Supabase.instance.client;

  /// Ambil artikel edukasi berdasarkan [audience] dan opsional [lokasi].
  ///
  /// - [audience]: nilai kolom `audience` di tabel, misal `'Umum'`, `'Anak-Anak'`, `'Difabel'`.
  /// - [lokasi]: filter tambahan berbasis kolom `lokasi` (case-insensitive). Diabaikan jika null/kosong.
  Future<List<EducationItem>> fetchEducationsByAudience({
    required String audience,
    String? lokasi,
  }) async {
    try {
      var query = _client
          .from('educations')
          .select()
          .eq('audience', audience);

      if (lokasi != null && lokasi.isNotEmpty) {
        query = query.ilike('lokasi', '%$lokasi%');
      }

      final List<dynamic> response =
          await query.order('created_at', ascending: false);

      return response
          .map((json) => EducationItem.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[EducationRepository] Error fetching educations (audience=$audience): $e');
      return [];
    }
  }

  /// Shorthand: Ambil artikel edukasi umum (`audience = 'Umum'`),
  /// difilter opsional berdasarkan [lokasi].
  Future<List<EducationItem>> fetchGeneralEducations({
    String? lokasi,
  }) =>
      fetchEducationsByAudience(audience: 'Umum', lokasi: lokasi);

  /// Shorthand: Ambil artikel edukasi anak-anak (`audience = 'Anak-Anak'`),
  /// difilter opsional berdasarkan [lokasi].
  Future<List<EducationItem>> fetchChildrenEducations({
    String? lokasi,
  }) =>
      fetchEducationsByAudience(audience: 'Anak-Anak', lokasi: lokasi);

  /// Shorthand: Ambil artikel edukasi difabel (`audience = 'Difabel'`),
  /// difilter opsional berdasarkan [lokasi].
  Future<List<EducationItem>> fetchDisabilityEducations({
    String? lokasi,
  }) =>
      fetchEducationsByAudience(audience: 'Difabel', lokasi: lokasi);
}
