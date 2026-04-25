import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  // ignore: unused_field
  late Interpreter _interpreter;

  Future<void> loadModel() async {
    // Loads the model into memory
    _interpreter = await Interpreter.fromAsset('models/head_shape.tflite');
  }

  Map<String, dynamic> runInference(double confidence) {
    // Implementation of the logic from your notebook:
    // < 40% = Normal, > 80% = Abnormal, else = Uncertain
    if (confidence < 0.40) {
      return {"status": "NORMAL", "color": 0xFF4CAF50, "msg": "Healthy Head Shape"};
    } else if (confidence > 0.80) {
      return {"status": "ABNORMAL", "color": 0xFFF44336, "msg": "Potential Asymmetry"};
    } else {
      return {"status": "UNCERTAIN", "color": 0xFFFF9800, "msg": "Inconclusive. Retake Photo"};
    }
  }
}
