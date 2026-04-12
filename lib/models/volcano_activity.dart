/// Model untuk data aktivitas terkini gunung berapi.
/// Diinput oleh admin secara berkala (harian/per-shift pengamatan).
///
/// Tabel Supabase: `volcano_activities`
class VolcanoActivity {
  final String id;
  final String volcanoId;
  final String description;
  final String activityType; // observation, seismic, visual, gas
  final int severityLevel;   // 1=ringan, 2=sedang, 3=berat
  final DateTime observedAt;
  final DateTime createdAt;

  VolcanoActivity({
    required this.id,
    required this.volcanoId,
    required this.description,
    this.activityType = 'observation',
    this.severityLevel = 1,
    required this.observedAt,
    required this.createdAt,
  });

  /// Parse dari JSON Supabase
  factory VolcanoActivity.fromJson(Map<String, dynamic> json) {
    return VolcanoActivity(
      id: json['id'] as String,
      volcanoId: json['volcano_id'] as String,
      description: json['description'] as String,
      activityType: json['activity_type'] as String? ?? 'observation',
      severityLevel: json['severity_level'] as int? ?? 1,
      observedAt: DateTime.parse(json['observed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Label tipe aktivitas untuk tampilan UI
  String get activityTypeLabel {
    switch (activityType) {
      case 'seismic':
        return 'Seismik';
      case 'visual':
        return 'Visual';
      case 'gas':
        return 'Gas & Kimia';
      case 'observation':
      default:
        return 'Pengamatan';
    }
  }

  /// Emoji untuk tipe aktivitas
  String get activityTypeEmoji {
    switch (activityType) {
      case 'seismic':
        return '🔬';
      case 'visual':
        return '👁️';
      case 'gas':
        return '💨';
      case 'observation':
      default:
        return '📋';
    }
  }

  /// Label severity untuk UI
  String get severityLabel {
    switch (severityLevel) {
      case 3:
        return 'Berat';
      case 2:
        return 'Sedang';
      case 1:
      default:
        return 'Ringan';
    }
  }
}
