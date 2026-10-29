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
  int _alertGeneration = 0;
  int _testGeneration = 0;
  int? _startingAlertGeneration;
  bool _pulseInProgress = false;
  int _preferenceGeneration = 0;
  int _locationCheckGeneration = 0;
  Future<void> _preferenceWrite = Future<void>.value();
  bool _hasAlertedThisSession = false; // Sekali per sesi, tanpa cooldown
  bool _wasInsideRadius = false; // Tracking state masuk/keluar radius
  String? _lastVolcanoName;
  double? _lastDistanceKm;

  Timer? _vibrationLoop;

  /// Callback dipanggil saat alert pertama kali trigger — untuk show modal.
  /// Dipasang oleh HomeScreen.
  void Function(String volcanoName, double distanceKm)? _onAlertTriggered;

  set onAlertTriggered(
    void Function(String volcanoName, double distanceKm)? callback,
  ) {
    _onAlertTriggered = callback;
    // Startup location checks can trigger before HomeScreen installs its
    // callback. Replay the active alert once the UI is ready to present it.
    if (callback != null && _isAlerting) {
      callback(_lastVolcanoName ?? 'puncak', _lastDistanceKm ?? _alertRadiusKm);
    }
  }

  bool get isEnabled => _isEnabled;
  bool get isAlerting => _isAlerting;

  /// Inisialisasi service dan pulihkan preferensi
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep the previous first-run behavior while preserving an explicit opt-out.
      _isEnabled = prefs.getBool('vibration_alert_enabled') ?? true;
      debugPrint('[VibrationAlert] initialized, enabled=$_isEnabled');
    } catch (e) {
      debugPrint('[VibrationAlert] initialize error: $e');
    }
  }

  /// Aktifkan atau nonaktifkan service.
  /// Jika dinonaktifkan, alert yang berjalan dihentikan.
  Future<void> setEnabled(bool value) async {
    final requestGeneration = ++_preferenceGeneration;
    _isEnabled = value;
    if (!value) {
      // Stop synchronously: waiting for preference I/O must not leave a pulse running.
      _testGeneration++;
      stopAlert();
    }

    final write = _preferenceWrite.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('vibration_alert_enabled', value);
    });
    _preferenceWrite = write;
    try {
      await write;
    } catch (e) {
      debugPrint('[VibrationAlert] save prefs error: $e');
    }
    debugPrint('[VibrationAlert] enabled=$value');
    if (requestGeneration != _preferenceGeneration) return;
    if (value &&
        _lastDistanceKm != null &&
        _lastDistanceKm! <= _alertRadiusKm) {
      _wasInsideRadius = false;
      _hasAlertedThisSession = false;
      await checkAndAlert(
        distanceKm: _lastDistanceKm!,
        volcanoName: _lastVolcanoName ?? 'puncak',
      );
    }
  }

  /// Dipanggil setiap kali posisi GPS diperbarui.
  /// [distanceKm] = jarak user ke puncak gunung aktif (km).
  /// [volcanoName] = nama gunung untuk ditampilkan di modal.
  Future<void> checkAndAlert({
    required double distanceKm,
    String volcanoName = 'puncak',
  }) async {
    final checkGeneration = ++_locationCheckGeneration;
    _lastDistanceKm = distanceKm;
    _lastVolcanoName = volcanoName;
    if (!_isEnabled) return;

    final isInsideRadius = distanceKm <= _alertRadiusKm;

    // Jika user keluar dari radius → stop alert otomatis
    if (!isInsideRadius && _isAlerting) {
      debugPrint('[VibrationAlert] User keluar radius. Auto-stop alert.');
      stopAlert();
      _wasInsideRadius = false;
      return;
    }
    if (!isInsideRadius && _startingAlertGeneration != null) {
      stopAlert();
      _wasInsideRadius = false;
      return;
    }

    // Trigger hanya saat PERTAMA masuk radius DAN belum pernah alert sesi ini
    if (isInsideRadius &&
        !_wasInsideRadius &&
        !_hasAlertedThisSession &&
        _startingAlertGeneration == null) {
      // Mark synchronously before awaiting hardware to prevent overlapping GPS callbacks.
      _wasInsideRadius = true;
      debugPrint(
        '[VibrationAlert] ⚡ Masuk radius 5km dari $volcanoName! '
        'Distance: ${distanceKm.toStringAsFixed(1)} km',
      );
      await startContinuousAlert(
        volcanoName: volcanoName,
        distanceKm: distanceKm,
      );
    }

    // A slower async GPS callback must not overwrite a newer radius state.
    if (checkGeneration == _locationCheckGeneration) {
      _wasInsideRadius = isInsideRadius;
    }
  }

  /// Mulai loop getar terus-menerus dan panggil callback untuk show modal.
  Future<void> startContinuousAlert({
    required String volcanoName,
    required double distanceKm,
  }) async {
    if (!_isEnabled || _isAlerting || _startingAlertGeneration != null) return;

    final generation = _alertGeneration;
    _startingAlertGeneration = generation;
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!_isEnabled || generation != _alertGeneration || !hasVibrator) {
        if (!hasVibrator) {
          debugPrint('[VibrationAlert] Perangkat tidak memiliki vibrator');
        }
        return;
      }

      _isAlerting = true;
      _hasAlertedThisSession = true;

      // Panggil callback untuk show modal SEBELUM mulai loop
      _lastVolcanoName = volcanoName;
      _lastDistanceKm = distanceKm;
      _onAlertTriggered?.call(volcanoName, distanceKm);

      // Getar pertama langsung
      await _triggerVibration(generation);
      if (!_isEnabled || generation != _alertGeneration || !_isAlerting) return;

      // Loop getar setiap interval sampai stopAlert() dipanggil
      _vibrationLoop = Timer.periodic(_vibrationInterval, (_) async {
        if (!_isEnabled || generation != _alertGeneration || !_isAlerting) {
          _vibrationLoop?.cancel();
          return;
        }
        await _triggerVibration(generation);
      });

      debugPrint('[VibrationAlert] 🔔 Loop getar dimulai untuk $volcanoName');
    } finally {
      if (_startingAlertGeneration == generation) {
        _startingAlertGeneration = null;
      }
    }
  }

  /// Hentikan loop getar — dipanggil dari modal "Matikan Peringatan"
  /// atau saat user keluar dari radius.
  void stopAlert() {
    _alertGeneration++;
    _startingAlertGeneration = null;
    _vibrationLoop?.cancel();
    _vibrationLoop = null;
    _isAlerting = false;

    // Hentikan getar yang sedang berjalan di OS
    unawaited(_cancelVibrationSafely());

    debugPrint('[VibrationAlert] ⏹ Alert dihentikan.');
  }

  /// Reset state radius saat gunung aktif berganti.
  /// TIDAK reset _hasAlertedThisSession — alert tetap hanya sekali per sesi.
  void resetRadiusState() {
    _wasInsideRadius = false;
  }

  /// Re-open the warning after returning to the app if the last known GPS
  /// position is still inside the danger radius and the user dismissed it.
  void onAppResumed() {
    final distanceKm = _lastDistanceKm;
    if (!_isEnabled || distanceKm == null || distanceKm > _alertRadiusKm) {
      return;
    }
    if (_isAlerting) return;

    _wasInsideRadius = false;
    _hasAlertedThisSession = false;
    unawaited(
      checkAndAlert(
        distanceKm: distanceKm,
        volcanoName: _lastVolcanoName ?? 'puncak',
      ),
    );
  }

  /// Trigger satu pulsa getar peringatan.
  Future<void> _triggerVibration(int generation) async {
    if (!_isEnabled ||
        !_isAlerting ||
        generation != _alertGeneration ||
        _pulseInProgress) {
      return;
    }
    _pulseInProgress = true;
    try {
      // Pola getar: tiga pulsa tegas — jelas terasa di saku
      await Vibration.vibrate(
        pattern: [0, 400, 150, 400, 150, 800],
        intensities: [0, 200, 0, 200, 0, 255],
      );
    } catch (e) {
      debugPrint('[VibrationAlert] Vibration error: $e');
    } finally {
      _pulseInProgress = false;
    }
  }

  /// Test getar — dipanggil dari UI saat toggle ON
  Future<void> testVibration() async {
    if (!_isEnabled || _isAlerting || _startingAlertGeneration != null) return;
    final generation = ++_testGeneration;
    try {
      final hasVibrator = (await Vibration.hasVibrator()) == true;
      if (!hasVibrator || !_isEnabled || generation != _testGeneration) return;
      await Vibration.vibrate(duration: 200);
    } catch (e) {
      debugPrint('[VibrationAlert] Test vibration error: $e');
    }
  }

  Future<void> _cancelVibrationSafely() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationAlert] Cancel vibration error: $e');
    }
  }
}
