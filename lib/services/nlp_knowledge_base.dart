class NlpKnowledgeBase {
  /// Training phrases mapped to their respective intents

  /// Language Marker Words
  static const Map<String, List<String>> languageMarkers = {
    'jv': [
      'kowe',
      'aku',
      'piye',
      'kepiye',
      'saiki',
      'ana',
      'endi',
      'mlayu',
      'dalan',
      'banyu',
      'awu',
      'udhan',
      'omah',
    ],
    'su': [
      'abdi',
      'maneh',
      'kumaha',
      'ayeuna',
      'aya',
      'kamana',
      'lebu',
      'cai',
      'bitu',
      'imah',
    ],
    'ba': [
      'tiang',
      'ragane',
      'kenken',
      'mangkin',
      'wenten',
      'dija',
      'margi',
      'yeh',
      'umah',
      'mewali',
    ],
    'sas': [
      'tiang',
      'side',
      'berembe',
      'napi',
      'mbe',
      'jelo',
      'bale',
      'tende',
      'aiq',
      'pelungguh',
      'tyang',
    ],
    'en': [
      'how',
      'what',
      'where',
      'when',
      'who',
      'is',
      'are',
      'status',
      'volcano',
      'evacuation',
      'safe',
      'danger',
    ],
  };

  static const Map<String, List<String>> trainingPhrases = {
    'status': [
      'bagaimana status merapi saat ini',
      'status gunung',
      'kondisi merapi sekarang',
      'apakah merapi aman',
      'tingkat aktivitas gunung api',
      'update merapi hari ini',
      'level gunung merapi',
      'informasi terkini merapi',
      'gimana kabar merapi',
      'statusnya awas siaga atau waspada',
      'ada letusan nggak hari ini',
    ],
    'evakuasi': [
      'jalur evakuasi mana yang aman',
      'harus lari kemana',
      'rute penyelamatan diri',
      'jalan keluar terdekat',
      'ke arah mana evakuasinya',
      'tempat pengungsian di mana',
      'cara evakuasi yang benar',
      'panduan mengungsi',
      'jalur aman dari lahar',
    ],
    'zona': [
      'berapa radius aman merapi',
      'zona bahaya merapi di mana saja',
      'apakah desa saya aman',
      'daerah terlarang masuk',
      'jarak wilayah aman dari puncak',
      'batas bahaya gunung api',
      'kawasan rawan bencana',
      'info ring satu merapi',
    ],
    'abu': [
      'ada hujan abu vulkanik tidak',
      'abu merapi sampai mana',
      'cara berlindung dari abu',
      'apakah perlu pakai masker',
      'tips menghadapi hujan abu',
      'membersihkan abu di genteng',
      'bahaya menghirup abu',
      'abu vulkanik arah mana',
    ],
    'p3k': [
      'pertolongan pertama kenda debu',
      'cara mengobati luka bakar lahar',
      'mata kelilipan abu harus bagaimana',
      'sesak napas karena abu',
      'p3k saat erupsi',
      'pertolongan medis darurat',
      'bantuan pertama korban selamat',
    ],
    'bantuan': [
      'nomor telepon darurat',
      'panggil ambulans',
      'hubungi sar',
      'kontak bnpb',
      'minta bantuan',
      'nomor bpbd',
      'butuh pertolongan segera',
      'nomor posko merapi',
    ],
    'persiapan': [
      'apa yang harus disiapkan sebelum erupsi',
      'isi tas siaga bencana',
      'persiapan menghadapi letusan',
      'barang bawaan penting untuk mengungsi',
      'cara mengepak barang saat darurat',
    ],
    'pasca': [
      'apa yang dilakukan setelah letusan',
      'kapan boleh pulang ke rumah',
      'membersihkan sisa abu vulkanik',
      'bahaya lahar dingin',
      'pemulihan pasca bencana',
    ],
    'salam': [
      'halo',
      'hai',
      'selamat pagi',
      'selamat siang',
      'assalamualaikum',
      'sugeng enjing',
      'punteun',
      'om swastiastu',
    ],
  };

  /// Multi-language responses mapped by intent and language code
  static const Map<String, Map<String, String>> responses = {
    'status': {
      'id':
          'Status Gunung Merapi saat ini berada di Level II (Waspada). Aktivitas vulkanik masih tinggi dengan guguran lava pijar teramati. Sumber: PVMBG.',
      'en':
          'The current status of Mount Merapi is at Level II (Alert). Volcanic activity remains high with incandescent lava avalanches observed. Source: PVMBG.',
      'jv':
          'Kahanan Gunung Merapi saiki ana ing Level II (Waspada). Aktivitas vulkanik isih dhuwur kanthi guguran lava pijar sing katon. Sumber: PVMBG.',
      'su':
          'Status Gunung Merapi ayeuna aya dina Level II (Waspada). Aktivitas vulkanik masih luhur jeung guguran lava pijar katingali. Sumber: PVMBG.',
      'ba':
          'Kahanan Gunung Merapi mangkin wonten ring Level II (Waspada). Aktivitas vulkanik kantun tegeh maduluran antuk guguran lava pijar sane ngantenang. Pustaka: PVMBG.',
      'sas':
          'Status Gunung Merapi wayah niki nggeh. Info pelungguh wenten ring Magma Indonesia.',
    },
    'evakuasi': {
      'id':
          'Jalur evakuasi teraman saat ini adalah Jalur Selatan. Ikuti papan penunjuk arah evakuasi dan arahan petugas di lapangan.',
      'en':
          'The safest evacuation route is the Southern Route. Follow the evacuation signs and instructions from officers in the field.',
      'jv':
          'Dalan evakuasi sing paling aman saiki yaiku Dalan Kidul. Tindakake tandha arah evakuasi lan arahan petugas ing lapangan.',
      'su':
          'Jalur evakuasi anu panga-amanna ayeuna nyaéta Jalur Kidul. Tuturkeun papan pituduh arah evakuasi jeung arahan patugas di lapangan.',
      'ba':
          'Margi evakuasi sane pinih aman mangkin inggih punika Margi Kelod. Rereh papan pituduh arah evakuasi miwah arahan petugas ring lapangan.',
      'sas': 'Silaq evakuasi jok tiitik kumpul saq terdekat dait paling aman.',
    },
    'zona': {
      'id':
          'Zona bahaya saat ini:\n🔴 Radius 5 km: DILARANG masuk\n🟠 Radius 10 km: Siap evakuasi\n🟡 Radius 15 km: Pantau informasi\n🟢 >15 km: Relatif Aman',
      'en':
          'Current danger zones:\n🔴 5 km radius: ENTRY PROHIBITED\n🟠 10 km radius: Ready to evacuate\n🟡 15 km radius: Monitor information\n🟢 >15 km: Relatively Safe',
      'jv':
          'Zona bebaya saiki:\n🔴 Radius 5 km: DILARANG mlebu\n🟠 Radius 10 km: Siap evakuasi\n🟡 Radius 15 km: Pantau informasi\n🟢 >15 km: Relatif Aman',
      'su':
          'Zona bahaya ayeuna:\n🔴 Radius 5 km: DILARANG asup\n🟠 Radius 10 km: Siap evakuasi\n🟡 Radius 15 km: Pantau informasi\n🟢 >15 km: Rélatif Aman',
      'ba':
          'Zona bahaya mangkin:\n🔴 Radius 5 km: DILARANG ngeranjing\n🟠 Radius 10 km: Siap evakuasi\n🟡 Radius 15 km: Pantau informasi\n🟢 >15 km: Relatif Aman',
      'sas': 'Kenali zona bahaya letusan dait patuhi bates aman.',
    },
    'abu': {
      'id':
          'Tips hujan abu: Gunakan masker, kacamata pelindung, tutup jendela, dan lindungi sumber air.',
      'en':
          'Ash rain tips: Use masks, protective glasses, close windows, and protect water sources.',
      'jv':
          'Tips udan awu: Gunakake masker, kacamata pelindung, tutup jendela, lan lindungi sumber banyu.',
      'su':
          'Tips hujan lebu: Pake masker, kacamata pelindung, tutup panto/jandéla, tur lindungan cai.',
      'ba':
          'Tips ujan abu: Anggen masker, kacamata pelindung, tutup jendela, lan lindungi sumber yeh.',
      'sas':
          'Antisipasi ujan abu: Pake masker, kacamata, kance tutup aiq dait ajengan.',
    },
    'p3k': {
      'id':
          'Pertolongan pertama: Pastikan jalan napas terbuka, bersihkan mata dengan air matang jika terkena abu, hubungi medis jika darurat.',
      'en':
          'First aid: Ensure open airways, clean eyes with boiled water if exposed to ash, contact medical for emergencies.',
      'jv':
          'Pertolongan pertama: Padhakake dalan ambegan mbukak, resiki mripat nganggo banyu mateng yen kena awu, hubungi medis yen darurat.',
      'su':
          'Pitulung munggaran: Pastikeun jalan napas muka, bersihkeun panon ku cai asak mun keuna lebu, hubungi medis mun darurat.',
      'ba':
          'Pitulung pertama: Pastikayang jalan angkihan mebading, besihin penyingakan aji yeh lebeng yening keni abu, hubungi medis yening darurat.',
      'sas': 'Siapang kotak P3K isi obat-obatan darurat dait perban.',
    },
    'bantuan': {
      'id': 'Kontak Darurat:\n📞 BNPB: 117\n📞 SAR: 115\n📞 Ambulans: 118',
      'en': 'Emergency Contacts:\n📞 BNPB: 117\n📞 SAR: 115\n📞 Ambulance: 118',
      'jv': 'Kontak Darurat:\n📞 BNPB: 117\n📞 SAR: 115\n📞 Ambulans: 118',
      'su': 'Kontak Darurat:\n📞 BNPB: 117\n📞 SAR: 115\n📞 Ambulans: 118',
      'ba': 'Kontak Darurat:\n📞 BNPB: 117\n📞 SAR: 115\n📞 Ambulans: 118',
      'sas': 'Hubungi nomer darurat mun side butuh bantuan.',
    },
    'persiapan': {
      'id':
          'Siapkan tas siaga berisi: dokumen penting, obat-obatan, senter, pakaian ganti, makanan kering, dan air minum.',
      'en':
          'Prepare an emergency bag containing: important documents, medicines, flashlight, clothes, dry food, and water.',
      'jv':
          'Siapake tas siaga isine: dokumen penting, obat-obatan, senter, klambi ganti, panganan garing, lan banyu ngombe.',
      'su':
          'Siapkeun tas siaga eusina: dokumén penting, ubar, séntér, papakéan ganti, kadaharan garing, sarta cai nginum.',
      'ba':
          'Siagayang tas siaga madaging: reriptan mabuat, ubad-ubadan, senter, pangangge, ajengan ngering, lan yeh inem.',
      'sas': 'Sedia tas siaga bencana saq misi dokumen dait persediaan.',
    },
    'pasca': {
      'id':
          'Pasca erupsi: Jangan kembali sebelum ada arahan resmi. Bersihkan atap dari abu agar tidak ambrol, waspadai lahar dingin di sungai.',
      'en':
          'Post-eruption: Do not return before official directions. Clean roofs from ash to avoid collapsing, beware of cold lava in rivers.',
      'jv':
          'Pasca erupsi: Aja bali sadurunge ana arahan resmi. Resiki atap saka awu amrih ora ambrol, waspada lahar adhem ing kali.',
      'su':
          'Rengse erupsi: Ulah waka balik saméméh aya arahan resmi. Bersihkeun kenténg ti lebu sangkan teu rugrug, waspada lahar tiis di walungan.',
      'ba':
          'Sasampun erupsi: Sampunang mewali sadurung wénten arahan resmi. Kedasin raab saking abu mangda nenten rugrug, waspada lahar dingin ring tukad.',
      'sas': 'Mulai pemulihan leq lingkungan sekitar mun kondisi wah aman.',
    },
    'salam': {
      'id':
          'Halo! Saya chatbot SIGUMI siap membantu Anda. Ada yang bisa saya bantu terkait informasi Gunung Merapi?',
      'en':
          'Hello! I am the SIGUMI chatbot ready to help you. How can I assist you with Mount Merapi information?',
      'jv':
          'Halo! Kula chatbot SIGUMI siap mbantu panjenengan. Wonten ingkang saget kula bantu ngengingi informasi Gunung Merapi?',
      'su':
          'Halo! Abdi chatbot SIGUMI siap mekelan anjeun. Aya nu tiasa dibantos ngeunaan informasi Gunung Merapi?',
      'ba':
          'Om Swastiastu! Tiang chatbot SIGUMI sayaga nulungin ragane. Napi sane presida tiang bantu indik informasi Gunung Merapi?',
      'sas': 'Tabe! Tyang Si Gumi. Napi saq bau tyang bantu?',
    },
    'default': {
      'id':
          'Maaf, saya kurang paham. Anda bisa bertanya tentang: status merapi, arah evakuasi, daerah aman, atau nomor bantuan.',
      'en':
          'Sorry, I don\'t understand. You can ask about: merapi status, evacuation routes, safe zones, or emergency numbers.',
      'jv':
          'Ngapunten, kula kirang paham. Panjenengan saget tanglet babagan: status merapi, arah evakuasi, daerah aman, utawi nomer pitulung.',
      'su':
          'Hapunten, abdi kirang ngartos. Anjeun tiasa naroskeun: status merapi, arah evakuasi, daérah aman, atanapi nomer bantuan.',
      'ba':
          'Ampura, tiang nenten ngresep. Ragane dados mataken indik: status merapi, arah evakuasi, genah aman, utawi nomer wantuan.',
      'sas':
          'Ampura tyang endeq pati ngerti. Silaq betakon soal status merapi atau lokasi evakuasi.',
    },
  };

  /// Regional language translation to Indonesian (basic keyword mapping for stemmer/NLP input)
  static const Map<String, String> regionalDictionaryToIndonesian = {
    // Javanese
    'kepiye': 'bagaimana',
    'piye': 'bagaimana',
    'kahanan': 'keadaan',
    'saiki': 'sekarang',
    'ana': 'ada', 'ing': 'di', 'endi': 'mana', 'pundi': 'mana',
    'mlayu': 'lari',
    'dalan': 'jalan',
    'kidul': 'selatan',
    'lor': 'utara',
    'wetan': 'timur',
    'kulon': 'barat',
    'banyu': 'air', 'awu': 'abu', 'udhan': 'hujan', 'tulung': 'tolong',

    // Sundanese
    'kumaha': 'bagaimana',
    'ayeuna': 'sekarang',
    'aya': 'ada',
    'di': 'di',
    'mana': 'mana',
    'kamana': 'kemana',
    'lebu': 'abu',
    'cai': 'air',
    'bantos': 'bantu',
    'nulungan': 'tolong',

    // Balinese
    'kenken': 'bagaimana',
    'mangkin': 'sekarang',
    'wenten': 'ada',
    'dija': 'dimana',
    'margi': 'jalan', 'yeh': 'air', 'wantuan': 'bantuan', 'nulungin': 'tolong',
  };
}
