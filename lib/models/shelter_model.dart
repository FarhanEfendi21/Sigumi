import 'dart:typed_data';

/// Model untuk Posko Evakuasi & Fasilitas Kesehatan
class ShelterModel {
  final String id;
  final String volcanoId;
  final String name;
  final String type; // 'posko_evakuasi', 'rumah_sakit', 'puskesmas', 'klinik', 'balai_desa', 'gor'
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final int? capacity;
  final bool hasMedical;
  final bool hasKitchen;
  final bool hasToilet;
  final bool is24h;
  final bool isActive;
  final String? notes;
  final double? distanceFromVolcano; // km, dari database
  final double? distanceFromUser;    // km, dihitung real-time
  final String? volcanoName;

  const ShelterModel({
    required this.id,
    required this.volcanoId,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.capacity,
    this.hasMedical = false,
    this.hasKitchen = false,
    this.hasToilet = true,
    this.is24h = false,
    this.isActive = true,
    this.notes,
    this.distanceFromVolcano,
    this.distanceFromUser,
    this.volcanoName,
  });

  /// Parse dari response Supabase RPC get_nearby_shelters
  factory ShelterModel.fromRpc(Map<String, dynamic> json) {
    return ShelterModel(
      id: json['id'] as String,
      volcanoId: '',
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      capacity: json['capacity'] as int?,
      hasMedical: json['has_medical'] as bool? ?? false,
      hasKitchen: json['has_kitchen'] as bool? ?? false,
      hasToilet: json['has_toilet'] as bool? ?? true,
      is24h: json['is_24h'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
      notes: json['notes'] as String?,
      distanceFromVolcano: (json['distance_from_volcano'] as num?)?.toDouble(),
      distanceFromUser: (json['distance_km'] as num?)?.toDouble(),
      volcanoName: json['volcano_name'] as String?,
    );
  }

  /// Parse titik dari tabel `evakuasi` yang memakai nama kolom Indonesia
  /// maupun Inggris. Baris tanpa koordinat valid dilewati oleh repository.
  static ShelterModel? fromEvakuasiRow(Map<String, dynamic> json) {
    final coordinates = _coordinates(json);
    if (coordinates == null) return null;

    final name = _firstValue(json, const [
      'nama', 'nama_titik', 'nama_lokasi', 'nama_tempat', 'nama_evakuasi', 'name', 'title',
    ]);
    final id = _firstValue(json, const ['id', 'uuid']);
    final type = _firstValue(json, const ['type', 'jenis', 'tipe']);
    final activeValue = json['is_active'] ?? json['aktif'] ?? json['status'];

    return ShelterModel(
      id: id?.toString() ?? '${coordinates.$1},${coordinates.$2}',
      volcanoId: json['volcano_id']?.toString() ?? '',
      name: name?.toString() ?? 'Titik Evakuasi',
      type: _normalizeType(type?.toString()),
      latitude: coordinates.$1,
      longitude: coordinates.$2,
      address: _firstValue(json, const ['alamat', 'address'])?.toString(),
      phone: _firstValue(json, const ['telepon', 'phone', 'no_telp'])?.toString(),
      capacity: _toInt(_firstValue(json, const ['kapasitas', 'capacity'])),
      hasMedical: _toBool(_firstValue(json, const ['has_medical', 'ada_medis'])) ?? false,
      hasKitchen: _toBool(_firstValue(json, const ['has_kitchen', 'ada_dapur'])) ?? false,
      hasToilet: _toBool(_firstValue(json, const ['has_toilet', 'ada_toilet'])) ?? true,
      is24h: _toBool(_firstValue(json, const ['is_24h', 'buka_24_jam'])) ?? false,
      isActive: _toBool(activeValue) ?? true,
      notes: _firstValue(json, const ['catatan', 'keterangan', 'notes'])?.toString(),
    );
  }

  static Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value != null && value.toString().trim().isNotEmpty) return value;
    }
    return null;
  }

  static (double, double)? _coordinates(Map<String, dynamic> json) {
    final lat = _toDouble(_firstValue(json, const ['latitude', 'lat', 'lintang']));
    final lng = _toDouble(_firstValue(json, const [
      'longitude', 'lng', 'lon', 'long', 'bujur',
    ]));
    if (lat != null && lng != null && lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180) {
      return (lat, lng);
    }

    // Beberapa tabel menyimpan point sebagai GeoJSON: {coordinates: [lng, lat]}.
    final location = json['location'] ?? json['lokasi'] ?? json['koordinat'];
    if (location is Map) {
      final point = location['coordinates'];
      if (point is List && point.length >= 2) {
        final pointLng = _toDouble(point[0]);
        final pointLat = _toDouble(point[1]);
        if (pointLat != null && pointLng != null &&
            pointLat >= -90 && pointLat <= 90 && pointLng >= -180 && pointLng <= 180) {
          return (pointLat, pointLng);
        }
      }
    }
    if (location is String) {
      // Geography columns may be returned as WKT: POINT(longitude latitude).
      final match = RegExp(r'POINT\s*\(\s*(-?[\d.]+)\s+(-?[\d.]+)\s*\)',
              caseSensitive: false)
          .firstMatch(location);
      if (match != null) {
        final pointLng = _toDouble(match.group(1));
        final pointLat = _toDouble(match.group(2));
        if (pointLat != null && pointLng != null &&
            pointLat >= -90 && pointLat <= 90 && pointLng >= -180 && pointLng <= 180) {
          return (pointLat, pointLng);
        }
      }

      // PostgREST can serialize PostGIS geography as EWKB hex, e.g. the
      // `location` column in the deployed shelters table.
      final point = _coordinatesFromWkb(location);
      if (point != null) return point;
    }
    return null;
  }

  static (double, double)? _coordinatesFromWkb(String value) {
    var hex = value.trim();
    if (hex.startsWith(r'\x')) hex = hex.substring(2);
    if (hex.length < 42 || hex.length.isOdd || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      return null;
    }

    try {
      final bytes = Uint8List.fromList([
        for (var i = 0; i < hex.length; i += 2)
          int.parse(hex.substring(i, i + 2), radix: 16),
      ]);
      final data = ByteData.sublistView(bytes);
      final byteOrder = data.getUint8(0);
      if (byteOrder != 0 && byteOrder != 1) return null;
      final endian = byteOrder == 1 ? Endian.little : Endian.big;
      final geometryType = data.getUint32(1, endian);
      final hasSrid = (geometryType & 0x20000000) != 0;
      final baseType = geometryType & 0x0FFFFFFF;
      if (baseType != 1 && baseType % 1000 != 1) return null;
      final coordinateOffset = 5 + (hasSrid ? 4 : 0);
      if (bytes.length < coordinateOffset + 16) return null;

      final longitude = data.getFloat64(coordinateOffset, endian);
      final latitude = data.getFloat64(coordinateOffset + 8, endian);
      if (!latitude.isFinite || !longitude.isFinite ||
          latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        return null;
      }
      return (latitude, longitude);
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }

  static String _normalizeType(String? value) {
    final type = value?.toLowerCase().trim();
    if (type == 'rumah_sakit' || type == 'puskesmas' || type == 'klinik') return type!;
    if (type == 'balai_desa' || type == 'gor') return type!;
    return 'posko_evakuasi';
  }

  static double? _toDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '');
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '');
  }

  static bool? _toBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    switch (value?.toString().toLowerCase().trim()) {
      case 'true':
      case '1':
      case 'aktif':
      case 'active':
        return true;
      case 'false':
      case '0':
      case 'nonaktif':
      case 'inactive':
        return false;
      default:
        return null;
    }
  }

  /// Label tipe dalam Bahasa Indonesia
  String get typeLabel {
    switch (type) {
      case 'posko_evakuasi': return 'Posko Evakuasi';
      case 'rumah_sakit':    return 'Rumah Sakit';
      case 'puskesmas':      return 'Puskesmas';
      case 'klinik':         return 'Klinik';
      case 'balai_desa':     return 'Balai Desa';
      case 'gor':            return 'GOR / Gedung';
      default:               return type;
    }
  }

  /// Apakah ini fasilitas kesehatan (bukan posko)
  bool get isHealthFacility =>
      type == 'rumah_sakit' || type == 'puskesmas' || type == 'klinik';

  /// Apakah ini posko evakuasi / shelter
  bool get isShelter =>
      type == 'posko_evakuasi' || type == 'balai_desa' || type == 'gor';

  /// Jarak user dalam format string
  String get distanceLabel {
    if (distanceFromUser == null) return '— km';
    if (distanceFromUser! < 1) {
      return '${(distanceFromUser! * 1000).toStringAsFixed(0)} m';
    }
    return '${distanceFromUser!.toStringAsFixed(1)} km';
  }

  ShelterModel copyWith({double? distanceFromUser}) {
    return ShelterModel(
      id: id,
      volcanoId: volcanoId,
      name: name,
      type: type,
      latitude: latitude,
      longitude: longitude,
      address: address,
      phone: phone,
      capacity: capacity,
      hasMedical: hasMedical,
      hasKitchen: hasKitchen,
      hasToilet: hasToilet,
      is24h: is24h,
      isActive: isActive,
      notes: notes,
      distanceFromVolcano: distanceFromVolcano,
      distanceFromUser: distanceFromUser ?? this.distanceFromUser,
      volcanoName: volcanoName,
    );
  }
}
