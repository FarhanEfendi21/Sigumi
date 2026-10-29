enum HikingSosStatus { savedToServer, queuedOffline, failed }

enum HikingSosFailure {
  none,
  signInRequired,
  sessionInactive,
  locationUnavailable,
  localStorageUnavailable,
}

class HikingSosLocation {
  const HikingSosLocation({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.accuracyMeters,
  });

  final double latitude;
  final double longitude;
  final DateTime recordedAt;
  final double? accuracyMeters;

  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'recorded_at': recordedAt.toUtc().toIso8601String(),
    'accuracy_meters': accuracyMeters,
  };

  factory HikingSosLocation.fromJson(Map<String, dynamic> json) {
    final recordedAt = DateTime.tryParse(json['recorded_at']?.toString() ?? '');
    if (recordedAt == null ||
        json['latitude'] is! num ||
        json['longitude'] is! num) {
      throw const FormatException('Lokasi SOS tersimpan tidak valid.');
    }
    return HikingSosLocation(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      recordedAt: recordedAt,
      accuracyMeters: (json['accuracy_meters'] as num?)?.toDouble(),
    );
  }
}

class HikingSosResult {
  const HikingSosResult({
    required this.status,
    this.failure = HikingSosFailure.none,
    this.alertId,
    this.location,
  });

  final HikingSosStatus status;
  final HikingSosFailure failure;
  final String? alertId;
  final HikingSosLocation? location;

  bool get isQueued => status == HikingSosStatus.queuedOffline;
}
