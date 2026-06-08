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

  bool _isAudioGuidanceEnabled = false;
  bool get isAudioGuidanceEnabled => _isAudioGuidanceEnabled;

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
    required bool isAudioGuidanceEnabled,
    UserModel? user,
    double? userLat,
    double? userLng,
  }) async {
    debugPrint('');
    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  🎤 GLOBAL VOICE ASSISTANT - INIT START  ║');
    debugPrint('╚══════════════════════════════════════════╝');

    _language = language;
    _isAudioGuidanceEnabled = isAudioGuidanceEnabled;
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

    // Set STT error listener to automatically handle errors
    _voiceService.onSttError = _onSttError;

    if (_voiceService.isWakeWordModelLoaded) {
      if (_isAudioGuidanceEnabled) {
        _isEnabled = true;
        debugPrint('[Assistant] 🟢 Wake word model READY — starting listener...');
        await _startWakeWordListening();
      } else {
        _isEnabled = false;
        _state = AssistantState.disabled;
        debugPrint('[Assistant] 🟡 Wake word model READY, but Audio Guidance is OFF.');
      }
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

  /// Menangani error STT (otomatis cancel jika error)
  void _onSttError(String errorMsg) {
    debugPrint('[Assistant] ❌ STT Error caught in Provider: $errorMsg');
    if (_state == AssistantState.listeningCommand || _state == AssistantState.processing) {
      cancelAssistant();
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE CONTEXT — dipanggil saat bahasa/user berubah
  // ══════════════════════════════════════════════════════════════

  /// Update konteks bahasa dan user tanpa re-init model.
  void updateContext({
    String? language,
    bool? isAudioGuidanceEnabled,
    UserModel? user,
    double? userLat,
    double? userLng,
  }) {
    if (language != null) _language = language;
    if (user != null) _currentUser = user;
    if (userLat != null) _userLat = userLat;
    if (userLng != null) _userLng = userLng;

    if (isAudioGuidanceEnabled != null && _isAudioGuidanceEnabled != isAudioGuidanceEnabled) {
      _isAudioGuidanceEnabled = isAudioGuidanceEnabled;
      if (_isAudioGuidanceEnabled) {
        if (_voiceService.isWakeWordModelLoaded && !_isEnabled) {
          enable();
        }
      } else {
        if (_isEnabled) {
          disable();
        }
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // WAKE WORD LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  /// Mulai mendengarkan wake word (kembali ke state IDLE).
  Future<void> _startWakeWordListening() async {
    _state = AssistantState.idle;
    notifyListeners();

    // 1. Matikan STT secara paksa untuk melepas mic
    await _voiceService.cancelListening();
    
    // 2. Jeda 600ms untuk mencegah race condition (memastikan hardware mic dilepas sepenuhnya)
    await Future.delayed(const Duration(milliseconds: 600));

    _voiceService.startListeningWakeWord(() {
      _onWakeWordDetected();
    });

    debugPrint('[Assistant] 🔄 State: IDLE — Listening for wake word...');
  }

  /// Callback saat wake word "Halo Sigumi" terdeteksi.
  ///
  /// Alur:
  /// 1. Stop wake word listening
  /// 2. Tunggu 400ms
  /// 3. Play beep/acknowledge TTS
  /// 4. Mulai STT untuk merekam perintah
  Future<void> _onWakeWordDetected() async {
    debugPrint('[Assistant] 🔥 Wake word detected!');

    // 1. Update state
    _state = AssistantState.listeningCommand;
    _lastCommand = '';
    notifyListeners();

    // 2. Matikan wake word listening (memastikan mic dilepas)
    _voiceService.stopListeningWakeWord();
    
    // 3. Jeda 600ms untuk hardware mic dilepas tflite_audio
    await Future.delayed(const Duration(milliseconds: 600));

    // 4. Beep acknowledge — "Ya?" singkat via TTS
    await _voiceService.playAcknowledgeBeep(language: _language);

    // 5. Pastikan STT sudah di-init
    if (!_voiceService.isSpeechEnabled) {
      await _voiceService.init();
    }

    // 6. Mulai STT — dengarkan perintah user
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
      await _startWakeWordListening();
      return;
    }

    // 1. Update state ke PROCESSING
    _state = AssistantState.processing;
    _lastCommand = command;
    notifyListeners();

    try {
      // 2. Cancel STT secara paksa (sudah selesai merekam, pastikan mic dilepas cepat)
      await _voiceService.cancelListening();

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

      // 6. Bacakan respons via TTS (akan di-await secara otomatis)
      await _voiceService.speak(textToSpeak, language: _language);

      // 7. Setelah selesai bicara, kembali ke wake word
      await _startWakeWordListening();

      debugPrint('[Assistant] 🔊 State: SPEAKING — Finished reading response.');
    } catch (e) {
      debugPrint('[Assistant] ❌ Error processing command: $e');
      await _startWakeWordListening();
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

  /// Batal asisten, matikan proses berjalan, lalu kembali mendengarkan wake word.
  Future<void> cancelAssistant() async {
    debugPrint('[Assistant] 🛑 Canceling current operation and returning to Wake Word...');
    await _voiceService.stopSpeaking();
    await _voiceService.cancelListening();
    _lastCommand = '';
    _lastResponse = '';
    
    // Resume listening for wake word with transition delay
    await _startWakeWordListening();
  }

  /// Stop TTS saat bot sedang bicara (user ingin interupsi).
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    if (_isEnabled) {
      await _startWakeWordListening();
    }
  }

  /// Jeda sementara wake word listener agar mic bisa dipakai modul lain
  /// (misal ChatbotScreen STT). Panggil [resumeWakeWord] setelah selesai.
  Future<void> pauseWakeWord() async {
    if (!_isEnabled) return;
    debugPrint('[Assistant] ⏸️ Wake word PAUSED (mic released for external use)');
    _voiceService.stopListeningWakeWord();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Lanjutkan wake word listener setelah modul lain selesai pakai mic.
  Future<void> resumeWakeWord() async {
    if (!_isEnabled) return;
    debugPrint('[Assistant] ▶️ Wake word RESUMED');
    await _startWakeWordListening();
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
