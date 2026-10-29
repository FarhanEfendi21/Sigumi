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
      analysisDate: DateTime.tryParse(json['analysis_date']?.toString() ?? ''),
      fetchedAt:
          DateTime.tryParse(json['fetched_at']?.toString() ?? '') ??
          DateTime.now(),
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
        utcDateTime: DateTime.tryParse(json['utc_datetime']?.toString() ?? ''),
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
        expiresAt: DateTime.tryParse(json['expires_at']?.toString() ?? ''),
      );
}
