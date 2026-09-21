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
    defaultValue: 'https://ollama-mvod.srv1985398.hstgr.cloud',
  );

  /// Model yang digunakan (Finetuned untuk SIGUMI).
  static const String modelName = String.fromEnvironment(
    'OLLAMA_MODEL',
    defaultValue: 'sigumi-finetuned',
  );

  /// Username untuk Basic Auth (didapat dari --dart-define).
  static const String ollamaUser = String.fromEnvironment(
    'OLLAMA_USER',
    defaultValue: '',
  );

  /// Password untuk Basic Auth (didapat dari --dart-define).
  static const String ollamaPass = String.fromEnvironment(
    'OLLAMA_PASS',
    defaultValue: '',
  );

  /// Cek apakah Ollama sudah dikonfigurasi (baseUrl tidak kosong).
  static bool get isConfigured => baseUrl.isNotEmpty;

  /// Cek apakah kredensial Basic Auth tersedia.
  static bool get hasBasicAuth => ollamaUser.isNotEmpty && ollamaPass.isNotEmpty;
}
