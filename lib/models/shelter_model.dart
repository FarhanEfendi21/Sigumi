/// Model untuk Posko Evakuasi & Fasilitas Kesehatan
class ShelterModel {
  final String id;
  final String volcanoId;
  final String name;
  final String type; // 'posko_evakuasi', 'rumah_sakit', 'puskesmas', 'klinik', 'balai_desa', 'gor'
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final int? capacity;
  final bool hasMedical;
  final bool hasKitchen;
  final bool hasToilet;
  final bool is24h;
  final bool isActive;
  final String? notes;
  final double? distanceFromVolcano; // km, dari database
  final double? distanceFromUser;    // km, dihitung real-time
  final String? volcanoName;

  const ShelterModel({
    required this.id,
    required this.volcanoId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.capacity,
    this.hasMedical = false,
    this.hasKitchen = false,
    this.hasToilet = true,
    this.is24h = false,
    this.isActive = true,
    this.notes,
    this.distanceFromVolcano,
    this.distanceFromUser,
    this.volcanoName,
  });

  /// Parse dari response Supabase RPC get_nearby_shelters
  factory ShelterModel.fromRpc(Map<String, dynamic> json) {
    return ShelterModel(
      id: json['id'] as String,
      volcanoId: '',
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      capacity: json['capacity'] as int?,
      hasMedical: json['has_medical'] as bool? ?? false,
      hasKitchen: json['has_kitchen'] as bool? ?? false,
      hasToilet: json['has_toilet'] as bool? ?? true,
      is24h: json['is_24h'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      distanceFromVolcano: (json['distance_from_volcano'] as num?)?.toDouble(),
      distanceFromUser: (json['distance_km'] as num?)?.toDouble(),
      volcanoName: json['volcano_name'] as String?,
    );
  }

  /// Label tipe dalam Bahasa Indonesia
  String get typeLabel {
    switch (type) {
      case 'posko_evakuasi': return 'Posko Evakuasi';
      case 'rumah_sakit':    return 'Rumah Sakit';
      case 'puskesmas':      return 'Puskesmas';
      case 'klinik':         return 'Klinik';
      case 'balai_desa':     return 'Balai Desa';
      case 'gor':            return 'GOR / Gedung';
      default:               return type;
    }
  }

  /// Apakah ini fasilitas kesehatan (bukan posko)
  bool get isHealthFacility =>
      type == 'rumah_sakit' || type == 'puskesmas' || type == 'klinik';

  /// Apakah ini posko evakuasi / shelter
  bool get isShelter =>
      type == 'posko_evakuasi' || type == 'balai_desa' || type == 'gor';

  /// Jarak user dalam format string
  String get distanceLabel {
    if (distanceFromUser == null) return '— km';
    if (distanceFromUser! < 1) {
      return '${(distanceFromUser! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceFromUser!.toStringAsFixed(1)} km';
  }

  ShelterModel copyWith({double? distanceFromUser}) {
    return ShelterModel(
      id: id,
      volcanoId: volcanoId,
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      capacity: capacity,
      hasMedical: hasMedical,
      hasKitchen: hasKitchen,
      hasToilet: hasToilet,
      is24h: is24h,
      isActive: isActive,
      notes: notes,
      distanceFromVolcano: distanceFromVolcano,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      volcanoName: volcanoName,
    );
  }
}
