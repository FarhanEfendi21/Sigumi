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
        return 'Normal (Level I)';
      case 2:
        return 'Waspada (Level II)';
      case 3:
        return 'Siaga (Level III)';
      case 4:
        return 'Awas (Level IV)';
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
      statusDescription:
          'Aktivitas vulkanik masih tinggi. Guguran lava pijar teramati dengan jarak luncur maksimum 1.8 km ke arah barat daya. Terjadi 45 kali gempa guguran dan 12 kali gempa vulkanik.',
      lastUpdate: DateTime.now(),
      lastEruption: '11 Maret 2023',
      recentActivities: [
        'Guguran lava pijar teramati jarak luncur maks 1.8 km arah barat daya',
        '45 kali gempa guguran',
        '12 kali gempa vulkanik dalam',
        '3 kali gempa tektonik lokal',
        'Asap kawah putih tebal 150m',
      ],
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
      statusDescription:
          'Aktivitas vulkanik tergolong normal. Tidak ada aktivitas kegempaan yang signifikan dalam 24 jam terakhir.',
      lastUpdate: DateTime.now(),
      lastEruption: '13 Juni 2019',
      recentActivities: [
        'Tidak ada aktivitas signifikan',
        'Cuaca cerah, angin lemah ke arah barat',
      ],
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
      statusDescription:
          'Aktivitas vulkanik waspada akibat peningkatan gempa. Terdapat hembusan asap putih di sekitar kawah.',
      lastUpdate: DateTime.now(),
      lastEruption: '27 September 2016',
      recentActivities: [
        'Hembusan asap putih tipis sesekali terlihat',
        '2 kali gempa vulkanik dalam',
        '10 kali gempa tektonik jauh',
      ],
      temperature: 22,
      windDirection: 'Selatan',
      windSpeed: 12,
    );
  }
}