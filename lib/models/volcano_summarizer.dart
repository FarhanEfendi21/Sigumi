/// Model untuk data ringkasan aktivitas gunung berapi harian.
/// Data ini di-fetch dari API eksternal dan disimpan di Supabase secara berkala.
///
/// Tabel Supabase: `volcano_summarizer`
class VolcanoSummarizer {
  final String id;
  final DateTime? fetchedAt;
  final DateTime reportDate;
  final String volcanoName;
  final String volcanoKey;
  final int levelCode; // 1=normal, 2=waspada, 3=siaga, 4=awas
  final String levelName;
  final String? periodStart;
  final String? periodEnd;
  final String timezone;
  final String? summary;
  final String? detailUrl;
  final String? author;
  final String? weather;
  final String? windDirection;
  final String? windSpeedText;
  final double? tempMin;
  final double? tempMax;
  final double? humidityMin;
  final double? humidityMax;
  final double? pressureMin;
  final double? pressureMax;

  VolcanoSummarizer({
    required this.id,
    this.fetchedAt,
    required this.reportDate,
    required this.volcanoName,
    required this.volcanoKey,
    required this.levelCode,
    required this.levelName,
    this.periodStart,
    this.periodEnd,
    this.timezone = 'WIB',
    this.summary,
    this.detailUrl,
    this.author,
    this.weather,
    this.windDirection,
    this.windSpeedText,
    this.tempMin,
    this.tempMax,
    this.humidityMin,
    this.humidityMax,
    this.pressureMin,
    this.pressureMax,
  });

  /// Parse dari JSON Supabase
  factory VolcanoSummarizer.fromJson(Map<String, dynamic> json) {
    return VolcanoSummarizer(
      id: json['id'] as String,
      fetchedAt:
          json['fetched_at'] != null
              ? DateTime.parse(json['fetched_at'] as String)
              : null,
      reportDate: DateTime.parse(json['report_date'] as String),
      volcanoName: json['volcano_name'] as String,
      volcanoKey: json['volcano_key'] as String,
      levelCode: json['level_code'] as int? ?? 1,
      levelName: json['level_name'] as String,
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      timezone: json['timezone'] as String? ?? 'WIB',
      summary: json['summary'] as String?,
      detailUrl: json['detail_url'] as String?,
      author: json['author'] as String?,
      weather: json['weather'] as String?,
      windDirection: json['wind_direction'] as String?,
      windSpeedText: json['wind_speed_text'] as String?,
      tempMin:
          json['temp_min'] != null
              ? (json['temp_min'] as num).toDouble()
              : null,
      tempMax:
          json['temp_max'] != null
              ? (json['temp_max'] as num).toDouble()
              : null,
      humidityMin:
          json['humidity_min'] != null
              ? (json['humidity_min'] as num).toDouble()
              : null,
      humidityMax:
          json['humidity_max'] != null
              ? (json['humidity_max'] as num).toDouble()
              : null,
      pressureMin:
          json['pressure_min'] != null
              ? (json['pressure_min'] as num).toDouble()
              : null,
      pressureMax:
          json['pressure_max'] != null
              ? (json['pressure_max'] as num).toDouble()
              : null,
    );
  }

  /// Label status level untuk UI
  String get levelLabel {
    switch (levelCode) {
      case 1:
        return 'Normal';
      case 2:
        return 'Waspada';
      case 3:
        return 'Siaga';
      case 4:
        return 'Awas';
      default:
        return levelName;
    }
  }

  /// Warna untuk status level
  /// Digunakan di UI untuk color-coding
  int get levelColor {
    switch (levelCode) {
      case 1:
        return 0xFF4CAF50; // Green
      case 2:
        return 0xFFFFC107; // Amber
      case 3:
        return 0xFFFF9800; // Orange
      case 4:
        return 0xFFF44336; // Red
      default:
        return 0xFF9E9E9E; // Gray
    }
  }

  /// Rentang suhu dalam format string
  String? get temperatureRange {
    if (tempMin == null || tempMax == null) return null;
    return '${tempMin?.toStringAsFixed(1)}°C - ${tempMax?.toStringAsFixed(1)}°C';
  }

  /// Rentang kelembaban dalam format string
  String? get humidityRange {
    if (humidityMin == null || humidityMax == null) return null;
    return '${humidityMin?.toStringAsFixed(1)}% - ${humidityMax?.toStringAsFixed(1)}%';
  }

  /// Rentang tekanan dalam format string
  String? get pressureRange {
    if (pressureMin == null || pressureMax == null) return null;
    return '${pressureMin?.toStringAsFixed(2)} - ${pressureMax?.toStringAsFixed(2)}';
  }
}
