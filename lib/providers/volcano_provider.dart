import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/eruption_history.dart';
import '../models/news_item.dart';
import '../models/user_model.dart';
import '../models/volcano_activity.dart';
import '../models/volcano_model.dart';
import '../models/emergency_contact.dart';
import '../repositories/auth_repository.dart';
import '../repositories/emergency_repository.dart';
import '../repositories/volcano_repository.dart';
import '../services/location_service.dart';

/// Provider utama untuk state management SIGUMI.
///
/// Mengelola:
/// - Data gunung berapi (dari Supabase atau mock)
/// - Auth state (login/logout)
/// - Preferensi user (bahasa, font, aksesibilitas)
/// - Data lokasi & zona risiko (via LocationService)
class VolcanoProvider extends ChangeNotifier {
  // ── Data gunung berapi ──
  VolcanoModel _volcano = VolcanoModel.mockMerapi();
  List<VolcanoModel> _allVolcanoes = [];
  final List<NewsItem> _newsItems = NewsItem.mockNews();

  // ── Aktivitas & Riwayat Erupsi (dari Supabase, diinput admin) ──
  List<VolcanoActivity> _recentActivities = [];
  List<EruptionHistory> _eruptionHistory = [];
  bool _isLoadingActivities = false;
  bool _isLoadingEruptions = false;

  // ── Nomor Telepon Darurat ──
  List<EmergencyContact> _emergencyContacts = [];
  bool _isLoadingContacts = false;

  // ── Refresh state ──
  bool _isRefreshing = false;

  // ── Auth & user state ──
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isAuthLoading = false;
  String? _authError;

  // ── Preferensi ──
  String _language = 'id';
  bool _isFirstTime = true; // Flag untuk onboarding
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _audioGuidance = false;
  bool _isOffline = false;
  String _selectedRegion = 'Yogyakarta';

  // ── Deteksi lokasi otomatis ──
  bool _isRegionAutoDetected = false;
  bool _locationInitialized = false;

  // ── Auth subscription ──
  StreamSubscription<AuthState>? _authSubscription;

  // ── Repository ──
  final AuthRepository _authRepo = AuthRepository();
  final VolcanoRepository _volcanoRepo = VolcanoRepository();
  final EmergencyRepository _emergencyRepo = EmergencyRepository();
  final LocationService _locationService = LocationService();

  // ── Multi-Client MAGMA Web ──
  SupabaseClient? _magmaClient;
  RealtimeChannel? _magmaChannel;

  // ── Getters ──
  VolcanoModel get volcano => _volcano;
  List<VolcanoModel> get allVolcanoes => _allVolcanoes;
  List<NewsItem> get newsItems => _newsItems;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  bool get isAuthLoading => _isAuthLoading;
  String? get authError => _authError;
  String get language => _language;
  double get fontSize => _fontSize;
  bool get highContrast => _highContrast;
  bool get audioGuidance => _audioGuidance;
  bool get isOffline => _isOffline;
  String get selectedRegion => _selectedRegion;
  bool get isRegionAutoDetected => _isRegionAutoDetected;
  bool get locationInitialized => _locationInitialized;
  bool get isFirstTime => _isFirstTime;
  String? get detectedRegion => _locationService.detectedRegion;

  // ── Getters Aktivitas & Riwayat Erupsi ──
  List<VolcanoActivity> get recentActivities => _recentActivities;
  List<EruptionHistory> get eruptionHistory => _eruptionHistory;
  bool get isLoadingActivities => _isLoadingActivities;
  bool get isLoadingEruptions => _isLoadingEruptions;
  bool get hasActivities => _recentActivities.isNotEmpty;
  bool get hasEruptionHistory => _eruptionHistory.isNotEmpty;

  // ── Getters Nomor Darurat ──
  List<EmergencyContact> get emergencyContacts => _emergencyContacts;
  bool get isLoadingContacts => _isLoadingContacts;

  // ── Getter Refresh ──
  bool get isRefreshing => _isRefreshing;

  // ── Lokasi (delegasi ke LocationService) ──
  double get distanceFromMerapi => _locationService.distanceFromVolcano;
  String get distanceLabel => _locationService.distanceLabel;
  String get zoneLabel => _locationService.zoneLabel;
  int get zoneLevel => _locationService.zoneLevel;

  VolcanoProvider() {
    _initAuthListener();
    _initMagmaRealtime();
    _initPrefs();
  }

  /// Inisialisasi preferensi lokal
  Future<void> _initPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _isFirstTime = prefs.getBool('is_first_time') ?? true;
    _language = prefs.getString('language') ?? 'id';
    notifyListeners();
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// REAL-TIME MAGMA WEB LISTENER
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Membuka koneksi Supabase paralel khusus ke database MAGMA
  /// untuk mendengarkan perubahan tabel volcanoes secara instan.
  void _initMagmaRealtime() {
    // Jalankan dengan sedikit delay agar tidak bentrok dengan inisialisasi utama (penting untuk Web)
    Future.delayed(const Duration(seconds: 2), () async {
      try {
        debugPrint('[MAGMA] ðŸš€ Inisialisasi Klien Kedua (MAGMA)...');
        _magmaClient = SupabaseClient(SupabaseConfig.magmaUrl, SupabaseConfig.magmaAnonKey);
        
        // 1. Test Fetch Manual (Pastikan RLS & Key OK)
        await _testMagmaConnection();

        // 2. Setup Realtime Channel dengan nama unik agar tidak bentrok di Web
        _magmaChannel = _magmaClient!.channel('sigumi_magma_sync');
        
        _magmaChannel!.onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'volcanoes',
          callback: (payload) {
            debugPrint('[MAGMA] ðŸ”¥ DATA REALTIME MASUK! Event: ${payload.eventType}');
            _processMagmaPayload(payload.newRecord);
          }
        ).subscribe((status, [error]) {
          debugPrint('[MAGMA] ðŸ“¡ Status Channel: $status');
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint('[MAGMA] âœ… Realtime MAGMA Aktif!');
          }
          if (error != null) {
            debugPrint('[MAGMA] âŒ Error Realtime: $error');
            // Jika Realtime gagal di Web, kita gunakan sistem Polling sebagai cadangan
            if (!_isPollingActive) _startMagmaPolling();
          }
        });

      } catch (e) {
        debugPrint('[MAGMA] âŒ Fatal Error Inisialisasi: $e');
        _startMagmaPolling();
      }
    });
  }

  bool _isPollingActive = false;
  Timer? _pollingTimer;

  /// Fallback untuk Web jika WebSocket bermasalah
  void _startMagmaPolling() {
    if (_isPollingActive) return;
    _isPollingActive = true;
    debugPrint('[MAGMA] ðŸ”„ Memulai mode Polling (Fallback Web)...');
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (timer) async {
       debugPrint('[MAGMA] ðŸ” Polling data terbaru...');
       try {
         final data = await _magmaClient!
            .from('volcanoes')
            .select('name, alert_level')
            .eq('name', _volcano.name.replaceAll('Gunung', '').trim())
            .maybeSingle();
         
         if (data != null) {
           _processMagmaPayload(data);
         }
       } catch (e) {
         debugPrint('[MAGMA] âŒ Polling Error: $e');
       }
    });
  }

  void _processMagmaPayload(Map<String, dynamic> record) {
    if (record.isEmpty) return;

    final String? volcanoName = record['name']?.toString();
    final String? alertLevel = record['alert_level']?.toString();
    
    if (volcanoName == null) return;

    final newStatusLevel = _mapAlertLevelToInt(alertLevel);
    final newDescription = _generateStatusDescriptionFor(volcanoName, newStatusLevel);

    // Matching logika
    String normalize(String s) => s.toLowerCase().replaceAll('gunung', '').trim();
    final normalizedInput = normalize(volcanoName);

    // 1. Update di list allVolcanoes agar tidak tertimpa saat ganti region/fetch ulang
    bool foundInList = false;
    for (int i = 0; i < _allVolcanoes.length; i++) {
      if (normalize(_allVolcanoes[i].name).contains(normalizedInput)) {
        _allVolcanoes[i] = _allVolcanoes[i].copyWith(
          statusLevel: newStatusLevel,
          statusDescription: newDescription,
          lastUpdate: DateTime.now(),
        );
        foundInList = true;
      }
    }

    // 2. Update objek volcano yang sedang aktif jika cocok
    if (normalize(_volcano.name).contains(normalizedInput)) {
       if (_volcano.statusLevel != newStatusLevel) {
          debugPrint('[MAGMA] âœ… Perubahan Terdeteksi! $volcanoName: Level $newStatusLevel');
          
          // Gunakan microtask agar tidak bentrok dengan siklus render UI Web
          Future.microtask(() {
            updateVolcanoStatus(newStatusLevel, newDescription);
          });
       }
    } else if (!foundInList && _volcano.name.isEmpty) {
       // Jika list kosong (init state), langsung set via microtask
       Future.microtask(() {
         updateVolcanoStatus(newStatusLevel, newDescription);
       });
    }
    
    // Hanya notifyListeners jika ada data masuk, bungkus agar aman di Web
    if (foundInList) {
       Future.microtask(() => notifyListeners());
    }
  }

  /// Fungsi Diagnosa: Mencoba membaca 1 baris data secara manual
  Future<void> _testMagmaConnection() async {
    try {
      final data = await _magmaClient!.from('volcanoes').select('name, alert_level').limit(1);
      if (data.isNotEmpty) {
        debugPrint('[MAGMA] âœ… TEST READ SUKSES! Ditemukan ${data.length} baris. Database MAGMA dapat diakses.');
        debugPrint('[MAGMA] Contoh data: ${data.first}');
      } else {
        debugPrint('[MAGMA] âš ï¸ TEST READ KOSONG. Tabel mungkin tidak ada isinya atau RLS memblokir.');
      }
    } catch (e) {
      debugPrint('[MAGMA] âŒ TEST READ GAGAL: $e');
      debugPrint('[MAGMA] Saran: Periksa kembali RLS Policy di Dashboard Supabase.');
    }
  }

  /// Memetakan tipe Varchar 'alert_level' (II, III, IV) menjadi int (2, 3, 4)
  int _mapAlertLevelToInt(String? alertLevel) {
    if (alertLevel == 'IV') return 4;
    if (alertLevel == 'III') return 3;
    if (alertLevel == 'II') return 2;
    return 1;
  }

  /// Generate placeholder deskripsi aman untuk Sigumi Edukasi mitigasi.
  String _generateStatusDescriptionFor(String name, int level) {
    switch (level) {
      case 4:
        return 'AWAS! Status Gunung $name berada pada Level IV. Data detail aktivitas sedang diperbarui...';
      case 3:
        return 'SIAGA! Status Gunung $name berada pada Level III. Data detail aktivitas sedang diperbarui...';
      case 2:
        return 'WASPADA! Status Gunung $name berada pada Level II. Data detail aktivitas sedang diperbarui...';
      default:
        return 'Status Gunung $name Normal (Level I). Data detail aktivitas sedang diperbarui...';
    }
  }

  /// ──────────────────────────────────────────────────────────────
  /// AUTO-DETECT REGION — Berdasarkan GPS
  /// ──────────────────────────────────────────────────────────────
  /// Inisialisasi GPS dan deteksi daerah otomatis.
  /// Akan auto-set region berdasarkan gunung terdekat terlepas dari seberapa jauh.
  Future<void> autoDetectAndSetRegion() async {
    if (_locationInitialized) return;  // Jangan double-init

    await _locationService.initialize();
    _locationInitialized = true;

    if (_locationService.isUsingRealGps) {
      final closest = _locationService.getClosestRegion();
      final detected = _locationService.detectRegion();
      
      if (detected != null) {
        // Didalam radius 40km
        _isRegionAutoDetected = true;
        setRegion(detected);
      } else {
        // Diluar radius 40km, default ke yang terdekat tapi seolah manual
        _isRegionAutoDetected = false;
        setRegion(closest);
      }
    } else {
      _isRegionAutoDetected = false;
      notifyListeners();
    }
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// AUTH LISTENER â€” React to session changes
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  void _initAuthListener() {
    if (!SupabaseConfig.isConfigured) return;

    _authSubscription = _authRepo.onAuthStateChange.listen(
      (AuthState state) {
        final event = state.event;
        final session = state.session;

        if (event == AuthChangeEvent.signedIn && session != null) {
          _isAuthenticated = true;
          _loadUserProfile();
        } else if (event == AuthChangeEvent.signedOut) {
          _isAuthenticated = false;
          _currentUser = null;
        }
        notifyListeners();
      },
    );

    // Cek session yang sudah ada saat app launch
    if (_authRepo.isLoggedIn) {
      _isAuthenticated = true;
      _loadUserProfile();
    }
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// REGISTER
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> register({
    required String phone,
    required String password,
    required String fullName,
    DateTime? dateOfBirth,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final normalizedPhone = AuthRepository.normalizePhone(phone);
      await _authRepo.register(
        phone: normalizedPhone,
        password: password,
        fullName: fullName,
        dateOfBirth: dateOfBirth,
      );
      _isAuthLoading = false;
      notifyListeners();
      return true;
    } on AuthRepositoryException catch (e) {
      _authError = e.message;
      _isAuthLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Terjadi kesalahan tidak terduga.';
      _isAuthLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// LOGIN
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<bool> login({
    required String phone,
    required String password,
  }) async {
    _isAuthLoading = true;
    _authError = null;
    notifyListeners();

    try {
      final normalizedPhone = AuthRepository.normalizePhone(phone);
      await _authRepo.login(
        phone: normalizedPhone,
        password: password,
      );
      _isAuthLoading = false;
      notifyListeners();
      return true;
    } on AuthRepositoryException catch (e) {
      _authError = e.message;
      _isAuthLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _authError = 'Terjadi kesalahan tidak terduga.';
      _isAuthLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// LOGOUT
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> logout() async {
    try {
      await _authRepo.logout();
      _currentUser = null;
      _isAuthenticated = false;
      _locationService.stopTracking();
      notifyListeners();
    } catch (e) {
      _authError = 'Gagal keluar.';
      notifyListeners();
    }
  }

  /// Clear error message
  void clearAuthError() {
    _authError = null;
    notifyListeners();
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// LOAD PROFIL USER dari Supabase
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authRepo.getProfile();
      if (profile != null) {
        final user = _authRepo.currentUser;
        _currentUser = UserModel(
          id: user!.id,
          name: profile['full_name'] ?? '',
          email: user.email ?? '',
          phone: profile['phone'] ?? user.userMetadata?['phone'] ?? '',
          age: _calculateAge(profile['date_of_birth']),
          language: profile['language'] ?? 'id',
          region: profile['region'],
          audioGuidance: profile['audio_guidance'] ?? false,
          fontSize: (profile['font_size'] as num?)?.toDouble() ?? 1.0,
          highContrast: profile['high_contrast'] ?? false,
        );

        // Sync preferensi dari profil
        _language = _currentUser!.language;
        _fontSize = _currentUser!.fontSize;
        _highContrast = _currentUser!.highContrast;
        _audioGuidance = _currentUser!.audioGuidance;
        if (_currentUser!.region != null) {
          _selectedRegion = _currentUser!.region!;
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('[VolcanoProvider] Load profile error: $e');
    }
  }

  /// Hitung umur dari tanggal lahir
  int? _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
    }
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// LOAD VOLCANOES dari Supabase
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  Future<void> loadVolcanoes() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('volcanoes')
          .select()
          .order('name');

      _allVolcanoes = (response as List).map((json) {
        // Parsing koordinat — robust (WKT, GeoJSON, kolom terpisah, fallback hardcoded)
        final lat = _parseCoordinateLat(json);
        final lng = _parseCoordinateLng(json);
        debugPrint('[VolcanoProvider] ${json['name']}: lat=$lat, lng=$lng');

        return VolcanoModel(
          id: json['id'],
          name: json['name'],
          latitude: lat,
          longitude: lng,
          elevation: (json['elevation'] as num).toDouble(),
          statusLevel: json['status_level'] ?? 1,
          statusDescription: json['status_description'] ?? '',
          lastUpdate: json['last_update'] != null
              ? DateTime.parse(json['last_update'])
              : DateTime.now(),
          lastEruption: json['last_eruption'],
          recentActivities: [], // Paksa kosong sementara menunggu data real dari admin panel
          temperature: (json['temperature'] as num?)?.toDouble(),
          windDirection: json['wind_direction'],
          windSpeed: (json['wind_speed'] as num?)?.toDouble(),
        );
      }).toList();

      // Set volcano pertama atau sesuai region
      _updateSelectedVolcano();
      notifyListeners();
    } catch (e) {
      debugPrint('[VolcanoProvider] Load volcanoes error: $e');
      // Fallback ke mock data tetap tersedia
    }
  }

  // â”€â”€ Koordinat fallback hardcoded berdasarkan nama gunung â”€â”€
  // Dipakai jika parsing PostGIS dari Supabase gagal (format tidak dikenal)
  static const Map<String, List<double>> _volcanoFallbackCoords = {
    'merapi':  [-7.5407,  110.4457],
    'agung':   [-8.3433,  115.5071],
    'rinjani': [-8.4111,  116.4573],
  };

  /// Parsing latitude dari berbagai format PostGIS yang mungkin dikembalikan Supabase.
  /// Mendukung: WKT string, GeoJSON Map, kolom lat/longitude terpisah, fallback hardcoded.
  double _parseCoordinateLat(Map<String, dynamic> json) {
    // Cara 1: kolom terpisah
    if (json['lat'] != null) return (json['lat'] as num).toDouble();
    if (json['latitude'] != null) return (json['latitude'] as num).toDouble();

    final location = json['location'];

    // Cara 2: GeoJSON Map { type: Point, coordinates: [lng, lat] }
    if (location is Map) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        return (coords[1] as num).toDouble();
      }
    }

    // Cara 3: WKT String â€” POINT(lng lat) atau SRID=4326;POINT(lng lat)
    if (location is String) {
      final match = RegExp(r'POINT\s*\(\s*([\d.-]+)\s+([\d.-]+)\s*\)')
          .firstMatch(location);
      if (match != null) return double.parse(match.group(2)!); // group 2 = lat
    }

    // Cara 4: fallback koordinat hardcoded
    return _coordFallback(json['name']?.toString(), 0);
  }

  double _parseCoordinateLng(Map<String, dynamic> json) {
    if (json['lng'] != null) return (json['lng'] as num).toDouble();
    if (json['longitude'] != null) return (json['longitude'] as num).toDouble();

    final location = json['location'];

    if (location is Map) {
      final coords = location['coordinates'];
      if (coords is List && coords.length >= 2) {
        return (coords[0] as num).toDouble();
      }
    }

    if (location is String) {
      final match = RegExp(r'POINT\s*\(\s*([\d.-]+)\s+([\d.-]+)\s*\)')
          .firstMatch(location);
      if (match != null) return double.parse(match.group(1)!); // group 1 = lng
    }

    return _coordFallback(json['name']?.toString(), 1);
  }

  double _coordFallback(String? name, int index) {
    if (name == null) return 0;
    final key = name.toLowerCase().replaceAll('gunung', '').trim();
    for (final entry in _volcanoFallbackCoords.entries) {
      if (key.contains(entry.key)) return entry.value[index];
    }
    debugPrint('[VolcanoProvider] âš ï¸ Koordinat tidak dikenal untuk "$name"');
    return 0;
  }

  void _updateSelectedVolcano() {
    if (_allVolcanoes.isEmpty) return;

    final match = _allVolcanoes.where(
      (v) => v.name.toLowerCase().contains(_selectedRegion.toLowerCase()) ||
             _getRegionForVolcano(v.name) == _selectedRegion,
    );

    if (match.isNotEmpty) {
      _volcano = match.first;
    } else {
      _volcano = _allVolcanoes.first;
    }
  }

  String _getRegionForVolcano(String volcanoName) {
    if (volcanoName.contains('Merapi')) return 'Yogyakarta';
    if (volcanoName.contains('Agung')) return 'Bali';
    if (volcanoName.contains('Rinjani')) return 'Lombok';
    return 'Unknown';
  }

  // â”€â”€ Setter methods (sama seperti sebelumnya) â”€â”€

  void setUser(UserModel user) {
    _currentUser = user;
    _language = user.language;
    _fontSize = user.fontSize;
    _highContrast = user.highContrast;
    _audioGuidance = user.audioGuidance;
    notifyListeners();
  }

  void setLanguage(String lang) async {
    _language = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', lang);
    if (_isAuthenticated) {
      _authRepo.updateProfileTable(language: lang);
    }
    notifyListeners();
  }

  /// Menandai onboarding selesai
  void completeOnboarding() async {
    _isFirstTime = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_first_time', false);
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size;
    if (_isAuthenticated) {
      _authRepo.updateProfileTable(fontSize: size);
    }
    notifyListeners();
  }

  void setHighContrast(bool value) {
    _highContrast = value;
    if (_isAuthenticated) {
      _authRepo.updateProfileTable(highContrast: value);
    }
    notifyListeners();
  }

  void setAudioGuidance(bool value) {
    _audioGuidance = value;
    if (_isAuthenticated) {
      _authRepo.updateProfileTable(audioGuidance: value);
    }
    notifyListeners();
  }

  void toggleOffline() {
    _isOffline = !_isOffline;
    notifyListeners();
  }

  void setRegion(String region) {
    _selectedRegion = region;

    // Prioritas 1: Gunakan data yang sudah ada di _allVolcanoes
    // JANGAN reset ke mock â€” ini penyebab status kembali ke default!
    if (_allVolcanoes.isNotEmpty) {
      _updateSelectedVolcano();
    } else {
      // List kosong: pakai mock sementara sebagai placeholder UI,
      // lalu langsung fetch data real. Hasilnya akan override mock ini.
      if (region == 'Yogyakarta') {
        _volcano = VolcanoModel.mockMerapi();
      } else if (region == 'Bali') {
        _volcano = VolcanoModel.mockAgung();
      } else if (region == 'Lombok') {
        _volcano = VolcanoModel.mockRinjani();
      }
      // Fetch data real segera â€” akan menimpa mock di atas
      Future.microtask(() => loadVolcanoes());
    }

    // Update LocationService agar hitung jarak ke gunung yang benar
    _locationService.setActiveVolcano(
      lat: _volcano.latitude,
      lng: _volcano.longitude,
      name: _volcano.name,
    );

    if (_isAuthenticated) {
      _authRepo.updateProfileTable(region: region);
    }
    notifyListeners();

    // Fetch data aktivitas & erupsi untuk gunung yang dipilih
    fetchRecentActivities();
    fetchEruptionHistory();

    // Fetch nomor darurat sesuai region baru
    fetchEmergencyContacts();

    // Sinkronisasi status real-time dari MAGMA untuk gunung baru.
    // Ini memastikan saat ganti region, statusLevel langsung terupdate
    // dari database MAGMA (tidak menunggu event realtime berikutnya).
    _syncMagmaStatusForCurrentVolcano();
  }

  /// Fetch status terbaru langsung dari MAGMA untuk gunung yang sedang aktif.
  /// Dipanggil setiap kali region berganti agar status tidak tertinggal.
  Future<void> _syncMagmaStatusForCurrentVolcano() async {
    if (_magmaClient == null) return;

    try {
      // Ambil nama gunung tanpa prefix "Gunung " untuk query MAGMA
      final searchName = _volcano.name
          .replaceAll('Gunung', '')
          .replaceAll('gunung', '')
          .trim();

      final data = await _magmaClient!
          .from('volcanoes')
          .select('name, alert_level')
          .ilike('name', '%$searchName%')
          .maybeSingle();

      if (data != null) {
        debugPrint('[MAGMA] ðŸ”„ Sync status untuk ${_volcano.name}: ${data['alert_level']}');
        _processMagmaPayload(data);
      }
    } catch (e) {
      debugPrint('[MAGMA] âš ï¸ Sync status error: $e');
    }
  }

  void updateVolcanoStatus(int level, String description) {
    _volcano = VolcanoModel(
      id: _volcano.id,
      name: _volcano.name,
      latitude: _volcano.latitude,
      longitude: _volcano.longitude,
      elevation: _volcano.elevation,
      statusLevel: level,
      statusDescription: description,
      lastUpdate: DateTime.now(),
      lastEruption: _volcano.lastEruption,
      recentActivities: _volcano.recentActivities,
      temperature: _volcano.temperature,
      windDirection: _volcano.windDirection,
      windSpeed: _volcano.windSpeed,
    );
    notifyListeners();
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// FETCH AKTIVITAS TERKINI dari Supabase
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Mengambil data aktivitas 7 hari terakhir dari tabel
  /// `volcano_activities`. Return kosong jika tabel belum ada
  /// (admin panel belum selesai).
  Future<void> fetchRecentActivities() async {
    _isLoadingActivities = true;
    notifyListeners();

    try {
      _recentActivities = await _volcanoRepo.getRecentActivities(
        _volcano.dbId,
      );
    } catch (e) {
      // Sembunyikan error tabel hilang karena admin panel belum selesai
      if (!e.toString().contains('PGRST205')) {
        debugPrint('[SIGUMI] Info: Tabel activities belum tersedia.');
      }
      _recentActivities = [];
    }

    _isLoadingActivities = false;
    notifyListeners();
  }

  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// FETCH RIWAYAT ERUPSI dari Supabase
  /// â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Mengambil seluruh riwayat erupsi dari tabel
  /// `eruption_history`. Return kosong jika tabel belum ada
  /// (admin panel belum selesai).
  Future<void> fetchEruptionHistory() async {
    _isLoadingEruptions = true;
    notifyListeners();

    try {
      _eruptionHistory = await _volcanoRepo.getEruptionHistory(
        _volcano.dbId,
      );
    } catch (e) {
      // Sembunyikan error tabel hilang karena admin panel belum selesai
      if (!e.toString().contains('PGRST205')) {
         debugPrint('[SIGUMI] Info: Tabel eruptions belum tersedia.');
      }
      _eruptionHistory = [];
    }

    _isLoadingEruptions = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────────
  /// FETCH NOMOR TELEPON DARURAT dari Supabase
  /// ──────────────────────────────────────────────────
  /// Mengambil kontak darurat berdasarkan region aktif.
  /// Fallback ke data statis jika tabel belum ada / offline.
  Future<void> fetchEmergencyContacts() async {
    _isLoadingContacts = true;
    notifyListeners();

    try {
      _emergencyContacts = await _emergencyRepo.getContacts(
        region: _selectedRegion,
      );
    } catch (e) {
      debugPrint('[SIGUMI] fetchEmergencyContacts error: $e');
      _emergencyContacts = [];
    }

    _isLoadingContacts = false;
    notifyListeners();
  }

  /// ──────────────────────────────────────────────────
  /// FORCE REFRESH — Paksa ambil ulang semua data dari MAGMA
  /// ──────────────────────────────────────────────────
  /// Dipanggil dari tombol refresh di UI (Home & Status Zona).
  /// Men-trigger fetch ulang status gunung, aktivitas, dan kontak darurat.
  Future<void> forceRefresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    notifyListeners();

    try {
      // Paksa reload semua volcano dari Supabase (termasuk status MAGMA)
      await loadVolcanoes();

      // Sync langsung status level dari MAGMA untuk gunung aktif
      await _syncMagmaStatusForCurrentVolcano();

      // Reload aktivitas & riwayat terkini
      await fetchRecentActivities();
      await fetchEruptionHistory();

      // Reload kontak darurat
      await fetchEmergencyContacts();
    } catch (e) {
      debugPrint('[VolcanoProvider] forceRefresh error: \$e');
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _magmaChannel?.unsubscribe();
    _pollingTimer?.cancel();
    _magmaClient?.dispose();
    super.dispose();
  }
}
