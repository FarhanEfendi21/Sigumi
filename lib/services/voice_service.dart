import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  
  bool _speechEnabled = false;

  Future<void> init() async {
    _speechEnabled = await _speechToText.initialize();
    
    // Initialize TTS settings
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);
  }

  bool get isSpeechEnabled => _speechEnabled;
  bool get isListening => _speechToText.isListening;

  Future<void> startListening(Function(String) onResult, {String localeId = 'id_ID'}) async {
    if (_speechEnabled) {
      await _speechToText.listen(
        onResult: (result) {
          onResult(result.recognizedWords);
        },
        localeId: localeId,
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
