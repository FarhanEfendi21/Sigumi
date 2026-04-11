import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../config/constants.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';
import '../../providers/volcano_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String _selectedLanguage = 'id';

  @override
  void initState() {
    super.initState();
    _initVoiceService();
    
    // Defer accessing Provider to avoid context errors in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _selectedLanguage = context.read<VolcanoProvider>().language;
      _sendWelcomeMessage();
    });
  }

  Future<void> _initVoiceService() async {
    await _voiceService.init();
    setState(() {});
  }

  void _sendWelcomeMessage() {
    setState(() {
      _messages.add(ChatMessage.system(
        AiService.getWelcomeMessage(_selectedLanguage) +
        '\n\nℹ️ Chatbot ini memahami bahasa Indonesia, English, Jawa, Sunda, dan Bali. Anda bebas mengetik atau menggunakan suara.',
        language: _selectedLanguage,
      ));
    });
    // Auto speak welcome if TTS is desired (optional, maybe not on start to avoid startling)
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage({bool isVoice = false}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
        language: _selectedLanguage,
        isVoice: isVoice,
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Voice Service stop
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
    }

    // Simulate thinking delay
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (mounted) {
        final response = AiService.getResponse(text, language: _selectedLanguage, isVoice: isVoice);
        setState(() {
          _messages.add(response);
          _isTyping = false;
        });
        _scrollToBottom();
        
        // Speak response using TTS
        await _voiceService.speak(response.content, language: _selectedLanguage);
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      setState(() {});
    } else {
      if (!_voiceService.isSpeechEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Akses mikrofon ditolak atau tidak tersedia.')),
        );
        return;
      }
      
      // Stop ongoing TTS when user starts speaking
      await _voiceService.stopSpeaking();
      
      String localeId = _selectedLanguage == 'en' ? 'en_US' : 'id_ID';

      await _voiceService.startListening(
        (recognizedText) {
          setState(() {
            _messageController.text = recognizedText;
          });
          // Send immediately if the user stops speaking
          if (!_voiceService.isListening && recognizedText.isNotEmpty) {
            _sendMessage(isVoice: true);
          }
        },
        localeId: localeId,
      );
      setState(() {}); // Update mic icon
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Chatbot SIGUMI'),
        actions: [
          _buildLanguageDropdown(),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: SigumiTheme.primaryBlue.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.info_outline, size: 16, color: SigumiTheme.primaryBlue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Chatbot ini dilengkapi fitur NLP, Voice Command, dan Text-to-Speech.',
                    style: TextStyle(
                      fontSize: 11,
                      color: SigumiTheme.primaryBlue.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isTyping ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isTyping) {
                  return _buildTypingIndicator();
                }
                final message = _messages[index];
                return _buildMessageBubble(message, index);
              },
            ),
          ),

          // Quick actions
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                _QuickAction('Status', () => _quickSend('status merapi sekarang?')),
                _QuickAction('Evakuasi', () => _quickSend('jalur evakuasi mana?')),
                _QuickAction('Zona', () => _quickSend('berapa zona bahayanya?')),
                _QuickAction('P3K', () => _quickSend('pertolongan pertama jika kena abu')),
                _QuickAction('Abu', () => _quickSend('tips hujan abu vulkanik')),
                _QuickAction('Bantuan', () => _quickSend('nomor telepon bantuan darurat')),
              ],
            ),
          ),

          // Input
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Microphone Button
                  GestureDetector(
                    onTap: _toggleListening,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _voiceService.isListening 
                            ? SigumiTheme.statusAwas 
                            : SigumiTheme.primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _voiceService.isListening ? Icons.mic : Icons.mic_none,
                        color: _voiceService.isListening 
                            ? Colors.white 
                            : SigumiTheme.primaryBlue,
                        size: 24,
                      ),
                    ).animate(target: _voiceService.isListening ? 1 : 0)
                     .scale(end: const Offset(1.2, 1.2), duration: 200.ms),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_voiceService.isListening,
                      decoration: InputDecoration(
                        hintText: _voiceService.isListening ? 'Mendengarkan...' : 'Ketik kalimat...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: SigumiTheme.background,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                      ),
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      color: SigumiTheme.primaryBlue,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => _sendMessage(),
                      icon: const Icon(Icons.send_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _quickSend(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  Widget _buildLanguageDropdown() {
    return Container(
      margin: const EdgeInsets.only(right: 12, top: 12, bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedLanguage,
        dropdownColor: SigumiTheme.primaryBlue,
        icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        underline: const SizedBox(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedLanguage = newValue;
              _voiceService.stopSpeaking();
            });
          }
        },
        items: AppConstants.supportedLanguages.keys.map<DropdownMenuItem<String>>((String key) {
          return DropdownMenuItem<String>(
            value: key,
            child: Text(
              key.toUpperCase(),
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: message.messageType == MessageType.system 
                    ? SigumiTheme.statusWaspada.withOpacity(0.2)
                    : SigumiTheme.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                message.messageType == MessageType.system ? Icons.info : Icons.smart_toy,
                size: 18, 
                color: message.messageType == MessageType.system 
                    ? SigumiTheme.statusSiaga 
                    : SigumiTheme.primaryBlue
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? SigumiTheme.primaryBlue
                        : message.messageType == MessageType.system 
                           ? SigumiTheme.surface
                           : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 16),
                    ),
                    border: message.messageType == MessageType.system
                        ? Border.all(color: SigumiTheme.statusWaspada, width: 1)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: message.isUser 
                        ? CrossAxisAlignment.end 
                        : CrossAxisAlignment.start,
                    children: [
                      if (message.isVoice)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.mic, size: 12, color: message.isUser ? Colors.white70 : SigumiTheme.textSecondary),
                              const SizedBox(width: 4),
                              Text('Pesan Suara', style: TextStyle(fontSize: 10, color: message.isUser ? Colors.white70 : SigumiTheme.textSecondary)),
                            ],
                          ),
                        ),
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser ? Colors.white : SigumiTheme.textPrimary,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                // Confidence Badge for Bot Responses
                if (!message.isUser && message.confidence != null && message.messageType != MessageType.system)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Text(
                      'Match: ${(message.confidence! * 100).toStringAsFixed(0)}% • ${message.confidenceLabel}',
                      style: TextStyle(
                        fontSize: 10,
                        color: SigumiTheme.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy,
                size: 18, color: SigumiTheme.primaryBlue),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: SigumiTheme.primaryBlue.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: 0,
                      end: -6,
                      duration: 500.ms,
                      delay: Duration(milliseconds: i * 150),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .moveY(
                      begin: -6,
                      end: 0,
                      duration: 500.ms,
                      curve: Curves.easeInOut,
                    );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickAction(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: SigumiTheme.primaryBlue.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SigumiTheme.primaryBlue.withOpacity(0.2)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: SigumiTheme.primaryBlue,
          ),
        ),
      ),
    );
  }
}
