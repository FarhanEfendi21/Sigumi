import 'dart:math';
import '../models/chat_message.dart';
import '../models/user_model.dart';
import 'nlp_engine.dart';
import 'nlp_knowledge_base.dart';

class AiService {
  static ChatMessage getResponse(String userMessage, {String language = 'id', bool isVoice = false}) {
    return NlpEngine.processMessage(userMessage, language: language, isVoice: isVoice);
  }

  static String getWelcomeMessage(String language) {
    if (NlpKnowledgeBase.responses.containsKey('salam') && 
        NlpKnowledgeBase.responses['salam']!.containsKey(language)) {
      return NlpKnowledgeBase.responses['salam']![language]!;
    }
    return NlpKnowledgeBase.responses['salam']!['id']!;
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
