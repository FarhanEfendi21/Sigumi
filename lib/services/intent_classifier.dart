import 'package:string_similarity/string_similarity.dart';
import 'nlp_knowledge_base.dart';

abstract class IntentClassifier {
  Future<void> init();
  Future<({String intent, double confidence})> classify(String input);
  void dispose();
}

/// TFLite Intent Classifier dengan Internal Fallback Dictionary
///
/// Jika model .tflite tersedia, akan menggunakan TFLite inference.
/// Jika belum tersedia / gagal load, akan menggunakan internal dictionary fallback
/// (menggunakan string_similarity) agar aplikasi tetap berjalan.
class TFLiteIntentClassifier implements IntentClassifier {
  bool _isTfliteInit = false;

  @override
  Future<void> init() async {
    try {
      // TODO: Initialize TFLite model when asset is available
      // Example: await Tflite.loadModel(model: "assets/model.tflite", labels: "assets/labels.txt");
      _isTfliteInit = false; // Saat ini masih false karena model belum ada
    } catch (e) {
      print('[SIGUMI] Failed to load TFLite model, falling back to dictionary. Error: $e');
      _isTfliteInit = false;
    }
  }

  @override
  Future<({String intent, double confidence})> classify(String input) async {
    if (_isTfliteInit) {
      // TODO: implement TFLite inference
      // return _runTfliteInference(input);
      return _runDictionaryFallback(input); // Sementara
    } else {
      // Internal Fallback
      return _runDictionaryFallback(input);
    }
  }

  /// Fallback Classifier: Dictionary-based String Similarity
  Future<({String intent, double confidence})> _runDictionaryFallback(String input) async {
    String bestIntent = 'default';
    double bestConfidence = 0.0;
    
    for (var entry in NlpKnowledgeBase.trainingPhrases.entries) {
      String intent = entry.key;
      List<String> phrases = entry.value;
      
      for (String phrase in phrases) {
        double sim = phrase.similarityTo(input);
        
        if (input.contains(phrase) || phrase.contains(input)) {
           sim += 0.3; // Boost score for substring match
           if (sim > 1.0) sim = 1.0;
        }

        if (sim > bestConfidence) {
          bestConfidence = sim;
          bestIntent = intent;
        }
      }
    }
    
    if (bestConfidence < 0.25) {
      return (intent: 'default', confidence: bestConfidence);
    }
    
    return (intent: bestIntent, confidence: bestConfidence);
  }

  @override
  void dispose() {
    if (_isTfliteInit) {
      // TODO: Tflite.close();
    }
  }
}
