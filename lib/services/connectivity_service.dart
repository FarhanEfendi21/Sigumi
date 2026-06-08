import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/ollama_config.dart';

/// Service ringan untuk mendeteksi koneksi internet/server.
///
/// Strategi: Ping Ollama server langsung (bukan google.com).
/// Alasan: Flutter Web kena CORS kalau HEAD ke google.com → selalu "offline".
/// Dengan ping Ollama, kita sekaligus cek apakah server LLM-nya hidup.
///
/// Hasil di-cache selama 30 detik agar tidak spam network check.
///
/// Digunakan oleh [ChatbotEngine] untuk menentukan apakah query
/// harus dikirim ke Cloud LLM atau langsung fallback ke rule-based.
class ConnectivityService {
  static DateTime? _lastCheck;
  static bool? _lastResult;

  /// Durasi cache hasil connectivity check.
  static const Duration _cacheDuration = Duration(seconds: 30);

  /// Timeout untuk HTTP request.
  static const Duration _timeout = Duration(seconds: 3);

  /// Cek apakah Ollama server bisa dijangkau.
  ///
  /// Ping ke Ollama endpoint `/` — return "Ollama is running" jika hidup.
  /// Ini lebih akurat daripada cek google.com karena:
  /// 1. Tidak kena CORS di Flutter Web
  /// 2. Langsung tahu apakah LLM server ready (bukan cuma internet)
  ///
  /// Hasil di-cache selama 30 detik.
  static Future<bool> hasInternet() async {
    // Gunakan cache jika masih valid
    if (_lastCheck != null &&
        _lastResult != null &&
        DateTime.now().difference(_lastCheck!) < _cacheDuration) {
      return _lastResult!;
    }

    try {
      final ollamaUrl = OllamaConfig.baseUrl;
      final response = await http.get(
        Uri.parse(ollamaUrl),
      ).timeout(_timeout);

      _lastResult = response.statusCode == 200;
      _lastCheck = DateTime.now();

      debugPrint('[Connectivity] ${_lastResult! ? '✅ Ollama reachable' : '❌ Ollama not reachable'}');
      return _lastResult!;
    } catch (e) {
      _lastResult = false;
      _lastCheck = DateTime.now();
      debugPrint('[Connectivity] ❌ Ollama unreachable (error: $e)');
      return false;
    }
  }

  /// Invalidate cache — paksa cek ulang pada panggilan berikutnya.
  static void invalidateCache() {
    _lastCheck = null;
    _lastResult = null;
  }
}
