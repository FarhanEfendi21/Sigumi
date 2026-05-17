import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_audio/tflite_audio.dart';
import 'wake_word_service.dart';

/// Mobile implementation — uses tflite_audio (dart:ffi).
/// Only compiled on Android/iOS via conditional import.
class WakeWordServiceImpl implements WakeWordService {
  bool _modelLoaded = false;
  bool _isListening = false;
  StreamSubscription<dynamic>? _subscription;

  static const String _wakeWordLabel = 'Halo Sigumi';

  @override
  bool get isModelLoaded => _modelLoaded;

  @override
  bool get isListening => _isListening;

  @override
  Future<void> loadModel() async {
    if (_modelLoaded) return;
    debugPrint('[WakeWord] 📦 Loading TFLite audio model...');
    try {
      await TfliteAudio.loadModel(
        model: 'assets/ml/soundclassifier_with_metadata.tflite',
        label: 'assets/ml/labels.txt',
        numThreads: 1,
        isAsset: true,
        inputType: 'rawAudio',
      );
      _modelLoaded = true;
      debugPrint('[WakeWord] ✅ Model loaded successfully!');
    } catch (e, stackTrace) {
      _modelLoaded = false;
      debugPrint('[WakeWord] ❌ Model FAILED to load: $e');
      debugPrint('[WakeWord] ❌ Stack: $stackTrace');
    }
  }

  @override
  void startListening(VoidCallback onDetected) {
    if (!_modelLoaded) {
      debugPrint('[WakeWord] ⚠️ Cannot start: model not loaded!');
      return;
    }
    if (_isListening) {
      debugPrint('[WakeWord] ⚠️ Already listening, skipping.');
      return;
    }

    _isListening = true;
    debugPrint('[WakeWord] 🎤 Starting audio recognition stream...');
    debugPrint('[WakeWord] 🎤 Config: sampleRate=44100, bufferSize=22016, recordingLength=44032');

    try {
      final stream = TfliteAudio.startAudioRecognition(
        numOfInferences: 999,
        sampleRate: 44100,
        bufferSize: 22016,
      );

      _subscription = stream.listen(
        (event) {
          final String label =
              event['recognitionResult']?.toString().trim() ?? '';
          debugPrint('[WakeWord] 🔍 Inference result: "$label"');

          // Defensive matching: tflite_audio bisa mengembalikan
          // "1 Halo Sigumi" atau "Halo Sigumi" tergantung versi.
          if (label.contains(_wakeWordLabel) && !label.contains('Background')) {
            debugPrint('[WakeWord] 🔥🔥🔥 WAKE WORD DETECTED! Raw: "$label"');
            stopListening();
            onDetected();
          }
        },
        onError: (e) {
          debugPrint('[WakeWord] ❌ Stream error: $e');
          _isListening = false;
        },
        onDone: () {
          debugPrint('[WakeWord] ℹ️ Stream done (all inferences completed)');
          _isListening = false;
        },
      );

      debugPrint('[WakeWord] ✅ Audio recognition stream started successfully!');
    } catch (e, stackTrace) {
      debugPrint('[WakeWord] ❌ Failed to start recognition: $e');
      debugPrint('[WakeWord] ❌ Stack: $stackTrace');
      _isListening = false;
    }
  }

  @override
  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
    _isListening = false;
    try {
      TfliteAudio.stopAudioRecognition();
    } catch (e) {
      debugPrint('[WakeWord] stop error (safe to ignore): $e');
    }
    debugPrint('[WakeWord] 🛑 Listening STOPPED');
  }

  @override
  void dispose() {
    stopListening();
  }
}
