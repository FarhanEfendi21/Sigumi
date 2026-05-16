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
  });

  factory VolcanicDailyReport.fromJson(Map<String, dynamic> json) {
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
    );
  }

  /// Label periode tampilan, e.g. "00:00 – 06:00 WIB"
  String get periodLabel {
    if (periodStart != null && periodEnd != null) {
      return '$periodStart – $periodEnd $timezone';
    }
    return timezone;
  }

  // ────────────────────────────────────────────────
  // Parsed sections dari summary (client-side split)
  // ────────────────────────────────────────────────

  /// Kalimat/frasa yang merupakan indikator klimatologi dari MAGMA.
  static const _climateKeywords = [
    'cuaca', 'suhu udara', 'kelembaban', 'tekanan udara',
    'angin lemah', 'angin sedang', 'angin kencang',
    'angin ke arah', 'angin tenang',
  ];

  /// Apakah kalimat ini termasuk klimatologi?
  static bool _isClimateSentence(String sentence) {
    final lower = sentence.toLowerCase().trim();
    return _climateKeywords.any((kw) => lower.contains(kw));
  }

  /// Pecah kalimat dari summary, return {visual: [...], climate: [...]}
  _SummaryParts get _parsedParts {
    if (summary == null || summary!.isEmpty) {
      return const _SummaryParts(visual: [], climate: []);
    }

    // Split by '. ' atau '.' agar tiap kalimat diproses
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
        1: _LevelStyle(colorHex: 0xFF4CAF50, label: 'Normal'),     // hijau
        2: _LevelStyle(colorHex: 0xFFFFEB3B, label: 'Waspada'),    // kuning
        3: _LevelStyle(colorHex: 0xFFFF9800, label: 'Siaga'),      // oranye
        4: _LevelStyle(colorHex: 0xFFF44336, label: 'Awas'),       // merah
      };

  _LevelStyle get style =>
      levelStyles[levelCode] ?? const _LevelStyle(colorHex: 0xFF9E9E9E, label: 'N/A');
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
