import 'package:flutter/foundation.dart';

/// Head TFLite classification has been retired in favor of Gemini-based
/// multimodal analysis. This no-op service remains only to avoid widening
/// changes in the posture pipeline bootstrap path.
class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  Future<void> initialize() async {
    debugPrint('ClassifierService.initialize: head TFLite classifier retired.');
  }
}
