import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'wake_word_service.dart';
import 'wake_word_service_factory.dart';

/// Status hasil inisialisasi speech recognition
enum SpeechPermissionStatus {
  granted,   // Permission diberikan, siap digunakan
  denied,    // Permission ditolak oleh user
  error,     // Error teknis saat init
}

/// Status TTS saat ini
enum TtsState {
  idle,      // Tidak sedang berbicara
  speaking,  // Sedang berbicara (TTS aktif)
  stopped,   // Dihentikan oleh user
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _hasBeenInitialized = false;

  // ── TTS State ──
  TtsState _ttsState = TtsState.idle;
  TtsState get ttsState => _ttsState;
  bool get isSpeaking => _ttsState == TtsState.speaking;

  // ── Listener untuk TTS state changes ──
  final _ttsStateController = StreamController<TtsState>.broadcast();
  Stream<TtsState> get ttsStateStream => _ttsStateController.stream;

  // ══════════════════════════════════════════════════════════════
  // WAKE WORD — Platform-safe via WakeWordService
  // ══════════════════════════════════════════════════════════════
  late final WakeWordService _wakeWordService = WakeWordServiceImpl();

  bool get isWakeWordModelLoaded => _wakeWordService.isModelLoaded;
  bool get isWakeWordListening => _wakeWordService.isListening;

  // ══════════════════════════════════════════════════════════════
  // INIT — Speech-to-Text
  // ══════════════════════════════════════════════════════════════

  Future<SpeechPermissionStatus> init() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          debugPrint('[VoiceService] STT Error: ${error.errorMsg}');
        },
      );
      _hasBeenInitialized = true;
      return _speechEnabled 
          ? SpeechPermissionStatus.granted 
          : SpeechPermissionStatus.denied;
    } catch (e) {
      _hasBeenInitialized = true;
      debugPrint('[VoiceService] Init Error: $e');
      return SpeechPermissionStatus.error;
    }
  }

  bool get hasBeenInitialized => _hasBeenInitialized;

  // ══════════════════════════════════════════════════════════════
  // INIT — TTS
  // ══════════════════════════════════════════════════════════════

  Future<void> initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    _flutterTts.setStartHandler(() {
      _ttsState = TtsState.speaking;
      _ttsStateController.add(_ttsState);
      debugPrint('[VoiceService] TTS Started Speaking');
    });

    _flutterTts.setCompletionHandler(() {
      _ttsState = TtsState.idle;
      _ttsStateController.add(_ttsState);
      debugPrint('[VoiceService] TTS Completed');
    });

    _flutterTts.setCancelHandler(() {
      _ttsState = TtsState.stopped;
      _ttsStateController.add(_ttsState);
      debugPrint('[VoiceService] TTS Cancelled');
    });

    _flutterTts.setErrorHandler((msg) {
      _ttsState = TtsState.idle;
      _ttsStateController.add(_ttsState);
      debugPrint('[VoiceService] TTS Error: $msg');
    });
  }

  bool get isSpeechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;

  // ══════════════════════════════════════════════════════════════
  // INIT — Wake Word (delegated to WakeWordService)
  // ══════════════════════════════════════════════════════════════

  Future<void> initWakeWord() async {
    await _wakeWordService.loadModel();
  }

  // ══════════════════════════════════════════════════════════════
  // WAKE WORD — Start/Stop (delegated)
  // ══════════════════════════════════════════════════════════════

  void startListeningWakeWord(VoidCallback onDetected) {
    _wakeWordService.startListening(onDetected);
  }

  void stopListeningWakeWord() {
    _wakeWordService.stopListening();
  }

  // ══════════════════════════════════════════════════════════════
  // STT — Speech-to-Text
  // ══════════════════════════════════════════════════════════════

  Future<void> startListening(
    Function(String) onResult, {
    String localeId = 'id_ID',
    Function(String)? onError,
    Function(String)? onStatus,
    Function(String)? onFinalResult,
  }) async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
          if (result.finalResult && result.recognizedWords.isNotEmpty) {
            onFinalResult?.call(result.recognizedWords);
          }
        },
        localeId: localeId,
        listenOptions: SpeechListenOptions(
          listenMode: ListenMode.confirmation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    }
  }

  Future<void> stopListening() async {
    await _speechToText.stop();
  }

  // ══════════════════════════════════════════════════════════════
  // TTS — Text-to-Speech
  // ══════════════════════════════════════════════════════════════
  
  Future<void> speak(
    String text, {
    String language = 'id',
    VoidCallback? onCompletion,
  }) async {
    String ttsLang = 'id-ID';
    if (language == 'en') ttsLang = 'en-US';
    
    if (onCompletion != null) {
      _flutterTts.setCompletionHandler(() {
        _ttsState = TtsState.idle;
        _ttsStateController.add(_ttsState);
        onCompletion();
        debugPrint('[VoiceService] TTS Completed (with onCompletion callback)');
      });
    }

    await _flutterTts.setLanguage(ttsLang);
    _ttsState = TtsState.speaking;
    _ttsStateController.add(_ttsState);
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
    _ttsState = TtsState.stopped;
    _ttsStateController.add(_ttsState);
  }

  // ══════════════════════════════════════════════════════════════
  // BEEP — Acknowledge wake word
  // ══════════════════════════════════════════════════════════════

  Future<void> playAcknowledgeBeep({String language = 'id'}) async {
    final beepText = language == 'en' ? 'Yes?' : 'Ya?';
    String ttsLang = language == 'en' ? 'en-US' : 'id-ID';

    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.setSpeechRate(0.6);
    await _flutterTts.speak(beepText);
    await Future.delayed(const Duration(milliseconds: 800));
    await _flutterTts.setSpeechRate(0.5);
  }

  // ══════════════════════════════════════════════════════════════
  // DISPOSE
  // ══════════════════════════════════════════════════════════════

  void dispose() {
    _wakeWordService.dispose();
    _ttsStateController.close();
    _flutterTts.stop();
    _speechToText.stop();
  }
}
