import 'dart:async';
import 'package:flutter/material.dart';
import '../services/voice_service.dart';
import '../services/ai_service.dart';
import '../models/user_model.dart';

/// State siklus hidup Global Voice Assistant.
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

  // ── Background pause flag ──
  bool _isPausedForBackground = false;

  // ── Timers untuk safety & debounce ──
  Timer? _commandTimeoutTimer;
  Timer? _sttDoneTimer;

  // ── User & Location (di-inject untuk personalisasi) ──
  UserModel? _currentUser;
  double? _userLat;
  double? _userLng;

  // ══════════════════════════════════════════════════════════════
  // INIT
  // ══════════════════════════════════════════════════════════════

  /// Inisialisasi assistant: load model + init TTS.
  /// STT hanya di-init jika panduan audio aktif untuk menghindari popup izin mic saat startup.
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

    // Step 2: Init TFLite Audio wake word model
    debugPrint('[Assistant] Step 2/3: Loading Wake Word model...');
    await _voiceService.initWakeWord();
    debugPrint('[Assistant] Step 2/3: Model loaded: ${_voiceService.isWakeWordModelLoaded}');

    // Register listeners
    _voiceService.onSttError = _onSttError;
    _voiceService.onSttStatus = _onSttStatus;

    // Step 3: Hanya aktifkan jika user mengaktifkan panduan audio
    if (_isAudioGuidanceEnabled && _voiceService.isWakeWordModelLoaded) {
      _isEnabled = true;
      debugPrint('[Assistant] Step 3/3: Initializing STT...');
      await _voiceService.init();
      debugPrint('[Assistant] 🟢 Wake word model READY — starting listener...');
      await _startWakeWordListening();
    } else {
      _isEnabled = false;
      _state = AssistantState.disabled;
      debugPrint('[Assistant] 🟡 Wake word model READY, but Audio Guidance is OFF.');
      notifyListeners();
    }

    debugPrint('╔══════════════════════════════════════════╗');
    debugPrint('║  🎤 INIT COMPLETE — State: $_state       ║');
    debugPrint('╚══════════════════════════════════════════╝');
    debugPrint('');
  }

  /// Menangani error STT (otomatis cancel jika error / timeout)
  void _onSttError(String errorMsg) {
    debugPrint('[Assistant] ❌ STT Error caught in Provider: $errorMsg');
    if (_state == AssistantState.listeningCommand || _state == AssistantState.processing) {
      cancelAssistant();
    }
  }

  /// Menangani perubahan status STT
  void _onSttStatus(String status) {
    debugPrint('[Assistant] STT Status: $status (state: $_state)');
    if ((status == 'done' || status == 'notListening') && _state == AssistantState.listeningCommand) {
      _sttDoneTimer?.cancel();
      _sttDoneTimer = Timer(const Duration(milliseconds: 600), () {
        if (_state == AssistantState.listeningCommand) {
          if (_lastCommand.trim().isNotEmpty) {
            _onCommandReceived(_lastCommand);
          } else {
            debugPrint('[Assistant] STT completed with empty command -> canceling.');
            cancelAssistant();
          }
        }
      });
    }
  }

  // ══════════════════════════════════════════════════════════════
  // UPDATE CONTEXT — dipanggil saat preferensi / user berubah
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
        if (_isEnabled || _state != AssistantState.disabled) {
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
    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) {
      _state = AssistantState.disabled;
      notifyListeners();
      return;
    }

    _state = AssistantState.idle;
    notifyListeners();

    // 1. Matikan STT secara paksa untuk melepas mic
    await _voiceService.cancelListening();
    
    // 2. Jeda 500ms untuk memastikan hardware mic dilepas sepenuhnya
    await Future.delayed(const Duration(milliseconds: 500));

    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) {
      _state = AssistantState.disabled;
      notifyListeners();
      return;
    }

    _voiceService.startListeningWakeWord(() {
      _onWakeWordDetected();
    });

    debugPrint('[Assistant] 🔄 State: IDLE — Listening for wake word...');
  }

  /// Callback saat wake word "Halo Sigumi" terdeteksi.
  Future<void> _onWakeWordDetected() async {
    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) return;
    if (_state != AssistantState.idle) return;

    debugPrint('[Assistant] 🔥 Wake word detected!');

    // 1. Update state
    _state = AssistantState.listeningCommand;
    _lastCommand = '';
    notifyListeners();

    // 2. Matikan wake word listening
    _voiceService.stopListeningWakeWord();
    
    // 3. Jeda 400ms untuk hardware mic dilepas
    await Future.delayed(const Duration(milliseconds: 400));

    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) return;

    // 4. Beep acknowledge — "Ya?" singkat via TTS
    await _voiceService.playAcknowledgeBeep(language: _language);

    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) return;

    // 5. Pastikan STT sudah di-init
    if (!_voiceService.isSpeechEnabled) {
      await _voiceService.init();
    }

    // 6. Mulai STT dengan safety timeout 7 detik
    final String localeId = _language == 'en' ? 'en_US' : 'id_ID';

    _commandTimeoutTimer?.cancel();
    _commandTimeoutTimer = Timer(const Duration(seconds: 7), () {
      if (_state == AssistantState.listeningCommand) {
        debugPrint('[Assistant] ⏱️ Command listen timeout reached (7s)');
        if (_lastCommand.trim().isNotEmpty) {
          _onCommandReceived(_lastCommand);
        } else {
          cancelAssistant();
        }
      }
    });

    await _voiceService.startListening(
      (recognizedText) {
        _lastCommand = recognizedText;
        notifyListeners();
      },
      localeId: localeId,
      onFinalResult: (finalText) {
        _commandTimeoutTimer?.cancel();
        _onCommandReceived(finalText);
      },
    );

    debugPrint('[Assistant] 🎤 State: LISTENING_COMMAND — Recording user command...');
  }

  /// Dipanggil saat STT menghasilkan final result.
  Future<void> _onCommandReceived(String command) async {
    _commandTimeoutTimer?.cancel();
    _sttDoneTimer?.cancel();
    debugPrint('[Assistant] 📝 Command received: "$command"');

    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) {
      _state = AssistantState.disabled;
      notifyListeners();
      return;
    }

    if (command.trim().isEmpty) {
      debugPrint('[Assistant] ⚠️ Empty command, returning to wake word.');
      await cancelAssistant();
      return;
    }

    // 1. Update state ke PROCESSING
    _state = AssistantState.processing;
    _lastCommand = command;
    notifyListeners();

    try {
      // 2. Cancel STT secara paksa
      await _voiceService.cancelListening();

      // 3. Kirim ke AiService untuk respons NLP
      final response = await AiService.getResponse(
        command,
        languageCode: _language,
        isVoice: true,
        user: _currentUser,
        userLat: _userLat,
        userLng: _userLng,
      );

      if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) {
        _state = AssistantState.disabled;
        notifyListeners();
        return;
      }

      _lastResponse = response.content;

      // 4. Cek navigasi otomatis
      String textToSpeak = response.content;

      if (response.intentId != null) {
        final didNavigate = AiService.tryNavigateForIntent(response.intentId!);
        if (didNavigate) {
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
      await _voiceService.speak(textToSpeak, language: _language);

      // 7. Selesai bicara, cooldown sebelum kembali ke wake word
      if (_isEnabled && _isAudioGuidanceEnabled && !_isPausedForBackground) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _startWakeWordListening();
      } else {
        _state = AssistantState.disabled;
        notifyListeners();
      }

      debugPrint('[Assistant] 🔊 State: SPEAKING — Finished reading response.');
    } catch (e) {
      debugPrint('[Assistant] ❌ Error processing command: $e');
      if (_isEnabled && _isAudioGuidanceEnabled && !_isPausedForBackground) {
        await Future.delayed(const Duration(milliseconds: 1000));
        await _startWakeWordListening();
      } else {
        _state = AssistantState.disabled;
        notifyListeners();
      }
    }
  }

  // ══════════════════════════════════════════════════════════════
  // MANUAL CONTROLS & LIFECYCLE
  // ══════════════════════════════════════════════════════════════

  /// Aktifkan assistant (mulai dengar wake word).
  void enable() async {
    _isAudioGuidanceEnabled = true;
    _isEnabled = true;
    _isPausedForBackground = false;

    if (!_voiceService.isWakeWordModelLoaded) {
      debugPrint('[Assistant] ❌ Cannot enable: model not loaded.');
      return;
    }

    if (!_voiceService.isSpeechEnabled) {
      await _voiceService.init();
    }

    await _startWakeWordListening();
  }

  /// Nonaktifkan assistant (stop semua dan pastikan mic bebas).
  void disable() {
    _isAudioGuidanceEnabled = false;
    _isEnabled = false;
    _isPausedForBackground = false;
    _commandTimeoutTimer?.cancel();
    _sttDoneTimer?.cancel();
    _voiceService.stopListeningWakeWord();
    _voiceService.cancelListening();
    _voiceService.stopSpeaking();
    _state = AssistantState.disabled;
    notifyListeners();
    debugPrint('[Assistant] 🛑 Assistant DISABLED');
  }

  /// Jeda asisten saat aplikasi masuk ke background.
  void pauseForBackground() {
    if (!_isEnabled || !_isAudioGuidanceEnabled) return;
    _isPausedForBackground = true;
    _commandTimeoutTimer?.cancel();
    _sttDoneTimer?.cancel();
    _voiceService.stopListeningWakeWord();
    _voiceService.cancelListening();
    _voiceService.stopSpeaking();
    _state = AssistantState.idle;
    debugPrint('[Assistant] ⏸️ Paused for background');
  }

  /// Lanjutkan asisten saat aplikasi kembali ke foreground (hanya jika aktif).
  void resumeFromBackground() {
    if (!_isAudioGuidanceEnabled) {
      if (_isEnabled || _state != AssistantState.disabled) {
        disable();
      }
      return;
    }

    if (_isPausedForBackground && _isEnabled) {
      _isPausedForBackground = false;
      _startWakeWordListening();
      debugPrint('[Assistant] ▶️ Resumed from background');
    }
  }

  /// Batal asisten, matikan proses berjalan, lalu kembali mendengarkan wake word.
  Future<void> cancelAssistant() async {
    _commandTimeoutTimer?.cancel();
    _sttDoneTimer?.cancel();
    debugPrint('[Assistant] 🛑 Canceling current operation...');

    await _voiceService.stopSpeaking();
    await _voiceService.cancelListening();
    _lastCommand = '';
    _lastResponse = '';

    if (_isEnabled && _isAudioGuidanceEnabled && !_isPausedForBackground) {
      _state = AssistantState.idle;
      notifyListeners();
      // Cooldown 1.2s agar suara sekitar / audio speaker tidak memicu wake word kembali
      await Future.delayed(const Duration(milliseconds: 1200));
      if (_isEnabled && _isAudioGuidanceEnabled && !_isPausedForBackground) {
        await _startWakeWordListening();
      }
    } else {
      _state = AssistantState.disabled;
      notifyListeners();
    }
  }

  /// Stop TTS saat bot sedang bicara (user ingin interupsi).
  Future<void> stopSpeaking() async {
    await _voiceService.stopSpeaking();
    if (_isEnabled && _isAudioGuidanceEnabled && !_isPausedForBackground) {
      await _startWakeWordListening();
    }
  }

  /// Jeda sementara wake word listener agar mic bisa dipakai modul lain (misal ChatbotScreen).
  Future<void> pauseWakeWord() async {
    if (!_isEnabled || !_isAudioGuidanceEnabled) return;
    debugPrint('[Assistant] ⏸️ Wake word PAUSED (mic released for external use)');
    _voiceService.stopListeningWakeWord();
    await Future.delayed(const Duration(milliseconds: 400));
  }

  /// Lanjutkan wake word listener setelah modul lain selesai pakai mic.
  Future<void> resumeWakeWord() async {
    if (!_isEnabled || !_isAudioGuidanceEnabled || _isPausedForBackground) return;
    debugPrint('[Assistant] ▶️ Wake word RESUMED');
    await _startWakeWordListening();
  }

  /// Akses VoiceService untuk keperluan UI.
  VoiceService get voiceService => _voiceService;

  // ══════════════════════════════════════════════════════════════
  // DISPOSE
  // ══════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _commandTimeoutTimer?.cancel();
    _sttDoneTimer?.cancel();
    _voiceService.dispose();
    super.dispose();
  }
}
