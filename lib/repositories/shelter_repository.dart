import 'dart:math' as math;

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shelter_model.dart';

/// Repository untuk mengambil data posko & faskes dari Supabase
class ShelterRepository {
  static final ShelterRepository _instance = ShelterRepository._internal();
  factory ShelterRepository() => _instance;
  ShelterRepository._internal();

  SupabaseClient get _client => Supabase.instance.client;

  /// Ambil shelter terdekat dari koordinat user
  /// [volcanoId] opsional — filter per gunung
  /// [type] opsional — 'posko_evakuasi' | 'rumah_sakit' | 'puskesmas' | dll
  Future<List<ShelterModel>> getNearbyShelters({
    required double lat,
    required double lng,
    String? volcanoId,
    String? type,
    int limit = 30,
  }) async {
    // Titik evakuasi pada aplikasi berasal dari tabel `evakuasi`. Baca tabel
    // ini langsung agar data yang sudah dimasukkan di back-office langsung
    // tersedia tanpa perlu menyalinnya ke tabel shelters.
    try {
      final points = await _loadPointsFromTable(
        'evakuasi', lat, lng, volcanoId, type, limit,
      );
      if (points.isNotEmpty) return points;
    } catch (_) {
      // Beberapa deployment menyimpan titiknya di tabel shelters.
    }

    try {
      final points = await _loadPointsFromTable(
        'shelters', lat, lng, volcanoId, type, limit,
      );
      if (points.isNotEmpty) return points;
    } catch (_) {
      // Lanjutkan ke RPC lama bila tabel langsung tidak tersedia.
    }

    try {
      final result = await _client.rpc('get_nearby_shelters', params: {
        'p_lat': lat,
        'p_lng': lng,
        if (volcanoId != null) 'p_volcano_id': volcanoId,
        if (type != null) 'p_type': type,
        'p_limit': limit,
      });

      if (result == null || result['success'] != true) return [];

      final sheltersList = result['shelters'] as List<dynamic>? ?? [];
      return sheltersList
          .map((json) => ShelterModel.fromRpc(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Return empty — UI handles empty state
      return [];
    }
  }

  /// Ambil shelter berdasarkan volcano_id (tanpa filter jarak)
  Future<List<ShelterModel>> getSheltersByVolcano({
    required String volcanoId,
    required double userLat,
    required double userLng,
  }) async {
    return getNearbyShelters(
      lat: userLat,
      lng: userLng,
      volcanoId: volcanoId,
    );
  }

  double _distanceKm(double lat1, double lng1, double lat2, double lng2) {
    const earthRadiusKm = 6371.0;
    final dLat = (lat2 - lat1) * 0.017453292519943295;
    final dLng = (lng2 - lng1) * 0.017453292519943295;
    final a = ((1 - _cos(dLat)) / 2 +
        _cos(lat1 * 0.017453292519943295) *
            _cos(lat2 * 0.017453292519943295) *
            (1 - _cos(dLng)) / 2)
        .clamp(0.0, 1.0);
    return earthRadiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _cos(double value) => math.cos(value);

  Future<List<ShelterModel>> _loadPointsFromTable(
    String table,
    double lat,
    double lng,
    String? volcanoId,
    String? type,
    int limit,
  ) async {
    final rows = await _client.from(table).select().limit(limit);
    return rows
        .whereType<Map<String, dynamic>>()
        .map(ShelterModel.fromEvakuasiRow)
        .whereType<ShelterModel>()
        .where((point) => point.isActive)
        .where((point) => type == null || point.type == type)
        .where((point) =>
            volcanoId == null || point.volcanoId.isEmpty || point.volcanoId == volcanoId)
        .map((point) => point.copyWith(
              distanceFromUser: _distanceKm(lat, lng, point.latitude, point.longitude),
            ))
        .toList();
  }
}
