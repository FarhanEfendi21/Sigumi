import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/tourism_destination.dart';
import '../models/tourism_event.dart';

/// Repository untuk mengambil data wisata dari Supabase.
/// Jika Supabase gagal atau tabel belum ada, fallback ke mock data.
class TourismRepository {
  SupabaseClient get _client => Supabase.instance.client;

  // ── Destinasi Wisata ──────────────────────────────────────

  /// Ambil semua destinasi wisata berdasarkan daerah.
  Future<List<TourismDestination>> getDestinationsByRegion(
    String region,
  ) async {
    if (!SupabaseConfig.isConfigured) {
      return TourismDestination.byRegion(region);
    }

    try {
      final response = await _client
          .from('tourism_destinations')
          .select()
          .eq('region', region)
          .order('name');

      return (response as List)
          .map((json) => TourismDestination.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[Tourism] Gagal fetch destinations, pakai mock: $e');
      return TourismDestination.byRegion(region);
    }
  }

  // ── Event & Agenda ────────────────────────────────────────

  /// Ambil semua event berdasarkan daerah.
  Future<List<TourismEvent>> getEventsByRegion(String region) async {
    if (!SupabaseConfig.isConfigured) {
      return TourismEvent.byRegion(region);
    }

    try {
      final response = await _client
          .from('tourism_events')
          .select()
          .eq('region', region)
          .order('start_date');

      return (response as List)
          .map((json) => TourismEvent.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('[Tourism] Gagal fetch events, pakai mock: $e');
      return TourismEvent.byRegion(region);
    }
  }

  /// Ambil event yang masih akan datang (max 30 hari ke depan),
  /// termasuk event rutin.
  Future<List<TourismEvent>> getUpcomingEvents(String region) async {
    final all = await getEventsByRegion(region);
    final cutoff = DateTime.now().add(const Duration(days: 60));

    return all.where((e) {
      if (e.isRecurring) return true;
      return e.startDate.isBefore(cutoff) && e.isUpcoming;
    }).toList()
      ..sort((a, b) {
        if (a.isRecurring && !b.isRecurring) return -1;
        if (!a.isRecurring && b.isRecurring) return 1;
        return a.startDate.compareTo(b.startDate);
      });
  }
}
