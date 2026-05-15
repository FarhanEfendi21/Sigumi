import 'nlp_knowledge_base.dart';
import 'intent_classifier.dart';
import '../models/chat_message.dart';

/// Engine NLP lokal untuk chatbot SIGUMI.
class NlpEngine {
  static IntentClassifier? _classifier;

  /// Inisialisasi classifier (Dual-Engine)
  static Future<void> init() async {
    if (_classifier != null) return;
    
    // Semua platform sekarang dilayani oleh TFLiteIntentClassifier
    // yang sudah memiliki built-in dictionary fallback!
    _classifier = TFLiteIntentClassifier();
    await _classifier!.init();
  }



  /// Deteksi intent dari query user menggunakan Classifier abstrak
  static Future<({String intent, double confidence})> detectIntent(String query) async {
    if (_classifier == null) {
      await init();
    }

    if (query.trim().isEmpty) {
      return (intent: 'default', confidence: 0.0);
    }
    
    String normalizedQuery = _normalizeText(query);
    normalizedQuery = _translateRegionalWords(normalizedQuery);
    
    return await _classifier!.classify(normalizedQuery);
  }

  static String _normalizeText(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }

  static String _translateRegionalWords(String query) {
    List<String> words = query.split(' ');
    for (int i = 0; i < words.length; i++) {
      String word = words[i];
      if (NlpKnowledgeBase.regionalDictionaryToIndonesian.containsKey(word)) {
        words[i] = NlpKnowledgeBase.regionalDictionaryToIndonesian[word]!;
      }
    }
    return words.join(' ');
  }

  /// Generate ChatMessage respons berdasarkan bahasa terbaca dan NLP intent
  static Future<ChatMessage> processMessage(
    String text, {
    required String appLanguage,
    bool isVoice = false,
    String ageCategory = 'dewasa',
  }) async {
    // 1. Deteksi intent dengan model/dictionary
    final result = await detectIntent(text);
    final intent = result.intent;
    
    // 2. Ambil respons sesuai bahasa (dari pengaturan aplikasi)
    String responseText = _getLocalizedResponse(
      intent: intent,
      language: appLanguage,
      ageCategory: ageCategory,
    );

    return ChatMessage(
      content: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      language: appLanguage, // simpan bahasa aktif aplikasi
      messageType: MessageType.text,
      confidence: result.confidence,
      intentId: intent,
      isVoice: false,
    );
  }

  static String _getLocalizedResponse({
    required String intent,
    required String language,
    required String ageCategory,
  }) {
    final responses = NlpKnowledgeBase.responses;

    if (responses.containsKey(intent)) {
      final intentResponses = responses[intent]!;

      if (intentResponses.containsKey(language)) {
        return intentResponses[language]!;
      }

      // Fallback ke id
      if (intentResponses.containsKey('id')) {
        return intentResponses['id']!;
      }
    }

    if (responses.containsKey('default')) {
      final def = responses['default']!;
      if (def.containsKey(language)) {
          return def[language]!;
      }
      if (def.containsKey('id')) {
          return def['id']!;
      }
    }

    return 'Maaf, saya kurang paham. Anda bisa bertanya tentang: status merapi, titik kumpul evakuasi, zona bahaya, atau nomor bantuan darurat.';
  }
}
