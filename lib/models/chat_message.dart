class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String language;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.language = 'id',
  });
}
