import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/volcano_activity.dart';
import '../models/eruption_history.dart';

/// Repository untuk fetch data aktivitas & erupsi dari Supabase.
///
/// Tabel yang digunakan:
/// - `volcano_activities` — aktivitas terkini (diinput admin berkala)
/// - `eruption_history` — riwayat erupsi historis
///
/// Kedua tabel akan dibuat oleh admin saat dashboard selesai.
/// Untuk saat ini, repository akan return list kosong jika tabel
/// belum ada atau belum ada data.
class VolcanoRepository {
  /// Fetch aktivitas terkini gunung (7 hari terakhir)
  ///
  /// [volcanoId] — UUID gunung di tabel `volcanoes`
  /// Returns list kosong jika tabel belum ada atau belum ada data
  Future<List<VolcanoActivity>> getRecentActivities(String? volcanoId) async {
    if (!SupabaseConfig.isConfigured || volcanoId == null) {
      return [];
    }

    try {
      final client = Supabase.instance.client;
      final sevenDaysAgo = DateTime.now()
          .subtract(const Duration(days: 7))
          .toIso8601String();

      final response = await client
          .from('volcano_activities')
          .select()
          .eq('volcano_id', volcanoId)
          .gte('observed_at', sevenDaysAgo)
          .order('observed_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => VolcanoActivity.fromJson(json))
          .toList();
    } catch (e) {
      // Tabel mungkin belum ada — ini expected saat admin panel belum ready
      // debugPrint('[VolcanoRepository] getRecentActivities: $e');
      return [];
    }
  }

  /// Fetch seluruh riwayat erupsi gunung
  ///
  /// [volcanoId] — UUID gunung di tabel `volcanoes`
  /// Returns list kosong jika tabel belum ada atau belum ada data
  Future<List<EruptionHistory>> getEruptionHistory(String? volcanoId) async {
    if (!SupabaseConfig.isConfigured || volcanoId == null) {
      return [];
    }

    try {
      final client = Supabase.instance.client;

      final response = await client
          .from('eruption_history')
          .select()
          .eq('volcano_id', volcanoId)
          .order('year', ascending: false);

      return (response as List)
          .map((json) => EruptionHistory.fromJson(json))
          .toList();
    } catch (e) {
      // Tabel mungkin belum ada — ini expected saat admin panel belum ready
      // debugPrint('[VolcanoRepository] getEruptionHistory: $e');
      return [];
    }
  }
}
