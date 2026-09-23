import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';

import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk peringatan getar saat pengguna masuk radius 5 km dari puncak.
///
/// Fitur:
/// - Getar terus-menerus (loop) saat dalam radius 5 km
/// - Alert hanya trigger SEKALI per sesi (sampai app di-restart)
/// - Berhenti HANYA jika pengguna menekan "Matikan Peringatan" [stopAlert()]
/// - Auto-stop jika user keluar dari radius 5 km
class VibrationAlertService {
  // Singleton
  static final VibrationAlertService _instance =
      VibrationAlertService._internal();
  factory VibrationAlertService() => _instance;
  VibrationAlertService._internal();

  static const double _alertRadiusKm = 5.0;

  // Loop getar setiap 2.5 detik agar tidak terlalu agresif
  static const Duration _vibrationInterval = Duration(milliseconds: 2500);

  bool _isEnabled = false;
  bool _isAlerting = false; // Apakah loop getar sedang aktif
  bool _hasAlertedThisSession = false; // Sekali per sesi, tanpa cooldown
  bool _wasInsideRadius = false; // Tracking state masuk/keluar radius

  Timer? _vibrationLoop;

  /// Callback dipanggil saat alert pertama kali trigger — untuk show modal.
  /// Dipasang oleh HomeScreen.
  void Function(String volcanoName, double distanceKm)? onAlertTriggered;

  bool get isEnabled => _isEnabled;
  bool get isAlerting => _isAlerting;

  /// Inisialisasi service dan pulihkan preferensi
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('vibration_alert_enabled') ?? false;
      debugPrint('[VibrationAlert] initialized, enabled=$_isEnabled');
    } catch (e) {
      debugPrint('[VibrationAlert] initialize error: $e');
    }
  }

  /// Aktifkan atau nonaktifkan service.
  /// Jika dinonaktifkan, alert yang berjalan dihentikan.
  Future<void> setEnabled(bool value) async {
    _isEnabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_alert_enabled', value);
    } catch (e) {
      debugPrint('[VibrationAlert] save prefs error: $e');
    }
    debugPrint('[VibrationAlert] enabled=$value');
    if (!value) {
      stopAlert();
    }
  }

  /// Dipanggil setiap kali posisi GPS diperbarui.
  /// [distanceKm] = jarak user ke puncak gunung aktif (km).
  /// [volcanoName] = nama gunung untuk ditampilkan di modal.
  Future<void> checkAndAlert({
    required double distanceKm,
    String volcanoName = 'puncak',
  }) async {
    if (!_isEnabled) return;

    final isInsideRadius = distanceKm <= _alertRadiusKm;

    // Jika user keluar dari radius → stop alert otomatis
    if (!isInsideRadius && _isAlerting) {
      debugPrint('[VibrationAlert] User keluar radius. Auto-stop alert.');
      stopAlert();
      _wasInsideRadius = false;
      return;
    }

    // Trigger hanya saat PERTAMA masuk radius DAN belum pernah alert sesi ini
    if (isInsideRadius && !_wasInsideRadius && !_hasAlertedThisSession) {
      debugPrint(
        '[VibrationAlert] ⚡ Masuk radius 5km dari $volcanoName! '
        'Distance: ${distanceKm.toStringAsFixed(1)} km',
      );
      await startContinuousAlert(
        volcanoName: volcanoName,
        distanceKm: distanceKm,
      );
    }

    _wasInsideRadius = isInsideRadius;
  }

  /// Mulai loop getar terus-menerus dan panggil callback untuk show modal.
  Future<void> startContinuousAlert({
    required String volcanoName,
    required double distanceKm,
  }) async {
    if (_isAlerting) return;

    final hasVibrator = (await Vibration.hasVibrator()) == true;
    if (!hasVibrator) {
      debugPrint('[VibrationAlert] Perangkat tidak memiliki vibrator');
      return;
    }

    _isAlerting = true;
    _hasAlertedThisSession = true;

    // Panggil callback untuk show modal SEBELUM mulai loop
    onAlertTriggered?.call(volcanoName, distanceKm);

    // Getar pertama langsung
    await _triggerVibration();

    // Loop getar setiap interval sampai stopAlert() dipanggil
    _vibrationLoop = Timer.periodic(_vibrationInterval, (_) async {
      if (!_isAlerting) {
        _vibrationLoop?.cancel();
        return;
      }
      await _triggerVibration();
    });

    debugPrint('[VibrationAlert] 🔔 Loop getar dimulai untuk $volcanoName');
  }

  /// Hentikan loop getar — dipanggil dari modal "Matikan Peringatan"
  /// atau saat user keluar dari radius.
  void stopAlert() {
    _vibrationLoop?.cancel();
    _vibrationLoop = null;
    _isAlerting = false;

    // Hentikan getar yang sedang berjalan di OS
    try {
      Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationAlert] Cancel vibration error: $e');
    }

    debugPrint('[VibrationAlert] ⏹ Alert dihentikan.');
  }

  /// Reset state radius saat gunung aktif berganti.
  /// TIDAK reset _hasAlertedThisSession — alert tetap hanya sekali per sesi.
  void resetRadiusState() {
    _wasInsideRadius = false;
  }

  /// Trigger satu pulsa getar peringatan.
  Future<void> _triggerVibration() async {
    try {
      // Pola getar: tiga pulsa tegas — jelas terasa di saku
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
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator) return;
      Vibration.vibrate(duration: 200);
    } catch (e) {
      debugPrint('[VibrationAlert] Test vibration error: $e');
    }
  }
}
