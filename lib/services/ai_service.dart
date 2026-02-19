import 'dart:math';
import '../models/chat_message.dart';
import '../models/user_model.dart';

class AiService {
  // Simulated NLP chatbot responses
  static final Map<String, List<String>> _responsePatterns = {
    'status': [
      'Status Gunung Merapi saat ini berada di Level II (Waspada). Aktivitas vulkanik masih tinggi dengan guguran lava pijar teramati jarak luncur maksimum 1.8 km ke arah barat daya. Sumber: PVMBG.',
    ],
    'evakuasi': [
      'Jalur evakuasi teraman saat ini adalah Jalur Selatan (Pakem → Jl. Kaliurang → Ring Road Utara → Stadion Maguwoharjo). Estimasi waktu tempuh 35 menit. Hindari jalur tenggara karena kepadatan tinggi.',
    ],
    'zona': [
      'Zona bahaya saat ini:\n🔴 Radius 5 km: Zona Bahaya Utama - DILARANG masuk\n🟠 Radius 10 km: Zona Waspada - Siap evakuasi\n🟡 Radius 15 km: Zona Perhatian - Pantau informasi\n🟢 >15 km: Zona Relatif Aman',
    ],
    'abu': [
      'Tips menghadapi hujan abu vulkanik:\n1. Gunakan masker atau kain basah untuk menutup hidung dan mulut\n2. Gunakan kacamata pelindung\n3. Tutup semua jendela dan pintu\n4. Lindungi sumber air dari abu\n5. Jangan menyalakan kendaraan saat abu tebal',
    ],
    'gempa': [
      'Jika terjadi gempa vulkanik:\n1. Jauhi bangunan dan tiang listrik\n2. Lindungi kepala\n3. Cari tempat terbuka yang aman\n4. Ikuti arahan petugas\n5. Pantau informasi dari BMKG dan PVMBG',
    ],
    'lahar': [
      'Bahaya lahar dingin/panas:\n1. Jauhi aliran sungai yang berhulu di gunung\n2. Jangan menyeberangi sungai saat hujan deras\n3. Perhatikan suara gemuruh dari arah hulu\n4. Segera mengungsi ke tempat tinggi jika melihat aliran lahar',
    ],
    'p3k': [
      'Pertolongan pertama saat bencana:\n1. Periksa kesadaran korban\n2. Pastikan jalan napas terbuka\n3. Hentikan pendarahan dengan menekan luka\n4. Jangan memindahkan korban patah tulang\n5. Hubungi 118 untuk ambulans darurat',
    ],
    'persiapan': [
      'Persiapan sebelum erupsi:\n1. Siapkan tas siaga berisi dokumen penting, obat-obatan, air minum, dan makanan\n2. Kenali jalur evakuasi terdekat\n3. Simpan nomor darurat\n4. Ikuti arahan BPBD setempat\n5. Pastikan kendaraan siap digunakan',
    ],
    'pasca': [
      'Langkah pasca erupsi:\n1. Tunggu arahan resmi sebelum kembali ke rumah\n2. Bersihkan abu dari atap (bahaya runtuh)\n3. Periksa sumber air sebelum digunakan\n4. Waspadai aliran lahar pascaerupsi\n5. Lapor kerusakan ke BPBD',
    ],
    'bantuan': [
      'Untuk bantuan darurat, hubungi:\n📞 BNPB: 117\n📞 SAR/Basarnas: 115\n📞 Ambulans: 118\n📞 BPBD DIY: (0274) 555679\n📞 Posko Merapi: (0274) 896573',
    ],
  };

  static final Map<String, List<String>> _responsePatternsEn = {
    'status': [
      'The current status of Mount Merapi is at Level II (Alert). Volcanic activity remains high with incandescent lava avalanches observed with a maximum slide distance of 1.8 km to the southwest. Source: PVMBG.',
    ],
    'evakuasi': [
      'The safest evacuation route currently is the Southern Route (Pakem → Jl. Kaliurang → Ring Road Utara → Maguwoharjo Stadium). Estimated travel time is 35 minutes.',
    ],
    'zona': [
      'Current danger zones:\n🔴 5 km radius: Main Danger Zone - ENTRY PROHIBITED\n🟠 10 km radius: Alert Zone - Ready to evacuate\n🟡 15 km radius: Caution Zone - Monitor information\n🟢 >15 km: Relatively Safe Zone',
    ],
    'bantuan': [
      'For emergency assistance, contact:\n📞 BNPB: 117\n📞 SAR/Basarnas: 115\n📞 Ambulance: 118\n📞 BPBD DIY: (0274) 555679',
    ],
  };

  static String _defaultResponse(String lang) {
    if (lang == 'en') {
      return 'Sorry, I don\'t understand your question. Try asking about:\n• Volcano status (type "status")\n• Evacuation routes (type "evakuasi")\n• Danger zones (type "zona")\n• Emergency help (type "bantuan")\n• Eruption preparation (type "persiapan")\n• Post-disaster steps (type "pasca")';
    }
    return 'Maaf, saya belum memahami pertanyaan Anda. Coba tanyakan tentang:\n• Status gunung (ketik "status")\n• Jalur evakuasi (ketik "evakuasi")\n• Zona bahaya (ketik "zona")\n• Hujan abu (ketik "abu")\n• Bantuan darurat (ketik "bantuan")\n• Pertolongan pertama (ketik "p3k")\n• Persiapan erupsi (ketik "persiapan")\n• Pasca bencana (ketik "pasca")';
  }

  static ChatMessage getResponse(String userMessage, {String language = 'id'}) {
    final query = userMessage.toLowerCase().trim();
    final patterns = language == 'en' ? _responsePatternsEn : _responsePatterns;

    for (final entry in patterns.entries) {
      if (query.contains(entry.key)) {
        return ChatMessage(
          content: entry.value[Random().nextInt(entry.value.length)],
          isUser: false,
          timestamp: DateTime.now(),
          language: language,
        );
      }
    }

    // Fallback to Indonesian patterns if English doesn't have the answer
    if (language == 'en') {
      for (final entry in _responsePatterns.entries) {
        if (query.contains(entry.key)) {
          return ChatMessage(
            content: entry.value[Random().nextInt(entry.value.length)],
            isUser: false,
            timestamp: DateTime.now(),
            language: 'id',
          );
        }
      }
    }

    return ChatMessage(
      content: _defaultResponse(language),
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
    );
  }

  // AI Personalization
  static String getPersonalizedGreeting(UserModel? user) {
    if (user == null) return 'Selamat datang di SIGUMI';
    if (user.isChild) return 'Halo, Adik! 👋 Yuk belajar tentang gunung berapi!';
    if (user.isElderly) return 'Selamat datang, Bapak/Ibu. Informasi penting tersedia untuk Anda.';
    return 'Selamat datang, ${user.name}!';
  }

  // AI-based report radius validation
  static bool isWithinReportRadius(double userLat, double userLng, double maxRadiusKm) {
    final distance = calculateDistance(
      userLat, userLng,
      -7.5407, 110.4457, // Merapi coordinates
    );
    return distance <= maxRadiusKm;
  }

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

  // AI Evacuation recommendation based on location, wind, congestion
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
