/// Konfigurasi koneksi Supabase untuk SIGUMI.
///
/// PENTING: Ganti URL dan anonKey dengan kredensial dari
/// Supabase Dashboard → Project Settings → API.
/// Lihat supabase/SETUP_GUIDE.md untuk panduan lengkap.
class SupabaseConfig {
  /// URL project Supabase - diutamakan dari Environment Variable Vercel
  static const String url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rtwanteecrvydxyrgpii.supabase.co',
  );

  /// Anon/public key Supabase - diutamakan dari Environment Variable Vercel
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJ0d2FudGVlY3J2eWR4eXJncGlpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUyMzU2NTQsImV4cCI6MjA5MDgxMTY1NH0.ofz33s1PLvEGu_rgnu1CTXt_IUKOi0Ppni_8rvCxKrU',
  );

  /// Kredensial Database Mockup-MAGMA untuk mendengarkan status Real-Time
  static const String magmaUrl = 'https://ekwspoggwiptbepeelne.supabase.co';
  static const String magmaAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImVrd3Nwb2dnd2lwdGJlcGVlbG5lIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzU5MDEzNDgsImV4cCI6MjA5MTQ3NzM0OH0.eVFsts2mkvFNAOgJp2yZ2BkmsD9qpFC4m-0oYSD7NGA';

  /// Cek apakah config sudah benar-benar terisi (bukan placeholder default)
  static bool get isConfigured =>
      url.isNotEmpty &&
      url.startsWith('http') &&
      anonKey.isNotEmpty &&
      anonKey.length > 50;
}
