import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/constants.dart';
import '../config/supabase_config.dart';
import '../models/emergency_contact.dart';

/// Repository untuk fetch data nomor telepon darurat dari Supabase.
///
/// Query mengambil kontak dengan `region = 'Nasional'` ATAU
/// `region = selectedRegion`, lalu diurutkan berdasarkan `sort_order`.
///
/// Jika Supabase tidak terkonfigurasi atau terjadi error,
/// fallback ke data statis dari [AppConstants.emergencyContacts].
class EmergencyRepository {
  /// Fetch kontak darurat berdasarkan region aktif pengguna.
  ///
  /// [region] — region yang dipilih: 'Yogyakarta', 'Bali', atau 'Lombok'
  Future<List<EmergencyContact>> getContacts({
    required String region,
  }) async {
    if (!SupabaseConfig.isConfigured) {
      debugPrint('[EmergencyRepository] Supabase belum dikonfigurasi, pakai fallback statis.');
      return _staticFallback();
    }

    try {
      final client = Supabase.instance.client;

      // Ambil data nasional + spesifik region sekaligus
      final response = await client
          .from('emergency_contacts')
          .select()
          .or('region.eq.Nasional,region.eq.$region')
          .eq('is_active', true)
          .order('sort_order', ascending: true);

      final contacts = (response as List)
          .map((json) => EmergencyContact.fromJson(json))
          .toList();

      if (contacts.isEmpty) {
        debugPrint('[EmergencyRepository] Data kosong dari Supabase, pakai fallback statis.');
        return _staticFallback();
      }

      return contacts;
    } catch (e) {
      debugPrint('[EmergencyRepository] Error: $e — pakai fallback statis.');
      return _staticFallback();
    }
  }

  /// Fallback: data statis dari AppConstants saat offline / error
  List<EmergencyContact> _staticFallback() {
    return AppConstants.emergencyContacts.asMap().entries.map((entry) {
      return EmergencyContact.fromStaticMap(entry.value, entry.key);
    }).toList();
  }
}
