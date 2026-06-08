/// Konfigurasi Ollama Server untuk Cloud LLM (Gemma 4).
///
/// Ollama menjalankan model Gemma 4 secara self-hosted di VPS/server.
/// Konfigurasi dapat di-set melalui environment variable saat build:
///
/// ```bash
/// flutter run \
///   --dart-define=OLLAMA_BASE_URL=https://your-vps.com:11434 \
///   --dart-define=OLLAMA_MODEL=gemma4:12b \
///   --dart-define=OLLAMA_API_KEY=your_secret_key
/// ```
///
/// Untuk development lokal, cukup jalankan Ollama di mesin sendiri:
/// ```bash
/// ollama pull gemma4:e4b
/// ollama serve
/// ```
class OllamaConfig {
  /// Base URL server Ollama.
  ///
  /// Default: `http://localhost:11434` (untuk development lokal).
  /// Production: Ganti ke URL VPS via `--dart-define=OLLAMA_BASE_URL=...`
  static const String baseUrl = String.fromEnvironment(
    'OLLAMA_BASE_URL',
    defaultValue: 'http://localhost:11434',
  );

  /// Model Gemma 4 yang digunakan.
  ///
  /// Variant yang tersedia di Ollama:
  /// - `gemma4:e2b`  → 2B params, untuk edge device
  /// - `gemma4:e4b`  → 4B params, balanced (rekomendasi VPS kecil)
  /// - `gemma4:12b`  → 12B params, workstation-grade
  /// - `gemma4:27b`  → 27B MoE, frontier-level
  static const String modelName = String.fromEnvironment(
    'OLLAMA_MODEL',
    defaultValue: 'gemma4:e4b',
  );

  /// API key opsional untuk autentikasi.
  ///
  /// Ollama default tidak butuh API key. Tapi jika server dilindungi
  /// reverse proxy (nginx/caddy) dengan auth, set key di sini.
  /// Dikirim sebagai header `Authorization: Bearer <key>`.
  static const String apiKey = String.fromEnvironment(
    'OLLAMA_API_KEY',
    defaultValue: '',
  );

  /// Cek apakah Ollama sudah dikonfigurasi (baseUrl tidak kosong).
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Cek apakah API key di-set (untuk reverse proxy auth).
  static bool get hasApiKey => apiKey.isNotEmpty;
}
