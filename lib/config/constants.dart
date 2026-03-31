class AppConstants {
  // Volcano Data
  static const double merapiLat = -7.5407;
  static const double merapiLng = 110.4457;
  static const String merapiName = 'Gunung Merapi';
  static const double merapiElevation = 2968;

  // Danger Zone Radii (in km)
  static const double zoneDangerRadius = 5.0;
  static const double zoneWarningRadius = 10.0;
  static const double zoneCautionRadius = 15.0;
  static const double zoneSafeRadius = 20.0;

  // Report Radius Filter (km) - AI limits reports within this radius
  static const double reportMaxRadius = 30.0;

  // Data Sources
  static const List<String> dataSources = [
    'BMKG (Badan Meteorologi, Klimatologi, dan Geofisika)',
    'PVMBG (Pusat Vulkanologi dan Mitigasi Bencana Geologi)',
    'BNPB (Badan Nasional Penanggulangan Bencana)',
    'BPBD Daerah',
    'Pemerintah Daerah',
    'Masyarakat Zona Rawan',
  ];

  // Emergency Contacts
  static const List<Map<String, String>> emergencyContacts = [
    {'name': 'BNPB', 'phone': '117', 'desc': 'Badan Nasional Penanggulangan Bencana'},
    {'name': 'BPBD DIY', 'phone': '(0274) 555679', 'desc': 'BPBD Daerah Istimewa Yogyakarta'},
    {'name': 'BPBD Jateng', 'phone': '(024) 3512441', 'desc': 'BPBD Jawa Tengah'},
    {'name': 'SAR/Basarnas', 'phone': '115', 'desc': 'Badan SAR Nasional'},
    {'name': 'PMI', 'phone': '021-7992325', 'desc': 'Palang Merah Indonesia'},
    {'name': 'Polisi', 'phone': '110', 'desc': 'Kepolisian Negara RI'},
    {'name': 'Ambulans', 'phone': '118', 'desc': 'Layanan Ambulans Darurat'},
    {'name': 'Damkar', 'phone': '113', 'desc': 'Pemadam Kebakaran'},
    {'name': 'PLN', 'phone': '123', 'desc': 'Gangguan Listrik'},
    {'name': 'Posko Merapi', 'phone': '(0274) 896573', 'desc': 'Posko Pengamatan Gunung Merapi'},
  ];

  // Supported Languages
  static const Map<String, String> supportedLanguages = {
    'en': 'English',
    'id': 'Bahasa Indonesia',
  };

  // Onboarding Pages
  static const List<Map<String, String>> onboardingPages = [
    {
      'title': 'Selamat Datang di SIGUMI',
      'desc': 'Sistem Informasi Gunung Berapi Mitigasi - Informasi bencana gunung berapi yang akurat dan terpercaya untuk keselamatan Anda.',
      'icon': 'volcano',
    },
    {
      'title': 'Peringatan Dini & Evakuasi',
      'desc': 'Dapatkan peringatan dini adaptif dan jalur evakuasi teraman berdasarkan lokasi GPS, arah angin, dan kepadatan jalur.',
      'icon': 'warning',
    },
    {
      'title': 'Akses Online & Offline',
      'desc': 'Informasi penting tetap tersedia meskipun tanpa koneksi internet. Panduan lengkap sebelum, saat, dan setelah erupsi.',
      'icon': 'offline',
    },
  ];
}
