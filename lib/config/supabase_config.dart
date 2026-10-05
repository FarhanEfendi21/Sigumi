import 'dart:convert';

/// Konfigurasi koneksi Supabase untuk SIGUMI.
///
/// PENTING: Ganti URL dan anonKey dengan kredensial dari
/// Supabase Dashboard → Project Settings → API.
/// Lihat supabase/SETUP_GUIDE.md untuk panduan lengkap.
class SupabaseConfig {
  static const String _httpVpsHost = '187.53.141.200';
  static const int _httpVpsPort = 8000;

  /// URL project Supabase - diutamakan dari Environment Variable (--dart-define)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://187.53.141.200:8000',
  );

  /// Anon/public key Supabase - diutamakan dari Environment Variable (--dart-define)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d2FudGVlY3J2eWR4eXJncGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzU2NTQsImV4cCI6MjA5MDgxMTY1NH0.ofz33s1PLvEGu_rgnu1CTXt_IUKOi0Ppni_8rvCxKrU',
  );

  /// Kredensial Database untuk mendengarkan status Real-Time (Project rtwanteecrvydxyrgpii)
  static const String magmaUrl = url;
  static const String magmaAnonKey = anonKey;

  /// HTTP hanya diizinkan untuk gateway Supabase VPS SIGUMI saat ini.
  /// Semua endpoint HTTP lain tetap dianggap konfigurasi yang tidak valid.
  static bool get isConfigured {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.host.isEmpty || !_isPublicKey(anonKey)) {
      return false;
    }

    final isHttps = uri.scheme == 'https';
    final isAllowedVpsHttp =
        uri.scheme == 'http' &&
        uri.host == _httpVpsHost &&
        uri.port == _httpVpsPort;

    return isHttps || isAllowedVpsHttp;
  }

  static bool _isPublicKey(String key) {
    if (key.isEmpty || key.startsWith('sb_secret_')) return false;
    final parts = key.split('.');
    if (parts.length != 3) return key.length > 20;

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['role'] != 'anon') return false;
      return key.length > 20;
    } on FormatException {
      return false;
    }
  }
}
