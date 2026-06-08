import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

/// Service Cloud LLM via Ollama Server (Gemma 4) — engine PRIMER chatbot SIGUMI.
///
/// Arsitektur Cloud-First:
/// ```
/// User Message → Ollama Server (Gemma 4) → respons generatif
///                        ↓ (gagal/offline)
///                  return null → ChatbotEngine fallback ke rule-based
/// ```
///
/// Fitur:
/// - Self-hosted Gemma 4 via Ollama (data tetap di server sendiri)
/// - Conversation history (maks 5 turn terakhir) untuk konteks percakapan
/// - Retry logic (1x retry dengan backoff) untuk mengatasi timeout sesaat
/// - Optional API key auth (untuk reverse proxy)
class CloudLlmService {
  static CloudLlmService? _instance;

  final String _baseUrl;
  final String _modelName;
  final String _apiKey;

  // ── Singleton factory ──
  static void init({
    required String baseUrl,
    required String modelName,
    String apiKey = '',
  }) {
    _instance = CloudLlmService._(
      baseUrl: baseUrl,
      modelName: modelName,
      apiKey: apiKey,
    );
    debugPrint('[CloudLLM] ✅ Initialized — Ollama at $baseUrl, model: $modelName');
  }

  static CloudLlmService? get instance => _instance;

  CloudLlmService._({
    required String baseUrl,
    required String modelName,
    String apiKey = '',
  })  : _baseUrl = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl,
        _modelName = modelName,
        _apiKey = apiKey;

  // ══════════════════════════════════════════════════════════════
  // SYSTEM PROMPT — Konteks kebencanaan SIGUMI
  // ══════════════════════════════════════════════════════════════

  static String _buildSystemPrompt(String language, String ageContext, String? locationContext) {
    final langInstruction = switch (language) {
      'en' => 'Respond in English.',
      'jv' => 'Respond in Javanese (Bahasa Jawa). Use polite krama or ngoko as appropriate.',
      'ba' => 'Respond in Balinese (Bahasa Bali). Use appropriate Balinese language levels (Alus, Madia, Kepara) matching the user\'s tone.',
      'sas' => 'Respond in Sasak (Bahasa Sasak Lombok). Use appropriate Sasak dialect and language levels.',
      _ => 'Respond in Indonesian (Bahasa Indonesia).',
    };

    final locContext = locationContext != null && locationContext.isNotEmpty
        ? '\nKONTEKS LOKASI USER SAAT INI:\n$locationContext\n'
        : '';

    return '''
Kamu adalah "Si Gumi", chatbot instruktur kesiapsiagaan bencana gunung berapi dan panduan pariwisata lokal pada aplikasi SIGUMI (Sistem Informasi Gunung Berapi Mitigasi).

$langInstruction

PERAN UTAMA:
- Edukasi & pelatihan mitigasi pra-bencana Gunung Merapi (Sleman/DIY), Gunung Agung/Batur (Bali), dan Gunung Rinjani (Lombok).
- Menjawab pertanyaan tentang SOP evakuasi, jadwal simulasi, tas siaga bencana, jalur evakuasi, mitigasi hujan abu, zona bahaya, status gunung, P3K, dan nomor darurat.
- Memberikan informasi pariwisata yang aman di sekitar daerah Sleman (wisata lereng Merapi seperti Kaliurang, Lava Tour), Bali (wisata budaya/pantai), dan Lombok (wisata Rinjani/pantai).
- Memberikan informasi yang akurat, ringkas, dan mudah dipahami.
$locContext
KONTEKS PENTING MITIGASI & PARIWISATA:
- Gunung Merapi: Sleman, DIY. Status Level I (Normal) s/d Level IV (Awas). Wisata aman jika di luar radius bahaya yang ditetapkan BPBD/BPPTKG. Wisata populer: Kaliurang, Candi Prambanan, Merapi Lava Tour.
- Gunung Agung & Batur: Bali. Wisata populer: Kuta, Ubud, Uluwatu, Kintamani (dekat Gunung Batur). Patuhi rambu peringatan setempat.
- Gunung Rinjani: Lombok, NTB. Wisata populer: Pendakian Rinjani, Pantai Senggigi, Gili Trawangan.
- Kontak darurat utama: BNPB (117), SAR (115), Ambulans (118), Polisi (110).

ATURAN RESPONS:
1. Jawab dengan singkat, ramah, dan terstruktur (gunakan bullet points/numbering).
2. Gunakan emoji yang sesuai untuk memperjelas informasi.
3. Fokus pada edukasi, pariwisata aman, dan kesiapsiagaan.
4. Jika pertanyaan di luar topik kebencanaan dan pariwisata, arahkan kembali dengan sopan ke topik yang relevan.
5. Jangan memberikan informasi medis detail — arahkan ke tenaga medis profesional.
6. Jangan membuat data/statistik yang tidak kamu ketahui.
7. Maksimal 300 kata per respons.

KONTEKS USIA USER:
$ageContext
''';
  }

  // ══════════════════════════════════════════════════════════════
  // GENERATE RESPONSE (with Conversation History & Retry)
  // ══════════════════════════════════════════════════════════════

  /// Kirim pesan ke Ollama Server (Gemma 4) dan dapatkan respons generatif.
  ///
  /// [conversationHistory] — opsional, maks 5 turn terakhir untuk konteks.
  /// Returns `null` jika gagal setelah retry (network error, server down, timeout).
  /// Caller harus fallback ke respons lokal jika null.
  Future<String?> generateResponse({
    required String userMessage,
    required String language,
    String ageCategory = 'dewasa',
    String? locationContext,
    List<ChatMessage>? conversationHistory,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    // Coba pertama
    final result = await _doRequest(
      userMessage: userMessage,
      language: language,
      ageCategory: ageCategory,
      locationContext: locationContext,
      conversationHistory: conversationHistory,
      timeout: timeout,
    );

    if (result != null) return result;

    // Retry 1x dengan backoff 1 detik
    debugPrint('[CloudLLM] 🔄 Retrying after 1s backoff...');
    await Future.delayed(const Duration(seconds: 1));

    return await _doRequest(
      userMessage: userMessage,
      language: language,
      ageCategory: ageCategory,
      locationContext: locationContext,
      conversationHistory: conversationHistory,
      timeout: timeout + const Duration(seconds: 10), // Tambah 10s untuk retry
    );
  }

  /// Eksekusi satu request ke Ollama API (`POST /api/chat`).
  Future<String?> _doRequest({
    required String userMessage,
    required String language,
    required String ageCategory,
    String? locationContext,
    List<ChatMessage>? conversationHistory,
    required Duration timeout,
  }) async {
    try {
      // Build age context
      final ageContext = switch (ageCategory) {
        'anak' => 'User adalah anak-anak (< 13 tahun). Gunakan bahasa yang sederhana, ceria, dan mudah dipahami. Gunakan analogi yang dekat dengan dunia anak.',
        'lansia' => 'User adalah lansia (> 60 tahun). Gunakan bahasa yang sopan, hormat, font yang jelas. Berikan instruksi step-by-step yang detail.',
        _ => 'User adalah dewasa. Gunakan bahasa yang profesional dan informatif.',
      };

      // Build messages array (system + history + current)
      final messages = _buildMessages(
        userMessage: userMessage,
        language: language,
        ageContext: ageContext,
        locationContext: locationContext,
        conversationHistory: conversationHistory,
      );

      final url = Uri.parse('$_baseUrl/api/chat');

      final body = jsonEncode({
        'model': _modelName,
        'messages': messages,
        'stream': false,
        'options': {
          'temperature': 0.7,
          'num_predict': 1024,
          'top_p': 0.9,
        },
      });

      debugPrint('[CloudLLM] 🌐 Sending request to Ollama ($url)...');

      // Build headers
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (_apiKey.isNotEmpty) {
        headers['Authorization'] = 'Bearer $_apiKey';
      }

      final response = await http.post(
        url,
        headers: headers,
        body: body,
      ).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final message = data['message'] as Map<String, dynamic>?;

        if (message != null) {
          final content = message['content'] as String?;
          if (content != null && content.trim().isNotEmpty) {
            debugPrint('[CloudLLM] ✅ Response received (${content.length} chars)');
            return content.trim();
          }
        }

        debugPrint('[CloudLLM] ⚠️ Empty response from Ollama');
        return null;
      } else {
        debugPrint('[CloudLLM] ❌ Server error: ${response.statusCode} — ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('[CloudLLM] ❌ Request failed: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MESSAGE BUILDER (Ollama Chat Format)
  // ══════════════════════════════════════════════════════════════

  /// Build Ollama messages array: system + conversation history + current message.
  ///
  /// Format Ollama:
  /// ```json
  /// [
  ///   {"role": "system", "content": "..."},
  ///   {"role": "user", "content": "..."},
  ///   {"role": "assistant", "content": "..."},
  ///   {"role": "user", "content": "current message"}
  /// ]
  /// ```
  List<Map<String, String>> _buildMessages({
    required String userMessage,
    required String language,
    required String ageContext,
    String? locationContext,
    List<ChatMessage>? conversationHistory,
  }) {
    final messages = <Map<String, String>>[];

    // 1. System prompt
    messages.add({
      'role': 'system',
      'content': _buildSystemPrompt(language, ageContext, locationContext),
    });

    // 2. Conversation history (maks 5 turn terakhir = 10 messages)
    if (conversationHistory != null && conversationHistory.isNotEmpty) {
      final recentHistory = conversationHistory.length > 10
          ? conversationHistory.sublist(conversationHistory.length - 10)
          : conversationHistory;

      for (final msg in recentHistory) {
        // Skip pesan sistem (welcome message dll)
        if (msg.messageType == MessageType.system) continue;

        messages.add({
          'role': msg.isUser ? 'user' : 'assistant',
          'content': msg.content,
        });
      }
    }

    // 3. Pesan user saat ini
    messages.add({
      'role': 'user',
      'content': userMessage,
    });

    return messages;
  }

  /// Cek apakah service tersedia (baseUrl ter-set).
  bool get isAvailable => _baseUrl.isNotEmpty;
}
