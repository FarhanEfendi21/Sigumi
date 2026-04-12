/// Model untuk data riwayat erupsi gunung berapi.
/// Diinput oleh admin saat terjadi erupsi signifikan.
///
/// Tabel Supabase: `eruption_history`
class EruptionHistory {
  final String id;
  final String volcanoId;
  final int year;
  final int? veiScale;       // Volcanic Explosivity Index (opsional)
  final String description;
  final int casualties;      // Jumlah korban jiwa
  final int evacuees;        // Jumlah pengungsi
  final DateTime createdAt;

  EruptionHistory({
    required this.id,
    required this.volcanoId,
    required this.year,
    this.veiScale,
    required this.description,
    this.casualties = 0,
    this.evacuees = 0,
    required this.createdAt,
  });

  /// Parse dari JSON Supabase
  factory EruptionHistory.fromJson(Map<String, dynamic> json) {
    return EruptionHistory(
      id: json['id'] as String,
      volcanoId: json['volcano_id'] as String,
      year: json['year'] as int,
      veiScale: json['vei_scale'] as int?,
      description: json['description'] as String,
      casualties: json['casualties'] as int? ?? 0,
      evacuees: json['evacuees'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Label VEI untuk UI (jika tersedia)
  String? get veiLabel => veiScale != null ? 'VEI $veiScale' : null;

  /// Apakah erupsi ini punya data korban?
  bool get hasCasualties => casualties > 0;

  /// Apakah erupsi ini punya data evakuasi?
  bool get hasEvacuees => evacuees > 0;
}
