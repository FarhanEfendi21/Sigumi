import 'dart:math';
import 'package:flutter/material.dart';
import '../config/globals.dart';
import '../config/routes.dart';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import 'nlp_engine.dart';
import 'nlp_knowledge_base.dart';

/// Service AI utama untuk chatbot SIGUMI.
///
/// Menangani:
/// - Routing pesan ke NlpEngine
/// - Personalisasi berdasarkan usia (anak/dewasa/lansia)
/// - Pencarian titik kumpul aman terdekat (intent evakuasi)
/// - Rekomendasi evakuasi berbasis arah angin
/// - Validasi radius laporan
class AiService {
  // ═══════════════════════════════════════════════════════════════
  // TITIK KUMPUL AMAN (Assembly Points)
  // ═══════════════════════════════════════════════════════════════
  // Data dummy realistis di sekitar Gunung Merapi
  // (campuran sisi Yogyakarta & Jawa Tengah)
  // ═══════════════════════════════════════════════════════════════
  static const List<Map<String, dynamic>> assemblyPoints = [
    {
      'name': 'Barak Pengungsian Glagaharjo',
      'lat': -7.6358,
      'lng': 110.4721,
      'desc': 'Desa Glagaharjo, Kec. Cangkringan, Sleman',
    },
    {
      'name': 'Barak Pengungsian Kepuharjo',
      'lat': -7.6142,
      'lng': 110.4537,
      'desc': 'Desa Kepuharjo, Kec. Cangkringan, Sleman',
    },
    {
      'name': 'Stadion Maguwoharjo',
      'lat': -7.7505,
      'lng': 110.4182,
      'desc': 'Jl. Stadion Maguwoharjo, Depok, Sleman',
    },
    {
      'name': 'Balai Desa Umbulharjo',
      'lat': -7.6280,
      'lng': 110.4385,
      'desc': 'Desa Umbulharjo, Kec. Cangkringan, Sleman',
    },
    {
      'name': 'Balai Desa Hargobinangun',
      'lat': -7.6185,
      'lng': 110.4015,
      'desc': 'Desa Hargobinangun, Kec. Pakem, Sleman',
    },
    {
      'name': 'Puskesmas Cangkringan',
      'lat': -7.6749,
      'lng': 110.4578,
      'desc': 'Panggung, Argomulyo, Kec. Cangkringan, Sleman',
    },
    {
      'name': 'Puskesmas Pakem',
      'lat': -7.6581,
      'lng': 110.4152,
      'desc': 'Jl. Kaliurang KM 17.5, Kec. Pakem, Sleman',
    },
    {
      'name': 'RS Panti Nugroho',
      'lat': -7.6545,
      'lng': 110.4168,
      'desc': 'Jl. Kaliurang KM 17, Pakembinangun, Pakem, Sleman',
    },
    {
      'name': 'Puskesmas Kemalang',
      'lat': -7.6314,
      'lng': 110.4805,
      'desc': 'Kec. Kemalang, Kabupaten Klaten, Jawa Tengah',
    },
    {
      'name': 'RSUD Sleman',
      'lat': -7.7165,
      'lng': 110.3492,
      'desc': 'Jl. Bhayangkara No.48, Triharjo, Sleman',
    },
  ];

  // ═══════════════════════════════════════════════════════════════
  // MAIN ENTRY POINT — getResponse()
  // ═══════════════════════════════════════════════════════════════

  /// Menghasilkan respons chatbot berdasarkan pesan user.
  ///
  /// Parameter opsional:
  /// - [user]: data profil user untuk personalisasi usia
  /// - [userLat], [userLng]: koordinat user untuk pencarian titik kumpul
  static Future<ChatMessage> getResponse(
    String userMessage, {
    required String languageCode,
    bool isVoice = false,
    UserModel? user,
    double? userLat,
    double? userLng,
  }) async {
    // 1. Tentukan kategori usia dari profil user
    final ageCategory = getAgeCategory(user);

    // 2. Deteksi intent dulu untuk cek apakah evakuasi
    final intentResult = await NlpEngine.detectIntent(userMessage);

    // 3. Jika intent evakuasi DAN lokasi tersedia → intercept dengan titik kumpul
    if (intentResult.intent == 'evakuasi' && userLat != null && userLng != null) {
      return _buildEvacuationResponse(
        userLat: userLat,
        userLng: userLng,
        language: languageCode,
        ageCategory: ageCategory,
        confidence: intentResult.confidence,
      );
    }

    // 4. Untuk intent lainnya, delegasi ke NlpEngine
    return await NlpEngine.processMessage(
      userMessage,
      appLanguage: languageCode,
      isVoice: isVoice,
      ageCategory: ageCategory,
    );
  }

  // ═══════════════════════════════════════════════════════════════
  // PERSONALISASI USIA
  // ═══════════════════════════════════════════════════════════════

  /// Menentukan kategori usia berdasarkan UserModel.
  /// - Usia < 13 → 'anak'
  /// - Usia > 60 → 'lansia'
  /// - Default → 'dewasa'
  static String getAgeCategory(UserModel? user) {
    if (user == null || user.age == null) return 'dewasa';
    if (user.isChild) return 'anak';
    if (user.isElderly) return 'lansia';
    return 'dewasa';
  }

  // ═══════════════════════════════════════════════════════════════
  // WELCOME MESSAGE
  // ═══════════════════════════════════════════════════════════════

  /// Mengambil pesan selamat datang berdasarkan bahasa dan usia.
  static String getWelcomeMessage(String language, {UserModel? user}) {
    // Cek di knowledge base dengan struktur 3-level baru
    final salamResponses = NlpKnowledgeBase.responses['salam'];
    if (salamResponses != null) {
      if (salamResponses.containsKey(language)) {
        return salamResponses[language] as String;
      }
      if (salamResponses.containsKey('id')) {
        return salamResponses['id'] as String;
      }
    }

    return 'Halo! Saya chatbot SIGUMI siap membantu Anda.';
  }

  // ═══════════════════════════════════════════════════════════════
  // PENCARIAN TITIK KUMPUL TERDEKAT
  // ═══════════════════════════════════════════════════════════════

  /// Mencari titik kumpul aman terdekat dari posisi user.
  /// Menggunakan formula Haversine untuk menghitung jarak.
  ///
  /// Return: ({String name, String desc, double distance})
  static ({String name, String desc, double distance}) getNearestAssemblyPoint(
    double userLat,
    double userLng,
  ) {
    String nearestName = assemblyPoints.first['name'];
    String nearestDesc = assemblyPoints.first['desc'];
    double nearestDistance = double.infinity;

    for (final point in assemblyPoints) {
      final distance = calculateDistance(
        userLat,
        userLng,
        (point['lat'] as num).toDouble(),
        (point['lng'] as num).toDouble(),
      );

      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestName = point['name'];
        nearestDesc = point['desc'];
      }
    }

    return (
      name: nearestName,
      desc: nearestDesc,
      distance: nearestDistance,
    );
  }

  /// Membangun respons evakuasi dinamis berdasarkan titik kumpul terdekat.
  /// Dipanggil ketika intent == 'evakuasi' dan koordinat user tersedia.
  static ChatMessage _buildEvacuationResponse({
    required double userLat,
    required double userLng,
    required String language,
    required String ageCategory,
    required double confidence,
  }) {
    final nearest = getNearestAssemblyPoint(userLat, userLng);
    final distanceStr = nearest.distance.toStringAsFixed(1);

    // Format pesan berdasarkan bahasa dan usia
    final responseText = _formatEvacuationMessage(
      name: nearest.name,
      desc: nearest.desc,
      distance: distanceStr,
      language: language,
      ageCategory: ageCategory,
    );

    return ChatMessage(
      content: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.text,
      confidence: confidence,
      intentId: 'evakuasi',
      isVoice: false,
    );
  }

  /// Format pesan evakuasi sesuai bahasa dan usia.
  static String _formatEvacuationMessage({
    required String name,
    required String desc,
    required String distance,
    required String language,
    required String ageCategory,
  }) {
    switch (language) {
      case 'en':
        switch (ageCategory) {
          case 'anak':
            return '📍 In this drill, the nearest assembly point is "$name" ($desc), '
                'about $distance km from you.\n\n'
                'Let\'s practice going there with your parents or a trusted adult! 🏃‍♂️\n'
                'Learn the evacuation signs!';
          case 'lansia':
            return 'TRAINING ASSEMBLY POINT:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km from your location.\n\n'
                'During a real emergency, please head there.\n'
                'Don\'t hesitate to ask family or neighbors for help if needed.';
          default:
            return '📍 Based on this training simulation, the nearest assembly point is **$name** ($desc), '
                'approximately $distance km from your location.\n\n'
                'Familiarize yourself with this route and follow BPBD officers\' instructions during drills.';
        }

      case 'jv':
        switch (ageCategory) {
          case 'anak':
            return '📍 Ing simulasi iki, titik kumpul sing paling cedhak yaiku "$name" ($desc), '
                'udakara $distance km saka kowe.\n\n'
                'Ayo sinau budhal bareng bapak ibu utawa wong tuwa! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL PELATIHAN:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km saka lokasi panjenengan.\n\n'
                'Ingkang darurat, monggo enggal tindak mriku.\n'
                'Nyuwun tulung keluwarga yen butuh bantuan.';
          default:
            return '📍 Adhedhasar simulasi pelatihan, titik kumpul keluwarga tercedhak yaiku: **$name** ($desc), '
                'udakara $distance km saka lokasi panjenengan.\n\n'
                'Monggo hapalake rute iki lan tindakake arahan petugas nalika simulasi.';
        }

      case 'sas':
        switch (ageCategory) {
          case 'anak':
            return '📍 Leq simulasi niki, titik kumpul saq paling dekat ie "$name" ($desc), '
                'kira-kira $distance km leq side.\n\n'
                'Silaq belajaraq uat bareng inaq amaq! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL PELATIHAN:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km leq lokasi side.\n\n'
                'Pas darurat, silaq langsung jok mriku.\n'
                'Boleh tulung jok keluarge mun butuh.';
          default:
            return '📍 Sesuai simulasi pelatihan niki, titik kumpul terdekat ie: **$name** ($desc), '
                'kira-kira $distance km leq lokasi side.\n\n'
                'Silaq hapalang rute niki dait turut arahan petugas pas simulasi bpbd.';
        }

      case 'ba':
        switch (ageCategory) {
          case 'anak':
            return '📍 Ring simulasi puniki, titik kumpul sane paling paek inggih punika "$name" ($desc), '
                'sawatara $distance km saking ragané.\n\n'
                'Ngiring malajah lunga sareng bapa miwah ibu! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL PELATIHAN:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km saking lokasi ragané.\n\n'
                'Yening darurat saje, mangda gelis lunga mriku.\n'
                'Nunas wantuan kulawarga yéning merluang.';
          default:
            return '📍 Miturut simulasi pelatihan, titik kumpul terpaek inggih punika: **$name** ($desc), '
                'sawatara $distance km saking lokasi ragané.\n\n'
                'Mangda apalang rute puniki lan tuutin arahan patugas BPBD yening simulasi.';
        }

      default: // Bahasa Indonesia
        switch (ageCategory) {
          case 'anak':
            return '📍 Dalam latihan simulasi ini, titik kumpul kita di "$name" ($desc), '
                'sekitar $distance km dari lokasimu.\n\n'
                'Ayo berlatih pergi ke sana bareng orang tua atau orang dewasa! 🏃‍♂️\n'
                'Hafalkan rambu-rambu evakuasinya ya!';
          case 'lansia':
            return 'TITIK KUMPUL LATIHAN:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km dari lokasi Anda.\n\n'
                'Pada simulasi/kejadian nyata, arahkan diri Anda ke sana.\n'
                'Jangan ragu meminta bantuan keluarga atau tetangga untuk evakuasi.';
          default:
            return '📍 Berdasarkan simulasi pelatihan, titik kumpul aman terdekat dari lokasi Anda adalah '
                '**$name** ($desc), berjarak sekitar $distance km.\n\n'
                'Hafalkan jalur evakuasi ini untuk berjaga-jaga, dan selalu ikuti petunjuk petugas BPBD pada saat gladi lapang.';
        }
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // AI PERSONALIZATION
  // ═══════════════════════════════════════════════════════════════

  /// Personalisasi sapaan berdasarkan profil user.
  static String getPersonalizedGreeting(UserModel? user) {
    if (user == null) return 'Selamat datang di SIGUMI';
    if (user.isChild) return 'Halo, Adik! 👋 Yuk belajar tentang gunung berapi!';
    if (user.isElderly) return 'Selamat datang, Bapak/Ibu. Informasi penting tersedia untuk Anda.';
    return 'Selamat datang, ${user.name}!';
  }

  // ═══════════════════════════════════════════════════════════════
  // AI-BASED REPORT RADIUS VALIDATION
  // ═══════════════════════════════════════════════════════════════

  /// Cek apakah user berada dalam radius valid untuk membuat laporan.
  static bool isWithinReportRadius(double userLat, double userLng, double maxRadiusKm) {
    final distance = calculateDistance(
      userLat, userLng,
      -7.5407, 110.4457, // Koordinat Merapi
    );
    return distance <= maxRadiusKm;
  }

  /// Menghitung jarak antara dua koordinat menggunakan formula Haversine.
  static double calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371; // km
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) => degree * pi / 180;

  // ═══════════════════════════════════════════════════════════════
  // AI EVACUATION RECOMMENDATION (wind-based)
  // ═══════════════════════════════════════════════════════════════

  /// Rekomendasi arah evakuasi berdasarkan arah angin.
  static String getEvacuationRecommendation(String? windDirection) {
    if (windDirection == null) {
      return 'Ikuti jalur evakuasi yang telah ditentukan oleh BPBD.';
    }
    switch (windDirection.toLowerCase()) {
      case 'barat daya':
      case 'barat':
        return 'Arah angin ke barat daya. Disarankan evakuasi ke arah timur atau selatan untuk menghindari hujan abu.';
      case 'timur':
      case 'tenggara':
        return 'Arah angin ke timur. Disarankan evakuasi ke arah barat atau selatan.';
      case 'utara':
        return 'Arah angin ke utara. Disarankan evakuasi ke arah selatan.';
      default:
        return 'Pantau arah angin dan ikuti jalur evakuasi yang direkomendasikan BPBD.';
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // NAVIGATION INTENT — Navigasi Otomatis dari Voice Assistant
  // ═══════════════════════════════════════════════════════════════

  /// Mapping intent NLP ke route aplikasi.
  /// Jika intent bukan navigasi, return null.
  static String? _getRouteForIntent(String intentId) {
    switch (intentId) {
      case 'evakuasi':
        return AppRoutes.map;
      case 'status':
        return AppRoutes.home;
      case 'bantuan':
        return AppRoutes.emergency;
      case 'zona_bahaya':
        return AppRoutes.map;
      case 'sop_evakuasi':
        return AppRoutes.education;
      case 'jadwal_pelatihan':
        return AppRoutes.education;
      case 'tas_siaga':
        return AppRoutes.education;
      case 'mitigasi_abu':
        return AppRoutes.education;
      case 'p3k':
        return AppRoutes.education;
      default:
        return null;
    }
  }

  /// Teks konfirmasi navigasi yang dibacakan TTS sebelum pindah halaman.
  static String _getNavigationConfirmation(String intentId, String language) {
    final Map<String, Map<String, String>> confirmations = {
      'evakuasi': {
        'id': 'Membuka halaman peta evakuasi.',
        'en': 'Opening evacuation map.',
      },
      'status': {
        'id': 'Membuka halaman beranda untuk melihat status gunung.',
        'en': 'Opening home page to check volcano status.',
      },
      'bantuan': {
        'id': 'Membuka halaman kontak darurat.',
        'en': 'Opening emergency contacts page.',
      },
      'zona_bahaya': {
        'id': 'Membuka halaman peta zona bahaya.',
        'en': 'Opening danger zone map.',
      },
      'sop_evakuasi': {
        'id': 'Membuka halaman edukasi evakuasi.',
        'en': 'Opening evacuation education page.',
      },
      'jadwal_pelatihan': {
        'id': 'Membuka halaman edukasi pelatihan.',
        'en': 'Opening training education page.',
      },
      'tas_siaga': {
        'id': 'Membuka halaman edukasi kesiapsiagaan.',
        'en': 'Opening preparedness education page.',
      },
      'mitigasi_abu': {
        'id': 'Membuka halaman edukasi mitigasi.',
        'en': 'Opening mitigation education page.',
      },
      'p3k': {
        'id': 'Membuka halaman edukasi P3K.',
        'en': 'Opening first aid education page.',
      },
    };

    final intentConfirm = confirmations[intentId];
    if (intentConfirm != null) {
      return intentConfirm[language] ?? intentConfirm['id'] ?? 'Memproses...';
    }
    return language == 'en' ? 'Processing...' : 'Memproses...';
  }

  /// Mencoba melakukan navigasi otomatis berdasarkan intent.
  /// Dipanggil oleh GlobalAssistantProvider setelah mendapat respons.
  ///
  /// Return true jika navigasi berhasil dilakukan.
  static bool tryNavigateForIntent(String intentId) {
    final route = _getRouteForIntent(intentId);
    if (route == null) return false;

    final navigator = globalNavigatorKey.currentState;
    if (navigator == null) {
      debugPrint('[AiService] ⚠️ Navigator not available for auto-navigate.');
      return false;
    }

    // Gunakan pushNamed agar user bisa kembali ke halaman sebelumnya
    navigator.pushNamed(route);
    debugPrint('[AiService] 🗺️ Auto-navigated to: $route (intent: $intentId)');
    return true;
  }

  /// Mendapatkan teks konfirmasi navigasi untuk TTS.
  static String getNavigationText(String intentId, String language) {
    return _getNavigationConfirmation(intentId, language);
  }
}
