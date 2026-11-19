import 'dart:convert';

/// Satu metrik kategori kegempaan harian dari laporan VAR MAGMA Indonesia.
class VolcanoSeismicMetric {
  final int count;
  final String? detail;

  const VolcanoSeismicMetric({required this.count, this.detail});

  VolcanoSeismicMetric merge(VolcanoSeismicMetric other) {
    final mergedDetail =
        (detail != null && detail!.trim().isNotEmpty) ? detail : other.detail;
    return VolcanoSeismicMetric(
      count: count + other.count,
      detail: mergedDetail,
    );
  }
}

/// Ringkasan kegempaan harian terstruktur (4 kategori utama VAR PVMBG/MAGMA).
class VolcanoSeismicitySummary {
  final VolcanoSeismicMetric? guguran;
  final VolcanoSeismicMetric? hembusan;
  final VolcanoSeismicMetric? vulkanik;
  final VolcanoSeismicMetric? tektonik;

  const VolcanoSeismicitySummary({
    this.guguran,
    this.hembusan,
    this.vulkanik,
    this.tektonik,
  });

  bool get hasAnyData =>
      guguran != null ||
      hembusan != null ||
      vulkanik != null ||
      tektonik != null;

  int get totalEvents =>
      (guguran?.count ?? 0) +
      (hembusan?.count ?? 0) +
      (vulkanik?.count ?? 0) +
      (tektonik?.count ?? 0);

  factory VolcanoSeismicitySummary.fromJson(Map<String, dynamic> json) {
    VolcanoSeismicMetric? mergeAll(List<String> keys) {
      VolcanoSeismicMetric? acc;
      for (final key in keys) {
        final metric = _parseMetricValue(json[key]);
        if (metric != null) {
          acc = acc == null ? metric : acc.merge(metric);
        }
      }
      return acc;
    }

    return VolcanoSeismicitySummary(
      guguran: mergeAll(['guguran', 'avalanche', 'rockfall', 'rf']),
      hembusan: mergeAll(['hembusan', 'emission', 'dg']),
      vulkanik: mergeAll([
        'vulkanik',
        'volcanic',
        'vulkanik_dangkal',
        'vulkanik_dalam',
        'hybrid',
        'fase_banyak',
        'vb',
        'va',
        'mp',
      ]),
      tektonik: mergeAll([
        'tektonik',
        'tectonic',
        'tektonik_lokal',
        'tektonik_jauh',
        'tl',
        'tj',
      ]),
    );
  }

  factory VolcanoSeismicitySummary.fromFlatJson(Map<String, dynamic> json) {
    VolcanoSeismicMetric? fromKeys(List<String> keys) {
      for (final key in keys) {
        final metric = _parseMetricValue(json[key]);
        if (metric != null) return metric;
      }
      return null;
    }

    return VolcanoSeismicitySummary(
      guguran: fromKeys(['quake_guguran', 'quake_avalanche_count']),
      hembusan: fromKeys(['quake_hembusan', 'quake_emission_count']),
      vulkanik: fromKeys(['quake_vulkanik', 'quake_volcanic_count']),
      tektonik: fromKeys(['quake_tektonik', 'quake_tectonic_count']),
    );
  }

  /// Ekstraksi best-effort dari narasi laporan VAR PVMBG/MAGMA jika kolom
  /// terstruktur `seismicity` belum tersedia di database.
  factory VolcanoSeismicitySummary.parseFromText(String? text) {
    if (text == null || text.trim().isEmpty) {
      return const VolcanoSeismicitySummary();
    }

    final segments = text
        .split(RegExp(r'(?:[\n;•]+|(?<=\.)\s+|,\s+(?=\d+\s+kali\b)|\s+dan\s+(?=\d+\s+kali\b))'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    VolcanoSeismicMetric? guguran;
    VolcanoSeismicMetric? hembusan;
    VolcanoSeismicMetric? vulkanik;
    VolcanoSeismicMetric? tektonik;

    for (final segment in segments) {
      final lower = segment.toLowerCase();
      final detail = _extractSeismicDetail(segment);

      // Abaikan kalimat visual guguran lava (mis. "Teramati 5 kali guguran lava")
      // agar tidak tercampur dengan rekaman seismik gempa guguran.
      final isVisualLavaAvalanche =
          lower.contains('guguran lava') && !lower.contains('gempa');

      if (!isVisualLavaAvalanche &&
          RegExp(r'\bguguran\b').hasMatch(lower) &&
          (lower.contains('gempa') || lower.contains('amplitudo'))) {
        final count = _extractCountForCategory(lower, r'guguran');
        if (count != null) {
          final m = VolcanoSeismicMetric(count: count, detail: detail);
          guguran = guguran == null ? m : guguran.merge(m);
        }
      }

      if (RegExp(r'\bhembusan\b').hasMatch(lower) &&
          (lower.contains('gempa') || lower.contains('amplitudo'))) {
        final count = _extractCountForCategory(lower, r'hembusan');
        if (count != null) {
          final m = VolcanoSeismicMetric(count: count, detail: detail);
          hembusan = hembusan == null ? m : hembusan.merge(m);
        }
      }

      if (RegExp(r'\b(vulkanik|hybrid|fase\s+banyak)\b').hasMatch(lower)) {
        final count = _extractCountForCategory(
          lower,
          r'(?:vulkanik(?:\s+(?:dangkal|dalam))?|hybrid(?:/fase\s+banyak)?|fase\s+banyak)',
        );
        if (count != null) {
          final m = VolcanoSeismicMetric(count: count, detail: detail);
          vulkanik = vulkanik == null ? m : vulkanik.merge(m);
        }
      }

      if (RegExp(r'\btektonik\b').hasMatch(lower)) {
        final count = _extractCountForCategory(
          lower,
          r'tektonik(?:\s+(?:lokal|jauh))?',
        );
        if (count != null) {
          final m = VolcanoSeismicMetric(count: count, detail: detail);
          tektonik = tektonik == null ? m : tektonik.merge(m);
        }
      }
    }

    return VolcanoSeismicitySummary(
      guguran: guguran,
      hembusan: hembusan,
      vulkanik: vulkanik,
      tektonik: tektonik,
    );
  }

  static VolcanoSeismicMetric? _parseMetricValue(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return VolcanoSeismicMetric(count: raw < 0 ? 0 : raw);
    if (raw is num) {
      final value = raw.toInt();
      return VolcanoSeismicMetric(count: value < 0 ? 0 : value);
    }
    if (raw is String) {
      final parsed = int.tryParse(raw.trim());
      if (parsed != null) {
        return VolcanoSeismicMetric(count: parsed < 0 ? 0 : parsed);
      }
      return null;
    }
    if (raw is Map) {
      final rawCount = raw['count'] ?? raw['jumlah'] ?? raw['total'];
      final parsed =
          rawCount is num
              ? rawCount.toInt()
              : int.tryParse(rawCount?.toString().trim() ?? '');
      if (parsed == null) return null;

      final parts = <String>[];
      final detail = raw['detail']?.toString().trim();
      if (detail != null && detail.isNotEmpty) {
        parts.add(detail);
      } else {
        final amp = (raw['amplitude'] ?? raw['amplitudo'])?.toString().trim();
        final dur = (raw['duration'] ?? raw['durasi'])?.toString().trim();
        if (amp != null && amp.isNotEmpty) parts.add('Amp $amp');
        if (dur != null && dur.isNotEmpty) parts.add('Dur $dur');
      }
      return VolcanoSeismicMetric(
        count: parsed < 0 ? 0 : parsed,
        detail: parts.isEmpty ? null : parts.join(' · '),
      );
    }
    return null;
  }

  static int? _extractCountForCategory(String lowerSegment, String categoryRe) {
    // Pola 1: "45 kali gempa guguran" / "3 kali aktivitas gempa vulkanik dalam"
    final before = RegExp(
      r'(\d+)\s*(?:kali\s+)?(?:aktivitas\s+)?(?:gempa\s+)?' +
          categoryRe +
          r'\b',
    ).firstMatch(lowerSegment);
    if (before != null) {
      return int.tryParse(before.group(1)!);
    }

    // Pola 2: "gempa guguran tercatat 45 kali" / "gempa hembusan: 3"
    final after = RegExp(
      r'(?:gempa\s+)?' +
          categoryRe +
          r'(?:\s+(?:tercatat|berjumlah|sebanyak|jumlah))?\s*[:=]?\s*(\d+)\s*(?:kali|kejadian)?\b',
    ).firstMatch(lowerSegment);
    if (after != null) {
      return int.tryParse(after.group(1)!);
    }
    return null;
  }

  static String? _extractSeismicDetail(String segment) {
    final parts = <String>[];
    final ampMatch = RegExp(
      r'amplitudo\s+([\d.,]+(?:\s*-\s*[\d.,]+)?\s*mm)',
      caseSensitive: false,
    ).firstMatch(segment);
    if (ampMatch != null) {
      parts.add('Amp ${ampMatch.group(1)!.trim()}');
    }
    final durMatch = RegExp(
      r'(?:lama\s+gempa|durasi)\s+([\d.,]+(?:\s*-\s*[\d.,]+)?\s*(?:detik|dtk|s))',
      caseSensitive: false,
    ).firstMatch(segment);
    if (durMatch != null) {
      parts.add('Dur ${durMatch.group(1)!.trim()}');
    }
    return parts.isEmpty ? null : parts.join(' · ');
  }
}

/// Ringkasan pengamatan visual puncak & kawah dari laporan VAR MAGMA Indonesia.
class VolcanoVisualObservation {
  final String? visibility;
  final String? craterSmoke;
  final String? avalancheNotes;

  const VolcanoVisualObservation({
    this.visibility,
    this.craterSmoke,
    this.avalancheNotes,
  });

  bool get hasAnyData =>
      (visibility?.trim().isNotEmpty ?? false) ||
      (craterSmoke?.trim().isNotEmpty ?? false) ||
      (avalancheNotes?.trim().isNotEmpty ?? false);
}

/// Model untuk data ringkasan aktivitas gunung berapi harian.
/// Data ini di-fetch dari MAGMA Indonesia (PVMBG) dan disimpan di Supabase.
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

  // ── Kolom opsional tambahan dari VAR & VONA MAGMA Indonesia ──
  final String? visualPhotoUrl;
  final String? vonaColorCode;
  final String? visibility;
  final String? craterSmoke;
  final String? avalancheNotes;
  final VolcanoSeismicitySummary? seismicity;

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
    this.visualPhotoUrl,
    this.vonaColorCode,
    this.visibility,
    this.craterSmoke,
    this.avalancheNotes,
    this.seismicity,
  });

  /// Parse dari JSON Supabase (kompatibel penuh dengan skema lama maupun baru).
  factory VolcanoSummarizer.fromJson(Map<String, dynamic> json) {
    final rawSeismicity = json['seismicity'];
    VolcanoSeismicitySummary? parsedSeismicity;
    if (rawSeismicity is Map) {
      final map = Map<String, dynamic>.from(rawSeismicity);
      final candidate = VolcanoSeismicitySummary.fromJson(map);
      if (candidate.hasAnyData) parsedSeismicity = candidate;
    } else if (rawSeismicity is String && rawSeismicity.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(rawSeismicity);
        if (decoded is Map) {
          final candidate = VolcanoSeismicitySummary.fromJson(
            Map<String, dynamic>.from(decoded),
          );
          if (candidate.hasAnyData) parsedSeismicity = candidate;
        }
      } catch (_) {
        // Abaikan jika JSON string tidak valid; fallback ke ekstraksi teks.
      }
    }
    if (parsedSeismicity == null) {
      final flat = VolcanoSeismicitySummary.fromFlatJson(json);
      if (flat.hasAnyData) parsedSeismicity = flat;
    }

    return VolcanoSummarizer(
      id: json['id']?.toString() ?? '',
      fetchedAt:
          json['fetched_at'] != null
              ? DateTime.tryParse(json['fetched_at'].toString())
              : null,
      reportDate:
          DateTime.tryParse(json['report_date']?.toString() ?? '') ??
          DateTime.now(),
      volcanoName: json['volcano_name']?.toString() ?? '',
      volcanoKey: json['volcano_key']?.toString() ?? '',
      levelCode:
          json['level_code'] is num
              ? (json['level_code'] as num).toInt()
              : int.tryParse(json['level_code']?.toString() ?? '') ?? 1,
      levelName: json['level_name']?.toString() ?? 'Normal',
      periodStart: _cleanOptionalString(json['period_start']),
      periodEnd: _cleanOptionalString(json['period_end']),
      timezone: _cleanOptionalString(json['timezone']) ?? 'WIB',
      summary: _cleanOptionalString(json['summary']),
      detailUrl: _cleanOptionalString(json['detail_url']),
      author: _cleanOptionalString(json['author']),
      weather: _cleanOptionalString(json['weather']),
      windDirection: _cleanOptionalString(json['wind_direction']),
      windSpeedText: _cleanOptionalString(json['wind_speed_text']),
      tempMin: _toDouble(json['temp_min']),
      tempMax: _toDouble(json['temp_max']),
      humidityMin: _toDouble(json['humidity_min']),
      humidityMax: _toDouble(json['humidity_max']),
      pressureMin: _toDouble(json['pressure_min']),
      pressureMax: _toDouble(json['pressure_max']),
      visualPhotoUrl: _cleanOptionalString(
        json['visual_photo_url'] ?? json['photo_url'] ?? json['image_url'],
      ),
      vonaColorCode: _normalizeVonaCode(
        json['vona_color_code'] ?? json['vona_code'],
      ),
      visibility: _cleanOptionalString(
        json['visibility'] ?? json['visual_visibility'],
      ),
      craterSmoke: _cleanOptionalString(
        json['crater_smoke'] ?? json['asap_kawah'],
      ),
      avalancheNotes: _cleanOptionalString(
        json['avalanche_notes'] ??
            json['guguran_notes'] ??
            json['pyroclastic_notes'],
      ),
      seismicity: parsedSeismicity,
    );
  }

  static String? _cleanOptionalString(dynamic value) {
    if (value == null) return null;
    final trimmed = value.toString().trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString().trim());
  }

  static String? _normalizeVonaCode(dynamic raw) {
    if (raw == null) return null;
    final upper = raw.toString().trim().toUpperCase();
    if (upper.isEmpty) return null;
    if (upper.contains('RED') || upper.contains('MERAH')) return 'RED';
    if (upper.contains('ORANGE') ||
        upper.contains('ORANYE') ||
        upper.contains('JINGGA')) {
      return 'ORANGE';
    }
    if (upper.contains('YELLOW') || upper.contains('KUNING')) return 'YELLOW';
    if (upper.contains('GREEN') || upper.contains('HIJAU')) return 'GREEN';
    return null;
  }

  static String _formatClockText(String raw) {
    final normalized = raw.trim().replaceAll('.', ':');
    final hhmmss = RegExp(r'^(\d{1,2}:\d{2})(?::\d{2})?$').firstMatch(
      normalized,
    );
    if (hhmmss != null) {
      final parts = hhmmss.group(1)!.split(':');
      return '${parts[0].padLeft(2, '0')}:${parts[1]}';
    }
    return raw.trim();
  }

  /// Angka Romawi level status (I–IV) sesuai standar MAGMA Indonesia.
  String get levelRoman {
    switch (levelCode) {
      case 1:
        return 'I';
      case 2:
        return 'II';
      case 3:
        return 'III';
      case 4:
        return 'IV';
      default:
        return '$levelCode';
    }
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

  /// Periode pengamatan asli dari VAR MAGMA (menggantikan jam statis '00.00').
  String get periodDisplay {
    final start = periodStart?.trim();
    final end = periodEnd?.trim();
    final tz = timezone.trim().isNotEmpty ? timezone.trim() : 'WIB';

    if (start != null && start.isNotEmpty && end != null && end.isNotEmpty) {
      return '${_formatClockText(start)}–${_formatClockText(end)} $tz';
    }
    if (start != null && start.isNotEmpty) {
      return '${_formatClockText(start)} $tz';
    }
    if (end != null && end.isNotEmpty) {
      return 's/d ${_formatClockText(end)} $tz';
    }
    if (fetchedAt != null) {
      final local = fetchedAt!.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '$hh:$mm $tz';
    }
    return 'Harian · $tz';
  }

  /// Kode warna VONA resmi (`GREEN`, `YELLOW`, `ORANGE`, `RED`), atau `null`
  /// jika belum ada rilis VONA pada laporan.
  String? get normalizedVonaCode {
    final direct = _normalizeVonaCode(vonaColorCode);
    if (direct != null) return direct;

    final text = summary;
    if (text == null || text.isEmpty) return null;
    final match = RegExp(
      r'\bVONA\b[^.\n]{0,32}\b(GREEN|YELLOW|ORANGE|RED|HIJAU|KUNING|ORANYE|MERAH)\b',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      return _normalizeVonaCode(match.group(1));
    }
    return null;
  }

  /// Pengamatan visual terstruktur (prioritas kolom DB, fallback ekstraksi
  /// kalimat dari `summary` agar kompatibel dengan data eksisting).
  VolcanoVisualObservation get resolvedVisualObservation {
    String? resolvedVisibility = visibility;
    String? resolvedSmoke = craterSmoke;
    String? resolvedAvalanche = avalancheNotes;

    final text = summary;
    if (text != null &&
        text.trim().isNotEmpty &&
        (resolvedVisibility == null ||
            resolvedSmoke == null ||
            resolvedAvalanche == null)) {
      final sentences = text
          .split(RegExp(r'(?<=[.!?])\s+|\n+'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);

      for (final sentence in sentences) {
        final lower = sentence.toLowerCase();
        if (resolvedVisibility == null &&
            RegExp(
              r'(terlihat\s+jelas|tertutup\s+kabut|kabut\s+0-|visibilitas)',
            ).hasMatch(lower)) {
          resolvedVisibility = sentence;
        }
        if (resolvedSmoke == null &&
            RegExp(
              r'(asap\s+kawah|asap\s+putih|asap\s+kelabu|hembusan\s+asap|solfatara)',
            ).hasMatch(lower)) {
          resolvedSmoke = sentence;
        }
        if (resolvedAvalanche == null &&
            RegExp(
              r'(guguran\s+lava|awan\s+panas|guguran\s+pijar|jarak\s+luncur|sinar\s+api|lontaran)',
            ).hasMatch(lower)) {
          resolvedAvalanche = sentence;
        }
      }
    }

    return VolcanoVisualObservation(
      visibility: resolvedVisibility,
      craterSmoke: resolvedSmoke,
      avalancheNotes: resolvedAvalanche,
    );
  }

  /// Data kegempaan harian terstruktur (prioritas kolom DB, fallback ekstraksi
  /// dari teks `summary`).
  VolcanoSeismicitySummary get resolvedSeismicity {
    if (seismicity != null && seismicity!.hasAnyData) {
      return seismicity!;
    }
    return VolcanoSeismicitySummary.parseFromText(summary);
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
