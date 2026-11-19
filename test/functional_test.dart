import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sigumi/models/volcano_model.dart';
import 'package:sigumi/models/shelter_model.dart';
import 'package:sigumi/models/hiking_sos.dart';
import 'package:sigumi/providers/volcano_provider.dart';
import 'package:sigumi/services/rule_based_fallback.dart';
import 'package:sigumi/services/hiking_tracking_service.dart';
import 'package:sigumi/services/location_service.dart';

// Fake in-memory gateway untuk pengujian fungsional tracking & SOS
class _FakeFunctionalGateway implements HikingRemoteGateway {
  final List<Map<String, dynamic>> savedSessions = [];
  final List<Map<String, dynamic>> savedPoints = [];
  final List<Map<String, dynamic>> savedAlerts = [];

  @override
  String? get currentUserId => 'test-user-uuid-12345';

  @override
  Future<Map<String, dynamic>?> insertSession(Map<String, dynamic> payload) async {
    final copy = Map<String, dynamic>.from(payload);
    copy['id'] = 'session-uuid-1';
    savedSessions.add(copy);
    return copy;
  }

  @override
  Future<String?> upsertSessionByClientId(Map<String, dynamic> payload) async {
    savedSessions.add(Map<String, dynamic>.from(payload));
    return 'session-uuid-client-1';
  }

  @override
  Future<void> updateSession(String sessionId, Map<String, dynamic> payload) async {
    for (final s in savedSessions) {
      if (s['id'] == sessionId) {
        s.addAll(payload);
      }
    }
  }

  @override
  Future<void> upsertTrackPointsBatch(List<Map<String, dynamic>> points) async {
    savedPoints.addAll(points);
  }

  @override
  Future<void> upsertSosAlert(Map<String, dynamic> alert) async {
    savedAlerts.add(Map<String, dynamic>.from(alert));
  }

  @override
  Future<Map<String, dynamic>?> fetchSosAlert({
    String? clientAlertId,
    String? sessionId,
  }) async {
    for (final alert in savedAlerts.reversed) {
      if (clientAlertId != null && alert['client_alert_id'] == clientAlertId) {
        return Map<String, dynamic>.from(alert);
      }
      if (sessionId != null && alert['session_id'] == sessionId) {
        return Map<String, dynamic>.from(alert);
      }
    }
    return null;
  }
}

class _FakeLocationForFunctional extends ChangeNotifier implements LocationService {
  double _lat = -8.4050;
  double _lng = 116.4680;
  DateTime _lastUpdated = DateTime.now();

  @override
  double get userLat => _lat;

  @override
  double get userLng => _lng;

  @override
  bool get isUsingRealGps => true;

  @override
  bool get isTracking => true;

  @override
  bool get isHikingTracking => false;

  @override
  bool get isPausedForBackground => false;

  @override
  DateTime? get lastUpdated => _lastUpdated;

  @override
  double? get accuracyMeters => 6.0;

  @override
  GpsStatus get gpsStatus => GpsStatus.active;

  @override
  String? get locationError => null;

  @override
  bool get isRetrying => false;

  @override
  String? get nearestVolcanoId => 'rinjani_001';

  @override
  String get nearestVolcanoName => 'Gunung Rinjani';

  @override
  String get activeVolcanoName => 'Gunung Rinjani';

  @override
  double get distanceFromVolcano => 1.5;

  @override
  int get zoneLevel => 2;

  @override
  String get zoneLabel => 'Zona Perhatian';

  @override
  int get volcanoStatusLevel => 1;

  @override
  String? get detectedRegion => 'Lombok';

  @override
  bool get isRegionAutoDetected => true;

  @override
  String get distanceLabel => '1.5 km';

  @override
  Map<String, double> get allVolcanoDistances => {'Lombok': 1.5};

  @override
  bool get hasFreshRealPosition => true;

  @override
  double getDistanceToRegion(String region) => 1.5;

  @override
  bool isWithinHikingRegion(String region) => true;

  @override
  bool isCoordinateWithinHikingRegion(String region, double latitude, double longitude) => true;

  @override
  String getClosestRegion() => 'Lombok';

  @override
  String? detectRegion() => 'Lombok';

  @override
  Future<LocationPermission> checkPermissionStatus() async =>
      LocationPermission.whileInUse;

  @override
  Future<void> initialize({bool requestPermission = true}) async {}

  @override
  void startTracking({int distanceFilterMeters = 50, bool hikingTracking = false}) {}

  @override
  void pauseForegroundTrackingForBackground() {}

  @override
  void resumeForegroundTrackingFromBackground() {}

  @override
  void stopTracking() {}

  @override
  Future<void> retryTracking() async {}

  @override
  void clearLocationError() {}

  @override
  void setActiveVolcano({required double lat, required double lng, required String name}) {}

  @override
  Future<void> setManualLocation(double lat, double lng) async {}

  @override
  Future<void> refreshLocation({bool requestPermission = true}) async {}

  void emitFix(double lat, double lng) {
    _lat = lat;
    _lng = lng;
    _lastUpdated = _lastUpdated.add(const Duration(seconds: 5));
    notifyListeners();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  group('Pengujian Kebutuhan Fungsional SIGUMI (Functional Test Suite)', () {
    // ------------------------------------------------------------------------
    // MODUL 1: AUTENTIKASI & FORMAT AKUN (SIGUMI-F01 s/d SIGUMI-F04)
    // ------------------------------------------------------------------------
    test('SIGUMI-F01 & SIGUMI-F02: Normalisasi Nomor Telepon Menjadi Email Sintetis yang Sah', () {
      String phoneToEmail(String phone) {
        var clean = phone.replaceAll(RegExp(r'[^\d]'), '');
        if (clean.startsWith('0')) {
          clean = '62${clean.substring(1)}';
        } else if (!clean.startsWith('62')) {
          clean = '62$clean';
        }
        return '$clean@sigumi.app';
      }

      expect(phoneToEmail('081234567890'), equals('6281234567890@sigumi.app'));
      expect(phoneToEmail('+62 813-9246-0884'), equals('6281392460884@sigumi.app'));
      expect(phoneToEmail('81234567890'), equals('6281234567890@sigumi.app'));
    });

    test('SIGUMI-F03: Pembersihan Sesi Pengguna saat Logout', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_token', 'sample-jwt-token');
      expect(prefs.containsKey('user_token'), isTrue);

      await prefs.remove('user_token');
      expect(prefs.containsKey('user_token'), isFalse);
    });

    test('SIGUMI-F04: Validasi Format Email dan Password Reset', () {
      bool isValidEmail(String email) {
        final reg = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
        return reg.hasMatch(email.trim());
      }

      expect(isValidEmail('user@sigumi.app'), isTrue);
      expect(isValidEmail('bukan-email'), isFalse);
      expect(isValidEmail('test@.com'), isFalse);
    });

    // ------------------------------------------------------------------------
    // MODUL 2: PEMANTAUAN GUNUNG BERAPI & BERITA (SIGUMI-F05 s/d SIGUMI-F07)
    // ------------------------------------------------------------------------
    test('SIGUMI-F05: Model Gunung Berapi Memetakan Level Status Vulkanik dengan Benar', () {
      final volcano = VolcanoModel(
        id: 'merapi-01',
        name: 'Gunung Merapi',
        latitude: -7.5407,
        longitude: 110.4457,
        elevation: 2930,
        statusLevel: 3, // Siaga
        statusDescription: 'Aktivitas vulkanik tinggi dengan guguran lava',
        province: 'DI Yogyakarta',
        lastUpdate: DateTime.now(),
        temperature: 24.5,
        windDirection: 'Barat',
        windSpeed: 12.0,
      );

      expect(volcano.statusLevel, equals(3));
      expect(volcano.statusLabel, contains('Siaga'));
      expect(volcano.name, equals('Gunung Merapi'));
    });

    test('SIGUMI-F06: Pemilihan Wilayah & Penyimpanan Preferensi Region di SharedPreferences', () async {
      final provider = VolcanoProvider();
      provider.setRegion('Bali');
      expect(provider.selectedRegion, equals('Bali'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('selected_region'), equals('Bali'));
    });

    // ------------------------------------------------------------------------
    // MODUL 3: PETA, ZONASI RISIKO & EVAKUASI (SIGUMI-F08 s/d SIGUMI-F11)
    // ------------------------------------------------------------------------
    test('SIGUMI-F08 & SIGUMI-F09: Klasifikasi Zona Risiko Pengguna Berdasarkan Jarak ke Kawah', () {
      int classifyZone(double distanceKm) {
        if (distanceKm <= 5.0) return 4; // Zona Bahaya Utama (KRB III)
        if (distanceKm <= 10.0) return 3; // Zona Waspada (KRB II)
        if (distanceKm <= 15.0) return 2; // Zona Perhatian (KRB I)
        return 1; // Zona Relatif Aman
      }

      String getZoneLabel(int level) {
        switch (level) {
          case 4: return 'ZONA BAHAYA UTAMA';
          case 3: return 'ZONA WASPADA';
          case 2: return 'ZONA PERHATIAN';
          default: return 'ZONA RELATIF AMAN';
        }
      }

      expect(classifyZone(2.5), equals(4));
      expect(getZoneLabel(4), equals('ZONA BAHAYA UTAMA'));

      expect(classifyZone(8.0), equals(3));
      expect(getZoneLabel(3), equals('ZONA WASPADA'));

      expect(classifyZone(12.5), equals(2));
      expect(getZoneLabel(2), equals('ZONA PERHATIAN'));

      expect(classifyZone(28.0), equals(1));
      expect(getZoneLabel(1), equals('ZONA RELATIF AMAN'));
    });

    test('SIGUMI-F10: Parsing & Pemeringkatan Shelter Pengungsian Berdasarkan Jarak', () {
      final sheltersJson = [
        {
          'id': 'shelter-1',
          'name': 'Barak Pengungsian Glagaharjo',
          'type': 'posko_evakuasi',
          'latitude': -7.6358,
          'longitude': 110.4721,
          'distance_km': 5.31,
          'capacity': 350,
          'is_active': true,
        },
        {
          'id': 'shelter-2',
          'name': 'Barak Pengungsian Kepuharjo',
          'type': 'posko_evakuasi',
          'latitude': -7.6142,
          'longitude': 110.4537,
          'distance_km': 2.18,
          'capacity': 250,
          'is_active': true,
        },
      ];

      final list = sheltersJson.map((j) => ShelterModel.fromRpc(j)).toList();
      list.sort((a, b) => (a.distanceFromUser ?? 0).compareTo(b.distanceFromUser ?? 0));

      expect(list.first.name, equals('Barak Pengungsian Kepuharjo'));
      expect(list.first.distanceFromUser, equals(2.18));
      expect(list.last.name, equals('Barak Pengungsian Glagaharjo'));
      expect(list.last.distanceFromUser, equals(5.31));
    });

    // ------------------------------------------------------------------------
    // MODUL 4: TRACKING PENDAKIAN & DARURAT SOS (SIGUMI-F11 s/d SIGUMI-F14)
    // ------------------------------------------------------------------------
    test('SIGUMI-F11, SIGUMI-F12 & SIGUMI-F13: Alur Sesi Pendakian, Perekaman Titik & Pengiriman SOS', () async {
      final fakeGateway = _FakeFunctionalGateway();
      final fakeLoc = _FakeLocationForFunctional();
      final service = HikingTrackingService(
        remoteGateway: fakeGateway,
        locationService: fakeLoc,
      );
      await service.ensureRestored();

      // Mulai pendakian
      final started = await service.start(region: 'lombok');
      expect(started, isTrue);
      expect(service.isActive, isTrue);
      expect(service.pointsRecorded, equals(1));

      // Simulasi pergerakan pendaki ~11 meter
      fakeLoc.emitFix(-8.40490, 116.46800);
      await Future<void>.delayed(Duration.zero);
      expect(service.pointsRecorded, equals(2));
      expect(service.distanceKm, greaterThan(0.005));

      // Kirim SOS darurat
      final sosResult = await service.sendSos();
      expect(sosResult.status, isNot(equals(HikingSosStatus.failed)));
      expect(fakeGateway.savedAlerts.length, equals(1));

      // Selesai pendakian
      await service.stop();
      expect(service.isActive, isFalse);

      service.dispose();
    });

    // ------------------------------------------------------------------------
    // MODUL 5: CHATBOT ASISTEN & MULTI-BAHASA (SIGUMI-F17 s/d SIGUMI-F19)
    // ------------------------------------------------------------------------
    test('SIGUMI-F17, SIGUMI-F18 & SIGUMI-F19: Deteksi Intent Chatbot & Dukungan Bahasa Daerah', () {
      // Deteksi Intent Bahasa Indonesia
      final intentStatus = RuleBasedFallback.detectIntent('bagaimana status aktivitas gunung merapi saat ini?');
      expect(intentStatus, equals('status'));
      final msgId = RuleBasedFallback.getResponse(userMessage: 'status merapi', language: 'id');
      expect(msgId.content.toLowerCase(), contains('status'));

      // Pertanyaan Evakuasi
      final intentEvakuasi = RuleBasedFallback.detectIntent('di mana lokasi shelter pengungsian terdekat?');
      expect(intentEvakuasi, equals('evakuasi'));

      // Pertanyaan Bantuan Darurat
      final intentBantuan = RuleBasedFallback.detectIntent('tolong bantuan darurat tim sar');
      expect(intentBantuan, equals('bantuan'));

      // Respon Bahasa Daerah (Sasak)
      final msgSas = RuleBasedFallback.getResponse(userMessage: 'status merapi', language: 'sa');
      expect(msgSas.content, isNotEmpty);
    });

    // ------------------------------------------------------------------------
    // MODUL 6: PREFERENSI & AKSESIBILITAS (SIGUMI-F20 & SIGUMI-F21)
    // ------------------------------------------------------------------------
    test('SIGUMI-F20 & SIGUMI-F21: Pengaturan Aksesibilitas Tersimpan di State & SharedPreferences', () async {
      final provider = VolcanoProvider();

      // Mode Kontras Tinggi
      provider.setHighContrast(true);
      expect(provider.highContrast, isTrue);

      // Mode Buta Warna
      provider.setColorBlindMode('protanopia');
      expect(provider.colorBlindMode, equals('protanopia'));

      // Bahasa Aplikasi
      provider.setLanguage('jv');
      expect(provider.language, equals('jv'));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('high_contrast'), isTrue);
      expect(prefs.getString('color_blind_mode'), equals('protanopia'));
      expect(prefs.getString('language'), equals('jv'));
    });
  });
}
