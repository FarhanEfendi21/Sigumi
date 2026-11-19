class HikingWeatherForecast {
  const HikingWeatherForecast({
    required this.areaName,
    required this.analysisDate,
    required this.fetchedAt,
    required this.forecasts,
    required this.warnings,
    this.timezoneLabel = 'WITA',
    this.utcOffsetHours = 8,
    this.isStale = false,
  });

  final String areaName;
  final DateTime? analysisDate;
  final DateTime fetchedAt;
  final List<HikingWeatherSlot> forecasts;
  final List<HikingWeatherWarning> warnings;
  final String timezoneLabel;
  final int utcOffsetHours;
  final bool isStale;

  HikingWeatherForecast withStale(bool stale) => HikingWeatherForecast(
    areaName: areaName,
    analysisDate: analysisDate,
    fetchedAt: fetchedAt,
    forecasts: forecasts,
    warnings: warnings,
    timezoneLabel: timezoneLabel,
    utcOffsetHours: utcOffsetHours,
    isStale: stale,
  );

  /// Panjang jendela satu slot prakiraan BMKG.
  static const Duration slotWindow = Duration(hours: 3);

  /// Slot prakiraan yang jendela 3 jamnya belum berakhir pada [now].
  ///
  /// Backend sudah memfilter slot lampau saat data diambil, tetapi data yang
  /// tersimpan di perangkat bisa dibuka berjam-jam kemudian (mis. saat offline).
  /// Tanpa filter ulang, slot lampau akan tampil sebagai kondisi "Terkini".
  /// Slot tanpa waktu yang dapat dibaca tetap dipertahankan.
  List<HikingWeatherSlot> activeForecasts([DateTime? now]) {
    final nowUtc = (now ?? DateTime.now()).toUtc();
    return forecasts.where((slot) {
      final start = slot.startUtc(utcOffsetHours);
      if (start == null) return true;
      return start.add(slotWindow).isAfter(nowUtc);
    }).toList();
  }

  /// Peringatan yang masih berlaku pada [now]: peringatan CAP yang belum
  /// kedaluwarsa, atau (jika tidak ada) peringatan otomatis dari slot aktif.
  List<HikingWeatherWarning> activeWarnings([DateTime? now]) {
    final nowUtc = (now ?? DateTime.now()).toUtc();
    final liveWarnings =
        warnings
            .where(
              (warning) =>
                  warning.expiresAt == null ||
                  warning.expiresAt!.toUtc().isAfter(nowUtc),
            )
            .toList();
    if (liveWarnings.isNotEmpty) return liveWarnings;
    return _forecastWarnings(activeForecasts(nowUtc));
  }

  /// Mengembalikan daftar peringatan cuaca yang menggabungkan peringatan dini
  /// CAP BMKG (`warnings`) dan peringatan otomatis dari slot prakiraan terdekat
  /// apabila terdeteksi kondisi cuaca berbahaya (seperti Hujan Lebat / Hujan Petir).
  ///
  /// Tidak memperhitungkan waktu; untuk tampilan gunakan [activeWarnings].
  List<HikingWeatherWarning> get effectiveWarnings {
    if (warnings.isNotEmpty) return warnings;
    return _forecastWarnings(forecasts);
  }

  List<HikingWeatherWarning> _forecastWarnings(List<HikingWeatherSlot> slots) {
    if (slots.isEmpty) return const [];

    final candidateSlots = slots.take(2).toList();
    HikingWeatherSlot? targetSlot;
    for (final slot in candidateSlots) {
      if (slot.isSevereWeather) {
        targetSlot = slot;
        break;
      }
    }
    targetSlot ??= candidateSlots.cast<HikingWeatherSlot?>().firstWhere(
      (slot) => slot != null && slot.isModerateHazardWeather,
      orElse: () => null,
    );

    if (targetSlot == null) return const [];

    final isSevere = targetSlot.isSevereWeather;
    final condLabel =
        targetSlot.condition.trim().isNotEmpty
            ? targetSlot.condition.trim()
            : (isSevere ? 'Cuaca Ekstrem' : 'Cuaca Kurang Bersahabat');
    final windInfo =
        (targetSlot.windKmh != null && targetSlot.windKmh! >= 20)
            ? ' disertai angin ${targetSlot.windKmh!.round()} km/j'
            : '';
    final areaLabel = areaName.trim().isNotEmpty ? ' di wilayah $areaName' : '';

    final headline =
        isSevere
            ? 'Peringatan Cuaca Pendakian: $condLabel'
            : 'Waspada Cuaca Pendakian: $condLabel';
    final description =
        isSevere
            ? 'Prakiraan BMKG$areaLabel menunjukkan potensi ${condLabel.toLowerCase()}$windInfo. Waspadai jalur licin, risiko hipotermia, jarak pandang terbatas, serta bahaya petir di area terbuka.'
            : 'Prakiraan BMKG$areaLabel menunjukkan potensi ${condLabel.toLowerCase()}$windInfo. Siapkan perlengkapan pelindung hujan dan pantau kondisi jalur.';

    final slotTimeKey =
        targetSlot.utcDateTime?.toIso8601String() ??
        targetSlot.localDateTime?.toIso8601String() ??
        'current';

    return [
      HikingWeatherWarning(
        identifier: 'forecast_hazard_${slotTimeKey}_$condLabel',
        headline: headline,
        description: description,
        severity: isSevere ? 'Severe' : 'Moderate',
        urgency: isSevere ? 'Immediate' : 'Expected',
        expiresAt: targetSlot.startUtc(utcOffsetHours)?.add(slotWindow),
      ),
    ];
  }

  Map<String, dynamic> toJson() => {
    'area': {
      'name': areaName,
      'timezone': timezoneLabel,
      'utc_offset_hours': utcOffsetHours,
    },
    'analysis_date': analysisDate?.toIso8601String(),
    'fetched_at': fetchedAt.toIso8601String(),
    'forecast': forecasts.map((slot) => slot.toJson()).toList(),
    'warnings': warnings.map((warning) => warning.toJson()).toList(),
  };

  factory HikingWeatherForecast.fromJson(Map<String, dynamic> json) {
    final forecastRows = json['forecast'] as List? ?? const [];
    final warningRows = json['warnings'] as List? ?? const [];
    final area = json['area'] is Map ? json['area'] as Map : null;
    return HikingWeatherForecast(
      areaName: (area?['name'] ?? json['area'])?.toString() ?? '',
      analysisDate: parseUtcDateTime(json['analysis_date']),
      fetchedAt:
          parseUtcDateTime(json['fetched_at']) ?? DateTime.now().toUtc(),
      timezoneLabel: area?['timezone']?.toString() ?? 'WITA',
      utcOffsetHours: (area?['utc_offset_hours'] as num?)?.toInt() ?? 8,
      forecasts:
          forecastRows
              .whereType<Map>()
              .map(
                (row) =>
                    HikingWeatherSlot.fromJson(Map<String, dynamic>.from(row)),
              )
              .toList(),
      warnings:
          warningRows
              .whereType<Map>()
              .map(
                (row) => HikingWeatherWarning.fromJson(
                  Map<String, dynamic>.from(row),
                ),
              )
              .toList(),
    );
  }
}

class HikingWeatherSlot {
  const HikingWeatherSlot({
    required this.utcDateTime,
    required this.localDateTime,
    required this.temperatureC,
    required this.humidityPercent,
    required this.condition,
    required this.windKmh,
    required this.windDirection,
  });

  final DateTime? utcDateTime;
  final DateTime? localDateTime;
  final double? temperatureC;
  final double? humidityPercent;
  final String condition;
  final double? windKmh;
  final String windDirection;

  /// Mengecek apakah kondisi prakiraan termasuk cuaca ekstrem bagi pendaki
  /// (Hujan Lebat, Hujan Sangat Lebat, Hujan Petir/Kilat, Badai, atau angin >= 35 km/j).
  bool get isSevereWeather {
    final c = condition.trim().toLowerCase();
    final wind = windKmh ?? 0;
    return c.contains('hujan lebat') ||
        c.contains('hujan sangat lebat') ||
        c.contains('hujan petir') ||
        c.contains('petir') ||
        c.contains('kilat') ||
        c.contains('badai') ||
        c.contains('ekstrem') ||
        c.contains('heavy rain') ||
        c.contains('thunderstorm') ||
        wind >= 35;
  }

  /// Mengecek apakah kondisi prakiraan memerlukan kewaspadaan pendaki
  /// (Hujan Sedang, Kabut Tebal, atau angin >= 25 km/j).
  bool get isModerateHazardWeather {
    if (isSevereWeather) return false;
    final c = condition.trim().toLowerCase();
    final wind = windKmh ?? 0;
    return c.contains('hujan sedang') ||
        c.contains('kabut tebal') ||
        c.contains('moderate rain') ||
        c.contains('dense fog') ||
        wind >= 25;
  }

  /// Waktu mulai slot dalam UTC. Memakai `utc_datetime`, atau menurunkan dari
  /// `local_datetime` (jam dinding wilayah) dikurangi offset zona wilayah.
  DateTime? startUtc(int utcOffsetHours) {
    final utc = utcDateTime;
    if (utc != null) return utc.toUtc();
    final local = localDateTime;
    if (local == null) return null;
    return _asUtcComponents(local).subtract(Duration(hours: utcOffsetHours));
  }

  Map<String, dynamic> toJson() => {
    'utc_datetime': utcDateTime?.toIso8601String(),
    'local_datetime': localDateTime?.toIso8601String(),
    'temperature_c': temperatureC,
    'humidity_percent': humidityPercent,
    'condition': condition,
    'wind_kmh': windKmh,
    'wind_direction': windDirection,
  };

  factory HikingWeatherSlot.fromJson(Map<String, dynamic> json) =>
      HikingWeatherSlot(
        utcDateTime: parseUtcDateTime(json['utc_datetime']),
        localDateTime: DateTime.tryParse(
          json['local_datetime']?.toString() ?? '',
        ),
        temperatureC: (json['temperature_c'] as num?)?.toDouble(),
        humidityPercent: (json['humidity_percent'] as num?)?.toDouble(),
        condition: json['condition']?.toString() ?? '',
        windKmh: (json['wind_kmh'] as num?)?.toDouble(),
        windDirection: json['wind_direction']?.toString() ?? '',
      );
}

class HikingWeatherWarning {
  const HikingWeatherWarning({
    required this.identifier,
    required this.headline,
    required this.description,
    required this.severity,
    required this.urgency,
    this.expiresAt,
  });

  final String identifier;
  final String headline;
  final String description;
  final String severity;
  final String urgency;
  final DateTime? expiresAt;

  Map<String, dynamic> toJson() => {
    'identifier': identifier,
    'headline': headline,
    'description': description,
    'severity': severity,
    'urgency': urgency,
    'expires_at': expiresAt?.toIso8601String(),
  };

  factory HikingWeatherWarning.fromJson(Map<String, dynamic> json) =>
      HikingWeatherWarning(
        identifier: json['identifier']?.toString() ?? '',
        headline: json['headline']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        severity: json['severity']?.toString() ?? '',
        urgency: json['urgency']?.toString() ?? '',
        expiresAt: parseUtcDateTime(json['expires_at']),
      );
}

/// Parse timestamp yang semantiknya UTC.
///
/// BMKG mengirim `utc_datetime` tanpa penanda zona (mis. `2026-11-18 06:00:00`),
/// yang oleh [DateTime.tryParse] dibaca sebagai waktu lokal perangkat. Nilai
/// tanpa zona dianggap UTC; nilai dengan `Z` / offset dikonversi normal.
DateTime? parseUtcDateTime(Object? raw) {
  final text = raw?.toString().trim() ?? '';
  if (text.isEmpty) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed == null) return null;
  return parsed.isUtc ? parsed : _asUtcComponents(parsed);
}

DateTime _asUtcComponents(DateTime value) =>
    value.isUtc
        ? value
        : DateTime.utc(
          value.year,
          value.month,
          value.day,
          value.hour,
          value.minute,
          value.second,
          value.millisecond,
          value.microsecond,
        );
