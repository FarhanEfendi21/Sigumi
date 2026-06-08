import 'package:flutter/foundation.dart';

/// Abstraksi wake word detection.
/// Stub (Web) dan Mobile punya implementasi berbeda.
abstract class WakeWordService {
  bool get isModelLoaded;
  bool get isListening;
  Future<void> loadModel();
  void startListening(VoidCallback onDetected);
  void stopListening();
  void dispose();
}
