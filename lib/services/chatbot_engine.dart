import 'package:flutter/material.dart';
import 'cloud_llm_service.dart';
import 'connectivity_service.dart';
import 'rule_based_fallback.dart';
import '../models/chat_message.dart';

/// Engine chatbot SIGUMI — Cloud LLM primary + Rule-Based fallback.
///
/// Arsitektur:
/// ```
/// User Message → Cek Internet
///   ├── ONLINE  → Cloud LLM (Ollama/Gemma 4) → sukses? → return ☁️
///   │                                        → gagal?  → Rule-Based fallback ⚠️
///   └── OFFLINE → Rule-Based fallback langsung 📱
/// ```
///
/// Tidak ada TFLite, tidak ada ML dependency. Ringan.
class ChatbotEngine {
  /// Proses pesan user — Cloud-first, rule-based failsafe.
  ///
  /// Returns ChatMessage respons bot.
  static Future<ChatMessage> processMessage(
    String text, {
    required String appLanguage,
    bool isVoice = false,
    String ageCategory = 'dewasa',
    String? locationContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    // ══════════════════════════════════════════════════════════
    // STEP 1: Coba Cloud LLM (Primary)
    // ══════════════════════════════════════════════════════════
    final hasInternet = await ConnectivityService.hasInternet();

    if (hasInternet) {
      debugPrint('[ChatbotEngine] 🌐 Online — trying Cloud LLM...');

      final cloudResponse = await _tryCloudLlm(
        userMessage: text,
        language: appLanguage,
        ageCategory: ageCategory,
        locationContext: locationContext,
        conversationHistory: conversationHistory,
      );

      if (cloudResponse != null) {
        debugPrint('[ChatbotEngine] ☁️ Cloud LLM response received');
        return ChatMessage(
          content: cloudResponse,
          isUser: false,
          timestamp: DateTime.now(),
          language: appLanguage,
          messageType: MessageType.text,
          confidence: 1.0,
          intentId: 'cloud_llm',
          isVoice: false,
          responseSource: ResponseSource.cloud,
        );
      }

      // Cloud gagal — fallback
      debugPrint('[ChatbotEngine] ⚠️ Cloud LLM failed, using rule-based fallback');
      return _buildFallbackResponse(text, appLanguage, ResponseSource.localFallback);
    }

    // ══════════════════════════════════════════════════════════
    // STEP 2: Offline → Rule-Based langsung
    // ══════════════════════════════════════════════════════════
    debugPrint('[ChatbotEngine] 📱 Offline — using rule-based fallback');
    return _buildFallbackResponse(text, appLanguage, ResponseSource.localRuleBased);
  }

  /// Coba Cloud LLM. Return null jika gagal.
  static Future<String?> _tryCloudLlm({
    required String userMessage,
    required String language,
    required String ageCategory,
    String? locationContext,
    List<ChatMessage>? conversationHistory,
  }) async {
    final cloudService = CloudLlmService.instance;
    if (cloudService == null || !cloudService.isAvailable) {
      debugPrint('[ChatbotEngine] ☁️ Cloud LLM not initialized, skipping');
      return null;
    }

    try {
      return await cloudService.generateResponse(
        userMessage: userMessage,
        language: language,
        ageCategory: ageCategory,
        locationContext: locationContext,
        conversationHistory: conversationHistory,
      );
    } catch (e) {
      debugPrint('[ChatbotEngine] ❌ Cloud LLM error: $e');
      return null;
    }
  }

  /// Build rule-based fallback response.
  static ChatMessage _buildFallbackResponse(
    String userMessage,
    String language,
    ResponseSource source,
  ) {
    final response = RuleBasedFallback.getResponse(
      userMessage: userMessage,
      language: language,
    );

    // Override response source based on context
    return ChatMessage(
      content: response.content,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.text,
      intentId: response.intentId,
      isVoice: false,
      responseSource: source,
    );
  }
}
