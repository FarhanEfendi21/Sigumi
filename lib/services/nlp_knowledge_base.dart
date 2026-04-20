/// Knowledge base NLP chatbot SIGUMI.
///
/// FOKUS: Edukasi & Pelatihan Mitigasi Pra-Bencana.
/// BUKAN: Arahan saat bencana aktif.
///
/// Bahasa yang didukung (5):
/// - 'id' : Indonesia
/// - 'en' : English
/// - 'jv' : Jawa
/// - 'ba' : Bali
/// - 'sas': Sasak (Lombok)
class NlpKnowledgeBase {
  // ═══════════════════════════════════════════════════════════════
  // LANGUAGE MARKERS — Penanda kata kunci per bahasa
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, List<String>> languageMarkers = {
    'jv': [
      'kowe', 'aku', 'piye', 'kepiye', 'saiki', 'ana', 'endi',
      'mlayu', 'dalan', 'banyu', 'awu', 'udhan', 'omah',
      'latihan', 'simulasi', 'monggo', 'panjenengan',
    ],
    'ba': [
      'tiang', 'ragane', 'kenken', 'mangkin', 'wenten', 'dija',
      'margi', 'yeh', 'umah', 'mewali',
      'latihan', 'simulasi', 'nulungin',
    ],
    'sas': [
      'tiang', 'side', 'berembe', 'napi', 'mbe', 'jelo',
      'bale', 'tende', 'aiq', 'pelungguh', 'tyang',
      'latihan', 'simulasi', 'belajaraq',
    ],
    'en': [
      'how', 'what', 'where', 'when', 'who', 'is', 'are',
      'status', 'volcano', 'evacuation', 'safe', 'danger',
      'training', 'simulation', 'drill', 'practice',
    ],
  };

  // ═══════════════════════════════════════════════════════════════
  // TRAINING PHRASES — Intent classification keywords
  // Fokus: Edukasi, Pelatihan, Simulasi, SOP Mitigasi
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, List<String>> trainingPhrases = {
    // === SALAM & PERKENALAN ===
    'salam': [
      'halo', 'hai', 'selamat pagi', 'selamat siang',
      'assalamualaikum', 'sugeng enjing', 'om swastiastu',
      'selamat sore', 'selamat malam', 'hello', 'hi',
    ],

    // === SOP EVAKUASI (Konteks Simulasi) ===
    'sop_evakuasi': [
      'bagaimana prosedur evakuasi saat simulasi',
      'sop evakuasi bencana', 'tata cara evakuasi yang benar',
      'langkah langkah evakuasi', 'cara evakuasi saat simulasi',
      'prosedur standar evakuasi', 'panduan evakuasi bencana',
      'urutan evakuasi yang baik', 'apa yang dilakukan saat evakuasi',
      'bagaimana cara evakuasi yang aman',
      'piye carane evakuasi sing bener',
      'kenken prosedur evakuasi',
    ],

    // === JADWAL PELATIHAN ===
    'jadwal_pelatihan': [
      'kapan jadwal pelatihan bencana', 'jadwal simulasi gempa',
      'kapan ada latihan evakuasi', 'pelatihan mitigasi bencana',
      'simulasi bencana terdekat', 'jadwal latihan kesiapsiagaan',
      'kapan drill evakuasi', 'pelatihan siaga bencana',
      'program pelatihan bpbd', 'kapan ada edukasi bencana',
      'kapan jadwal latihan', 'kapan ada pelatihan',
    ],

    // === TAS SIAGA BENCANA ===
    'tas_siaga': [
      'apa saja isi tas siaga bencana', 'perlengkapan tas siaga',
      'barang yang harus disiapkan tas siaga', 'checklist tas siaga',
      'persiapan tas darurat', 'tas siaga bencana isi apa',
      'barang penting tas siaga', 'apa yang dimasukkan tas siaga',
      'perlengkapan darurat bencana', 'barang wajib tas siaga',
      'isi tas siaga lengkap', 'persiapan menghadapi letusan',
    ],

    // === JALUR SIMULASI / EVAKUASI ===
    'evakuasi': [
      'di mana jalur simulasi evakuasi', 'rute evakuasi latihan',
      'jalur evakuasi terdekat', 'titik kumpul simulasi',
      'lokasi jalur evakuasi', 'arah evakuasi saat drill',
      'kemana harus evakuasi', 'jalur aman evakuasi',
      'peta jalur evakuasi', 'rute pelarian bencana',
      'titik berkumpul saat simulasi', 'jalur evakuasi desa',
      'tempat pengungsian di mana', 'jalan keluar terdekat',
      'harus lari kemana', 'cara evakuasi yang benar',
    ],

    // === MITIGASI HUJAN ABU (Edukasi) ===
    'mitigasi_abu': [
      'cara menghadapi hujan abu', 'tips saat hujan abu vulkanik',
      'perlindungan dari abu vulkanik', 'cara berlindung dari abu',
      'masker untuk abu vulkanik', 'bahaya abu vulkanik',
      'cara membersihkan abu', 'perlengkapan saat hujan abu',
      'tips menghadapi erupsi', 'cara melindungi diri dari abu',
      'antisipasi hujan abu',
    ],

    // === ZONA BAHAYA (Edukasi Pra-Bencana) ===
    'zona_bahaya': [
      'apa itu zona bahaya merapi', 'radius bahaya gunung api',
      'zona merah merapi', 'daerah rawan bencana',
      'kawasan berbahaya merapi', 'zona aman dari gunung api',
      'batas zona bahaya', 'pengertian zona bahaya',
      'zona rawan erupsi', 'daerah terlarang dekat gunung',
      'zona evakuasi wajib', 'berapa radius aman merapi',
    ],

    // === STATUS GUNUNG API (Edukasi Pemantauan Mandiri) ===
    'status': [
      'bagaimana status merapi saat ini', 'status gunung',
      'kondisi merapi sekarang', 'apakah merapi aman',
      'tingkat aktivitas gunung api', 'update merapi hari ini',
      'level gunung merapi', 'informasi terkini merapi',
      'gimana kabar merapi', 'status gunung api terbaru',
      'ada letusan nggak hari ini',
    ],

    // === P3K DASAR (Edukasi) ===
    'p3k': [
      'pertolongan pertama luka', 'cara mengobati luka bakar',
      'mata kelilipan abu', 'p3k saat bencana',
      'pertolongan medis darurat', 'bantuan pertama korban',
      'kotak p3k isi apa', 'obat obatan p3k',
      'perlengkapan p3k', 'cara menangani luka',
    ],

    // === NOMOR DARURAT ===
    'bantuan': [
      'nomor telepon darurat', 'panggil ambulans', 'hubungi sar',
      'kontak bnpb', 'minta bantuan', 'nomor bpbd',
      'butuh pertolongan segera', 'nomor posko merapi',
      'kontak darurat bencana', 'nomor telepon bpbd',
    ],
  };

  // ═══════════════════════════════════════════════════════════════
  // RESPONSES — Multi-language (5 bahasa, tone edukasi/pelatihan)
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, Map<String, String>> responses = {
    'salam': {
      'id':
          'Halo! Saya Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Saya siap membantu Anda mempelajari SOP evakuasi, jadwal simulasi, '
          'persiapan tas siaga, dan edukasi kesiapsiagaan. Ada yang bisa saya bantu?',
      'en':
          'Hello! I am Si Gumi, your disaster mitigation training instructor. '
          'I can help you learn evacuation SOPs, simulation schedules, '
          'emergency bag preparation, and preparedness education. How can I assist you?',
      'jv':
          'Halo! Kula Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Kula siap mbantu panjenengan sinau SOP evakuasi, jadwal simulasi, '
          'lan persiapan tanggap bencana. Wonten ingkang saged kula bantu?',
      'ba':
          'Om Swastiastu! Tiang Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Tiang siap nulungin ragane malajah SOP evakuasi, jadwal simulasi, '
          'miwah persiapan tanggap bencana. Napi sane presida tiang bantu?',
      'sas':
          'Tabe! Tyang Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Tyang siap bantu side belajaraq SOP evakuasi, jadwal simulasi, '
          'dait persiapan bencana. Napi saq bau tyang bantu?',
    },

    'sop_evakuasi': {
      'id':
          'SOP Evakuasi (Materi Pelatihan):\n\n'
          '1. Dengarkan alarm/sirine evakuasi dari petugas\n'
          '2. Ambil tas siaga yang sudah disiapkan\n'
          '3. Ikuti jalur evakuasi yang telah ditentukan\n'
          '4. Berjalan cepat dan tertib, jangan panik\n'
          '5. Bantu lansia, anak-anak, dan penyandang disabilitas\n'
          '6. Kumpul di titik kumpul (balai desa/lapangan)\n'
          '7. Petugas akan melakukan absensi kehadiran\n'
          '8. Tunggu instruksi selanjutnya dari koordinator\n\n'
          '💡 Latihan rutin akan membuat Anda siap saat situasi sesungguhnya.',
      'en':
          'Evacuation SOP (Training Material):\n\n'
          '1. Listen to the evacuation alarm/siren from officers\n'
          '2. Take your pre-prepared emergency bag\n'
          '3. Follow designated evacuation routes\n'
          '4. Walk quickly and orderly, do not panic\n'
          '5. Assist elderly, children, and disabled persons\n'
          '6. Gather at assembly point (village hall/field)\n'
          '7. Officers will conduct attendance check\n'
          '8. Wait for further instructions from coordinator\n\n'
          '💡 Regular drills will prepare you for actual situations.',
      'jv':
          'SOP Evakuasi (Materi Pelatihan):\n\n'
          '1. Rungokake alarm/sirine evakuasi saka petugas\n'
          '2. Jupuk tas siaga sing wis disiapake\n'
          '3. Melu jalur evakuasi sing wis ditentukake\n'
          '4. Mlaku cepet lan tertib, aja panik\n'
          '5. Mbantu lansia, anak-anak, lan disabilitas\n'
          '6. Kumpul ing titik kumpul (balai desa/lapangan)\n'
          '7. Petugas bakal nindakake absensi\n'
          '8. Ngenteni instruksi sabanjure saka koordinator\n\n'
          '💡 Latihan rutin bakal nyiapake awake dhewe kanggo situasi nyata.',
      'ba':
          'SOP Evakuasi (Materi Pelatihan):\n\n'
          '1. Runguang alarm/sirine evakuasi saking petugas\n'
          '2. Ambil tas siaga sane sampun kasiagayang\n'
          '3. Tuutin jalur evakuasi sane sampun kabadaang\n'
          '4. Majalan gelis lan tertib, sampunang panik\n'
          '5. Nulungin lansia, alit-alit, lan disabilitas\n'
          '6. Kumpul ring titik kumpul (balai desa/lapangan)\n'
          '7. Petugas pacang ngamargiang absensi\n'
          '8. Ngantosang instruksi salajengne saking koordinator\n\n'
          '💡 Latihan rutin pacang nyiagayang ragane ring situasi nyata.',
      'sas':
          'SOP Evakuasi (Materi Pelatihan):\n\n'
          '1. Dengaq alarm evakuasi leq petugas\n'
          '2. Bait tas siaga saq sampun disiapang\n'
          '3. Turut jalur evakuasi saq sampun ditentukang\n'
          '4. Lampaq gelis dait tertib, ndeq usah panik\n'
          '5. Bantu dengan lansia, kanak-kanak, dait disabilitas\n'
          '6. Kumpul leq titik kumpul (balai desa/lapangan)\n'
          '7. Petugas gen ngabsen\n'
          '8. Tunggu instruksi selanjutne leq koordinator\n\n'
          '💡 Latihan rutin gen nyiapang side dengan situasi nyata.',
    },

    'jadwal_pelatihan': {
      'id':
          'Jadwal Pelatihan & Simulasi Bencana:\n\n'
          '📅 Setiap Bulan Pertama: Simulasi evakuasi tingkat desa\n'
          '📅 Setiap 3 Bulan: Pelatihan P3K dasar\n'
          '📅 Setiap 6 Bulan: Simulasi gabungan multi-desa\n'
          '📅 Setiap Tahun: Gladi besar tanggap bencana\n\n'
          'Untuk info jadwal spesifik di daerah Anda:\n'
          '• Hubungi BPBD setempat\n'
          '• Cek grup WhatsApp warga\n'
          '• Tanyakan ke koordinator desa\n\n'
          'Mari ikuti pelatihan untuk meningkatkan kesiapsiagaan!',
      'en':
          'Disaster Training & Simulation Schedule:\n\n'
          '📅 Every 1st Month: Village-level evacuation drill\n'
          '📅 Every 3 Months: Basic first aid training\n'
          '📅 Every 6 Months: Multi-village joint simulation\n'
          '📅 Every Year: Large-scale disaster response drill\n\n'
          'For specific schedule in your area:\n'
          '• Contact local BPBD\n'
          '• Check community WhatsApp group\n'
          '• Ask village coordinator\n\n'
          'Join training to improve preparedness!',
      'jv':
          'Jadwal Pelatihan & Simulasi Bencana:\n\n'
          '📅 Saben Sasi Kawitan: Simulasi evakuasi tingkat desa\n'
          '📅 Saben 3 Sasi: Pelatihan P3K dasar\n'
          '📅 Saben 6 Sasi: Simulasi gabungan multi-desa\n'
          '📅 Saben Taun: Gladi besar tanggap bencana\n\n'
          'Kanggo info jadwal spesifik ing daerah panjenengan:\n'
          '• Hubungi BPBD setempat\n'
          '• Cek grup WhatsApp warga\n'
          '• Takon koordinator desa\n\n'
          'Ayo melu pelatihan kanggo ningkatake kesiapsiagaan!',
      'ba':
          'Jadwal Pelatihan & Simulasi Bencana:\n\n'
          '📅 Nyabran Sasih: Simulasi evakuasi tingkat desa\n'
          '📅 Nyabran 3 Sasih: Pelatihan P3K dasar\n'
          '📅 Nyabran 6 Sasih: Simulasi gabungan multi-desa\n'
          '📅 Nyabran Warsa: Gladi besar tanggap bencana\n\n'
          'Antuk info jadwal spesifik ring daerah ragane:\n'
          '• Hubungi BPBD setempat\n'
          '• Cek grup WhatsApp warga\n'
          '• Tanyakang koordinator desa\n\n'
          'Mari nutugin pelatihan antuk kesiapsiagaan!',
      'sas':
          'Jadwal Pelatihan & Simulasi Bencana:\n\n'
          '📅 Setiap Bulan Ke-1: Simulasi evakuasi tingkat desa\n'
          '📅 Setiap 3 Bulan: Pelatihan P3K dasar\n'
          '📅 Setiap 6 Bulan: Simulasi gabungan multi-desa\n'
          '📅 Setiap Taun: Gladi besar tanggap bencana\n\n'
          'Untuk info jadwal leq daerah side:\n'
          '• Hubungi BPBD setempat\n'
          '• Cek grup WhatsApp warga\n'
          '• Tanyakang koordinator desa\n\n'
          'Mari ikut pelatihan untuk kesiapsiagaan!',
    },

    'tas_siaga': {
      'id':
          'Edukasi Isi Tas Siaga Bencana:\n\n'
          'Dalam pelatihan ini, pastikan tas siaga Anda berisi:\n\n'
          '📋 DOKUMEN PENTING:\n'
          '• KTP, KK, akta kelahiran (dalam plastik kedap air)\n'
          '• Buku tabungan, polis asuransi\n\n'
          '💊 KESEHATAN:\n'
          '• Kotak P3K lengkap\n'
          '• Obat-obatan pribadi (jika ada)\n'
          '• Masker N95, hand sanitizer\n\n'
          '🔦 PERLENGKAPAN:\n'
          '• Senter + baterai cadangan\n'
          '• Peluit darurat\n'
          '• Powerbank + kabel charger\n\n'
          '👕 KEBUTUHAN DASAR:\n'
          '• Pakaian ganti 2 set\n'
          '• Selimut darurat\n'
          '• Makanan kering + air minum 3 liter\n'
          '• Uang tunai secukupnya\n\n'
          '⚠️ Siapkan tas siaga SEKARANG, jangan tunggu bencana!',
      'en':
          'Emergency Bag Contents Education:\n\n'
          'In this training, ensure your emergency bag contains:\n\n'
          '📋 IMPORTANT DOCUMENTS:\n'
          '• ID card, family card, birth certificate (in waterproof bag)\n'
          '• Bank book, insurance policy\n\n'
          '💊 HEALTH:\n'
          '• Complete first aid kit\n'
          '• Personal medicines (if any)\n'
          '• N95 masks, hand sanitizer\n\n'
          '🔦 EQUIPMENT:\n'
          '• Flashlight + spare batteries\n'
          '• Emergency whistle\n'
          '• Powerbank + charger\n\n'
          '👕 BASIC NEEDS:\n'
          '• 2 sets of clothes\n'
          '• Emergency blanket\n'
          '• Dried food + 3 liters drinking water\n'
          '• Sufficient cash\n\n'
          '⚠️ Prepare your emergency bag NOW, do not wait for disaster!',
      'jv':
          'Edukasi Isi Tas Siaga Bencana:\n\n'
          'Ing pelatihan iki, pastekake tas siaga panjenengan isine:\n\n'
          '📋 DOKUMEN PENTING:\n'
          '• KTP, KK, akta kelahiran (ing plastik kedap air)\n\n'
          '💊 KESEHATAN:\n'
          '• Kotak P3K lengkap\n'
          '• Obat-obatan pribadi\n'
          '• Masker, handsanitizer\n\n'
          '🔦 PERLENGKAPAN:\n'
          '• Senter + baterai cadangan\n'
          '• Peluit darurat\n'
          '• Powerbank\n\n'
          '👕 KEBUTUHAN DASAR:\n'
          '• Pakaian ganti\n'
          '• Panganan garing + banyu ngombe\n'
          '• Duwit tunai\n\n'
          '⚠️ Siapake tas siaga SAIKI!',
      'ba':
          'Edukasi Isi Tas Siaga Bencana:\n\n'
          'Ring pelatihan puniki, pastiang tas siaga ragane madaging:\n\n'
          '📋 DOKUMEN PENTING:\n'
          '• KTP, KK, akta kelahiran (ring plastik kedap air)\n\n'
          '💊 KESEHATAN:\n'
          '• Kotak P3K lengkap\n'
          '• Ubad-ubadan pribadi\n\n'
          '🔦 PERLENGKAPAN:\n'
          '• Senter + baterai cadangan\n'
          '• Peluit darurat\n'
          '• Powerbank\n\n'
          '👕 KEBUTUHAN DASAR:\n'
          '• Pangangge ganti\n'
          '• Ajengan ngering + yeh inem\n'
          '• Jinah tunai\n\n'
          '⚠️ Siagayang tas siaga MANGKIN!',
      'sas':
          'Edukasi Isi Tas Siaga Bencana:\n\n'
          'Leq pelatihan niki, pastikang tas siaga side berisi:\n\n'
          '📋 DOKUMEN PENTING:\n'
          '• KTP, KK, akta kelahiran (ring plastik kedap air)\n\n'
          '💊 KESEHATAN:\n'
          '• Kotak P3K lengkap\n'
          '• Obat-obatan pribadi\n\n'
          '🔦 PERLENGKAPAN:\n'
          '• Senter + baterai cadangan\n'
          '• Peluit darurat\n'
          '• Powerbank\n\n'
          '👕 KEBUTUHAN DASAR:\n'
          '• Pakaian ganti\n'
          '• Makanan kering + aiq inem\n'
          '• Uang tunai\n\n'
          '⚠️ Siapke tas siaga JOQ INEQ!',
    },

    'evakuasi': {
      'id':
          'Materi Pelatihan Jalur Evakuasi:\n\n'
          '🗺️ CARA MENGENALI JALUR EVAKUASI:\n'
          '1. Identifikasi papan rambu evakuasi di desa Anda\n'
          '2. Tanyakan koordinator kebencanaan desa\n'
          '3. Ikuti tanda panah hijau (arah evakuasi)\n'
          '4. Catat lokasi titik kumpul terdekat\n\n'
          '📍 TITIK KUMPUL PELATIHAN MERAPI:\n'
          '• Barak Glagaharjo • Barak Kepuharjo\n'
          '• Stadion Maguwoharjo • Balai Desa Umbulharjo\n'
          '• Balai Desa Hargobinangun\n\n'
          '🚶 TIPS PENTING:\n'
          '• Hafalkan 2-3 rute alternatif\n'
          '• Jangan gunakan lift/elevator\n'
          '• Hindari jembatan yang tidak stabil\n'
          '• Ikuti arahan petugas lapangan\n\n'
          'Mari berlatih menuju titik kumpul terdekat secara rutin!',
      'en':
          'Evacuation Route Training Material:\n\n'
          '🗺️ HOW TO IDENTIFY EVACUATION ROUTES:\n'
          '1. Identify evacuation signs in your village\n'
          '2. Ask village disaster coordinator\n'
          '3. Follow green arrows (evacuation direction)\n'
          '4. Note nearest assembly point location\n\n'
          '📍 MERAPI TRAINING ASSEMBLY POINTS:\n'
          '• Glagaharjo Barracks • Kepuharjo Barracks\n'
          '• Maguwoharjo Stadium • Umbulharjo Village Hall\n'
          '• Hargobinangun Village Hall\n\n'
          '🚶 IMPORTANT TIPS:\n'
          '• Memorize 2-3 alternative routes\n'
          '• Do not use elevators\n'
          '• Avoid unstable bridges\n'
          '• Follow field officers instructions\n\n'
          'Practice heading to the nearest assembly point regularly!',
      'jv':
          'Materi Pelatihan Jalur Evakuasi:\n\n'
          '🗺️ CARA NGENALI JALUR EVAKUASI:\n'
          '1. Identifikasi papan rambu evakuasi ing desa\n'
          '2. Takon koordinator kebencanaan desa\n'
          '3. Melu tanda panah ijo (arah evakuasi)\n'
          '4. Catet lokasi titik kumpul terdekat\n\n'
          '📍 TITIK KUMPUL PELATIHAN MERAPI:\n'
          '• Barak Glagaharjo • Barak Kepuharjo\n'
          '• Stadion Maguwoharjo • Balai Desa Umbulharjo\n\n'
          '🚶 TIPS PENTING:\n'
          '• Hafalake 2-3 rute alternatif\n'
          '• Aja nggunakake lift\n'
          '• Hindarani jembatan sing ora stabil\n\n'
          'Ayo latihan mlaku menyang titik kumpul kanthi rutin!',
      'ba':
          'Materi Pelatihan Jalur Evakuasi:\n\n'
          '🗺️ CARA NGENALIN JALUR EVAKUASI:\n'
          '1. Identifikasi papan rambu evakuasi ring desa\n'
          '2. Tanyakang koordinator kebencanaan desa\n'
          '3. Tuutin tanda panah ijo (arah evakuasi)\n'
          '4. Catet lokasi titik kumpul terpaek\n\n'
          '📍 TITIK KUMPUL PELATIHAN MERAPI:\n'
          '• Barak Glagaharjo • Barak Kepuharjo\n'
          '• Stadion Maguwoharjo • Balai Desa Umbulharjo\n\n'
          '🚶 TIPS PENTING:\n'
          '• Hapalang 2-3 rute alternatif\n'
          '• Sampunang nganggen lift\n\n'
          'Mari latihan majalan ring titik kumpul sacara rutin!',
      'sas':
          'Materi Pelatihan Jalur Evakuasi:\n\n'
          '🗺️ CARA NGENALI JALUR EVAKUASI:\n'
          '1. Identifikasi papan rambu evakuasi leq desa\n'
          '2. Tanyakang koordinator kebencanaan desa\n'
          '3. Turut tanda panah ijo (arah evakuasi)\n'
          '4. Catet lokasi titik kumpul terdekat\n\n'
          '📍 TITIK KUMPUL PELATIHAN MERAPI:\n'
          '• Barak Glagaharjo • Barak Kepuharjo\n'
          '• Stadion Maguwoharjo • Balai Desa Umbulharjo\n\n'
          '🚶 TIPS PENTING:\n'
          '• Hapalang 2-3 rute alternatif\n'
          '• Endaq gunain lift\n\n'
          'Mari latihan lampaq jok titik kumpul sacara rutin!',
    },

    'mitigasi_abu': {
      'id':
          'Edukasi Mitigasi Hujan Abu Vulkanik:\n\n'
          '🛡️ PERSIAPAN SEBELUM:\n'
          '• Siapkan masker N95 atau masker medis\n'
          '• Siapkan kacamata pelindung\n'
          '• Tutup rapat jendela dan pintu\n'
          '• Siapkan plastik untuk menutup barang elektronik\n\n'
          '🧤 SAAT HUJAN ABU:\n'
          '• Gunakan masker dan kacamata\n'
          '• Pakai baju lengan panjang\n'
          '• Hindari aktivitas di luar ruangan\n'
          '• Tutup sumber air dan makanan\n\n'
          '🧹 SETELAH HUJAN ABU:\n'
          '• Basahi abu sebelum membersihkan (jangan disapu kering)\n'
          '• Gunakan masker saat membersihkan\n'
          '• Bersihkan atap secara bertahap\n\n'
          '⚠️ Menghirup abu vulkanik dapat menyebabkan gangguan pernapasan.',
      'en':
          'Volcanic Ash Rain Mitigation Education:\n\n'
          '🛡️ PREPARATION:\n'
          '• Prepare N95 or medical masks\n'
          '• Prepare protective goggles\n'
          '• Close windows and doors tightly\n'
          '• Cover electronics with plastic\n\n'
          '🧤 DURING ASH RAIN:\n'
          '• Wear masks and goggles\n'
          '• Wear long-sleeved clothes\n'
          '• Avoid outdoor activities\n'
          '• Cover water and food sources\n\n'
          '🧹 AFTER ASH RAIN:\n'
          '• Wet ash before sweeping (do not dry sweep)\n'
          '• Wear mask when cleaning\n'
          '• Clean roof gradually\n\n'
          '⚠️ Inhaling volcanic ash can cause respiratory problems.',
      'jv':
          'Edukasi Mitigasi Udan Abu Vulkanik:\n\n'
          '🛡️ PERSIAPAN:\n'
          '• Siapake masker N95\n'
          '• Siapake kacamata pelindung\n'
          '• Tutup rapet jendela lan pintu\n\n'
          '🧤 SAAT UDAN ABU:\n'
          '• Gunakake masker lan kacamata\n'
          '• Hindarani aktivitas ing njaba\n\n'
          '🧹 SESAMPUNE UDAN ABU:\n'
          '• Basahi abu sadurunge ngresiki\n'
          '• Resiki atap secara bertahap\n\n'
          '⚠️ Ngirup abu vulkanik bisa nyebabake gangguan pernapasan.',
      'ba':
          'Edukasi Mitigasi Ujan Abu Vulkanik:\n\n'
          '🛡️ PERSIAPAN:\n'
          '• Siagayang masker N95\n'
          '• Siagayang kacamata pelindung\n'
          '• Tutup rapet jendela lan pintu\n\n'
          '🧤 SAAT UJAN ABU:\n'
          '• Anggen masker lan kacamata\n'
          '• Hindarin aktivitas ring jaba\n\n'
          '🧹 SASAMPUN UJAN ABU:\n'
          '• Basahang abu sadurung ngresiki\n'
          '• Resiki raab secara bertahap\n\n'
          '⚠️ Ngirup abu vulkanik nyidayang nyebabang gangguan pernapasan.',
      'sas':
          'Edukasi Mitigasi Ujan Abu Vulkanik:\n\n'
          '🛡️ PERSIAPAN:\n'
          '• Siapang masker N95\n'
          '• Siapang kacamata pelindung\n'
          '• Tutup rapet jendela dait pintu\n\n'
          '🧤 SAAT UJAN ABU:\n'
          '• Pake masker dait kacamata\n'
          '• Hindari aktivitas leq luar\n\n'
          '🧹 SAMPUN UJAN ABU:\n'
          '• Basahi abu sebelum bersihin\n'
          '• Bersihin atap secara bertahap\n\n'
          '⚠️ Ngirup abu vulkanik bise nyebabang gangguan pernapasan.',
    },

    'zona_bahaya': {
      'id':
          'Edukasi Zona Bahaya Gunung Api:\n\n'
          '🔴 ZONA MERAH (Radius < 5 km):\n'
          '• DILARANG masuk untuk permukiman\n'
          '• Area paling berbahaya saat erupsi\n\n'
          '🟠 ZONA KUNING (Radius 5-10 km):\n'
          '• Siap siaga evakuasi kapan saja\n'
          '• Pantau informasi secara ketat\n'
          '• Tas siaga harus selalu siap\n\n'
          '🟡 ZONA HIJAU MUDA (Radius 10-15 km):\n'
          '• Pantau informasi bencana\n'
          '• Kenali jalur evakuasi\n'
          '• Ikuti simulasi rutin\n\n'
          '🟢 ZONA HIJAU (> 15 km):\n'
          '• Relatif aman\n'
          '• Tetap waspada dan ikuti arahan\n\n'
          '💡 Kenali zona bahaya daerah Anda SEBELUM bencana terjadi!',
      'en':
          'Volcanic Danger Zone Education:\n\n'
          '🔴 RED ZONE (Radius < 5 km):\n'
          '• ENTRY PROHIBITED for settlement\n'
          '• Most dangerous area during eruption\n\n'
          '🟠 YELLOW ZONE (Radius 5-10 km):\n'
          '• Ready for evacuation at any time\n'
          '• Monitor information closely\n'
          '• Emergency bag always ready\n\n'
          '🟡 LIGHT GREEN ZONE (Radius 10-15 km):\n'
          '• Monitor disaster information\n'
          '• Know evacuation routes\n'
          '• Join regular simulation\n\n'
          '🟢 GREEN ZONE (> 15 km):\n'
          '• Relatively safe\n'
          '• Stay alert and follow instructions\n\n'
          '💡 Know your area danger zone BEFORE disaster occurs!',
      'jv':
          'Edukasi Zona Bahaya Gunung Api:\n\n'
          '🔴 ZONA MERAH (Radius < 5 km): DILARANG mlebu\n'
          '🟠 ZONA KUNING (Radius 5-10 km): Siap siaga evakuasi\n'
          '🟡 ZONA IJO MUDA (Radius 10-15 km): Pantau informasi\n'
          '🟢 ZONA IJO (> 15 km): Relatif aman\n\n'
          '💡 Kenali zona bahaya daerah panjenengan SADURUNGE bencana dumadi!',
      'ba':
          'Edukasi Zona Bahaya Gunung Api:\n\n'
          '🔴 ZONA MERAH (Radius < 5 km): DILARANG ngeranjing\n'
          '🟠 ZONA KUNING (Radius 5-10 km): Siap siaga evakuasi\n'
          '🟡 ZONA IJO MUDA (Radius 10-15 km): Pantau informasi\n'
          '🟢 ZONA IJO (> 15 km): Relatif aman\n\n'
          '💡 Kenali zona bahaya ring daerah ragane SADURUNG bencana.',
      'sas':
          'Edukasi Zona Bahaya Gunung Api:\n\n'
          '🔴 ZONA MERAH (Radius < 5 km): DILARANG masuk\n'
          '🟠 ZONA KUNING (Radius 5-10 km): Siap siaga evakuasi\n'
          '🟡 ZONA HIJAU MUDA (Radius 10-15 km): Pantau informasi\n'
          '🟢 ZONA HIJAU (> 15 km): Relatif aman\n\n'
          '💡 Kenali zona bahaya leq daerah side SEBELUM bencana!',
    },

    'status': {
      'id':
          'Edukasi Pemantauan Status Gunung Api:\n\n'
          'Pelajari cara memantau status gunung secara mandiri:\n\n'
          '🌐 SUMBER INFORMASI RESMI:\n'
          '• magma.vsi.esdm.go.id (MAGMA Indonesia)\n'
          '• Instagram @bnpb_indonesia\n'
          '• Instagram @pvmbg_\n\n'
          '📞 KONTAK:\n'
          '• Call Center BNPB: 117\n'
          '• Pos Pengamatan terdekat\n\n'
          '📊 TINGKAT STATUS:\n'
          '• Level I (Normal) → Aktivitas dasar\n'
          '• Level II (Waspada) → Peningkatan aktivitas\n'
          '• Level III (Siaga) → Kecenderungan erupsi\n'
          '• Level IV (Awas) → Erupsi segera/sedang berlangsung\n\n'
          '💡 Biasakan cek status gunung secara rutin melalui sumber resmi!',
      'en':
          'Volcano Monitoring Education:\n\n'
          'Learn how to monitor volcano status independently:\n\n'
          '🌐 OFFICIAL SOURCES:\n'
          '• magma.vsi.esdm.go.id (MAGMA Indonesia)\n'
          '• Instagram @bnpb_indonesia\n\n'
          '📊 STATUS LEVELS:\n'
          '• Level I (Normal) → Baseline activity\n'
          '• Level II (Alert) → Increased activity\n'
          '• Level III (Standby) → Eruption tendency\n'
          '• Level IV (Warning) → Imminent/ongoing eruption\n\n'
          '💡 Make it a habit to check status regularly through official sources!',
      'jv':
          'Edukasi Pemantauan Status Gunung Api:\n\n'
          'Sinau cara mantau status gunung kanthi mandiri:\n\n'
          '🌐 SUMBER RESMI:\n'
          '• magma.vsi.esdm.go.id (MAGMA Indonesia)\n'
          '• Call Center BNPB: 117\n\n'
          '📊 TINGKAT STATUS:\n'
          '• Level I (Normal) • Level II (Waspada)\n'
          '• Level III (Siaga) • Level IV (Awas)\n\n'
          '💡 Biasake cek status gunung kanthi rutin!',
      'ba':
          'Edukasi Pemantauan Status Gunung Api:\n\n'
          'Malajah cara ngatonang status gunung sacara mandiri:\n\n'
          '🌐 SUMBER RESMI:\n'
          '• magma.vsi.esdm.go.id (MAGMA Indonesia)\n'
          '• Call Center BNPB: 117\n\n'
          '📊 TINGKAT STATUS:\n'
          '• Level I (Normal) • Level II (Waspada)\n'
          '• Level III (Siaga) • Level IV (Awas)\n\n'
          '💡 Biasayang cek status gunung sacara rutin!',
      'sas':
          'Edukasi Pemantauan Status Gunung Api:\n\n'
          'Belajaraq cara mantau status gunung sacara mandiri:\n\n'
          '🌐 SUMBER RESMI:\n'
          '• magma.vsi.esdm.go.id (MAGMA Indonesia)\n'
          '• Call Center BNPB: 117\n\n'
          '📊 TINGKAT STATUS:\n'
          '• Level I (Normal) • Level II (Waspada)\n'
          '• Level III (Siaga) • Level IV (Awas)\n\n'
          '💡 Biaseang cek status gunung sacara rutin!',
    },

    'p3k': {
      'id':
          'Edukasi P3K Dasar untuk Kesiapsiagaan:\n\n'
          '🩹 PRINSIP PERTOLONGAN PERTAMA:\n'
          '• Pastikan area aman untuk penolong\n'
          '• Cek kesadaran korban (panggil & sentuh)\n'
          '• Cek napas (lihat, dengar, rasakan)\n\n'
          '🚨 PRIORITAS PENANGANAN:\n'
          '1. Pernapasan terhenti → RJP (Resusitasi)\n'
          '2. Pendarahan hebat → Tekan luka\n'
          '3. Luka bakar → Siram air mengalir 10+ menit\n'
          '4. Patah tulang → Imobilisasi (jangan digerakkan)\n\n'
          '💊 ISI KOTAK P3K WAJIB:\n'
          '• Perban steril & plester\n'
          '• Antiseptik (betadine, alkohol)\n'
          '• Gunting & pinset\n'
          '• Sarung tangan medis\n\n'
          '💡 Ikuti pelatihan P3K resmi untuk keterampilan praktis!',
      'en':
          'Basic First Aid Education for Preparedness:\n\n'
          '🩹 FIRST AID PRINCIPLES:\n'
          '• Ensure area is safe for rescuer\n'
          '• Check victim consciousness (call & touch)\n'
          '• Check breathing (look, listen, feel)\n\n'
          '🚨 TREATMENT PRIORITY:\n'
          '1. Breathing stopped → CPR\n'
          '2. Severe bleeding → Apply pressure\n'
          '3. Burns → Running water 10+ minutes\n'
          '4. Fractures → Immobilize\n\n'
          '💊 ESSENTIAL FIRST AID KIT:\n'
          '• Sterile bandages & plasters\n'
          '• Antiseptic\n'
          '• Scissors & tweezers\n'
          '• Medical gloves\n\n'
          '💡 Join official first aid training for practical skills!',
      'jv':
          'Edukasi P3K Dasar kanggo Kesiapsiagaan:\n\n'
          '🩹 PRINSIP PERTOLONGAN PERTAMA:\n'
          '• Pastekake area aman kanggo penolong\n'
          '• Cek kesadaran korban\n'
          '• Cek napas\n\n'
          '💊 ISI KOTAK P3K:\n'
          '• Perban steril & plester\n'
          '• Antiseptik\n'
          '• Gunting & pinset\n\n'
          '💡 Melu pelatihan P3K resmi kanggo katrampilan praktis!',
      'ba':
          'Edukasi P3K Dasar antuk Kesiapsiagaan:\n\n'
          '🩹 PRINSIP PERTOLONGAN PERTAMA:\n'
          '• Pastiang daerah aman antuk penolong\n'
          '• Cek kesadaran korban\n'
          '• Cek angkihan\n\n'
          '💊 ISI KOTAK P3K:\n'
          '• Perban steril & plester\n'
          '• Antiseptik\n\n'
          '💡 Nutugin pelatihan P3K resmi antuk katrampilan praktis!',
      'sas':
          'Edukasi P3K Dasar untuk Kesiapsiagaan:\n\n'
          '🩹 PRINSIP PERTOLONGAN PERTAMA:\n'
          '• Pastikang daerah aman untuk penolong\n'
          '• Cek kesadaran korban\n'
          '• Cek napas\n\n'
          '💊 ISI KOTAK P3K:\n'
          '• Perban steril & plester\n'
          '• Antiseptik\n\n'
          '💡 Ikut pelatihan P3K resmi untuk keterampilan praktis!',
    },

    'bantuan': {
      'id':
          'Kontak Darurat & Layanan Bantuan:\n\n'
          '📞 NOMOR TELEPON PENTING:\n'
          '• BNPB: 117 (Call Center)\n'
          '• SAR Nasional: 115\n'
          '• Ambulans: 118\n'
          '• Polisi: 110\n'
          '• Damkar: 113\n\n'
          '📱 KONTAK LOKAL:\n'
          '• Posko Pengungsian (kontak lokal)\n'
          '• BPBD Provinsi/Kabupaten\n'
          '• PMI Cabang terdekat\n\n'
          '⚠️ Gunakan nomor darurat hanya untuk keperluan mendesak!',
      'en':
          'Emergency Contacts & Assistance:\n\n'
          '📞 IMPORTANT NUMBERS:\n'
          '• BNPB: 117 (Call Center)\n'
          '• National SAR: 115\n'
          '• Ambulance: 118\n'
          '• Police: 110\n'
          '• Fire Department: 113\n\n'
          '⚠️ Use emergency numbers ONLY for urgent matters!',
      'jv':
          'Kontak Darurat & Bantuan:\n\n'
          '📞 NOMOR PENTING:\n'
          '• BNPB: 117 • SAR: 115\n'
          '• Ambulans: 118 • Polisi: 110\n'
          '• Damkar: 113\n\n'
          '⚠️ Gunakake nomor darurat MUNG kanggo keperluan mendesak!',
      'ba':
          'Kontak Darurat & Wantuan:\n\n'
          '📞 NOMER PENTING:\n'
          '• BNPB: 117 • SAR: 115\n'
          '• Ambulans: 118 • Polisi: 110\n'
          '• Damkar: 113\n\n'
          '⚠️ Anggon nomer darurat WANTAH antuk keperluan mendesak!',
      'sas':
          'Kontak Darurat & Bantuan:\n\n'
          '📞 NOMER PENTING:\n'
          '• BNPB: 117 • SAR: 115\n'
          '• Ambulans: 118 • Polisi: 110\n'
          '• Damkar: 113\n\n'
          '⚠️ Gunakang nomer darurat cuma untuk keperluan mendesak!',
    },

    'default': {
      'id':
          'Maaf, saya kurang memahami pertanyaan Anda. '
          'Saya adalah instruktur pelatihan mitigasi bencana.\n\n'
          'Saya dapat membantu dengan topik:\n'
          '• SOP Evakuasi (simulasi)\n'
          '• Jadwal Pelatihan & Simulasi\n'
          '• Isi Tas Siaga Bencana\n'
          '• Jalur & Titik Kumpul Evakuasi\n'
          '• Mitigasi Hujan Abu\n'
          '• Zona Bahaya Gunung Api\n'
          '• Pemantauan Status Gunung\n'
          '• P3K Dasar\n'
          '• Nomor Darurat\n\n'
          'Silakan tanya tentang salah satu topik di atas.',
      'en':
          'Sorry, I do not understand your question. '
          'I am a disaster mitigation training instructor.\n\n'
          'I can help with topics:\n'
          '• Evacuation SOP (simulation)\n'
          '• Training & Simulation Schedule\n'
          '• Emergency Bag Contents\n'
          '• Evacuation Routes & Assembly Points\n'
          '• Ash Rain Mitigation\n'
          '• Volcanic Danger Zones\n'
          '• Volcano Status Monitoring\n'
          '• Basic First Aid\n'
          '• Emergency Numbers\n\n'
          'Please ask about one of the topics above.',
      'jv':
          'Ngapunten, kula kirang mangertos pertanyaan panjenengan. '
          'Kula menika instruktur pelatihan mitigasi bencana.\n\n'
          'Kula saged mbiyantu kanthi topik:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n'
          '• Mitigasi Abu • Zona Bahaya\n'
          '• P3K Dasar • Nomor Darurat\n\n'
          'Monggo tanglet babagan salah satunggal topik ing nginggil.',
      'ba':
          'Ampura, tiang nenten uning indik pitaken ragane. '
          'Tiang menika instruktur pelatihan mitigasi bencana.\n\n'
          'Tiang presida nulungin antuk topik:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n'
          '• Mitigasi Abu • Zona Bahaya\n'
          '• P3K Dasar • Nomor Darurat\n\n'
          'Monggo mataken indik salah tunggil topik ring duur.',
      'sas':
          'Ampura, tyang endeq pati ngerti pitakon side. '
          'Tyang menika instruktur pelatihan mitigasi bencana.\n\n'
          'Tyang presida bantu topik:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n'
          '• Mitigasi Abu • Zona Bahaya\n'
          '• P3K Dasar • Nomor Darurat\n\n'
          'Silaq betakon soal salah satu topik di atas.',
    },
  };

  // ═══════════════════════════════════════════════════════════════
  // REGIONAL DICTIONARY — Terjemahan kata daerah ke Indonesia
  // Untuk normalisasi input NLP sebelum klasifikasi intent
  // ═══════════════════════════════════════════════════════════════
  static const Map<String, String> regionalDictionaryToIndonesian = {
    // ── Jawa ──
    'kepiye': 'bagaimana', 'piye': 'bagaimana',
    'kahanan': 'keadaan', 'saiki': 'sekarang',
    'ana': 'ada', 'ing': 'di', 'endi': 'mana', 'pundi': 'mana',
    'mlayu': 'lari', 'dalan': 'jalan',
    'kidul': 'selatan', 'lor': 'utara', 'wetan': 'timur', 'kulon': 'barat',
    'banyu': 'air', 'awu': 'abu', 'udhan': 'hujan', 'tulung': 'tolong',
    'latihan': 'latihan', 'simulasi': 'simulasi',

    // ── Bali ──
    'kenken': 'bagaimana', 'mangkin': 'sekarang',
    'wenten': 'ada', 'dija': 'dimana',
    'margi': 'jalan', 'yeh': 'air',
    'wantuan': 'bantuan', 'nulungin': 'tolong',

    // ── Sasak (Lombok) ──
    'berembe': 'bagaimana', 'jelo': 'kemana',
    'bale': 'balai', 'tende': 'tolong',
    'aiq': 'air', 'pelungguh': 'beritahu',
    'belajaraq': 'belajar', 'endeq': 'tidak',
    'leq': 'di', 'jok': 'ke', 'lampaq': 'jalan',
  };
}
