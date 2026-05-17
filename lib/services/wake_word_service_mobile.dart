import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:tflite_audio/tflite_audio.dart';
import 'wake_word_service.dart';

/// Mobile implementation — uses tflite_audio (dart:ffi).
/// Only compiled on Android/iOS via conditional import.
///
/// State machine mic:
///   tflite_audio ON  → wake word detected → tflite_audio OFF → STT ON
///   STT done → tflite_audio ON (kembali ke loop)
///
/// tflite_audio dan STT TIDAK BOLEH menyala bersamaan.
class WakeWordServiceImpl implements WakeWordService {
  bool _modelLoaded = false;
  bool _isListening = false;
  StreamSubscription<dynamic>? _subscription;

  /// Jumlah inference awal yang di-skip (warm-up).
  /// Model TFLite sering menghasilkan output tidak akurat pada
  /// beberapa inference pertama karena buffer audio belum terisi.
  static const int _warmUpSkipCount = 3;
  int _inferenceCount = 0;

  /// Label wake word sesuai labels.txt: "1 Halo Sigumi"
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
        model: 'assets/ml/voice-assistant.tflite',
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
    _inferenceCount = 0; // Reset warm-up counter
    debugPrint('[WakeWord] 🎤 Starting audio recognition stream...');
    debugPrint('[WakeWord] 🎤 Config: sampleRate=16000, bufferSize=1288, warmUpSkip=$_warmUpSkipCount');

    try {
      // Model input: [1, 1287] float32
      // sampleRate=16000 (Edge Impulse default)
      // bufferSize=1288 (must be even for Android AudioRecord, ≈ model input 1287)
      final stream = TfliteAudio.startAudioRecognition(
        numOfInferences: 999,
        sampleRate: 16000,
        bufferSize: 1288,
      );

      _subscription = stream.listen(
        (event) {
          final String label =
              event['recognitionResult']?.toString().trim() ?? '';
          _inferenceCount++;
          debugPrint('[WakeWord] 🔍 Inference #$_inferenceCount result: "$label"');

          // Skip warm-up inferences — buffer audio belum terisi data valid,
          // sehingga output model tidak bisa dipercaya.
          if (_inferenceCount <= _warmUpSkipCount) {
            debugPrint('[WakeWord] ⏭️ Skipping warm-up inference #$_inferenceCount/$_warmUpSkipCount');
            return;
          }

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
