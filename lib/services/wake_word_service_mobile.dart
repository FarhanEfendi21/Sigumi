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
        inputType: 'decodedWav',
        outputRawScores: true,
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
    debugPrint('[WakeWord] 🎤 Config: sampleRate=44100, bufferSize=22016, warmUpSkip=$_warmUpSkipCount');

    try {
      // Teachable Machine audio model configuration
      final stream = TfliteAudio.startAudioRecognition(
        numOfInferences: 999,
        sampleRate: 44100,
        bufferSize: 22016,
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

          // Parse raw scores: "[score_noise, score_wakeword]"
          double wakeWordScore = 0.0;
          try {
            final clean = label.replaceAll('[', '').replaceAll(']', '');
            final parts = clean.split(',');
            if (parts.length >= 2) {
              // Index 0: 0 Background Noise
              // Index 1: 1 Halo Sigumi
              wakeWordScore = double.tryParse(parts[1].trim()) ?? 0.0;
            }
          } catch (e) {
            debugPrint('[WakeWord] ❌ Error parsing scores: $e');
          }

          // Threshold 0.85 to avoid false triggers from noise
          const double threshold = 0.85;
          if (wakeWordScore >= threshold) {
            debugPrint('[WakeWord] 🔥🔥🔥 WAKE WORD DETECTED! Score: $wakeWordScore >= $threshold');
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
