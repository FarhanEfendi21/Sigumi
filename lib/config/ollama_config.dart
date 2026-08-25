import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi Ollama Server untuk Cloud LLM (Gemma 4).
///
/// Mendukung dua mode:
/// 1. **Compile-time** via `--dart-define=OLLAMA_BASE_URL=...` (untuk build)
/// 2. **Runtime** via SharedPreferences (untuk testing/settings UI)
///
/// Prioritas: Runtime override > compile-time > default.
class OllamaConfig {
  // ── SharedPreferences keys ──
  static const _keyBaseUrl = 'ollama_base_url';
  static const _keyModelName = 'ollama_model_name';

  // ── Runtime overrides (di-load dari SharedPreferences) ──
  static String? _runtimeBaseUrl;
  static String? _runtimeModelName;

  /// Compile-time base URL (dari --dart-define atau default).
  static const String _compileTimeBaseUrl = String.fromEnvironment(
    'OLLAMA_BASE_URL',
    defaultValue: 'http://localhost:11434',
  );

  /// Compile-time model name.
  static const String _compileTimeModelName = String.fromEnvironment(
    'OLLAMA_MODEL',
    defaultValue: 'gemma4:e4b',
  );

  /// API key opsional untuk autentikasi reverse proxy.
  static const String apiKey = String.fromEnvironment(
    'OLLAMA_API_KEY',
    defaultValue: '',
  );

  /// Base URL aktif — runtime override > compile-time.
  static String get baseUrl => _runtimeBaseUrl ?? _compileTimeBaseUrl;

  /// Model name aktif — runtime override > compile-time.
  static String get modelName => _runtimeModelName ?? _compileTimeModelName;

  /// Cek apakah Ollama sudah dikonfigurasi.
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Cek apakah API key di-set.
  static bool get hasApiKey => apiKey.isNotEmpty;

  /// Cek apakah sedang pakai runtime override.
  static bool get hasRuntimeOverride =>
      _runtimeBaseUrl != null || _runtimeModelName != null;

  /// Load runtime config dari SharedPreferences.
  /// Panggil sekali saat app startup (di main()).
  static Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString(_keyBaseUrl);
    final savedModel = prefs.getString(_keyModelName);

    if (savedUrl != null && savedUrl.isNotEmpty) {
      _runtimeBaseUrl = savedUrl;
    }
    if (savedModel != null && savedModel.isNotEmpty) {
      _runtimeModelName = savedModel;
    }
  }

  /// Simpan runtime config ke SharedPreferences.
  /// Dipanggil dari Settings UI.
  static Future<void> saveToPrefs({
    required String baseUrl,
    required String modelName,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    if (baseUrl.trim().isNotEmpty) {
      _runtimeBaseUrl = baseUrl.trim();
      await prefs.setString(_keyBaseUrl, _runtimeBaseUrl!);
    } else {
      _runtimeBaseUrl = null;
      await prefs.remove(_keyBaseUrl);
    }

    if (modelName.trim().isNotEmpty) {
      _runtimeModelName = modelName.trim();
      await prefs.setString(_keyModelName, _runtimeModelName!);
    } else {
      _runtimeModelName = null;
      await prefs.remove(_keyModelName);
    }
  }

  /// Reset runtime overrides — kembali ke compile-time values.
  static Future<void> clearRuntimeOverrides() async {
    final prefs = await SharedPreferences.getInstance();
    _runtimeBaseUrl = null;
    _runtimeModelName = null;
    await prefs.remove(_keyBaseUrl);
    await prefs.remove(_keyModelName);
  }
}
