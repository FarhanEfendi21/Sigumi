import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/volcano_provider.dart';

/// Extension untuk akses terjemahan yang ringkas: context.tr('key')
extension AppLocalizations on BuildContext {
  String tr(String key) {
    final lang = read<VolcanoProvider>().language;
    return LocalizationService.translate(key, lang);
  }
}

/// Layanan lokalisasi untuk mendukung 5 bahasa: Indonesia, English, Jawa, Bali, Sasak
class LocalizationService {
  // Pemetaan string untuk semua bahasa yang didukung
  static const Map<String, Map<String, String>> translations = {
    'id': {
      // Login & Register
      'welcome_back': 'Selamat Datang',
      'sign_in': 'Masuk ke akun SIGUMI Anda',
      'phone_number': 'Nomor Telepon',
      'phone_hint': 'Contoh: 081234567890',
      'password': 'Kata Sandi',
      'password_hint': 'Masukkan kata sandi Anda',
      'forgot_password': 'Lupa Kata Sandi?',
      'login': 'Masuk',
      'sign_up': 'Daftar',
      'create_account': 'Buat Akun Baru',
      'dont_have_account': 'Belum punya akun?',
      'already_have_account': 'Sudah punya akun?',
      'email': 'Email',
      'email_hint': 'Masukkan email Anda',
      'name': 'Nama Lengkap',
      'name_hint': 'Masukkan nama lengkap Anda',

      // Home
      'home': 'Beranda',
      'status': 'Status',
      'volcano_status': 'Status Gunung Berapi',
      'last_update': 'Pembaruan Terakhir',

      // Settings & Profile
      'profile': 'Profil',
      'settings': 'Pengaturan',
      'language': 'Bahasa',
      'accessibility': 'Aksesibilitas',
      'about': 'Tentang SIGUMI',
      'logout': 'Keluar',
      'language_changed': 'Bahasa telah diubah',
      'language_settings_applied':
          'Pengaturan bahasa diterapkan ke seluruh aplikasi',

      // Accessibility
      'text_size': 'Ukuran Teks',
      'contrast': 'Kontras Tinggi',
      'audio_guidance': 'Panduan Audio',

      // Common
      'cancel': 'Batal',
      'save': 'Simpan',
      'delete': 'Hapus',
      'continue': 'Lanjutkan',
      'back': 'Kembali',
      'loading': 'Memuat...',
      'error': 'Kesalahan',
      'success': 'Berhasil',
      'close': 'Tutup',

      // Home
      'main_menu': 'Menu Utama',
      'evacuation_point': 'Titik Aman\nEvakuasi',
      'cctv_monitoring': 'Pantauan\nCCTV',
      'education': 'Edukasi',
      'posko_faskes': 'Posko &\nFaskes',
      'ask_sigumi': 'Tanya\nSi Gumi',
      'emergency_number': 'Nomor\nDarurat',
      'latest_news': 'Berita Terkini',
      'loading_news': 'Memuat berita...',
      'no_news': 'Belum ada berita',
      'explore_tourism': 'Jelajahi Wisata',
      'find_destination': 'Temukan destinasi & agenda budaya menarik',
      'select_region': 'Pilih Daerah',
      'monitor_volcano': 'Pantau gunung berapi aktif di daerah Anda',
      'from_summit': 'dari puncak',
      'your_location': 'Lokasi Anda',

      // Navigation
      'nav_home': 'Beranda',
      'nav_map': 'Peta',
      'nav_report': 'Lapor',
      'nav_chatbot': 'Chatbot',
      'nav_profile': 'Profil',

      // Settings
      'account_pref': 'Preferensi Akun',
      'system_app': 'Sistem & Aplikasi',
      'offline_data': 'Data Offline',
      'offline_active': 'Mode offline aktif',
      'using_online': 'Menggunakan data online',
      'notification': 'Notifikasi',
      'notif_subtitle': 'Atur peringatan dini & notifikasi',
      'about_sigumi': 'Tentang SIGUMI',
      'version': 'Versi 1.0.0',
      'logout_confirm_title': 'Keluar Akun',
      'logout_confirm_msg': 'Apakah kamu yakin ingin keluar dari akun SIGUMI?',
      'about_desc': 'SIGUMI — Sistem Informasi Gunung Berapi Mitigasi\n\nMemberikan informasi terpercaya tentang aktivitas gunung berapi untuk mendukung keselamatan masyarakat.\n\nVersi 1.0.0',
      'language_note': 'Pengaturan bahasa akan diterapkan ke seluruh halaman aplikasi secara otomatis.',
      'available_languages': 'BAHASA TERSEDIA',
      'choose_language': 'Pilih Bahasa',

      // Register
      'register_title': 'Daftar Akun Baru',
      'register_subtitle': 'Isi data untuk personalisasi informasi bencana',
      'date_of_birth': 'Tanggal Lahir',
      'dob_hint': 'Pilih tanggal lahir',
      'dob_ai_note': 'Untuk personalisasi AI informasi bencana',
      'register_btn': 'Daftar',
      'reg_success_title': 'Pendaftaran Berhasil',
      'reg_success_msg': 'Akun Anda telah berhasil dibuat. Silakan masuk menggunakan nomor telepon dan kata sandi Anda.',
      'login_now': 'Masuk Sekarang',
      'reg_fail_title': 'Pendaftaran Gagal',
      'login_fail_title': 'Gagal Masuk',
    },
    'en': {
      // Login & Register
      'welcome_back': 'Welcome Back',
      'sign_in': 'Sign in to your SIGUMI account',
      'phone_number': 'Phone Number',
      'phone_hint': 'e.g. 081234567890',
      'password': 'Password',
      'password_hint': 'Enter your password',
      'forgot_password': 'Forgot Password?',
      'login': 'Sign In',
      'sign_up': 'Register',
      'create_account': 'Create New Account',
      'dont_have_account': "Don't have an account?",
      'already_have_account': 'Already have an account?',
      'email': 'Email',
      'email_hint': 'Enter your email',
      'name': 'Full Name',
      'name_hint': 'Enter your full name',

      // Home
      'home': 'Home',
      'status': 'Status',
      'volcano_status': 'Volcano Status',
      'last_update': 'Last Update',

      // Settings & Profile
      'profile': 'Profile',
      'settings': 'Settings',
      'language': 'Language',
      'accessibility': 'Accessibility',
      'about': 'About SIGUMI',
      'logout': 'Logout',
      'language_changed': 'Language has been changed',
      'language_settings_applied':
          'Language settings applied to entire application',

      // Accessibility
      'text_size': 'Text Size',
      'contrast': 'High Contrast',
      'audio_guidance': 'Audio Guidance',

      // Common
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'continue': 'Continue',
      'back': 'Back',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'close': 'Close',

      // Home
      'main_menu': 'Main Menu',
      'evacuation_point': 'Safe\nEvacuation',
      'cctv_monitoring': 'CCTV\nMonitoring',
      'education': 'Education',
      'posko_faskes': 'Post &\nClinic',
      'ask_sigumi': 'Ask\nSi Gumi',
      'emergency_number': 'Emergency\nNumbers',
      'latest_news': 'Latest News',
      'loading_news': 'Loading news...',
      'no_news': 'No news yet',
      'explore_tourism': 'Explore Tourism',
      'find_destination': 'Find destinations & cultural events',
      'select_region': 'Select Region',
      'monitor_volcano': 'Monitor active volcanoes in your area',
      'from_summit': 'from summit',
      'your_location': 'Your Location',

      // Navigation
      'nav_home': 'Home',
      'nav_map': 'Map',
      'nav_report': 'Report',
      'nav_chatbot': 'Chatbot',
      'nav_profile': 'Profile',

      // Settings
      'account_pref': 'Account Preferences',
      'system_app': 'System & App',
      'offline_data': 'Offline Data',
      'offline_active': 'Offline mode active',
      'using_online': 'Using online data',
      'notification': 'Notifications',
      'notif_subtitle': 'Manage early warnings & notifications',
      'about_sigumi': 'About SIGUMI',
      'version': 'Version 1.0.0',
      'logout_confirm_title': 'Sign Out',
      'logout_confirm_msg': 'Are you sure you want to sign out of SIGUMI?',
      'about_desc': 'SIGUMI — Volcano Information & Mitigation System\n\nProvides trusted information about volcanic activity to support community safety.\n\nVersion 1.0.0',
      'language_note': 'Language settings will be applied to the entire application automatically.',
      'available_languages': 'AVAILABLE LANGUAGES',
      'choose_language': 'Choose Language',

      // Register
      'register_title': 'Create Account',
      'register_subtitle': 'Fill in your details for disaster info personalization',
      'date_of_birth': 'Date of Birth',
      'dob_hint': 'Select date of birth',
      'dob_ai_note': 'For AI personalization of disaster information',
      'register_btn': 'Register',
      'reg_success_title': 'Registration Successful',
      'reg_success_msg': 'Your account has been created. Please sign in using your phone number and password.',
      'login_now': 'Sign In Now',
      'reg_fail_title': 'Registration Failed',
      'login_fail_title': 'Sign In Failed',
    },
    'jv': {
      // Login & Register
      'welcome_back': 'Sugeng Rawuh Mangke',
      'sign_in': 'Mlebu ing akun SIGUMI Sampéyan',
      'phone_number': 'Nomer Telpon',
      'phone_hint': 'Contone: 081234567890',
      'password': 'Sandi',
      'password_hint': 'Tulisen sandi Sampéyan',
      'forgot_password': 'Lali Sandi?',
      'login': 'Mlebu',
      'sign_up': 'Daftar',
      'create_account': 'Gawé Akun Anyar',
      'dont_have_account': 'Durung nduwé akun?',
      'already_have_account': 'Wis nduwé akun?',
      'email': 'Email',
      'email_hint': 'Tulisen email Sampéyan',
      'name': 'Jeneng Lengkap',
      'name_hint': 'Tulisen jeneng lengkap Sampéyan',

      // Home
      'home': 'Kulina',
      'status': 'Status',
      'volcano_status': 'Status Gunung Sedheng',
      'last_update': 'Pembaruan Paling Anyar',

      // Settings & Profile
      'profile': 'Profil',
      'settings': 'Pangaturan',
      'language': 'Basa',
      'accessibility': 'Aksesbilitas',
      'about': 'Ngenani SIGUMI',
      'logout': 'Metu',
      'language_changed': 'Basa wis diowah',
      'language_settings_applied':
          'Pangaturan basa kaicalan ing kabeh aplikasi',

      // Accessibility
      'text_size': 'Gawene Teks',
      'contrast': 'Kontras Dhuwur',
      'audio_guidance': 'Panduan Swara',

      // Common
      'cancel': 'Batal',
      'save': 'Simpen',
      'delete': 'Busak',
      'continue': 'Lanjutna',
      'back': 'Bali',
      'loading': 'Lenggah...',
      'error': 'Kesalahan',
      'success': 'Kasil',
      'close': 'Tutup',

      // Home
      'main_menu': 'Menu Utama',
      'evacuation_point': 'Titik Aman\nEvakuasi',
      'cctv_monitoring': 'Pantauan\nCCTV',
      'education': 'Edukasi',
      'posko_faskes': 'Posko &\nFaskes',
      'ask_sigumi': 'Takon\nSi Gumi',
      'emergency_number': 'Nomer\nDarurat',
      'latest_news': 'Warta Anyar',
      'loading_news': 'Ngenteni warta...',
      'no_news': 'Durung ana warta',
      'explore_tourism': 'Jelajah Wisata',
      'find_destination': 'Golek papan wisata & agenda budaya',
      'select_region': 'Pilih Daerah',
      'monitor_volcano': 'Pantau gunung berapi aktif ing daerahmu',
      'from_summit': 'saka puncak',
      'your_location': 'Lokasi Sampeyan',

      // Navigation
      'nav_home': 'Kulina',
      'nav_map': 'Peta',
      'nav_report': 'Lapor',
      'nav_chatbot': 'Chatbot',
      'nav_profile': 'Profil',

      // Settings
      'account_pref': 'Preferensi Akun',
      'system_app': 'Sistem & Aplikasi',
      'offline_data': 'Data Offline',
      'offline_active': 'Mode offline aktif',
      'using_online': 'Nggunakake data online',
      'notification': 'Notifikasi',
      'notif_subtitle': 'Atur peringatan dini & notifikasi',
      'about_sigumi': 'Ngenani SIGUMI',
      'version': 'Versi 1.0.0',
      'logout_confirm_title': 'Metu Akun',
      'logout_confirm_msg': 'Apa sampeyan yakin arep metu saka akun SIGUMI?',
      'about_desc': 'SIGUMI — Sistem Informasi Gunung Sedheng Mitigasi\n\nMenehi informasi sing dipercaya babagan aktivitas gunung berapi.\n\nVersi 1.0.0',
      'language_note': 'Pangaturan basa bakal diterapake ing kabeh kaca aplikasi.',
      'available_languages': 'BASA KANG KASEDHIYA',
      'choose_language': 'Pilih Basa',

      // Register
      'register_title': 'Gawe Akun Anyar',
      'register_subtitle': 'Isi data kanggo personalisasi informasi bencana',
      'date_of_birth': 'Tanggal Lair',
      'dob_hint': 'Pilih tanggal lair',
      'dob_ai_note': 'Kanggo personalisasi AI informasi bencana',
      'register_btn': 'Daftar',
      'reg_success_title': 'Pendaftaran Kasil',
      'reg_success_msg': 'Akun sampeyan wis kasil digawe. Mangga mlebu nggunakake nomer telpon lan sandi.',
      'login_now': 'Mlebu Saiki',
      'reg_fail_title': 'Pendaftaran Gagal',
      'login_fail_title': 'Gagal Mlebu',
    },
    'ba': {
      // Login & Register
      'welcome_back': 'Suksma Datang',
      'sign_in': 'Masuk ten akun SIGUMI ipun',
      'phone_number': 'Nomer Telepon',
      'phone_hint': 'Contone: 081234567890',
      'password': 'Kata Sandi',
      'password_hint': 'Tulisang kata sandi ipun',
      'forgot_password': 'Lali Kata Sandi?',
      'login': 'Masuk',
      'sign_up': 'Daftar',
      'create_account': 'Gawé Akun Anyar',
      'dont_have_account': 'Durung nyan akun?',
      'already_have_account': 'Sampun nyan akun?',
      'email': 'Email',
      'email_hint': 'Tulisang email ipun',
      'name': 'Jenang Lengkap',
      'name_hint': 'Tulisang jenang lengkap ipun',

      // Home
      'home': 'Kalianan',
      'status': 'Status',
      'volcano_status': 'Status Gunung Sedheng',
      'last_update': 'Pembaruan Terakhir',

      // Settings & Profile
      'profile': 'Profil',
      'settings': 'Pengaturan',
      'language': 'Basa',
      'accessibility': 'Aksesibilitas',
      'about': 'Ngenani SIGUMI',
      'logout': 'Metu',
      'language_changed': 'Basa sampun diowah',
      'language_settings_applied':
          'Pengaturan basa kaicalan ring kabeh aplikasi',

      // Accessibility
      'text_size': 'Gawene Teks',
      'contrast': 'Kontras Dhuwur',
      'audio_guidance': 'Panduan Swara',

      // Common
      'cancel': 'Batal',
      'save': 'Simpen',
      'delete': 'Busak',
      'continue': 'Lanjutna',
      'back': 'Bali',
      'loading': 'Lenggah...',
      'error': 'Kesalahan',
      'success': 'Kasil',
      'close': 'Tutup',

      // Home
      'main_menu': 'Menu Utama',
      'evacuation_point': 'Titik Aman\nEvakuasi',
      'cctv_monitoring': 'Pantauan\nCCTV',
      'education': 'Edukasi',
      'posko_faskes': 'Posko &\nFaskes',
      'ask_sigumi': 'Takon\nSi Gumi',
      'emergency_number': 'Nomer\nDarurat',
      'latest_news': 'Berita Anyar',
      'loading_news': 'Ngenteni berita...',
      'no_news': 'Durung ada berita',
      'explore_tourism': 'Jelajah Wisata',
      'find_destination': 'Golek destinasi & agenda budaya',
      'select_region': 'Pilih Daerah',
      'monitor_volcano': 'Pantau gunung berapi aktif ring daerah',
      'from_summit': 'saking puncak',
      'your_location': 'Lokasi Sami',

      // Navigation
      'nav_home': 'Kalianan',
      'nav_map': 'Peta',
      'nav_report': 'Lapor',
      'nav_chatbot': 'Chatbot',
      'nav_profile': 'Profil',

      // Settings
      'account_pref': 'Preferensi Akun',
      'system_app': 'Sistem & Aplikasi',
      'offline_data': 'Data Offline',
      'offline_active': 'Mode offline aktif',
      'using_online': 'Nggunakang data online',
      'notification': 'Notifikasi',
      'notif_subtitle': 'Atur peringatan & notifikasi',
      'about_sigumi': 'Ngenani SIGUMI',
      'version': 'Versi 1.0.0',
      'logout_confirm_title': 'Medal Akun',
      'logout_confirm_msg': 'Apa iraq yakin arep medal saking akun SIGUMI?',
      'about_desc': 'SIGUMI — Sistem Informasi Gunung Sedheng Mitigasi\n\nMenehi informasi babagan aktivitas gunung berapi.\n\nVersi 1.0.0',
      'language_note': 'Pengaturan basa lakar diterapang ring kabeh kaca aplikasi.',
      'available_languages': 'BASA KANG TERSEDIA',
      'choose_language': 'Pilih Basa',

      // Register
      'register_title': 'Gawe Akun Anyar',
      'register_subtitle': 'Isi data kanggo personalisasi informasi bencana',
      'date_of_birth': 'Tanggal Lair',
      'dob_hint': 'Pilih tanggal lair',
      'dob_ai_note': 'Kanggo personalisasi AI informasi bencana',
      'register_btn': 'Daftar',
      'reg_success_title': 'Pendaftaran Kasil',
      'reg_success_msg': 'Akun sampun kasil digawe. Mangga marak nggunakang nomer telpon lan sandi.',
      'login_now': 'Marak Saiki',
      'reg_fail_title': 'Pendaftaran Gagal',
      'login_fail_title': 'Gagal Marak',
    },
    'sa': {
      // Login & Register
      'welcome_back': 'Sumbur Bé Muluk',
      'sign_in': 'Marak ten akun SIGUMI sampun',
      'phone_number': 'Nomer Telpon',
      'phone_hint': 'Contone: 081234567890',
      'password': 'Kata Sandi',
      'password_hint': 'Tulisen kata sandi sampun',
      'forgot_password': 'Ilang Kata Sandi?',
      'login': 'Marak',
      'sign_up': 'Daftar',
      'create_account': 'Gawé Akun Anyar',
      'dont_have_account': 'Durung nyan akun?',
      'already_have_account': 'Sampun nyan akun?',
      'email': 'Email',
      'email_hint': 'Tulisen email sampun',
      'name': 'Ngaran Lengkap',
      'name_hint': 'Tulisen ngaran lengkap sampun',

      // Home
      'home': 'Pujokan',
      'status': 'Status',
      'volcano_status': 'Status Gunung Sedheng',
      'last_update': 'Perbaroan Terakhir',

      // Settings & Profile
      'profile': 'Profil',
      'settings': 'Pangaturan',
      'language': 'Basa',
      'accessibility': 'Aksesibilitas',
      'about': 'Ngenani SIGUMI',
      'logout': 'Metu',
      'language_changed': 'Basa sampun diowah',
      'language_settings_applied':
          'Pangaturan basa kaicalan ring kabeh aplikasi',

      // Accessibility
      'text_size': 'Gawene Teks',
      'contrast': 'Kontras Dhuwur',
      'audio_guidance': 'Panduan Swara',

      // Common
      'cancel': 'Batal',
      'save': 'Simpen',
      'delete': 'Busak',
      'continue': 'Lanjutna',
      'back': 'Bali',
      'loading': 'Lenggah...',
      'error': 'Kesalahan',
      'success': 'Kasil',
      'close': 'Tutup',

      // Home
      'main_menu': 'Menu Utama',
      'evacuation_point': 'Titik Aman\nEvakuasi',
      'cctv_monitoring': 'Pantauan\nCCTV',
      'education': 'Edukasi',
      'posko_faskes': 'Posko &\nFaskes',
      'ask_sigumi': 'Takon\nSi Gumi',
      'emergency_number': 'Nomer\nDarurat',
      'latest_news': 'Berita Anyar',
      'loading_news': 'Ngenteni berita...',
      'no_news': 'Durung ara berita',
      'explore_tourism': 'Jelajah Wisata',
      'find_destination': 'Golek destinasi & agenda budaya',
      'select_region': 'Pilih Daerah',
      'monitor_volcano': 'Pantau gunung berapi aktif leq daerah side',
      'from_summit': 'saking puncak',
      'your_location': 'Lokasi Side',

      // Navigation
      'nav_home': 'Pujokan',
      'nav_map': 'Peta',
      'nav_report': 'Lapor',
      'nav_chatbot': 'Chatbot',
      'nav_profile': 'Profil',

      // Settings
      'account_pref': 'Preferensi Akun',
      'system_app': 'Sistem & Aplikasi',
      'offline_data': 'Data Offline',
      'offline_active': 'Mode offline aktif',
      'using_online': 'Menggunakan data online',
      'notification': 'Notifikasi',
      'notif_subtitle': 'Atur peringatan & notifikasi',
      'about_sigumi': 'Ngenani SIGUMI',
      'version': 'Versi 1.0.0',
      'logout_confirm_title': 'Medal Akun',
      'logout_confirm_msg': 'Ape side yakin mele medal leq akun SIGUMI?',
      'about_desc': 'SIGUMI — Sistem Informasi Gunung Berapi Mitigasi\n\nMenehi informasi babagan aktivitas gunung berapi.\n\nVersi 1.0.0',
      'language_note': 'Pengaturan basa lakar diterapang leq semua halaman aplikasi.',
      'available_languages': 'BASA KANG TERSEDIA',
      'choose_language': 'Pilih Basa',

      // Register
      'register_title': 'Gawe Akun Anyar',
      'register_subtitle': 'Isi data kanggo personalisasi informasi bencana',
      'date_of_birth': 'Tanggal Lahir',
      'dob_hint': 'Pilih tanggal lahir',
      'dob_ai_note': 'Untuk personalisasi AI informasi bencana',
      'register_btn': 'Daftar',
      'reg_success_title': 'Pendaftaran Kasil',
      'reg_success_msg': 'Akun side sampun kasil digawe. Mangga marak nggunakang nomer telpon lan sandi.',
      'login_now': 'Marak Saiki',
      'reg_fail_title': 'Pendaftaran Gagal',
      'login_fail_title': 'Gagal Marak',
    },
  };

  /// Dapatkan string terjemahan berdasarkan kunci dan bahasa
  static String translate(String key, String language) {
    final lang = language.toLowerCase();

    if (!translations.containsKey(lang)) {
      // Fallback ke Indonesian jika bahasa tidak tersedia
      return translations['id']?[key] ?? key;
    }

    return translations[lang]?[key] ?? key;
  }

  /// Dapatkan semua kunci terjemahan yang tersedia
  static List<String> getAllLanguages() {
    return translations.keys.toList();
  }

  /// Check apakah bahasa tersedia
  static bool isLanguageSupported(String language) {
    return translations.containsKey(language.toLowerCase());
  }
}
