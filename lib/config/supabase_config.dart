/// Konfigurasi koneksi Supabase untuk SIGUMI.
///
/// PENTING: Ganti URL dan anonKey dengan kredensial dari
/// Supabase Dashboard → Project Settings → API.
/// Lihat supabase/SETUP_GUIDE.md untuk panduan lengkap.
class SupabaseConfig {
  /// URL project Supabase (contoh: https://xxxxx.supabase.co)
  static const String url = 'https://rtwanteecrvydxyrgpii.supabase.co';

  /// Anon/public key dari Supabase Dashboard
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d2FudGVlY3J2eWR4eXJncGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzU2NTQsImV4cCI6MjA5MDgxMTY1NH0.ofz33s1PLvEGu_rgnu1CTXt_IUKOi0Ppni_8rvCxKrU';

  /// Cek apakah config sudah diisi
  static bool get isConfigured =>
      url != 'YOUR_SUPABASE_URL' && anonKey != 'YOUR_SUPABASE_ANON_KEY';
}
