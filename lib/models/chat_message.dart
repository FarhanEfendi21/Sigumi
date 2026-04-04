/// Tipe pesan dalam chatbot
enum MessageType {
  text,
  voice,
  system,
}

/// Model untuk pesan dalam chatbot SIGUMI
class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;
  final MessageType messageType;
  final double? confidence;
  final String? detectedIntent;
  final bool isVoice;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'id',
    this.messageType = MessageType.text,
    this.confidence,
    this.detectedIntent,
    this.isVoice = false,
  });

  /// Membuat pesan system/info
  factory ChatMessage.system(String content, {String language = 'id'}) {
    return ChatMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.system,
    );
  }

  /// Label confidence dalam bahasa yang sesuai
  String get confidenceLabel {
    if (confidence == null) return '';
    if (confidence! >= 0.8) return '✅ Sangat Yakin';
    if (confidence! >= 0.6) return '🟡 Cukup Yakin';
    if (confidence! >= 0.4) return '🟠 Kurang Yakin';
    return '🔴 Tidak Yakin';
  }
}
