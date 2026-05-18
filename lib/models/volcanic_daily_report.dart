/// Model untuk laporan harian gunung berapi dari MAGMA Indonesia.
///
/// Data diambil via Edge Function scraper dari:
/// https://magma.esdm.go.id/v1/gunung-api/laporan-harian
///
/// Tabel Supabase: `volcanic_daily_reports`
class VolcanicDailyReport {
  final String id;
  final DateTime fetchedAt;
  final DateTime reportDate;
  final String volcanoName;   // "Merapi", "Agung", "Rinjani"
  final String volcanoKey;    // "merapi", "agung", "rinjani"
  final int levelCode;        // 1=Normal, 2=Waspada, 3=Siaga, 4=Awas
  final String levelName;     // "Level II (Waspada)"
  final String? periodStart;  // "00:00"
  final String? periodEnd;    // "06:00"
  final String timezone;      // "WIB", "WITA", "WIT"
  final String? summary;      // teks laporan singkat (raw dari MAGMA)
  final String? detailUrl;    // URL ke laporan lengkap MAGMA
  final String? author;       // nama petugas

  // ── Data Klimatologi Terstruktur dari MAGMA ──
  final String? weather;         // "Cerah hingga mendung"
  final String? windDirection;   // "Timur", "Barat Daya"
  final String? windSpeedText;   // "Tenang", "Lemah", "Sedang", "Kencang"
  final double? tempMin;         // °C
  final double? tempMax;         // °C
  final double? humidityMin;     // %
  final double? humidityMax;     // %
  final double? pressureMin;     // mmHg
  final double? pressureMax;     // mmHg

  const VolcanicDailyReport({
    required this.id,
    required this.fetchedAt,
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
    // Klimatologi
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

  factory VolcanicDailyReport.fromJson(Map<String, dynamic> json) {
    final rawSummary = json['summary'] as String?;

    // Ambil dari DB dulu
    double? tempMin = (json['temp_min'] as num?)?.toDouble();
    double? tempMax = (json['temp_max'] as num?)?.toDouble();
    String? weather = json['weather'] as String?;
    String? windDirection = json['wind_direction'] as String?;
    String? windSpeedText = json['wind_speed_text'] as String?;
    double? humidityMin = (json['humidity_min'] as num?)?.toDouble();
    double? humidityMax = (json['humidity_max'] as num?)?.toDouble();
    double? pressureMin = (json['pressure_min'] as num?)?.toDouble();
    double? pressureMax = (json['pressure_max'] as num?)?.toDouble();

    // Client-side fallback: parse dari summary jika kolom DB masih null
    // (terjadi saat scraper lama belum di-deploy ulang)
    if (rawSummary != null && rawSummary.isNotEmpty) {
      // Suhu udara: "19.5-22.4°C" atau "20-28 °C"
      if (tempMin == null) {
        final suhuRe = RegExp(
          r'[Ss]uhu(?:\s+udara)?\s+(?:sekitar\s+)?([\d.,]+)\s*[-–]\s*([\d.,]+)\s*°?C',
        );
        final m = suhuRe.firstMatch(rawSummary);
        if (m != null) {
          tempMin = double.tryParse(m.group(1)!.replaceAll(',', '.'));
          tempMax = double.tryParse(m.group(2)!.replaceAll(',', '.'));
        }
      }
      // Cuaca: "Cuaca cerah hingga mendung"
      if (weather == null) {
        final cuacaRe = RegExp(r'[Cc]uaca\s+([^,.\n]+)');
        final m = cuacaRe.firstMatch(rawSummary);
        if (m != null) {
          final val = m.group(1)!.trim();
          weather = val[0].toUpperCase() + val.substring(1);
        }
      }
    }

    return VolcanicDailyReport(
      id: json['id'] as String? ?? '',
      fetchedAt: json['fetched_at'] != null
          ? DateTime.parse(json['fetched_at'] as String)
          : DateTime.now(),
      reportDate: json['report_date'] != null
          ? DateTime.parse(json['report_date'] as String)
          : DateTime.now(),
      volcanoName: json['volcano_name'] as String? ?? '',
      volcanoKey: json['volcano_key'] as String? ?? '',
      levelCode: json['level_code'] as int? ?? 1,
      levelName: json['level_name'] as String? ?? 'Level I (Normal)',
      periodStart: json['period_start'] as String?,
      periodEnd: json['period_end'] as String?,
      timezone: json['timezone'] as String? ?? 'WIB',
      summary: json['summary'] as String?,
      detailUrl: json['detail_url'] as String?,
      author: json['author'] as String?,
      // Klimatologi — pakai variabel fallback (sudah di-parse client-side jika null dari DB)
      weather: weather,
      windDirection: windDirection,
      windSpeedText: windSpeedText,
      tempMin: tempMin,
      tempMax: tempMax,
      humidityMin: humidityMin,
      humidityMax: humidityMax,
      pressureMin: pressureMin,
      pressureMax: pressureMax,
    );
  }

  /// Label periode tampilan, e.g. "00:00 – 06:00 WIB"
  String get periodLabel {
    if (periodStart != null && periodEnd != null) {
      return '$periodStart – $periodEnd $timezone';
    }
    return timezone;
  }

  /// Label suhu tampilan: "19.5 – 22.4°C" atau "-" jika null
  String get tempLabel {
    if (tempMin == null && tempMax == null) return '-';
    if (tempMin == tempMax) return '${_fmt(tempMin)}°C';
    return '${_fmt(tempMin)} – ${_fmt(tempMax)}°C';
  }

  /// Label kelembaban tampilan: "73 – 79.1%" atau "-"
  String get humidityLabel {
    if (humidityMin == null && humidityMax == null) return '-';
    if (humidityMin == humidityMax) return '${_fmt(humidityMin)}%';
    return '${_fmt(humidityMin)} – ${_fmt(humidityMax)}%';
  }

  /// Label tekanan tampilan: "871.8 – 914.4 mmHg" atau "-"
  String get pressureLabel {
    if (pressureMin == null && pressureMax == null) return '-';
    if (pressureMin == pressureMax) return '${_fmt(pressureMin)} mmHg';
    return '${_fmt(pressureMin)} – ${_fmt(pressureMax)} mmHg';
  }

  /// Label angin: "Tenang ke arah Timur" atau hanya salah satu
  String get windLabel {
    final parts = <String>[];
    if (windSpeedText != null) parts.add(windSpeedText!);
    if (windDirection != null) parts.add('ke arah ${windDirection!}');
    return parts.isEmpty ? '-' : parts.join(' ');
  }

  /// Apakah punya data klimatologi valid?
  bool get hasClimatologyData =>
      weather != null ||
      windDirection != null ||
      tempMin != null ||
      humidityMin != null ||
      pressureMin != null;

  // ────────────────────────────────────────────────
  // Parsed sections dari summary (client-side split)
  // ────────────────────────────────────────────────

  static const _climateKeywords = [
    'cuaca', 'suhu udara', 'kelembaban', 'tekanan udara',
    'angin lemah', 'angin sedang', 'angin kencang',
    'angin ke arah', 'angin tenang',
  ];

  static bool _isClimateSentence(String sentence) {
    final lower = sentence.toLowerCase().trim();
    return _climateKeywords.any((kw) => lower.contains(kw));
  }

  _SummaryParts get _parsedParts {
    if (summary == null || summary!.isEmpty) {
      return const _SummaryParts(visual: [], climate: []);
    }

    final sentences = summary!
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final visual = <String>[];
    final climate = <String>[];

    for (final sentence in sentences) {
      if (_isClimateSentence(sentence)) {
        climate.add(sentence);
      } else {
        visual.add(sentence);
      }
    }

    return _SummaryParts(visual: visual, climate: climate);
  }

  /// Teks pengamatan visual (kondisi gunung, asap kawah, guguran, dsb)
  String get visualObservation {
    final parts = _parsedParts;
    if (parts.visual.isEmpty) return summary ?? '';
    return parts.visual.join(' ');
  }

  /// Teks kondisi klimatologi (cuaca, suhu, kelembaban, tekanan, angin)
  String? get climatology {
    final parts = _parsedParts;
    if (parts.climate.isEmpty) return null;
    return parts.climate.join(' ');
  }

  /// Warna level untuk UI (sesuai standar PVMBG)
  static Map<int, _LevelStyle> get levelStyles => const {
        1: _LevelStyle(colorHex: 0xFF4CAF50, label: 'Normal'),
        2: _LevelStyle(colorHex: 0xFFFFEB3B, label: 'Waspada'),
        3: _LevelStyle(colorHex: 0xFFFF9800, label: 'Siaga'),
        4: _LevelStyle(colorHex: 0xFFF44336, label: 'Awas'),
      };

  _LevelStyle get style =>
      levelStyles[levelCode] ?? const _LevelStyle(colorHex: 0xFF9E9E9E, label: 'N/A');

  /// Format angka: hilangkan desimal jika bulat, max 1 desimal
  static String _fmt(double? v) {
    if (v == null) return '-';
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _SummaryParts {
  final List<String> visual;
  final List<String> climate;
  const _SummaryParts({required this.visual, required this.climate});
}

/// Style data untuk badge level aktivitas
class _LevelStyle {
  final int colorHex;
  final String label;
  const _LevelStyle({required this.colorHex, required this.label});
}
