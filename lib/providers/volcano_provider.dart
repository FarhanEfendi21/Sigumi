import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';
import '../models/news_item.dart';
import '../models/user_model.dart';
import '../models/volcano_model.dart';
import '../repositories/auth_repository.dart';
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

  // ── Auth & user state ──
  UserModel? _currentUser;
  bool _isAuthenticated = false;
  bool _isAuthLoading = false;
  String? _authError;

  // ── Preferensi ──
  String _language = 'id';
  double _fontSize = 1.0;
  bool _highContrast = false;
  bool _audioGuidance = false;
  bool _isOffline = false;
  String _selectedRegion = 'Yogyakarta';

  // ── Auth subscription ──
  StreamSubscription<AuthState>? _authSubscription;

  // ── Repository ──
  final AuthRepository _authRepo = AuthRepository();
  final LocationService _locationService = LocationService();

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

  // ── Lokasi (delegasi ke LocationService) ──
  double get distanceFromMerapi => _locationService.distanceFromVolcano;
  String get distanceLabel => _locationService.distanceLabel;
  String get zoneLabel => _locationService.zoneLabel;
  int get zoneLevel => _locationService.zoneLevel;

  VolcanoProvider() {
    _initAuthListener();
  }

  /// ──────────────────────────────────────────────
  /// AUTH LISTENER — React to session changes
  /// ──────────────────────────────────────────────
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

  /// ──────────────────────────────────────────────
  /// REGISTER
  /// ──────────────────────────────────────────────
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

  /// ──────────────────────────────────────────────
  /// LOGIN
  /// ──────────────────────────────────────────────
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

  /// ──────────────────────────────────────────────
  /// LOGOUT
  /// ──────────────────────────────────────────────
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

  /// ──────────────────────────────────────────────
  /// LOAD PROFIL USER dari Supabase
  /// ──────────────────────────────────────────────
  Future<void> _loadUserProfile() async {
    try {
      final profile = await _authRepo.getProfile();
      if (profile != null) {
        final user = _authRepo.currentUser;
        _currentUser = UserModel(
          id: user!.id,
          name: profile['full_name'] ?? '',
          email: user.email ?? '',
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

  /// ──────────────────────────────────────────────
  /// LOAD VOLCANOES dari Supabase
  /// ──────────────────────────────────────────────
  Future<void> loadVolcanoes() async {
    if (!SupabaseConfig.isConfigured) return;

    try {
      final client = Supabase.instance.client;
      final response = await client
          .from('volcanoes')
          .select()
          .order('name');

      _allVolcanoes = (response as List).map((json) {
        // Parsing PostGIS geography point dari Supabase
        final location = json['location'];
        double lat = 0, lng = 0;
        if (location is String && location.contains('POINT')) {
          // Format WKT: POINT(lng lat)
          final match = RegExp(r'POINT\(([\d.-]+) ([\d.-]+)\)').firstMatch(location);
          if (match != null) {
            lng = double.parse(match.group(1)!);
            lat = double.parse(match.group(2)!);
          }
        }

        return VolcanoModel(
          id: json['id'],
          name: json['name'],
          latitude: lat,
          longitude: lng,
          elevation: (json['elevation'] as num).toDouble(),
          statusLevel: json['status_level'],
          statusDescription: json['status_description'] ?? '',
          lastUpdate: DateTime.parse(json['last_update']),
          lastEruption: json['last_eruption'],
          recentActivities: (json['recent_activities'] as List?)
              ?.map((e) => e.toString())
              .toList() ?? [],
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

  // ── Setter methods (sama seperti sebelumnya) ──

  void setUser(UserModel user) {
    _currentUser = user;
    _language = user.language;
    _fontSize = user.fontSize;
    _highContrast = user.highContrast;
    _audioGuidance = user.audioGuidance;
    notifyListeners();
  }

  void setLanguage(String lang) {
    _language = lang;
    if (_isAuthenticated) {
      _authRepo.updateProfileTable(language: lang);
    }
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

    // Coba ambil dari data Supabase dulu
    if (_allVolcanoes.isNotEmpty) {
      _updateSelectedVolcano();
    } else {
      // Fallback ke mock data
      if (region == 'Yogyakarta') {
        _volcano = VolcanoModel.mockMerapi();
      } else if (region == 'Bali') {
        _volcano = VolcanoModel.mockAgung();
      } else if (region == 'Lombok') {
        _volcano = VolcanoModel.mockRinjani();
      }
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

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}