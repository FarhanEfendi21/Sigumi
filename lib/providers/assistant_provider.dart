import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../models/user_model.dart';

/// State siklus hidup Global Voice Assistant.
///
/// ```
/// ┌──────────────────────────────────────────────┐
/// │  IDLE ──(wake word)──► LISTENING_COMMAND      │
/// │    ▲                         │                │
/// │    │                    (STT selesai)          │
/// │    │                         ▼                │
/// │    │                    PROCESSING             │
/// │    │                         │                │
/// │    │                    (NLP response)         │
/// │    │                         ▼                │
/// │    └─────(TTS done)──── SPEAKING              │
/// └──────────────────────────────────────────────┘
/// ```
enum AssistantState {
  /// Mendengarkan wake word di background (tflite_audio aktif)
  idle,

  /// Wake word terdeteksi, sedang merekam perintah user (STT aktif)
  listeningCommand,

  /// Perintah diterima, sedang diproses oleh NLP/AiService
  processing,

  /// Bot sedang berbicara (TTS aktif)
  speaking,

  /// Asisten dinonaktifkan (user matikan atau error)
  disabled,
}

/// Provider global yang mengontrol siklus hidup Voice Assistant.
///
/// Lifecycle:
/// 1. [initAssistant] — load model TFLite Audio & mulai dengar wake word.
/// 2. Wake word terdeteksi → [_onWakeWordDetected]
/// 3. Beep → STT command → NLP → TTS response → kembali ke wake word.
///
/// Provider ini TIDAK mengelola chat messages UI (itu tetap di ChatbotScreen).
/// Provider ini HANYA mengelola siklus hands-free global.
class GlobalAssistantProvider extends ChangeNotifier {
  final VoiceService _voiceService = VoiceService();

  // ── State ──
  AssistantState _state = AssistantState.disabled;
  AssistantState get state => _state;

  String _lastCommand = '';
  String get lastCommand => _lastCommand;

  String _lastResponse = '';
  String get lastResponse => _lastResponse;

  bool _isEnabled = false;
  bool get isEnabled => _isEnabled;

  // ── Bahasa mengikuti state aplikasi, di-inject dari luar ──
  String _language = 'id';
  String get language => _language;

  // ── User & Location (di-inject untuk personalisasi) ──
  UserModel? _currentUser;
  double? _userLat;
  double? _userLng;

  // ══════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════

  /// Inisialisasi assistant: load model + init TTS + init STT.
  /// Panggil dari widget top-level (misal di MainNavigation atau Home).
  Future<void> initAssistant({
    required String language,
    UserModel? user,
    double? userLat,
    double? userLng,
  }) async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  🎤 GLOBAL VOICE ASSISTANT - INIT START  ║');
    debugPrint('╚══════════════════════════════════════════╝');

    _language = language;
    _currentUser = user;
    _userLat = userLat;
    _userLng = userLng;

    // Step 1: Init TTS
    debugPrint('[Assistant] Step 1/3: Initializing TTS...');
    await _voiceService.initTts();
    debugPrint('[Assistant] Step 1/3: ✅ TTS initialized');

    // Step 2: Init STT (minta permission jika belum)
    debugPrint('[Assistant] Step 2/3: Initializing STT...');
    await _voiceService.init();
    debugPrint('[Assistant] Step 2/3: ✅ STT initialized (speech enabled: ${_voiceService.isSpeechEnabled})');

    // Step 3: Init TFLite Audio wake word model
    debugPrint('[Assistant] Step 3/3: Loading Wake Word model...');
    await _voiceService.initWakeWord();
    debugPrint('[Assistant] Step 3/3: Model loaded: ${_voiceService.isWakeWordModelLoaded}');

    if (_voiceService.isWakeWordModelLoaded) {
      _isEnabled = true;
      debugPrint('[Assistant] 🟢 Wake word model READY — starting listener...');
      _startWakeWordListening();
    } else {
      _state = AssistantState.disabled;
      debugPrint('[Assistant] 🔴 Wake word model NOT loaded — assistant DISABLED');
      debugPrint('[Assistant] 🔴 Check logcat for [WakeWord] errors above');
    }

    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  🎤 INIT COMPLETE — State: $_state       ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('');

    notifyListeners();
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE CONTEXT — dipanggil saat bahasa/user berubah
  // ══════════════════════════════════════════════════════════════

  /// Update konteks bahasa dan user tanpa re-init model.
  void updateContext({
    String? language,
    UserModel? user,
    double? userLat,
    double? userLng,
  }) {
    if (language != null) _language = language;
    if (user != null) _currentUser = user;
    if (userLat != null) _userLat = userLat;
    if (userLng != null) _userLng = userLng;
  }

  // ══════════════════════════════════════════════════════════════
  // WAKE WORD LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  /// Mulai mendengarkan wake word (kembali ke state IDLE).
  void _startWakeWordListening() {
    _state = AssistantState.idle;
    notifyListeners();

    _voiceService.startListeningWakeWord(() {
      _onWakeWordDetected();
    });

    debugPrint('[Assistant] 🔄 State: IDLE — Listening for wake word...');
  }

  /// Callback saat wake word "Halo Sigumi" terdeteksi.
  ///
  /// Alur:
  /// 1. Stop wake word listening (sudah dilakukan di VoiceService)
  /// 2. Play beep/acknowledge TTS
  /// 3. Mulai STT untuk merekam perintah
  Future<void> _onWakeWordDetected() async {
    debugPrint('[Assistant] 🔥 Wake word detected!');

    // 1. Update state
    _state = AssistantState.listeningCommand;
    _lastCommand = '';
    notifyListeners();

    // 2. Beep acknowledge — "Ya?" singkat via TTS
    await _voiceService.playAcknowledgeBeep(language: _language);

    // 3. Pastikan STT sudah di-init
    if (!_voiceService.isSpeechEnabled) {
      await _voiceService.init();
    }

    // 4. Mulai STT — dengarkan perintah user
    final String localeId = _language == 'en' ? 'en_US' : 'id_ID';

    await _voiceService.startListening(
      // Partial results — update lastCommand secara real-time
      (recognizedText) {
        _lastCommand = recognizedText;
        notifyListeners();
      },
      localeId: localeId,
      onFinalResult: (finalText) {
        _onCommandReceived(finalText);
      },
    );

    debugPrint('[Assistant] 🎤 State: LISTENING_COMMAND — Recording user command...');
  }

  /// Dipanggil saat STT menghasilkan final result.
  Future<void> _onCommandReceived(String command) async {
    debugPrint('[Assistant] 📝 Command received: "$command"');

    if (command.trim().isEmpty) {
      // Tidak ada input, kembali ke idle
      debugPrint('[Assistant] ⚠️ Empty command, returning to wake word.');
      _startWakeWordListening();
      return;
    }

    // 1. Update state ke PROCESSING
    _state = AssistantState.processing;
    _lastCommand = command;
    notifyListeners();

    try {
      // 2. Stop STT (sudah selesai, tapi pastikan bersih)
      await _voiceService.stopListening();

      // 3. Kirim ke AiService untuk mendapat respons NLP
      final response = await AiService.getResponse(
        command,
        languageCode: _language,
        isVoice: true,
        user: _currentUser,
        userLat: _userLat,
        userLng: _userLng,
      );

      _lastResponse = response.content;

      // 4. Cek apakah intent ini memiliki navigasi otomatis
      //    Jika ya, navigasi + ucapkan konfirmasi pendek.
      //    Jika tidak, bacakan respons lengkap.
      String textToSpeak = response.content;

      if (response.intentId != null) {
        final didNavigate = AiService.tryNavigateForIntent(response.intentId!);
        if (didNavigate) {
          // Ganti teks TTS dengan konfirmasi navigasi yang lebih pendek
          textToSpeak = AiService.getNavigationText(
            response.intentId!,
            _language,
          );
          _lastResponse = textToSpeak;
        }
      }

      // 5. Update state ke SPEAKING
      _state = AssistantState.speaking;
      notifyListeners();

      // 6. Bacakan respons via TTS
      await _voiceService.speak(
        textToSpeak,
        language: _language,
        onCompletion: () {
          // 7. Setelah selesai bicara, kembali ke wake word
          _startWakeWordListening();
        },
      );

      debugPrint('[Assistant] 🔊 State: SPEAKING — Reading response...');
    } catch (e) {
      debugPrint('[Assistant] ❌ Error processing command: $e');
      _startWakeWordListening();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MANUAL CONTROLS
  // ══════════════════════════════════════════════════════════════

  /// Aktifkan assistant (mulai dengar wake word).
  void enable() {
    if (!_voiceService.isWakeWordModelLoaded) {
      debugPrint('[Assistant] ❌ Cannot enable: model not loaded.');
      return;
    }
    _isEnabled = true;
    _startWakeWordListening();
  }

  /// Nonaktifkan assistant (stop semua).
  void disable() {
    _isEnabled = false;
    _voiceService.stopListeningWakeWord();
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _state = AssistantState.disabled;
    notifyListeners();
    debugPrint('[Assistant] 🛑 Assistant DISABLED');
  }

  /// Stop TTS saat bot sedang bicara (user ingin interupsi).
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    if (_isEnabled) {
      _startWakeWordListening();
    }
  }

  /// Akses VoiceService untuk keperluan UI (misal manual TTS).
  VoiceService get voiceService => _voiceService;

  // ══════════════════════════════════════════════════════════════
  // DISPOSE
  // ══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _voiceService.dispose();
    super.dispose();
  }
}
