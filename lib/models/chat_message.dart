/// Tipe pesan dalam chat
enum MessageType {
  text,   // Pesan biasa dari bot
  system, // Pesan sistem (welcome, info)
  user,   // Pesan dari pengguna
}

class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;
  final MessageType messageType;
  final bool isVoice;
  final double? confidence;
  final String? detectedIntent;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'id',
    this.messageType = MessageType.text,
    this.isVoice = false,
    this.confidence,
    this.detectedIntent,
  });

  /// Factory constructor untuk pesan sistem (welcome, info, dll.)
  factory ChatMessage.system(String content, {String language = 'id'}) {
    return ChatMessage(
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      language: language,
      messageType: MessageType.system,
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
}
