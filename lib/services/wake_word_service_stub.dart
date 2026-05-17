import 'package:flutter/foundation.dart';
import 'wake_word_service.dart';

/// Stub implementation — used on Web where dart:ffi is unavailable.
/// All methods are no-ops.
class WakeWordServiceImpl implements WakeWordService {
  @override
  bool get isModelLoaded => false;

  @override
  bool get isListening => false;

  @override
  Future<void> loadModel() async {
    debugPrint('[WakeWord] Platform not supported (Web). Skipping.');
  }

  @override
  void startListening(VoidCallback onDetected) {}

  @override
  void stopListening() {}

  @override
  void dispose() {}
}
