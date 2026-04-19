import 'dart:math';
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
      'name': 'Stadion Maguwoharjo',
      'lat': -7.7492,
      'lng': 110.4147,
      'desc': 'Sleman, Yogyakarta',
    },
    {
      'name': 'Balai Desa Umbulharjo',
      'lat': -7.6097,
      'lng': 110.4421,
      'desc': 'Cangkringan, Sleman',
    },
    {
      'name': 'Lapangan Desa Kepuharjo',
      'lat': -7.5858,
      'lng': 110.4433,
      'desc': 'Cangkringan, Sleman',
    },
    {
      'name': 'SMP N 2 Cangkringan',
      'lat': -7.6287,
      'lng': 110.4527,
      'desc': 'Cangkringan, Sleman',
    },
    {
      'name': 'GOR Amongrogo',
      'lat': -7.7853,
      'lng': 110.3787,
      'desc': 'Kota Yogyakarta',
    },
    {
      'name': 'Balai Desa Muntilan',
      'lat': -7.5837,
      'lng': 110.2887,
      'desc': 'Muntilan, Magelang',
    },
    {
      'name': 'Lapangan Desa Srumbung',
      'lat': -7.5612,
      'lng': 110.3345,
      'desc': 'Srumbung, Magelang',
    },
    {
      'name': 'Stadion Kridanggo',
      'lat': -7.4773,
      'lng': 110.2118,
      'desc': 'Kota Magelang',
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
      String detectedLang = NlpEngine.detectLanguage(userMessage);
      return _buildEvacuationResponse(
        userLat: userLat,
        userLng: userLng,
        language: detectedLang,
        ageCategory: ageCategory,
        confidence: intentResult.confidence,
      );
    }

    // 4. Untuk intent lainnya, delegasi ke NlpEngine
    return await NlpEngine.processMessage(
      userMessage,
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
      detectedIntent: 'evakuasi',
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
            return '📍 The nearest safe point is "$name" ($desc), '
                'about $distance km from you.\n\n'
                'Go there with your parents or a trusted adult! 🏃‍♂️\n'
                'Follow the evacuation signs and stay calm!';
          case 'lansia':
            return 'NEAREST ASSEMBLY POINT:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km from your location.\n\n'
                'Please head there immediately.\n'
                'Ask family or neighbors for help if needed.';
          default:
            return '📍 Nearest assembly point: **$name** ($desc), '
                'approximately $distance km from your location.\n\n'
                'Please head there immediately and follow BPBD officers\' instructions.';
        }

      case 'jv':
        switch (ageCategory) {
          case 'anak':
            return '📍 Titik kumpul sing paling cedhak yaiku "$name" ($desc), '
                'udakara $distance km saka kowe.\n\n'
                'Ayo budhal bareng bapak ibu utawa wong tuwa! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL TERCEDHAK:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km saka lokasi panjenengan.\n\n'
                'Monggo enggal tindak mriku.\n'
                'Nyuwun tulung keluwarga yen butuh bantuan.';
          default:
            return '📍 Titik kumpul aman tercedhak: **$name** ($desc), '
                'udakara $distance km saka lokasi panjenengan.\n\n'
                'Monggo enggal tindak mriku lan tindakake arahan petugas BPBD.';
        }

      case 'su':
        switch (ageCategory) {
          case 'anak':
            return '📍 Titik kumpul pangdeukeutna nyaéta "$name" ($desc), '
                'kira-kira $distance km ti hidep.\n\n'
                'Hayu indit bareng bapa ibu atawa kolot! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL PANGDEUKEUTNA:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km ti lokasi anjeun.\n\n'
                'Mangga enggal angkat ka dinya.\n'
                'Ménta bantuan kulawarga upami peryogi.';
          default:
            return '📍 Titik kumpul aman pangdeukeutna: **$name** ($desc), '
                'kira-kira $distance km ti lokasi anjeun.\n\n'
                'Mangga enggal angkat ka dinya sareng turutan arahan patugas BPBD.';
        }

      case 'ba':
        switch (ageCategory) {
          case 'anak':
            return '📍 Titik kumpul sané pinih paek inggih punika "$name" ($desc), '
                'sawatara $distance km saking ragané.\n\n'
                'Ngilangang lunga sareng bapa miwah ibu! 🏃‍♂️';
          case 'lansia':
            return 'TITIK KUMPUL TERPAEK:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km saking lokasi ragané.\n\n'
                'Mangda gelis lunga mriku.\n'
                'Nunas wantuan kulawarga yéning merluang.';
          default:
            return '📍 Titik kumpul aman terpaek: **$name** ($desc), '
                'sawatara $distance km saking lokasi ragané.\n\n'
                'Mangda gelis lunga mriku lan tuutin arahan patugas BPBD.';
        }

      default: // Bahasa Indonesia
        switch (ageCategory) {
          case 'anak':
            return '📍 Titik kumpul aman terdekat adalah "$name" ($desc), '
                'sekitar $distance km dari kamu.\n\n'
                'Ayo pergi ke sana bareng orang tua atau orang dewasa! 🏃‍♂️\n'
                'Ikuti rambu evakuasi dan jangan panik ya!';
          case 'lansia':
            return 'TITIK KUMPUL TERDEKAT:\n\n'
                '📍 $name\n'
                '📌 $desc\n'
                '📏 $distance km dari lokasi Anda.\n\n'
                'Segera menuju ke sana.\n'
                'Minta bantuan keluarga atau tetangga jika diperlukan.';
          default:
            return '📍 Titik kumpul aman terdekat dari lokasi Anda adalah '
                '**$name** ($desc), berjarak sekitar $distance km.\n\n'
                'Silakan segera menuju ke sana dan ikuti arahan petugas BPBD di lapangan.';
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
}
