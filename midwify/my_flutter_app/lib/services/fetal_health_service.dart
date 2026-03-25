import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'offline_model_service.dart';

/// Result of a fetal health prediction.
class FetalHealthResult {
  final int prediction; // 1=Normal, 2=Suspect, 3=Pathological
  final String label;
  final double confidence;
  final List<Map<String, dynamic>> xaiReasons;
  final bool isOffline;

  FetalHealthResult({
    required this.prediction,
    required this.label,
    required this.confidence,
    required this.xaiReasons,
    required this.isOffline,
  });

  /// Color indication: green/amber/red.
  String get riskColor {
    switch (prediction) {
      case 1:
        return 'green';
      case 2:
        return 'amber';
      case 3:
        return 'red';
      default:
        return 'grey';
    }
  }
}

/// High-level fetal health prediction service.
/// Tries Flask API first; falls back to offline model.
class FetalHealthService {
  // Change this to your Flask server address.
  // For Chrome/web: use http://localhost:5000
  // For Android emulator: use http://10.0.2.2:5000
  // For physical device: use your PC's local IP e.g. http://192.168.x.x:5000
  static const String _baseUrl = 'http://192.168.8.176:5000';

  /// Feature names in the correct order.
  static const List<String> featureNames = [
    'baseline value',
    'accelerations',
    'fetal_movement',
    'uterine_contractions',
    'light_decelerations',
    'severe_decelerations',
    'prolongued_decelerations',
    'abnormal_short_term_variability',
    'mean_value_of_short_term_variability',
    'percentage_of_time_with_abnormal_long_term_variability',
    'mean_value_of_long_term_variability',
    'histogram_width',
    'histogram_min',
    'histogram_max',
    'histogram_number_of_peaks',
    'histogram_number_of_zeroes',
    'histogram_mode',
    'histogram_mean',
    'histogram_median',
    'histogram_variance',
    'histogram_tendency',
  ];

  /// Abbreviated labels for each feature.
  static const Map<String, String> featureLabels = {
    'baseline value': 'Baseline',
    'accelerations': 'Accel',
    'fetal_movement': 'Fetal Mov',
    'uterine_contractions': 'Uterine Con',
    'light_decelerations': 'Light Decel',
    'severe_decelerations': 'Severe Decel',
    'prolongued_decelerations': 'Prolonged Decel',
    'abnormal_short_term_variability': 'Abnormal STV',
    'mean_value_of_short_term_variability': 'Mean STV',
    'percentage_of_time_with_abnormal_long_term_variability': 'Abnormal LTV',
    'mean_value_of_long_term_variability': 'Mean LTV',
    'histogram_width': 'Hist Width',
    'histogram_min': 'Hist Min',
    'histogram_max': 'Hist Max',
    'histogram_number_of_peaks': 'Hist Peaks',
    'histogram_number_of_zeroes': 'Hist Zeroes',
    'histogram_mode': 'Hist Mode',
    'histogram_mean': 'Hist Mean',
    'histogram_median': 'Hist Median',
    'histogram_variance': 'Hist Variance',
    'histogram_tendency': 'Hist Tendency',
  };

  /// Example numeric hints for each feature.
  static const Map<String, String> featureHints = {
    'baseline value': '120.0',
    'accelerations': '0.005',
    'fetal_movement': '0.002',
    'uterine_contractions': '0.004',
    'light_decelerations': '0.001',
    'severe_decelerations': '0.0',
    'prolongued_decelerations': '0.0',
    'abnormal_short_term_variability': '45.0',
    'mean_value_of_short_term_variability': '1.2',
    'percentage_of_time_with_abnormal_long_term_variability': '10.0',
    'mean_value_of_long_term_variability': '8.5',
    'histogram_width': '50.0',
    'histogram_min': '80.0',
    'histogram_max': '130.0',
    'histogram_number_of_peaks': '3',
    'histogram_number_of_zeroes': '0',
    'histogram_mode': '120.0',
    'histogram_mean': '118.0',
    'histogram_median': '121.0',
    'histogram_variance': '15.0',
    'histogram_tendency': '0',
  };

  /// The form sections for organized input.
  static const Map<String, List<String>> formSections = {
    'Heart Rate & Movements': [
      'baseline value',
      'accelerations',
      'fetal_movement',
      'uterine_contractions',
    ],
    'Decelerations': [
      'light_decelerations',
      'severe_decelerations',
      'prolongued_decelerations',
    ],
    'Variability': [
      'abnormal_short_term_variability',
      'mean_value_of_short_term_variability',
      'percentage_of_time_with_abnormal_long_term_variability',
      'mean_value_of_long_term_variability',
    ],
    'Histogram Analysis': [
      'histogram_width',
      'histogram_min',
      'histogram_max',
      'histogram_number_of_peaks',
      'histogram_number_of_zeroes',
      'histogram_mode',
      'histogram_mean',
      'histogram_median',
      'histogram_variance',
      'histogram_tendency',
    ],
  };

  /// Run prediction: tries server first, then offline.
  static Future<FetalHealthResult> predict(List<double> features) async {
    // Try online prediction first
    try {
      final result = await _predictOnline(features)
          .timeout(const Duration(seconds: 5));
      return result;
    } catch (_) {
      // Fall back to offline prediction
      return _predictOffline(features);
    }
  }

  /// Predict via Flask API.
  static Future<FetalHealthResult> _predictOnline(
      List<double> features) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/predict'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'features': features}),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return FetalHealthResult(
        prediction: data['prediction'] as int,
        label: data['label'] as String,
        confidence: (data['confidence'] as num).toDouble(),
        xaiReasons: List<Map<String, dynamic>>.from(data['xai_reasons']),
        isOffline: false,
      );
    } else {
      throw Exception('Server error: ${response.statusCode}');
    }
  }

  /// Predict using the embedded offline model.
  static Future<FetalHealthResult> _predictOffline(
      List<double> features) async {
    // Ensure the model is loaded
    if (!OfflineModelService.isLoaded) {
      await OfflineModelService.loadModel();
    }

    final result = OfflineModelService.predict(features);
    return FetalHealthResult(
      prediction: result['prediction'] as int,
      label: result['label'] as String,
      confidence: (result['confidence'] as num).toDouble(),
      xaiReasons: List<Map<String, dynamic>>.from(result['xai_reasons']),
      isOffline: true,
    );
  }
}
