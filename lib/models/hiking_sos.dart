enum HikingSosStatus {
  savedToServer,
  acknowledged,
  resolved,
  cancelled,
  queuedOffline,
  failed,
}

HikingSosStatus parseHikingSosServerStatus(String? status) {
  switch (status?.trim().toLowerCase()) {
    case 'acknowledged':
      return HikingSosStatus.acknowledged;
    case 'resolved':
      return HikingSosStatus.resolved;
    case 'cancelled':
      return HikingSosStatus.cancelled;
    case 'open':
    default:
      return HikingSosStatus.savedToServer;
  }
}

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
    this.remoteId,
    this.location,
    this.createdAt,
    this.acknowledgedAt,
    this.resolvedAt,
  });

  final HikingSosStatus status;
  final HikingSosFailure failure;
  final String? alertId;
  final String? remoteId;
  final HikingSosLocation? location;
  final DateTime? createdAt;
  final DateTime? acknowledgedAt;
  final DateTime? resolvedAt;

  bool get isQueued => status == HikingSosStatus.queuedOffline;

  bool get isServerStored =>
      status == HikingSosStatus.savedToServer ||
      status == HikingSosStatus.acknowledged ||
      status == HikingSosStatus.resolved ||
      status == HikingSosStatus.cancelled;

  HikingSosResult copyWith({
    HikingSosStatus? status,
    HikingSosFailure? failure,
    String? alertId,
    String? remoteId,
    HikingSosLocation? location,
    DateTime? createdAt,
    DateTime? acknowledgedAt,
    DateTime? resolvedAt,
  }) {
    return HikingSosResult(
      status: status ?? this.status,
      failure: failure ?? this.failure,
      alertId: alertId ?? this.alertId,
      remoteId: remoteId ?? this.remoteId,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      acknowledgedAt: acknowledgedAt ?? this.acknowledgedAt,
      resolvedAt: resolvedAt ?? this.resolvedAt,
    );
  }
}
