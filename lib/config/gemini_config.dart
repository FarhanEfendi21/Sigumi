/// Konfigurasi Cloud LLM (Gemini API) untuk chatbot SIGUMI.
///
/// API key dapat di-set melalui:
/// 1. Environment variable: `--dart-define=GEMINI_API_KEY=your_key`
/// 2. Default value di bawah (untuk development)
///
/// Dapatkan API key gratis di: https://aistudio.google.com/apikey
class GeminiConfig {
  /// API key Gemini — diutamakan dari Environment Variable
  static const String apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '', // Kosongkan jika belum ada — chatbot tetap jalan tanpa cloud
  );

  /// Model Gemini yang digunakan
  /// - 'gemini-2.0-flash' : Cepat, gratis 15 RPM (rekomendasi)
  /// - 'gemini-1.5-flash' : Alternatif stabil
  /// - 'gemini-1.5-pro'   : Lebih pintar, kuota lebih kecil
  static const String modelName = String.fromEnvironment(
    'GEMINI_MODEL',
    defaultValue: 'gemini-2.0-flash',
  );

  /// Cek apakah Gemini API sudah dikonfigurasi
  static bool get isConfigured => apiKey.isNotEmpty;
}
