import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import '../../config/theme.dart';
import '../../config/fonts.dart';
import '../../config/theme_extensions.dart';
import '../../models/chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/voice_service.dart';
import '../../services/location_service.dart';
import '../../services/nlp_knowledge_base.dart';
import '../../providers/volcano_provider.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;

  // State untuk voice UI
  bool _isListening = false;
  bool _permissionChecked = false;

  // State untuk Voice Assistant Loop
  bool _isBotSpeaking = false;
  StreamSubscription<TtsState>? _ttsSubscription;

  // Animasi pulse untuk mic aktif
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Animasi wave bars saat merekam
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _initTts();
    _subscribeTtsState();

    // Setup animasi pulse mic
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    // Setup animasi wave bars
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Defer accessing Provider to avoid context errors in initState
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendWelcomeMessage();
    });
  }

  /// Init TTS saja dulu (tidak butuh permission khusus)
  Future<void> _initTts() async {
    await _voiceService.initTts();
  }

  /// Subscribe ke stream TTS state agar UI reaktif terhadap status bicara bot
  void _subscribeTtsState() {
    _ttsSubscription = _voiceService.ttsStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isBotSpeaking = state == TtsState.speaking;
      });
    });
  }

  /// Init speech recognition dengan handling permission yang proper
  /// Dipanggil saat user pertama kali tap tombol mic
  Future<bool> _initSpeechWithPermission() async {
    if (_voiceService.isSpeechEnabled) return true;

    // Tampilkan dialog info sebelum minta permission
    if (!_permissionChecked) {
      final shouldProceed = await _showPermissionInfoDialog();
      if (!shouldProceed) return false;
      _permissionChecked = true;
    }

    final status = await _voiceService.init();

    switch (status) {
      case SpeechPermissionStatus.granted:
        return true;

      case SpeechPermissionStatus.denied:
        if (mounted) {
          _showPermissionDeniedDialog();
        }
        return false;

      case SpeechPermissionStatus.error:
        if (mounted) {
          _showErrorSnackBar(
              'Terjadi kesalahan saat mengakses mikrofon. Coba lagi nanti.');
        }
        return false;
    }
  }

  /// Dialog informatif sebelum minta permission microphone
  Future<bool> _showPermissionInfoDialog() async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => Dialog(
            backgroundColor: dialogContext.bgSurface,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ikon mikrofon dengan background lingkaran
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: dialogContext.accentPrimary.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mic_rounded,
                      size: 36,
                      color: dialogContext.accentPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Text(
                    'Izin Akses Mikrofon',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: dialogContext.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Untuk menggunakan fitur voice input, Si Gumi memerlukan akses ke mikrofon perangkat Anda.\n\nSuara Anda hanya diproses untuk mengenali perintah dan tidak disimpan.',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 14,
                      color: dialogContext.textTertiary,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Tombol Izinkan
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton(
                      height: 48,
                      backgroundColor: dialogContext.accentPrimary,
                      onPressed: () => Navigator.of(dialogContext).pop(true),
                      child: Text(
                        'Izinkan Akses',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dialogContext.bgPrimary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tombol Nanti
                  SizedBox(
                    width: double.infinity,
                    child: ShadButton.outline(
                      height: 48,
                      onPressed: () => Navigator.of(dialogContext).pop(false),
                      child: Text(
                        'Nanti Saja',
                        style: AppFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: dialogContext.textTertiary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ) ??
        false;
  }

  /// Dialog ketika permission ditolak
  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: dialogContext.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Ikon warning
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: dialogContext.warningColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.mic_off_rounded,
                  size: 36,
                  color: dialogContext.warningColor,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Akses Mikrofon Ditolak',
                style: AppFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: dialogContext.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              Text(
                'Fitur voice input memerlukan akses ke mikrofon.\n\nAnda masih bisa mengetik pertanyaan secara manual. Untuk mengaktifkan mikrofon, buka Pengaturan > Izin Aplikasi.',
                style: AppFonts.plusJakartaSans(
                  fontSize: 14,
                  color: dialogContext.textTertiary,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ShadButton(
                  height: 48,
                  backgroundColor: dialogContext.accentPrimary,
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    'Mengerti',
                    style: AppFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: dialogContext.bgPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: AppFonts.plusJakartaSans(
            color: context.bgPrimary, 
            fontSize: 13
          ),
        ),
        backgroundColor: context.errorColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _sendWelcomeMessage() {
    final provider = context.read<VolcanoProvider>();
    final user = provider.currentUser;
    final currentAppLanguage = provider.language;
    setState(() {
      _messages.add(ChatMessage.system(
        '${AiService.getWelcomeMessage(currentAppLanguage, user: user)}\n\nℹ️ Chatbot merespons menggunakan bahasa aplikasi yang Anda pilih di menu Pengaturan.',
      ));
    });
  }

  @override
  void dispose() {
    _ttsSubscription?.cancel();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _voiceService.dispose();
    _messageController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _sendMessage({bool isVoice = false}) async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentAppLanguage = context.read<VolcanoProvider>().language;

    setState(() {
      _messages.add(ChatMessage(
        content: text,
        isUser: true,
        timestamp: DateTime.now(),
        language: currentAppLanguage,
        isVoice: isVoice,
        isVoiceInput: isVoice,
      ));
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Voice Service stop
    if (_voiceService.isListening) {
      await _voiceService.stopListening();
      _stopListeningUI();
    }

    // Simulate thinking delay
    Future.delayed(const Duration(milliseconds: 1000), () async {
      if (mounted) {
        // Ambil data user dan lokasi untuk personalisasi chatbot
        final provider = context.read<VolcanoProvider>();
        final user = provider.currentUser;
        final locationService = LocationService();

        final response = await AiService.getResponse(
          text,
          languageCode: currentAppLanguage,
          isVoice: isVoice,
          user: user,
          userLat: locationService.userLat,
          userLng: locationService.userLng,
        );
        setState(() {
          _messages.add(response);
          _isTyping = false;
        });
        _scrollToBottom();

        // ══════════════════════════════════════════════════
        // VOICE ASSISTANT LOOP — Auto-TTS untuk voice input
        // ══════════════════════════════════════════════════
        // Jika pesan user sebelumnya berasal dari suara (isVoiceInput == true),
        // otomatis bacakan respons bot via TTS.
        // Jika user mengetik (isVoiceInput == false), TTS TIDAK otomatis.
        if (isVoice && mounted) {
          final displayContent = _getDisplayContent(response, currentAppLanguage);
          await _voiceService.speak(
            displayContent,
            language: currentAppLanguage,
            onCompletion: () {
              if (mounted) {
                setState(() {
                  _isBotSpeaking = false;
                });
              }
            },
          );
        }
      }
    });
  }

  /// Memulai/menghentikan pengenalan suara dengan visual feedback
  Future<void> _toggleListening() async {
    if (_isListening) {
      // Berhenti mendengarkan
      await _voiceService.stopListening();
      _stopListeningUI();
    } else {
      // Mulai Voice Assistant Loop
      await _startVoiceAssistantLoop();
    }
  }

  /// Voice Assistant Loop — Alur lengkap:
  /// 1. Cek permission → 2. Stop TTS jika sedang bicara →
  /// 3. Mulai STT → 4. Saat final result → kirim pesan (isVoice: true) →
  /// 5. _sendMessage() akan auto-trigger TTS untuk respons bot.
  Future<void> _startVoiceAssistantLoop() async {
    // Cek & minta permission dulu (hanya pertama kali)
    final hasPermission = await _initSpeechWithPermission();
    if (!hasPermission) return;

    // Stop ongoing TTS when user starts speaking
    await _voiceService.stopSpeaking();

    // Gunakan locale sesuai bahasa aplikasi
    final currentLang = context.read<VolcanoProvider>().language;
    String localeId = 'id_ID';
    if (currentLang == 'en') localeId = 'en_US';
    // Regional languages (jv, ba, sas) tetap gunakan id_ID karena 
    // STT engine umumnya tidak support bahasa daerah

    _startListeningUI();

    await _voiceService.startListening(
      // Callback partial results — update text field secara real-time
      (recognizedText) {
        if (mounted) {
          setState(() {
            _messageController.text = recognizedText;
          });
        }
      },
      localeId: localeId,
      // Callback final result — STT selesai, kirim pesan
      onFinalResult: (finalText) {
        if (mounted && finalText.isNotEmpty) {
          _stopListeningUI();
          _sendMessage(isVoice: true);
        }
      },
    );
  }

  /// Aktifkan animasi dan state saat mulai mendengarkan
  void _startListeningUI() {
    setState(() {
      _isListening = true;
    });
    _pulseController.repeat();
    _waveController.repeat(reverse: true);
  }

  /// Matikan animasi dan state saat selesai mendengarkan
  void _stopListeningUI() {
    setState(() {
      _isListening = false;
    });
    _pulseController.stop();
    _pulseController.reset();
    _waveController.stop();
    _waveController.reset();
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

  void _quickSend(String text) {
    _messageController.text = text;
    _sendMessage();
  }

  String _getListeningText(String lang) {
    switch(lang) {
      case 'en': return 'Listening...';
      case 'jv': return 'Ngrungokake...';
      case 'ba': return 'Mirengang...';
      case 'sas': return 'Mendengaq...';
      default: return 'Mendengarkan...';
    }
  }

  String _getSpeakClearlyText(String lang) {
    switch(lang) {
      case 'en': return 'Please speak clearly';
      case 'jv': return 'Tulung ngomong sing cetha';
      case 'ba': return 'Durus mabaos sane tatas';
      case 'sas': return 'Silaq bebaos saq jelas';
      default: return 'Silakan bicara dengan jelas';
    }
  }

  String _getAskPlaceholder(String lang) {
    switch(lang) {
      case 'en': return 'Ask Si Gumi...';
      case 'jv': return 'Takon Si Gumi...';
      case 'ba': return 'Takon Si Gumi...';
      case 'sas': return 'Betakon Si Gumi...';
      default: return 'Tanya Si Gumi...';
    }
  }

  String _getListeningPlaceholder(String lang) {
    switch(lang) {
      case 'en': return 'Listening to voice...';
      case 'jv': return 'Ngrungokake swara...';
      case 'ba': return 'Mirengang swara...';
      case 'sas': return 'Mendengaq suare...';
      default: return 'Mendengarkan suara...';
    }
  }

  String _getDisplayContent(ChatMessage message, String currentLang) {
    if (message.intentId != null) {
      final responses = NlpKnowledgeBase.responses[message.intentId];
      if (responses != null) {
        // Khusus untuk intent evakuasi dinamis yang dikalkulasi AiService, kita biarkan text aslinya.
        // Namun, respons dinamis ini dirender sekali. Untuk reactivity penuh pada respons dinamis, 
        // lebih baik logic format berada di tingkat widget state jika memungkinkan.
        // Di sini kita proteksi agar tidak tertimpa teks statis:
        if (message.intentId == 'evakuasi' && message.content.contains('km')) {
          return message.content; 
        }

        String baseContent = message.content;
        if (responses.containsKey(currentLang)) {
          baseContent = responses[currentLang]!;
        } else if (responses.containsKey('id')) {
          baseContent = responses['id']!;
        }
        
        if (message.messageType == MessageType.system && message.intentId == 'salam') {
          return '$baseContent\n\nℹ️ Chatbot merespons menggunakan bahasa aplikasi yang Anda pilih di menu Pengaturan.';
        }
        return baseContent;
      }
    }
    return message.content;
  }

  @override
  Widget build(BuildContext context) {
    final currentAppLanguage = context.watch<VolcanoProvider>().language;
    final quickActions = NlpKnowledgeBase.quickActionLabels[currentAppLanguage] ?? 
                         NlpKnowledgeBase.quickActionLabels['id']!;

    return Scaffold(
      backgroundColor: context.bgSecondary,
      appBar: AppBar(
        backgroundColor: context.bgPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Tanya Si Gumi',
              style: AppFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 18,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: context.successColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: context.successColor.withValues(alpha: 0.3),
                  width: context.borderWidth,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: context.successColor,
                      shape: BoxShape.circle,
                    ),
                  )
                      .animate(
                          onPlay: (controller) =>
                              controller.repeat(reverse: true))
                      .fade(duration: 800.ms, begin: 0.3, end: 1.0),
                  const SizedBox(width: 4),
                  Text(
                    'Aktif',
                    style: AppFonts.plusJakartaSans(
                      color: context.successColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: context.borderWidth,
            color: context.dividerColor,
          ),
        ),
      ),
      body: Column(
        children: [
          // Chat messages area
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
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

          // Listening Overlay — Tampil saat mic aktif
          if (_isListening) _buildListeningOverlay(currentAppLanguage),

          // Bot Speaking Overlay — Tampil saat TTS sedang membacakan respons
          if (_isBotSpeaking) _buildBotSpeakingOverlay(currentAppLanguage),

          // Quick Actions (Horizontal Scroll)
          Container(
            color: context.bgPrimary,
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: quickActions.map((action) {
                  return _QuickActionButton(
                    action['label']!,
                    () => _quickSend(action['message']!),
                  );
                }).toList(),
              ),
            ),
          ),

          // Input Area Bottom Bar
          _buildInputBar(context, currentAppLanguage),
        ],
      ),
    );
  }

  /// Widget overlay saat mic sedang mendengarkan — tampilkan visual feedback
  Widget _buildListeningOverlay(String appLanguage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            context.accentPrimary.withValues(alpha: 0.05),
            context.errorColor.withValues(alpha: 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: Border(
          top: BorderSide(
            color: context.dividerColor, 
            width: context.borderWidth,
          ),
          bottom: BorderSide(
            color: context.dividerColor, 
            width: context.borderWidth,
          ),
        ),
      ),
      child: Row(
        children: [
          // Animated mic icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.errorColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.mic_rounded,
              color: context.errorColor,
              size: 20,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 600.ms,
              ),

          const SizedBox(width: 12),

          // "Listening" text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getListeningText(appLanguage),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: context.errorColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _getSpeakClearlyText(appLanguage),
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: context.textTertiary,
                  ),
                ),
              ],
            ),
          ),

          // Wave bars animasi
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (i) {
              return AnimatedBuilder(
                animation: _waveController,
                builder: (context, child) {
                  // Setiap bar punya tinggi yang berbeda berdasarkan offset-nya
                  final value = (_waveController.value + i * 0.15) % 1.0;
                  final height = 8.0 + (value * 16.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    width: 3,
                    height: height,
                    decoration: BoxDecoration(
                      color: context.errorColor.withValues(
                          alpha: 0.5 + value * 0.5),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                },
              );
            }),
          ),

          const SizedBox(width: 12),

          // Tombol stop
          GestureDetector(
            onTap: _toggleListening,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.errorColor,
                shape: BoxShape.circle,
                boxShadow: context.cardShadow,
              ),
              child: Icon(
                Icons.stop_rounded,
                color: context.bgPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  /// Widget overlay saat bot sedang membacakan respons via TTS
  Widget _buildBotSpeakingOverlay(String appLanguage) {
    final speakingText = appLanguage == 'en' ? 'Si Gumi is speaking...' : 'Si Gumi sedang berbicara...';
    final tapToStopText = appLanguage == 'en' ? 'Tap to stop' : 'Ketuk untuk berhenti';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            SigumiTheme.primaryBlue.withValues(alpha: 0.06),
            Colors.purple.withValues(alpha: 0.04),
          ],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        border: const Border(
          top: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
          bottom: BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Animated speaker icon
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: SigumiTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.volume_up_rounded,
              color: SigumiTheme.primaryBlue,
              size: 20,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                begin: const Offset(0.9, 0.9),
                end: const Offset(1.1, 1.1),
                duration: 600.ms,
              ),

          const SizedBox(width: 12),

          // "Bot is Speaking" text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  speakingText,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: SigumiTheme.primaryBlue,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tapToStopText,
                  style: AppFonts.plusJakartaSans(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),

          // Wave bars animasi untuk TTS
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(5, (i) {
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                width: 3,
                height: 12,
                decoration: BoxDecoration(
                  color: SigumiTheme.primaryBlue.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(2),
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleY(
                    begin: 0.4,
                    end: 1.0,
                    duration: Duration(milliseconds: 400 + i * 100),
                    curve: Curves.easeInOut,
                  );
            }),
          ),

          const SizedBox(width: 12),

          // Tombol stop TTS
          GestureDetector(
            onTap: () async {
              await _voiceService.stopSpeaking();
              if (mounted) {
                setState(() {
                  _isBotSpeaking = false;
                });
              }
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: SigumiTheme.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: SigumiTheme.primaryBlue.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stop_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.1, end: 0);
  }

  /// Input bar (bottom) dengan mic button yang sudah diupgrade
  Widget _buildInputBar(BuildContext context, String appLanguage) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: 12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.bgPrimary,
        border: Border(
          top: BorderSide(
            color: context.dividerColor, 
            width: context.borderWidth,
          ),
        ),
        boxShadow: context.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Mic Button — dengan pulse & warna dinamis
          _buildMicButton(),

          const SizedBox(width: 8),

          // Text Input Field
          Expanded(
            child: ShadInput(
              controller: _messageController,
              placeholder: Text(
                  _isListening ? _getListeningPlaceholder(appLanguage) : _getAskPlaceholder(appLanguage)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: context.textPrimary,
              ),
              placeholderStyle: AppFonts.plusJakartaSans(
                fontSize: 14,
                color: _isListening
                    ? context.errorColor
                    : context.textTertiary,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Send Button
          ShadButton(
            width: 48,
            height: 48,
            padding: EdgeInsets.zero,
            backgroundColor: context.accentPrimary,
            onPressed: () => _sendMessage(),
            child: Icon(
              Icons.send_rounded, 
              color: context.bgPrimary, 
              size: 20
            ),
          ),
        ],
      ),
    );
  }

  /// Tombol mic dengan 3 layer visual:
  /// 1. Pulse ring (outer glow saat aktif)
  /// 2. Background tombol (berubah warna)
  /// 3. Icon mic (berubah state)
  Widget _buildMicButton() {
    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: Pulse ring — hanya tampil saat listening
          if (_isListening)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  width: 48 * _pulseAnimation.value,
                  height: 48 * _pulseAnimation.value,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: context.errorColor
                        .withValues(alpha: 0.3 * (2 - _pulseAnimation.value)),
                  ),
                );
              },
            ),

          // Layer 2: Tombol utama
          ShadButton.outline(
            width: 48,
            height: 48,
            padding: EdgeInsets.zero,
            backgroundColor:
                _isListening ? context.errorColor.withValues(alpha: 0.1) : context.bgPrimary,
            onPressed: _toggleListening,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                color: _isListening
                    ? context.errorColor
                    : context.textTertiary,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final actLang = context.read<VolcanoProvider>().language;
    final displayContent = _getDisplayContent(message, actLang);

    if (message.messageType == MessageType.system) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
              ),
              boxShadow: context.cardShadow,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: context.accentPrimary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 14, 
                    color: context.accentPrimary
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    displayContent,
                    style: AppFonts.plusJakartaSans(
                      fontSize: 12,
                      color: context.textTertiary,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
        ),
      );
    }

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot Avatar
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: context.bgSurface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.borderColor,
                  width: context.borderWidth,
                ),
                boxShadow: context.cardShadow,
              ),
              child: ClipOval(
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Image.asset(
                    'assets/images/SIGUMI-logo.png',
                    errorBuilder: (ctx, err, stack) => Icon(
                        Icons.smart_toy_rounded,
                        size: 20,
                        color: context.accentPrimary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],

          // Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? context.accentPrimary : context.bgSurface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: isUser
                    ? null
                    : Border.all(
                        color: context.borderColor,
                        width: context.borderWidth,
                      ),
                boxShadow: context.cardShadow,
              ),
              child: Column(
                crossAxisAlignment:
                    isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (message.isVoice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.mic_rounded,
                            size: 14,
                            color: isUser
                                ? context.bgPrimary.withValues(alpha: 0.7)
                                : context.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Pesan Suara',
                            style: AppFonts.plusJakartaSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isUser
                                  ? context.bgPrimary.withValues(alpha: 0.7)
                                  : context.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Text(
                    displayContent,
                    style: AppFonts.plusJakartaSans(
                      color: isUser ? context.bgPrimary : context.textPrimary,
                      fontSize: 14,
                      height: 1.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (!isUser) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: context.borderWidth,
                      color: context.dividerColor,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Theme(
                          data: Theme.of(context).copyWith(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: InkWell(
                            onTap: () async {
                               // Manual tts
                               await _voiceService.speak(displayContent, language: message.language);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.volume_up_rounded, 
                                    size: 16, 
                                    color: context.accentPrimary
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Dengarkan',
                                    style: AppFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: context.accentPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        if (message.language != 'id') ...[
                           const SizedBox(width: 12),
                           Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: context.accentPrimary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                message.language.toUpperCase(),
                                style: AppFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: context.accentPrimary,
                                ),
                              ),
                           ),
                        ]
                      ],
                    ),
                  ],
                ],
              ),
            ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0),
          ),

          if (isUser)
            const SizedBox(width: 4), // Small padding from edge
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: context.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
              ),
            ),
            child: Icon(
              Icons.smart_toy_rounded,
              size: 20, 
              color: context.accentPrimary
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: context.bgSurface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(
                color: context.borderColor,
                width: context.borderWidth,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: context.textTertiary,
                    shape: BoxShape.circle,
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: 0,
                      end: -4,
                      duration: 400.ms,
                      delay: Duration(milliseconds: i * 150),
                      curve: Curves.easeInOut,
                    )
                    .then()
                    .moveY(
                      begin: -4,
                      end: 0,
                      duration: 400.ms,
                      curve: Curves.easeInOut,
                    );
              }),
            ),
          ).animate().fadeIn(duration: 200.ms),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickActionButton(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: ShadButton.outline(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        onPressed: onTap,
        backgroundColor: context.bgSurface,
        child: Text(
          label,
          style: AppFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ),
    );
  }
}
