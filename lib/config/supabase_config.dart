/// Konfigurasi koneksi Supabase untuk SIGUMI.
///
/// PENTING: Ganti URL dan anonKey dengan kredensial dari
/// Supabase Dashboard → Project Settings → API.
/// Lihat supabase/SETUP_GUIDE.md untuk panduan lengkap.
class SupabaseConfig {
  /// URL project Supabase - diutamakan dari Environment Variable (--dart-define)
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'http://187.53.141.200:8000',
  );

  /// Anon/public key Supabase - diutamakan dari Environment Variable (--dart-define)
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d2FudGVlY3J2eWR4eXJncGlpIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3NTIzNTY1NCwiZXhwIjoyMDkwODExNjU0fQ.JVC38IwWJcllhnKvlfGjPoTN4kDadDBP8P53ck6Wq04',
  );

  /// Kredensial Database untuk mendengarkan status Real-Time (Project rtwanteecrvydxyrgpii)
  static const String magmaUrl = url;
  static const String magmaAnonKey = anonKey;

  /// Cek apakah config sudah benar-benar terisi (bukan placeholder default)
  static bool get isConfigured =>
      url.isNotEmpty &&
      url.startsWith('http') &&
      anonKey.isNotEmpty &&
      anonKey.length > 50;
}
