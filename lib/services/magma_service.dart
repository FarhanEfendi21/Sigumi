import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;

class VolcanoStatus {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int statusLevel;
  final String statusLabel;
  final String? lastUpdate;

  VolcanoStatus({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.statusLevel,
    required this.statusLabel,
    this.lastUpdate,
  });

  factory VolcanoStatus.fromJson(Map<String, dynamic> json) {
    final name = json['nama_gunungapi'] ?? json['name'] ?? 'Unknown';
    final lat = _parseDouble(json['latitude'] ?? json['lat'] ?? 0);
    final lng = _parseDouble(json['longitude'] ?? json['lon'] ?? 0);
    final level = _parseLevel(json['tingkat_aktivitas'] ?? json['level'] ?? '1');
    return VolcanoStatus(
      id: json['id']?.toString() ?? name,
      name: name,
      latitude: lat,
      longitude: lng,
      statusLevel: level,
      statusLabel: _levelToLabel(level),
      lastUpdate: json['tanggal'] ?? json['last_update'],
    );
  }

  static double _parseDouble(dynamic val) {
    if (val is double) return val;
    if (val is int) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  static int _parseLevel(dynamic val) {
    final str = val.toString().toLowerCase();
    if (str.contains('awas') || str == '4') return 4;
    if (str.contains('siaga') || str == '3') return 3;
    if (str.contains('waspada') || str == '2') return 2;
    return 1;
  }

  static String _levelToLabel(int level) {
    switch (level) {
      case 4: return 'Awas';
      case 3: return 'Siaga';
      case 2: return 'Waspada';
      default: return 'Normal';
    }
  }
}

class MagmaService {
  static const _baseUrl = 'https://magma.esdm.go.id/v1';
  static const _timeout = Duration(seconds: 15);
  static const _headers = {
    'Accept': 'application/json',
    'User-Agent': 'Mozilla/5.0 (Linux; Android 10) AppleWebKit/537.36',
  };

  static Future<List<VolcanoStatus>> fetchAllVolcanoStatus() async {
  try {
    final uri = Uri.parse('$_baseUrl/gunung-api/tingkat-aktivitas');
    final response = await http.get(uri, headers: _headers).timeout(_timeout);
    if (response.statusCode == 200) {
      final parsed = _parseResponse(response.body);
      if (parsed.isNotEmpty) return parsed;
    }
  } catch (_) {
    // Tangkap semua error: network, timeout, dll
  }

  return _mockVolcanoList();
}

  static List<VolcanoStatus> _parseResponse(String body) {
    try {
      final decoded = json.decode(body);
      List<dynamic> items;
      if (decoded is List) {
        items = decoded;
      } else if (decoded is Map) {
        items = (decoded['data'] ?? decoded['gunungapi'] ?? decoded['result'] ?? []) as List;
      } else {
        return [];
      }
      return items
          .whereType<Map<String, dynamic>>()
          .map(VolcanoStatus.fromJson)
          .where((v) => v.latitude != 0 && v.longitude != 0)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<VolcanoStatus> _mockVolcanoList() => [
    VolcanoStatus(id: 'merapi', name: 'Merapi', latitude: -7.5407, longitude: 110.4457, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'semeru', name: 'Semeru', latitude: -8.1077, longitude: 112.9226, statusLevel: 3, statusLabel: 'Siaga', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'krakatau', name: 'Anak Krakatau', latitude: -6.1025, longitude: 105.4230, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'bromo', name: 'Bromo', latitude: -7.9425, longitude: 112.9500, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'agung', name: 'Agung', latitude: -8.3428, longitude: 115.5079, statusLevel: 1, statusLabel: 'Normal', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'sinabung', name: 'Sinabung', latitude: 3.1700, longitude: 98.3920, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'marapi', name: 'Marapi', latitude: -0.3817, longitude: 100.4730, statusLevel: 3, statusLabel: 'Siaga', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'lewotobi', name: 'Lewotobi Laki-laki', latitude: -8.5303, longitude: 122.7758, statusLevel: 4, statusLabel: 'Awas', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'ibu', name: 'Ibu', latitude: 1.4883, longitude: 127.6300, statusLevel: 3, statusLabel: 'Siaga', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'dukono', name: 'Dukono', latitude: 1.6933, longitude: 127.8942, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'rinjani', name: 'Rinjani', latitude: -8.4119, longitude: 116.4670, statusLevel: 1, statusLabel: 'Normal', lastUpdate: 'Data lokal (offline)'),
    VolcanoStatus(id: 'kerinci', name: 'Kerinci', latitude: -1.6973, longitude: 101.2641, statusLevel: 2, statusLabel: 'Waspada', lastUpdate: 'Data lokal (offline)'),
  ];
}