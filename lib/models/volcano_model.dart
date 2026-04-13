class VolcanoModel {
  // ── UUID riil di database Supabase ─────────────────────────────
  // Harus sesuai dengan data di tabel volcanoes & shelters
  static const String kMerapiUuid = 'a1b2c3d4-e5f6-7890-abcd-111111111111';
  static const String kAgungUuid  = 'a1b2c3d4-e5f6-7890-abcd-222222222222';
  static const String kRinjaniUuid = 'a1b2c3d4-e5f6-7890-abcd-333333333333';
  // ────────────────────────────────────────────────────────────────
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double elevation;
  final int statusLevel; // 1=Normal, 2=Waspada, 3=Siaga, 4=Awas
  final String statusDescription;
  final DateTime lastUpdate;
  final String? lastEruption;
  final List<String> recentActivities;
  final double? temperature;
  final String? windDirection;
  final double? windSpeed;

  VolcanoModel({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.elevation,
    required this.statusLevel,
    required this.statusDescription,
    required this.lastUpdate,
    this.lastEruption,
    this.recentActivities = const [],
    this.temperature,
    this.windDirection,
    this.windSpeed,
  });

  VolcanoModel copyWith({
    String? id,
    String? name,
    double? latitude,
    double? longitude,
    double? elevation,
    int? statusLevel,
    String? statusDescription,
    DateTime? lastUpdate,
    String? lastEruption,
    List<String>? recentActivities,
    double? temperature,
    String? windDirection,
    double? windSpeed,
  }) {
    return VolcanoModel(
      id: id ?? this.id,
      name: name ?? this.name,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      elevation: elevation ?? this.elevation,
      statusLevel: statusLevel ?? this.statusLevel,
      statusDescription: statusDescription ?? this.statusDescription,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lastEruption: lastEruption ?? this.lastEruption,
      recentActivities: recentActivities ?? this.recentActivities,
      temperature: temperature ?? this.temperature,
      windDirection: windDirection ?? this.windDirection,
      windSpeed: windSpeed ?? this.windSpeed,
    );
  }

  /// Mengembalikan UUID database yang sesuai berdasarkan ID mock atau UUID asli.
  /// Digunakan untuk query ke Supabase (tabel shelters, dll).
  String? get dbId {
    // Jika sudah UUID asli → langsung pakai
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    );
    if (uuidRegex.hasMatch(id)) return id;

    // Mapping mock ID → UUID database
    switch (id) {
      case 'merapi_001':
        return kMerapiUuid;
      case 'agung_001':
        return kAgungUuid;
      case 'rinjani_001':
        return kRinjaniUuid;
      default:
        return null; // tidak dikenal → query tanpa filter
    }
  }

  String get statusLabel {
    switch (statusLevel) {
      case 1:
        return 'Level I • Normal';
      case 2:
        return 'Level II • Waspada';
      case 3:
        return 'Level III • Siaga';
      case 4:
        return 'Level IV • Awas';
      default:
        return 'Tidak Diketahui';
    }
  }

  static VolcanoModel mockMerapi() {
    return VolcanoModel(
      id: 'merapi_001',
      name: 'Gunung Merapi',
      latitude: -7.5407,
      longitude: 110.4457,
      elevation: 2968,
      statusLevel: 2,
      statusDescription: 'Data sedang diperbarui oleh petugas...',
      lastUpdate: DateTime.now(),
      lastEruption: '11 Maret 2023',
      recentActivities: [],
      temperature: 28,
      windDirection: 'Barat Daya',
      windSpeed: 15,
    );
  }

  static VolcanoModel mockAgung() {
    return VolcanoModel(
      id: 'agung_001',
      name: 'Gunung Agung',
      latitude: -8.3433,
      longitude: 115.5071,
      elevation: 3031,
      statusLevel: 1,
      statusDescription: 'Aktivitas vulkanik tergolong normal.',
      lastUpdate: DateTime.now(),
      lastEruption: '13 Juni 2019',
      recentActivities: [],
      temperature: 24,
      windDirection: 'Barat',
      windSpeed: 10,
    );
  }

  static VolcanoModel mockRinjani() {
    return VolcanoModel(
      id: 'rinjani_001',
      name: 'Gunung Rinjani',
      latitude: -8.4111,
      longitude: 116.4573,
      elevation: 3726,
      statusLevel: 2,
      statusDescription: 'Data sedang diperbarui...',
      lastUpdate: DateTime.now(),
      lastEruption: '27 September 2016',
      recentActivities: [],
      temperature: 22,
      windDirection: 'Selatan',
      windSpeed: 12,
    );
  }
}