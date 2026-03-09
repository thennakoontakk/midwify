import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'offline_maternal_model_service.dart';

/// Result of a maternal health prediction.
class MaternalHealthResult {
  final int predictionScore; // 1=Low, 3=Mid, 6=High
  final String label;
  final double confidence;
  final List<Map<String, dynamic>> xaiReasons;
  final bool isOffline;

  MaternalHealthResult({
    required this.predictionScore,
    required this.label,
    required this.confidence,
    required this.xaiReasons,
    required this.isOffline,
  });

  /// Color indication: green/amber/red.
  String get riskColor {
    if (predictionScore >= 6) return 'red';
    if (predictionScore >= 3) return 'amber';
    return 'green';
  }
}

/// High-level maternal health prediction service.
/// Tries Flask API first; falls back to offline model.
class MaternalHealthService {
  static const String _baseUrl = 'http://192.168.8.176:5000';

  /// Predict maternal risk: tries server first, then offline.
  /// Features: [Age, SystolicBP, DiastolicBP, BS, BodyTemp, HeartRate]
  static Future<MaternalHealthResult> predict(List<double> features) async {
    try {
      final result = await _predictOnline(features)
          .timeout(const Duration(seconds: 4));
      return result;
    } catch (_) {
      // Fall back to offline prediction
      return _predictOffline(features);
    }
  }

  static Future<MaternalHealthResult> _predictOnline(
      List<double> features) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict-maternal'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return MaternalHealthResult(
        predictionScore: data['prediction'] as int,
        label: data['label'] as String,
        confidence: (data['confidence'] as num).toDouble(),
        xaiReasons: List<Map<String, dynamic>>.from(data['xai_reasons']),
        isOffline: false,
      );
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  static Future<MaternalHealthResult> _predictOffline(
      List<double> features) async {
    if (!OfflineMaternalModelService.isLoaded) {
      await OfflineMaternalModelService.loadModel();
    }

    final result = OfflineMaternalModelService.predict(features);
    return MaternalHealthResult(
      predictionScore: result['prediction'] as int,
      label: result['label'] as String,
      confidence: (result['confidence'] as num).toDouble(),
      xaiReasons: List<Map<String, dynamic>>.from(result['xai_reasons']),
      isOffline: true,
    );
  }
}
