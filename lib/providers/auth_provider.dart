import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/supabase_config.dart';
import '../repositories/auth_repository.dart';

/// Provider khusus untuk mengelola auth state dan session persistence
///
/// Fitur:
/// - Auto-restore session dari Supabase saat app launch
/// - Simpan user data ke local storage sebagai backup
/// - Real-time auth state changes
/// - Logout yang proper
class AuthProvider extends ChangeNotifier {
  final AuthRepository _authRepo = AuthRepository();
  late SharedPreferences _prefs;

  // Auth state
  bool _isAuthenticated = false;
  bool _isSessionRestored = false;
  String? _userPhone;
  String? _userName;
  String? _userEmail;
  String? _authError;

  // Subscription
  StreamSubscription<AuthState>? _authSubscription;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isSessionRestored => _isSessionRestored;
  String? get userPhone => _userPhone;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get authError => _authError;

  AuthProvider() {
    _initializeAuth();
  }

  /// Initialize auth dan restore session
  Future<void> _initializeAuth() async {
    try {
      // Load SharedPreferences
      _prefs = await SharedPreferences.getInstance();

      // Cek auth state di Supabase
      if (SupabaseConfig.isConfigured) {
        // Subscribe ke auth state changes
        _subscribeToAuthChanges();

        // Tunggu sebentar untuk Supabase restore session
        await Future.delayed(const Duration(milliseconds: 500));

        // Cek session yang sudah ada
        if (_authRepo.isLoggedIn) {
          _isAuthenticated = true;
          _getUserData();
        } else {
          // Coba restore dari local storage
          _restoreFromLocalStorage();
        }
      }

      _isSessionRestored = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      _isSessionRestored = true;
      notifyListeners();
    }
  }

  /// Subscribe ke auth state changes
  void _subscribeToAuthChanges() {
    _authSubscription = _authRepo.onAuthStateChange.listen((AuthState state) {
      if (state.event == AuthChangeEvent.signedIn && state.session != null) {
        _isAuthenticated = true;
        _getUserData();
        _saveToLocalStorage();
      } else if (state.event == AuthChangeEvent.signedOut) {
        _isAuthenticated = false;
        _userPhone = null;
        _userName = null;
        _userEmail = null;
        _clearLocalStorage();
      }
      notifyListeners();
    });
  }

  /// Get user data dari Supabase auth metadata
  void _getUserData() {
    try {
      final user = _authRepo.currentUser;
      if (user != null) {
        _userEmail = user.email;
        _userName = user.userMetadata?['full_name'] as String?;
        _userPhone = user.userMetadata?['phone'] as String?;
      }
    } catch (e) {
      debugPrint('Error getting user data: $e');
    }
  }

  /// Simpan auth data ke local storage
  Future<void> _saveToLocalStorage() async {
    try {
      if (_userEmail != null) {
        await _prefs.setString('user_email', _userEmail!);
      }
      if (_userName != null) {
        await _prefs.setString('user_name', _userName!);
      }
      if (_userPhone != null) {
        await _prefs.setString('user_phone', _userPhone!);
      }
      await _prefs.setBool('is_authenticated', true);
      debugPrint('Auth data saved to local storage');
    } catch (e) {
      debugPrint('Error saving to local storage: $e');
    }
  }

  /// Restore auth data dari local storage (jika Supabase session invalid)
  void _restoreFromLocalStorage() {
    try {
      final isAuth = _prefs.getBool('is_authenticated') ?? false;
      if (isAuth) {
        _userEmail = _prefs.getString('user_email');
        _userName = _prefs.getString('user_name');
        _userPhone = _prefs.getString('user_phone');

        // Try to restore Supabase session
        _tryRestoreSession();
      }
    } catch (e) {
      debugPrint('Error restoring from local storage: $e');
    }
  }

  /// Coba restore session ke Supabase
  Future<void> _tryRestoreSession() async {
    try {
      // Supabase should handle this automatically,
      // tapi ini sebagai backup jika perlu
      final session = _authRepo.currentSession;
      if (session != null) {
        _isAuthenticated = true;
      }
    } catch (e) {
      debugPrint('Error restoring session: $e');
    }
  }

  /// Clear local storage saat logout
  Future<void> _clearLocalStorage() async {
    try {
      await _prefs.remove('user_email');
      await _prefs.remove('user_name');
      await _prefs.remove('user_phone');
      await _prefs.setBool('is_authenticated', false);
      debugPrint('Local storage cleared');
    } catch (e) {
      debugPrint('Error clearing local storage: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      _isAuthenticated = false;
      _userPhone = null;
      _userName = null;
      _userEmail = null;
      await _authRepo.logout();
      await _clearLocalStorage();
      notifyListeners();
    } catch (e) {
      _authError = 'Gagal logout: $e';
      notifyListeners();
      rethrow;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
