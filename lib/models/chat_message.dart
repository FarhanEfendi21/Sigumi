/// Tipe pesan dalam chat
enum MessageType {
  text,   // Pesan biasa dari bot
  system, // Pesan sistem (welcome, info)
  user,   // Pesan dari pengguna
}

/// Sumber respons chatbot — untuk tracking dan UI badge.
///
/// - [cloud]: Respons dari Cloud LLM (Ollama) ☁️
/// - [localRuleBased]: Respons dari rule-based fallback karena offline 📱
/// - [localFallback]: Respons rule-based karena Cloud LLM gagal/error ⚠️
enum ResponseSource {
  cloud,            // ☁️ Dijawab oleh AI Cloud
  localRuleBased,   // 📱 Dijawab offline (rule-based)
  localFallback,    // ⚠️ Cloud gagal, fallback ke rule-based
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;
  final MessageType messageType;
  final bool isVoice;
  /// Menandai bahwa pesan ini berasal dari input suara (bukan ketikan).
  /// Digunakan oleh Voice Assistant Loop untuk menentukan apakah
  /// bot harus otomatis membacakan respons via TTS.
  final bool isVoiceInput;
  final double? confidence;
  final String? intentId;

  /// Sumber respons: cloud, localRuleBased, atau localFallback.
  /// Null untuk pesan user atau pesan sistem.
  final ResponseSource? responseSource;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'id',
    this.messageType = MessageType.text,
    this.isVoice = false,
    this.isVoiceInput = false,
    this.confidence,
    this.intentId,
    this.responseSource,
  });

  /// Factory constructor untuk pesan sistem (welcome, info, dll.)
  factory ChatMessage.system(String content, {String language = 'id'}) {
    return ChatMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.system,
      intentId: 'salam', // history intentId untuk pesan selamat datang
    );
  }

  /// Label confidence level untuk ditampilkan di UI
  String get confidenceLabel {
    if (confidence == null) return '';
    if (confidence! >= 0.8) return 'Sangat Yakin';
    if (confidence! >= 0.6) return 'Yakin';
    if (confidence! >= 0.4) return 'Cukup Yakin';
    if (confidence! >= 0.25) return 'Kurang Yakin';
    return 'Tidak Yakin';
  }

  /// Label sumber respons untuk ditampilkan di UI
  String get sourceLabel {
    switch (responseSource) {
      case ResponseSource.cloud:
        return '☁️ AI Cloud';
      case ResponseSource.localRuleBased:
        return '📱 Offline';
      case ResponseSource.localFallback:
        return '⚠️ Fallback Lokal';
      default:
        return '';
    }
  }
}
