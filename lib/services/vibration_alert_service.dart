import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

/// Service untuk peringatan getar saat pengguna masuk radius 5 km dari puncak.
///
/// Fitur:
/// - Toggle on/off disimpan ke SharedPreferences (persisten)
/// - Hanya getar SATU kali saat pertama masuk radius (cooldown 30 menit)
/// - Tidak spam: ada cooldown & debounce
class VibrationAlertService {
  // Singleton
  static final VibrationAlertService _instance =
      VibrationAlertService._internal();
  factory VibrationAlertService() => _instance;
  VibrationAlertService._internal();

  static const String _prefKey = 'vibration_alert_enabled';
  static const double _alertRadiusKm = 5.0;

  // Cooldown 30 menit antar alert agar tidak spam
  static const Duration _alertCooldown = Duration(minutes: 30);

  bool _isEnabled = false;
  DateTime? _lastAlertTime;
  bool _wasInsideRadius = false; // tracking state masuk/keluar radius

  bool get isEnabled => _isEnabled;

  /// Load preferensi dari SharedPreferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool(_prefKey) ?? false;
      debugPrint(
        '[VibrationAlert] Initialized. enabled=$_isEnabled',
      );
    } catch (e) {
      debugPrint('[VibrationAlert] Init error: $e');
      _isEnabled = false;
    }
  }

  /// Toggle on/off dan simpan ke SharedPreferences
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, value);
      debugPrint('[VibrationAlert] Preference saved: enabled=$value');
    } catch (e) {
      debugPrint('[VibrationAlert] Save preference error: $e');
    }
  }

  /// Dipanggil setiap kali posisi GPS diperbarui.
  /// [distanceKm] = jarak user ke puncak gunung aktif (km).
  /// [volcanoName] = nama gunung untuk log.
  Future<void> checkAndAlert({
    required double distanceKm,
    String volcanoName = 'puncak',
  }) async {
    if (!_isEnabled) return;

    final isInsideRadius = distanceKm <= _alertRadiusKm;

    // Hanya trigger saat TRANSISI masuk radius (edge-trigger, bukan level-trigger)
    // Ini mencegah spam getar saat user sudah di dalam radius
    if (isInsideRadius && !_wasInsideRadius) {
      // Cek cooldown
      final now = DateTime.now();
      final canAlert = _lastAlertTime == null ||
          now.difference(_lastAlertTime!) >= _alertCooldown;

      if (canAlert) {
        await _triggerVibration();
        _lastAlertTime = now;
        debugPrint(
          '[VibrationAlert] ⚡ Alert triggered! Distance: ${distanceKm.toStringAsFixed(1)} km dari $volcanoName',
        );
      }
    }

    _wasInsideRadius = isInsideRadius;
  }

  /// Reset state masuk/keluar radius (panggil saat gunung aktif berganti)
  void resetRadiusState() {
    _wasInsideRadius = false;
  }

  /// Trigger pola getar peringatan
  Future<void> _triggerVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) {
        debugPrint('[VibrationAlert] Perangkat tidak memiliki vibrator');
        return;
      }

      // Pola getar: tiga pulsa tegas — jelas terasa di saku
      // Format: [delay, duration, delay, duration, ...]
      Vibration.vibrate(
        pattern: [0, 400, 150, 400, 150, 800],
        intensities: [0, 200, 0, 200, 0, 255],
      );
    } catch (e) {
      debugPrint('[VibrationAlert] Vibration error: $e');
    }
  }

  /// Test getar — dipanggil dari UI saat toggle ON
  Future<void> testVibration() async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (!hasVibrator) return;

      Vibration.vibrate(duration: 200);
    } catch (e) {
      debugPrint('[VibrationAlert] Test vibration error: $e');
    }
  }
}
