import 'package:string_similarity/string_similarity.dart';
import 'nlp_knowledge_base.dart';
import '../models/chat_message.dart';

class NlpEngine {
  /// Simple NLP processing using Cosine Similarity on character n-grams.
  /// Returns a record with detected Intent and Confidence Score.
  static ({String intent, double confidence}) detectIntent(String query) {
    if (query.trim().isEmpty) {
      return (intent: 'default', confidence: 0.0);
    }
    
    // 1. Lowercase and basic punctuation removal
    String normalizedQuery = _normalizeText(query);
    
    // 2. Translate regional words to Indonesian to help the matcher
    normalizedQuery = _translateRegionalWords(normalizedQuery);
    
    // 3. Match against all training phrases using string_similarity
    String bestIntent = 'default';
    double bestConfidence = 0.0;
    
    for (var entry in NlpKnowledgeBase.trainingPhrases.entries) {
      String intent = entry.key;
      List<String> phrases = entry.value;
      
      for (String phrase in phrases) {
        // Find similarities
        // Dice's coefficient is good for short conversational sentences mapping
        double sim = phrase.similarityTo(normalizedQuery);
        
        // Boost score if keyword exactly matches
        if (normalizedQuery.contains(phrase) || phrase.contains(normalizedQuery)) {
           sim += 0.3; 
           if (sim > 1.0) sim = 1.0;
        }

        if (sim > bestConfidence) {
          bestConfidence = sim;
          bestIntent = intent;
        }
      }
    }
    
    // Fallback if confidence is too low (< 0.25)
    if (bestConfidence < 0.25) {
      return (intent: 'default', confidence: bestConfidence);
    }
    
    return (intent: bestIntent, confidence: bestConfidence);
  }

  static String _normalizeText(String text) {
    return text.toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remove punctuation
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

  /// Generate a response based on NLP intent
  static ChatMessage processMessage(String text, {String language = 'id', bool isVoice = false}) {
    final result = detectIntent(text);
    final intent = result.intent;
    
    // Get localized response
    Map<String, String>? localizedResponses = NlpKnowledgeBase.responses[intent];
    String responseText;
    
    if (localizedResponses != null && localizedResponses.containsKey(language)) {
      responseText = localizedResponses[language]!;
    } else if (localizedResponses != null && localizedResponses.containsKey('id')) {
      responseText = localizedResponses['id']!;
    } else {
      responseText = NlpKnowledgeBase.responses['default']![language] ?? NlpKnowledgeBase.responses['default']!['id']!;
    }

    return ChatMessage(
      content: responseText,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.text,
      confidence: result.confidence,
      detectedIntent: intent,
      isVoice: false, // The bot's response is presented as text initially
    );
  }
}
