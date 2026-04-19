import 'package:flutter/foundation.dart';
import 'package:string_similarity/string_similarity.dart';
import 'nlp_knowledge_base.dart';

abstract class IntentClassifier {
  Future<void> init();
  Future<({String intent, double confidence})> classify(String input);
  void dispose();
}

class DictionaryIntentClassifier implements IntentClassifier {
  @override
  Future<void> init() async {}

  @override
  Future<({String intent, double confidence})> classify(String input) async {
    String bestIntent = 'default';
    double bestConfidence = 0.0;
    
    for (var entry in NlpKnowledgeBase.trainingPhrases.entries) {
      String intent = entry.key;
      List<String> phrases = entry.value;
      
      for (String phrase in phrases) {
        double sim = phrase.similarityTo(input);
        
        if (input.contains(phrase) || phrase.contains(input)) {
           sim += 0.3; 
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
  void dispose() {}
}

class TFLiteIntentClassifier implements IntentClassifier {
  bool _isInit = false;

  @override
  Future<void> init() async {
    if (kIsWeb) return;
    // TODO: Initialize TFLite model when asset is available
    _isInit = true;
  }

  @override
  Future<({String intent, double confidence})> classify(String input) async {
    if (!_isInit) {
      return DictionaryIntentClassifier().classify(input);
    }
    // TODO: implement TFLite inference
    // Fallback to dictionary for now since no model is present.
    return DictionaryIntentClassifier().classify(input);
  }

  @override
  void dispose() {}
}
