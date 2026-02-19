class VolcanoModel {
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
}
