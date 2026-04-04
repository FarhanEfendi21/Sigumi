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
}
