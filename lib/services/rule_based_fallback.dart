import '../models/chat_message.dart';

/// Lightweight rule-based fallback untuk chatbot SIGUMI.
///
/// Digunakan saat Cloud LLM (Ollama) tidak tersedia:
/// - Offline / no internet
/// - Server down / timeout
///
/// Arsitektur sederhana: keyword matching → canned response.
/// Tanpa ML, tanpa TFLite, tanpa dependency tambahan.
class RuleBasedFallback {
  // ═══════════════════════════════════════════════════════════════
  // KEYWORD → INTENT MAPPING
  // Simple keyword contains check — lightweight, no ML needed.
  // ═══════════════════════════════════════════════════════════════

  /// Keyword groups per intent. Checked via `contains()`.
  /// Order matters — first match wins.
  static const Map<String, List<String>> _intentKeywords = {
    'salam': [
      'halo', 'hai', 'hello', 'hi', 'selamat pagi', 'selamat siang',
      'selamat sore', 'selamat malam', 'assalamualaikum',
      'sugeng', 'om swastiastu', 'tabe',
    ],
    'evakuasi': [
      'evakuasi', 'evacuation', 'titik kumpul', 'jalur evakuasi',
      'assembly point', 'rute evakuasi', 'mengungsi', 'pengungsian',
      'harus lari', 'kemana lari', 'tempat aman', 'safe point',
      'titik berkumpul', 'posko',
    ],
    'sop_evakuasi': [
      'sop evakuasi', 'prosedur evakuasi', 'tata cara evakuasi',
      'langkah evakuasi', 'cara evakuasi', 'evacuation procedure',
      'urutan evakuasi',
    ],
    'zona_bahaya': [
      'zona bahaya', 'zona merah', 'zona kuning', 'zona hijau',
      'danger zone', 'radius bahaya', 'kawasan berbahaya',
      'daerah rawan', 'zona aman', 'zona evakuasi',
    ],
    'status': [
      'status merapi', 'status gunung', 'kondisi merapi',
      'aktivitas gunung', 'level gunung', 'volcano status',
      'kabar merapi', 'merapi hari ini', 'update merapi',
      'merapi aman', 'ada letusan',
    ],
    'tas_siaga': [
      'tas siaga', 'emergency bag', 'go bag', 'perlengkapan darurat',
      'barang siaga', 'persiapan bencana', 'checklist siaga',
      'isi tas', 'tas darurat',
    ],
    'bantuan': [
      'nomor darurat', 'emergency number', 'hubungi', 'telepon darurat',
      'kontak darurat', 'ambulans', 'sar', 'bnpb', 'bpbd',
      'minta bantuan', 'tolong', 'pertolongan',
    ],
    'mitigasi_abu': [
      'hujan abu', 'abu vulkanik', 'volcanic ash', 'mitigasi abu',
      'masker', 'cara menghadapi abu', 'tips abu',
    ],
    'p3k': [
      'p3k', 'pertolongan pertama', 'first aid', 'luka bakar',
      'obat', 'kotak p3k', 'bantuan medis',
    ],
    'jadwal_pelatihan': [
      'jadwal pelatihan', 'jadwal simulasi', 'kapan latihan',
      'kapan simulasi', 'pelatihan bencana', 'drill', 'training schedule',
    ],
    'pariwisata': [
      'wisata', 'pariwisata', 'liburan', 'tempat menarik', 'pantai', 'candi',
      'hotel', 'kuliner', 'attraction', 'recreation', 'rekreasi', 'holiday',
      'prambanan', 'kaliurang', 'kuta', 'ubud', 'rinjani', 'senggigi',
      'gili', 'uluwatu',
    ],
  };

  // ═══════════════════════════════════════════════════════════════
  // DETECT INTENT — Simple keyword matching
  // ═══════════════════════════════════════════════════════════════

  /// Detect intent dari pesan user via keyword contains.
  /// Return intent string. Default = 'default'.
  static String detectIntent(String message) {
    final normalized = message.toLowerCase().trim();
    if (normalized.isEmpty) return 'default';

    for (final entry in _intentKeywords.entries) {
      for (final keyword in entry.value) {
        if (normalized.contains(keyword)) {
          return entry.key;
        }
      }
    }
    return 'default';
  }

  /// Check apakah user bertanya tentang evakuasi (untuk intercept assembly point).
  static bool isEvacuationIntent(String message) {
    final normalized = message.toLowerCase().trim();
    const evacuationKeywords = [
      'evakuasi', 'evacuation', 'titik kumpul', 'assembly point',
      'mengungsi', 'pengungsian', 'harus lari', 'kemana lari',
      'tempat aman', 'jalur evakuasi', 'rute evakuasi',
    ];
    return evacuationKeywords.any((kw) => normalized.contains(kw));
  }

  // ═══════════════════════════════════════════════════════════════
  // GET RESPONSE — Canned multi-language responses
  // ═══════════════════════════════════════════════════════════════

  /// Get full ChatMessage response for offline/failsafe.
  static ChatMessage getResponse({
    required String userMessage,
    required String language,
  }) {
    final intent = detectIntent(userMessage);
    final responseText = _getLocalizedResponse(intent, language);

    return ChatMessage(
      content: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.text,
      intentId: intent,
      isVoice: false,
      responseSource: ResponseSource.localRuleBased,
    );
  }

  /// Get localized response string for intent.
  static String _getLocalizedResponse(String intent, String language) {
    final intentResponses = _responses[intent];
    if (intentResponses != null) {
      return intentResponses[language] ?? intentResponses['id'] ?? _defaultResponse(language);
    }
    return _defaultResponse(language);
  }

  static String _defaultResponse(String language) {
    return _responses['default']?[language] ?? _responses['default']?['id'] ?? 'Maaf, saya kurang memahami pertanyaan Anda.';
  }

  // ═══════════════════════════════════════════════════════════════
  // WELCOME MESSAGE
  // ═══════════════════════════════════════════════════════════════

  static String getWelcomeMessage(String language) {
    return _responses['salam']?[language] ?? _responses['salam']?['id'] ?? 'Halo! Saya Si Gumi, siap membantu Anda.';
  }

  // ═══════════════════════════════════════════════════════════════
  // QUICK ACTION LABELS — Multi-language
  // ═══════════════════════════════════════════════════════════════

  static const Map<String, List<Map<String, String>>> quickActionLabels = {
    'id': [
      {'label': 'Status Gunung', 'message': 'status gunung hari ini?'},
      {'label': 'Jalur Evakuasi', 'message': 'jalur evakuasi mana?'},
      {'label': 'Zona Bahaya', 'message': 'berapa zona bahayanya?'},
      {'label': 'Tips Hujan Abu', 'message': 'tips saat hujan abu'},
      {'label': 'Nomor Darurat', 'message': 'nomor telepon darurat'},
    ],
    'en': [
      {'label': 'Volcano Status', 'message': 'volcano status today?'},
      {'label': 'Evacuation Route', 'message': 'where is the evacuation route?'},
      {'label': 'Danger Zone', 'message': 'what is the danger zone?'},
      {'label': 'Ash Rain Tips', 'message': 'tips for ash rain'},
      {'label': 'Emergency Numbers', 'message': 'emergency telephone numbers'},
    ],
    'jv': [
      {'label': 'Status Gunung', 'message': 'status gunung saiki?'},
      {'label': 'Jalur Evakuasi', 'message': 'jalur evakuasi ndi?'},
      {'label': 'Zona Bahaya', 'message': 'piro zona bahayane?'},
      {'label': 'Tips Udan Abu', 'message': 'tips wektu udan abu'},
      {'label': 'Nomor Darurat', 'message': 'nomor telepon darurat'},
    ],
    'ba': [
      {'label': 'Status Gunung', 'message': 'status gunung mangkin?'},
      {'label': 'Jalur Evakuasi', 'message': 'jalur evakuasi dija?'},
      {'label': 'Zona Bahaya', 'message': 'kuda zona bahayane?'},
      {'label': 'Tips Ujan Abu', 'message': 'tips dugas ujan abu'},
      {'label': 'Nomor Darurat', 'message': 'nomor telepon darurat'},
    ],
    'sas': [
      {'label': 'Status Gunung', 'message': 'status gunung niki?'},
      {'label': 'Jalur Evakuasi', 'message': 'jalur evakuasi mbe?'},
      {'label': 'Zona Bahaya', 'message': 'berape zona bahayane?'},
      {'label': 'Tips Ujan Abu', 'message': 'tips ujan abu'},
      {'label': 'Nomor Darurat', 'message': 'nomor telepon darurat'},
    ],
  };

  // ═══════════════════════════════════════════════════════════════
  // CANNED RESPONSES — Multi-language (5 bahasa)
  // Sama dengan responses lama tapi tanpa overhead NLP.
  // ═══════════════════════════════════════════════════════════════

  static const Map<String, Map<String, String>> _responses = {
    'salam': {
      'id': 'Halo! Saya Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Saya siap membantu Anda mempelajari SOP evakuasi, jadwal simulasi, '
          'persiapan tas siaga, dan edukasi kesiapsiagaan. Ada yang bisa saya bantu?',
      'en': 'Hello! I am Si Gumi, your disaster mitigation training instructor. '
          'I can help you learn evacuation SOPs, simulation schedules, '
          'emergency bag preparation, and preparedness education. How can I assist you?',
      'jv': 'Halo! Kula Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Kula siap mbantu panjenengan sinau SOP evakuasi, jadwal simulasi, '
          'lan persiapan tanggap bencana. Wonten ingkang saged kula bantu?',
      'ba': 'Om Swastiastu! Tiang Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Tiang siap nulungin ragane malajah SOP evakuasi, jadwal simulasi, '
          'miwah persiapan tanggap bencana. Napi sane presida tiang bantu?',
      'sas': 'Tabe! Tyang Si Gumi, instruktur pelatihan mitigasi bencana. '
          'Tyang siap bantu side belajaraq SOP evakuasi, jadwal simulasi, '
          'dait persiapan bencana. Napi saq bau tyang bantu?',
    },

    'sop_evakuasi': {
      'id': 'SOP Evakuasi (Materi Pelatihan):\n\n'
          '1. Dengarkan alarm/sirine evakuasi dari petugas\n'
          '2. Ambil tas siaga yang sudah disiapkan\n'
          '3. Ikuti jalur evakuasi yang telah ditentukan\n'
          '4. Berjalan cepat dan tertib, jangan panik\n'
          '5. Bantu lansia, anak-anak, dan penyandang disabilitas\n'
          '6. Kumpul di titik kumpul (balai desa/lapangan)\n'
          '7. Petugas akan melakukan absensi kehadiran\n'
          '8. Tunggu instruksi selanjutnya dari koordinator\n\n'
          '💡 Latihan rutin akan membuat Anda siap saat situasi sesungguhnya.',
      'en': 'Evacuation SOP (Training Material):\n\n'
          '1. Listen to the evacuation alarm/siren from officers\n'
          '2. Take your pre-prepared emergency bag\n'
          '3. Follow designated evacuation routes\n'
          '4. Walk quickly and orderly, do not panic\n'
          '5. Assist elderly, children, and disabled persons\n'
          '6. Gather at assembly point (village hall/field)\n'
          '7. Officers will conduct attendance check\n'
          '8. Wait for further instructions from coordinator\n\n'
          '💡 Regular drills will prepare you for actual situations.',
    },

    'jadwal_pelatihan': {
      'id': 'Jadwal Pelatihan & Simulasi Bencana:\n\n'
          '📅 Setiap Bulan Pertama: Simulasi evakuasi tingkat desa\n'
          '📅 Setiap 3 Bulan: Pelatihan P3K dasar\n'
          '📅 Setiap 6 Bulan: Simulasi gabungan multi-desa\n'
          '📅 Setiap Tahun: Gladi besar tanggap bencana\n\n'
          'Untuk info jadwal spesifik di daerah Anda:\n'
          '• Hubungi BPBD setempat\n'
          '• Cek grup WhatsApp warga\n'
          '• Tanyakan ke koordinator desa',
      'en': 'Disaster Training & Simulation Schedule:\n\n'
          '📅 Every 1st Month: Village-level evacuation drill\n'
          '📅 Every 3 Months: Basic first aid training\n'
          '📅 Every 6 Months: Multi-village joint simulation\n'
          '📅 Every Year: Large-scale disaster response drill\n\n'
          'For specific schedule in your area:\n'
          '• Contact local BPBD\n'
          '• Check community WhatsApp group\n'
          '• Ask village coordinator',
    },

    'tas_siaga': {
      'id': 'Isi Tas Siaga Bencana:\n\n'
          '📋 DOKUMEN: KTP, KK, akta (dalam plastik kedap air)\n'
          '💊 KESEHATAN: P3K, obat pribadi, masker N95\n'
          '🔦 PERLENGKAPAN: Senter, peluit, powerbank\n'
          '👕 KEBUTUHAN: Pakaian ganti, selimut, makanan kering, air 3 liter, uang tunai\n\n'
          '⚠️ Siapkan tas siaga SEKARANG, jangan tunggu bencana!',
      'en': 'Emergency Bag Contents:\n\n'
          '📋 DOCUMENTS: ID, family card, certificates (waterproof bag)\n'
          '💊 HEALTH: First aid kit, personal medicine, N95 masks\n'
          '🔦 EQUIPMENT: Flashlight, whistle, powerbank\n'
          '👕 BASICS: Clothes, blanket, dried food, 3L water, cash\n\n'
          '⚠️ Prepare your emergency bag NOW!',
    },

    'evakuasi': {
      'id': 'Jalur Evakuasi Gunung Merapi:\n\n'
          '🗺️ CARA MENGENALI JALUR:\n'
          '1. Identifikasi papan rambu evakuasi di desa\n'
          '2. Ikuti tanda panah hijau (arah evakuasi)\n'
          '3. Catat lokasi titik kumpul terdekat\n\n'
          '📍 TITIK KUMPUL MERAPI:\n'
          '• Barak Glagaharjo • Barak Kepuharjo\n'
          '• Stadion Maguwoharjo • Balai Desa Umbulharjo\n\n'
          '🚶 TIPS: Hafalkan 2-3 rute alternatif, hindari lembah & sungai.',
      'en': 'Merapi Evacuation Routes:\n\n'
          '🗺️ HOW TO IDENTIFY ROUTES:\n'
          '1. Identify evacuation signs in your village\n'
          '2. Follow green arrows (evacuation direction)\n'
          '3. Note nearest assembly point\n\n'
          '📍 MERAPI ASSEMBLY POINTS:\n'
          '• Glagaharjo Barracks • Kepuharjo Barracks\n'
          '• Maguwoharjo Stadium • Umbulharjo Village Hall\n\n'
          '🚶 TIPS: Memorize 2-3 alternative routes, avoid valleys & rivers.',
    },

    'mitigasi_abu': {
      'id': 'Mitigasi Hujan Abu Vulkanik:\n\n'
          '🛡️ PERSIAPAN: Masker N95, kacamata pelindung, tutup jendela rapat\n'
          '🧤 SAAT HUJAN ABU: Pakai masker, baju lengan panjang, hindari luar ruangan\n'
          '🧹 SETELAH: Basahi abu sebelum bersihkan (jangan sapu kering), bersihkan atap bertahap\n\n'
          '⚠️ Menghirup abu vulkanik dapat menyebabkan gangguan pernapasan.',
      'en': 'Volcanic Ash Mitigation:\n\n'
          '🛡️ PREP: N95 mask, goggles, close windows tightly\n'
          '🧤 DURING: Wear mask, long sleeves, stay indoors\n'
          '🧹 AFTER: Wet ash before sweeping, clean roof gradually\n\n'
          '⚠️ Inhaling volcanic ash can cause respiratory problems.',
    },

    'zona_bahaya': {
      'id': 'Zona Bahaya Gunung Merapi:\n\n'
          '🔴 ZONA MERAH (< 5 km): DILARANG masuk, paling berbahaya\n'
          '🟠 ZONA KUNING (5-10 km): Siap siaga evakuasi kapan saja\n'
          '🟡 ZONA HIJAU MUDA (10-15 km): Pantau informasi, ikuti simulasi\n'
          '🟢 ZONA HIJAU (> 15 km): Relatif aman, tetap waspada\n\n'
          '💡 Kenali zona bahaya daerah Anda SEBELUM bencana!',
      'en': 'Merapi Danger Zones:\n\n'
          '🔴 RED ZONE (< 5 km): PROHIBITED, most dangerous\n'
          '🟠 YELLOW ZONE (5-10 km): Ready for evacuation anytime\n'
          '🟡 LIGHT GREEN (10-15 km): Monitor info, join drills\n'
          '🟢 GREEN ZONE (> 15 km): Relatively safe, stay alert\n\n'
          '💡 Know your danger zone BEFORE disaster!',
    },

    'status': {
      'id': 'Pemantauan Status Gunung Merapi:\n\n'
          '🌐 SUMBER RESMI: magma.vsi.esdm.go.id\n'
          '📞 Call Center BNPB: 117\n\n'
          '📊 TINGKAT STATUS:\n'
          '• Level I (Normal) → Aktivitas dasar\n'
          '• Level II (Waspada) → Peningkatan aktivitas\n'
          '• Level III (Siaga) → Kecenderungan erupsi\n'
          '• Level IV (Awas) → Erupsi segera/berlangsung\n\n'
          '💡 Biasakan cek status gunung secara rutin!',
      'en': 'Merapi Volcano Status Monitoring:\n\n'
          '🌐 OFFICIAL SOURCE: magma.vsi.esdm.go.id\n'
          '📞 BNPB Call Center: 117\n\n'
          '📊 STATUS LEVELS:\n'
          '• Level I (Normal) → Baseline activity\n'
          '• Level II (Alert) → Increased activity\n'
          '• Level III (Standby) → Eruption tendency\n'
          '• Level IV (Warning) → Imminent/ongoing eruption\n\n'
          '💡 Check volcano status regularly!',
    },

    'p3k': {
      'id': 'P3K Dasar Kesiapsiagaan:\n\n'
          '🩹 PRINSIP: Pastikan area aman, cek kesadaran, cek napas\n'
          '🚨 PRIORITAS:\n'
          '1. Napas berhenti → RJP\n'
          '2. Pendarahan → Tekan luka\n'
          '3. Luka bakar → Air mengalir 10+ menit\n'
          '4. Patah tulang → Imobilisasi\n\n'
          '💊 ISI P3K: Perban, antiseptik, gunting, sarung tangan medis\n\n'
          '💡 Ikuti pelatihan P3K resmi untuk keterampilan praktis!',
      'en': 'Basic First Aid Preparedness:\n\n'
          '🩹 PRINCIPLES: Ensure area safe, check consciousness, check breathing\n'
          '🚨 PRIORITY:\n'
          '1. No breathing → CPR\n'
          '2. Severe bleeding → Apply pressure\n'
          '3. Burns → Running water 10+ min\n'
          '4. Fractures → Immobilize\n\n'
          '💊 KIT: Bandages, antiseptic, scissors, medical gloves\n\n'
          '💡 Join official first aid training!',
    },

    'bantuan': {
      'id': 'Kontak Darurat Bencana:\n\n'
          '📞 NOMOR PENTING:\n'
          '• BNPB: 117 • SAR: 115\n'
          '• Ambulans: 118 • Polisi: 110\n'
          '• Damkar: 113\n\n'
          '📱 KONTAK LOKAL:\n'
          '• BPBD Provinsi/Kabupaten\n'
          '• PMI Cabang terdekat\n\n'
          '⚠️ Gunakan nomor darurat hanya untuk keperluan mendesak!',
      'en': 'Emergency Contacts:\n\n'
          '📞 IMPORTANT NUMBERS:\n'
          '• BNPB: 117 • SAR: 115\n'
          '• Ambulance: 118 • Police: 110\n'
          '• Fire Dept: 113\n\n'
          '⚠️ Use emergency numbers ONLY for urgent matters!',
    },

    'pariwisata': {
      'id': 'Panduan Pariwisata Aman (Sleman, Bali, Lombok):\n\n'
          '🏔️ Sleman (DIY): Kaliurang, Candi Prambanan, Lava Tour Merapi (aman jika di luar radius bahaya).\n'
          '🌊 Bali: Pantai Kuta, Ubud, Uluwatu, Kintamani (Gunung Batur).\n'
          '🏝️ Lombok: Gili Trawangan, Pantai Senggigi, Gunung Rinjani.\n\n'
          '💡 Selalu pantau status gunung berapi aktif setempat sebelum berkunjung!',
      'en': 'Safe Tourism Guide (Sleman, Bali, Lombok):\n\n'
          '🏔️ Sleman (DIY): Kaliurang, Prambanan Temple, Merapi Lava Tour (safe outside hazard zones).\n'
          '🌊 Bali: Kuta Beach, Ubud, Uluwatu, Kintamani (Mount Batur).\n'
          '🏝️ Lombok: Gili Trawangan, Senggigi Beach, Mount Rinjani.\n\n'
          '💡 Always monitor local volcanic status before visiting!',
      'jv': 'Panduan Wisata Aman (Sleman, Bali, Lombok):\n\n'
          '🏔️ Sleman (DIY): Kaliurang, Candi Prambanan, Lava Tour Merapi (aman yen ing sanjabane zona bahaya).\n'
          '🌊 Bali: Pantai Kuta, Ubud, Uluwatu, Kintamani (Gunung Batur).\n'
          '🏝️ Lombok: Gili Trawangan, Pantai Senggigi, Gunung Rinjani.\n\n'
          '💡 Eling tansah mriksa status gunung berapi sadurunge budhal plonco!',
      'ba': 'Panduan Wisata Aman (Sleman, Bali, Lombok):\n\n'
          '🏔️ Sleman (DIY): Kaliurang, Candi Prambanan, Lava Tour Merapi (aman yening ring jabaan zona bahaya).\n'
          '🌊 Bali: Pantai Kuta, Ubud, Uluwatu, Kintamani (Gunung Batur).\n'
          '🏝️ Lombok: Gili Trawangan, Pantai Senggigi, Gunung Rinjani.\n\n'
          '💡 Tetep cingak status gunung api sadurunge melali!',
      'sas': 'Panduan Wisata Aman (Sleman, Bali, Lombok):\n\n'
          '🏔️ Sleman (DIY): Kaliurang, Candi Prambanan, Lava Tour Merapi (aman mun leq luar zona bahaye).\n'
          '🌊 Bali: Pantai Kuta, Ubud, Uluwatu, Kintamani (Gunung Batur).\n'
          '🏝️ Lombok: Gili Trawangan, Pantai Senggigi, Gunung Rinjani.\n\n'
          '💡 Silaq tetep saksian status gunung berapi seberuq bekelor!',
    },

    'default': {
      'id': 'Maaf, saya kurang memahami pertanyaan Anda. '
          'Saya adalah instruktur pelatihan mitigasi bencana.\n\n'
          'Saya dapat membantu dengan topik:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n'
          '• Mitigasi Abu • Zona Bahaya\n'
          '• Status Gunung • P3K Dasar\n'
          '• Nomor Darurat\n\n'
          'Silakan tanya tentang salah satu topik di atas.',
      'en': 'Sorry, I do not understand your question. '
          'I am a disaster mitigation training instructor.\n\n'
          'I can help with:\n'
          '• Evacuation SOP • Training Schedule\n'
          '• Emergency Bag • Evacuation Routes\n'
          '• Ash Mitigation • Danger Zones\n'
          '• Volcano Status • First Aid\n'
          '• Emergency Numbers\n\n'
          'Please ask about one of the topics above.',
      'jv': 'Ngapunten, kula kirang mangertos. '
          'Kula instruktur pelatihan mitigasi bencana.\n\n'
          'Kula saged mbiyantu:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n'
          '• Mitigasi Abu • Zona Bahaya\n\n'
          'Monggo tanglet babagan topik ing nginggil.',
      'ba': 'Ampura, tiang nenten uning. '
          'Tiang instruktur pelatihan mitigasi bencana.\n\n'
          'Tiang presida nulungin:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n\n'
          'Monggo mataken indik topik ring duur.',
      'sas': 'Ampura, tyang endeq pati ngerti. '
          'Tyang instruktur pelatihan mitigasi bencana.\n\n'
          'Tyang presida bantu:\n'
          '• SOP Evakuasi • Jadwal Pelatihan\n'
          '• Tas Siaga • Jalur Evakuasi\n\n'
          'Silaq betakon soal topik di atas.',
    },
  };
}
