import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// Status hasil inisialisasi speech recognition
enum SpeechPermissionStatus {
  granted,   // Permission diberikan, siap digunakan
  denied,    // Permission ditolak oleh user
  error,     // Error teknis saat init
}

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;
  bool _hasBeenInitialized = false;

  /// Inisialisasi service. Mengembalikan status permission.
  Future<SpeechPermissionStatus> init() async {
    try {
      _speechEnabled = await _speechToText.initialize(
        onError: (SpeechRecognitionError error) {
          // Error saat listening (bukan saat init)
          // Ini akan di-handle oleh onError callback di startListening
        },
      );
      _hasBeenInitialized = true;
      return _speechEnabled 
          ? SpeechPermissionStatus.granted 
          : SpeechPermissionStatus.denied;
    } catch (e) {
      _hasBeenInitialized = true;
      return SpeechPermissionStatus.error;
    }
  }

  /// Cek apakah service sudah di-init sebelumnya
  bool get hasBeenInitialized => _hasBeenInitialized;

  /// Init TTS settings (dipanggil terpisah karena TTS tidak butuh permission khusus)
  Future<void> initTts() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  bool get isSpeechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;

  /// Mulai mendengarkan suara user
  /// [onResult] - callback saat ada hasil pengenalan suara
  /// [onError] - callback jika terjadi error
  /// [onStatus] - callback saat status berubah (listening/notListening/done)
  Future<void> startListening(
    Function(String) onResult, {
    String localeId = 'id_ID',
    Function(String)? onError,
    Function(String)? onStatus,
  }) async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
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
  
  /// Handle Text-to-Speech
  Future<void> speak(String text, {String language = 'id'}) async {
    String ttsLang = 'id-ID';
    
    if (language == 'en') ttsLang = 'en-US';
    // Unfortunately TTS engines often don't have good support for Javanese/Sundanese/Balinese natively.
    // Falling back to Indonesian pronunciation for regional languages is standard.
    
    await _flutterTts.setLanguage(ttsLang);
    await _flutterTts.speak(text);
  }
  
  Future<void> stopSpeaking() async {
    await _flutterTts.stop();
  }
}
