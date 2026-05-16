import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/volcano_activity.dart';
import '../models/eruption_history.dart';
import '../models/volcanic_daily_report.dart';

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

  /// Fetch laporan harian terbaru dari MAGMA Indonesia (via tabel volcanic_daily_reports)
  ///
  /// [volcanoKey] — 'merapi', 'agung', atau 'rinjani'
  /// [date] — tanggal laporan (default: hari ini)
  /// Returns list kosong jika belum ada data atau scraper belum jalan
  Future<List<VolcanicDailyReport>> getDailyReports(String volcanoKey, {DateTime? date}) async {
    if (!SupabaseConfig.isConfigured) return [];

    try {
      final client = Supabase.instance.client;
      final targetDate = (date ?? DateTime.now()).toIso8601String().substring(0, 10);

      final response = await client
          .from('volcanic_daily_reports')
          .select()
          .eq('volcano_key', volcanoKey)
          .gte('report_date', targetDate) // hari ini atau lebih baru
          .order('report_date', ascending: false)
          .order('period_start', ascending: false)
          .limit(1);

      // Jika tidak ada hari ini, ambil laporan terbaru apapun
      if ((response as List).isEmpty) {
        final fallback = await client
            .from('volcanic_daily_reports')
            .select()
            .eq('volcano_key', volcanoKey)
            .order('report_date', ascending: false)
            .order('period_start', ascending: false)
            .limit(1);
        return (fallback as List)
            .map((json) => VolcanicDailyReport.fromJson(json))
            .toList();
      }

      return response
          .map((json) => VolcanicDailyReport.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // debugPrint('[VolcanoRepository] getDailyReports: $e');
      return [];
    }
  }

  /// Fetch laporan terbaru (1 entry) untuk semua 3 gunung sekaligus
  /// Digunakan untuk overview/ringkasan di home screen
  Future<List<VolcanicDailyReport>> getLatestReportAllVolcanoes() async {
    if (!SupabaseConfig.isConfigured) return [];

    try {
      final client = Supabase.instance.client;
      final results = <VolcanicDailyReport>[];

      for (final key in ['merapi', 'agung', 'rinjani']) {
        final response = await client
            .from('volcanic_daily_reports')
            .select()
            .eq('volcano_key', key)
            .order('report_date', ascending: false)
            .order('period_start', ascending: false)
            .limit(1);

        if ((response as List).isNotEmpty) {
          results.add(VolcanicDailyReport.fromJson(response.first));
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }
}
