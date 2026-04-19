import 'package:flutter/material.dart';

/// Model untuk Nomor Telepon Darurat.
///
/// Data diambil dari tabel `emergency_contacts` di Supabase.
/// Kolom `region` menentukan apakah kontak berlaku untuk semua daerah
/// ('Nasional') atau spesifik per daerah ('Yogyakarta', 'Bali', 'Lombok').
class EmergencyContact {
  final String id;
  final String name;
  final String phone;
  final String description;
  final String category; // 'posko' | 'faskes' | 'nasional'
  final String region;   // 'Nasional' | 'Yogyakarta' | 'Bali' | 'Lombok'
  final int sortOrder;
  final bool isActive;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phone,
    required this.description,
    required this.category,
    required this.region,
    this.sortOrder = 99,
    this.isActive = true,
  });

  /// Parse dari response Supabase
  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] as String,
      name: json['name'] as String,
      phone: json['phone'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String? ?? 'nasional',
      region: json['region'] as String? ?? 'Nasional',
      sortOrder: json['sort_order'] as int? ?? 99,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  /// Label kategori dalam Bahasa Indonesia
  String get categoryLabel {
    switch (category) {
      case 'posko':    return 'Posko';
      case 'faskes':   return 'Faskes';
      case 'nasional': return 'Nasional';
      default:         return category;
    }
  }

  /// Warna badge kategori
  Color get categoryColor {
    switch (category) {
      case 'posko':    return const Color(0xFFE65100);
      case 'faskes':   return const Color(0xFF1565C0);
      case 'nasional': return const Color(0xFF2E7D32);
      default:         return const Color(0xFF546E7A);
    }
  }

  /// Icon berdasarkan nama/kategori layanan
  IconData get serviceIcon {
    if (name.contains('PMI') || name.contains('Ambulans') ||
        name.contains('RS') || name.contains('Rumah Sakit') ||
        name.contains('Puskesmas') || name.contains('Dinkes') ||
        category == 'faskes') {
      return Icons.local_hospital_rounded;
    } else if (name.contains('Polisi') || name.contains('Polres') ||
        name.contains('Polda')) {
      return Icons.local_police_rounded;
    } else if (name.contains('Damkar')) {
      return Icons.local_fire_department_rounded;
    } else if (name.contains('SAR') || name.contains('Basarnas')) {
      return Icons.saved_search_rounded;
    } else if (name.contains('PLN')) {
      return Icons.electric_bolt_rounded;
    } else if (name.contains('Posko') || name.contains('BPBD') ||
        name.contains('BNPB')) {
      return Icons.warning_amber_rounded;
    }
    return Icons.emergency_rounded;
  }

  /// Warna accent berdasarkan nama/kategori
  Color get accentColor {
    if (name.contains('PMI') || name.contains('Ambulans') ||
        name.contains('RS') || name.contains('Rumah Sakit') ||
        name.contains('Puskesmas') || name.contains('Dinkes')) {
      return const Color(0xFFC62828);
    } else if (name.contains('Polisi') || name.contains('Polres') ||
        name.contains('Polda')) {
      return const Color(0xFF1565C0);
    } else if (name.contains('Damkar')) {
      return const Color(0xFFE65100);
    } else if (name.contains('SAR') || name.contains('Basarnas')) {
      return const Color(0xFF00695C);
    } else if (name.contains('PLN')) {
      return const Color(0xFFF57F17);
    } else if (name.contains('Posko') || name.contains('BPBD') ||
        name.contains('BNPB')) {
      return const Color(0xFFBF360C);
    }
    return const Color(0xFF37474F);
  }

  /// Konversi dari data statis AppConstants (untuk fallback offline)
  static EmergencyContact fromStaticMap(
      Map<String, String> map, int index) {
    return EmergencyContact(
      id: 'static_$index',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      description: map['desc'] ?? '',
      category: 'nasional',
      region: 'Nasional',
      sortOrder: index,
    );
  }
}
