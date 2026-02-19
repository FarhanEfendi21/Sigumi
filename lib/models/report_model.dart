class ReportModel {
  final String id;
  final String userId;
  final String category;
  final String description;
  final double latitude;
  final double longitude;
  final double distanceFromVolcano;
  final DateTime timestamp;
  final String status;
  final List<String>? mediaUrls;

  ReportModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.description,
    required this.latitude,
    required this.longitude,
    required this.distanceFromVolcano,
    required this.timestamp,
    this.status = 'pending',
    this.mediaUrls,
  });

  static List<String> get categories => [
        'Guguran Lava',
        'Hujan Abu',
        'Lahar Dingin',
        'Lahar Panas',
        'Getaran/Gempa',
        'Banjir Lahar',
        'Kerusakan Infrastruktur',
        'Kebutuhan Evakuasi',
        'Lainnya',
      ];
}
