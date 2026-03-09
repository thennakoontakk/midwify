import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Pure Dart Random Forest inference engine for Maternal Health Risk.
/// Loads the exported JSON model and runs predictions entirely offline.
class OfflineMaternalModelService {
  static Map<String, dynamic>? _modelData;
  static bool _isLoaded = false;

  /// Load the RF model JSON from app assets.
  static Future<void> loadModel() async {
    if (_isLoaded) return;
    try {
      final jsonStr =
          await rootBundle.loadString('assets/maternal_risk_rf_model.json');
      _modelData = json.decode(jsonStr) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      // Model might not be exported yet, fail gracefully
      _isLoaded = false;
    }
  }

  /// Check if the model is loaded.
  static bool get isLoaded => _isLoaded;

  /// Get feature importances.
  static List<double> get featureImportances {
    if (_modelData == null) return [];
    return List<double>.from(
        _modelData!['feature_importances'].map((e) => (e as num).toDouble()));
  }

  /// Get clinical labels for features.
  static Map<String, String> get featureClinicalLabels {
    if (_modelData == null) return {};
    return Map<String, String>.from(_modelData!['feature_clinical_labels']);
  }

  /// Run prediction on a feature vector (6 doubles).
  /// Features: [Age, SystolicBP, DiastolicBP, BS, BodyTemp, HeartRate]
  static Map<String, dynamic> predict(List<double> features) {
    if (_modelData == null) {
      throw Exception('Maternal Model not loaded offline. Try API first.');
    }

    // Classes could be ints or strings based on how it was trained
    final classesRaw = _modelData!['classes'] as List;
    final trees = _modelData!['trees'] as List;
    final nClasses = classesRaw.length;

    // Accumulate votes from all trees
    final votes = List<double>.filled(nClasses, 0.0);

    for (final tree in trees) {
      final nodes = tree as List;
      final leafValues = _traverseTree(nodes, features);

      final total = leafValues.fold<double>(0, (a, b) => a + b);
      if (total > 0) {
        for (int i = 0; i < nClasses && i < leafValues.length; i++) {
          votes[i] += leafValues[i] / total;
        }
      }
    }

    // Normalize
    final totalVotes = votes.fold<double>(0, (a, b) => a + b);
    final probabilities = totalVotes > 0
        ? votes.map((v) => v / totalVotes).toList()
        : List<double>.filled(nClasses, 1.0 / nClasses);

    int maxIdx = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[maxIdx]) {
        maxIdx = i;
      }
    }

    final rawPrediction = classesRaw[maxIdx];
    final confidence = probabilities[maxIdx];

    int predScore;
    String label;

    if (rawPrediction is String) {
      label = _capitalizeTitle(rawPrediction);
      predScore = _mapStringToScore(rawPrediction);
    } else {
      predScore = (rawPrediction as num).toInt();
      label = _mapScoreToLabel(predScore);
    }

    final xaiReasons = _generateXaiReasons(features, predScore);

    return {
      'prediction': predScore,
      'label': label,
      'confidence': double.parse(confidence.toStringAsFixed(4)),
      'xai_reasons': xaiReasons,
    };
  }

  static List<double> _traverseTree(List nodes, List<double> features) {
    int nodeIdx = 0;
    while (true) {
      final node = nodes[nodeIdx] as Map<String, dynamic>;
      final leftChild = node['left_child'] as int;
      final rightChild = node['right_child'] as int;

      if (leftChild == -1 || rightChild == -1) {
        return List<double>.from(
            (node['value'] as List).map((e) => (e as num).toDouble()));
      }

      final featureIdx = node['feature_index'] as int;
      final threshold = (node['threshold'] as num).toDouble();

      if (features[featureIdx] <= threshold) {
        nodeIdx = leftChild;
      } else {
        nodeIdx = rightChild;
      }
    }
  }

  static List<Map<String, dynamic>> _generateXaiReasons(
      List<double> features, int predictionScore) {
    if (predictionScore == 1) return []; // Low risk

    final fNames = List<String>.from(_modelData!['feature_names']);
    final importances = featureImportances;
    final clinicalLabels = featureClinicalLabels;

    final indexed = <Map<String, dynamic>>[];
    for (int i = 0; i < fNames.length && i < importances.length; i++) {
      indexed.add({
        'index': i,
        'name': fNames[i],
        'importance': importances[i],
      });
    }
    indexed.sort((a, b) =>
        (b['importance'] as double).compareTo(a['importance'] as double));

    final reasons = <Map<String, dynamic>>[];
    for (final feat in indexed) {
      if (reasons.length >= 3) break;
      if ((feat['importance'] as double) > 0.05) {
        final name = feat['name'] as String;
        reasons.add({
          'feature': name,
          'value': features[feat['index'] as int],
          'importance':
              double.parse((feat['importance'] as double).toStringAsFixed(4)),
          'description': clinicalLabels[name] ?? name,
        });
      }
    }
    return reasons;
  }

  static int _mapStringToScore(String pred) {
    final lower = pred.toLowerCase();
    if (lower.contains('low')) return 1;
    if (lower.contains('mid')) return 3;
    if (lower.contains('high')) return 6;
    return 1;
  }

  static String _mapScoreToLabel(int score) {
    if (score == 1) return 'Low Risk';
    if (score == 3) return 'Mid Risk';
    if (score == 6) return 'High Risk';
    return 'Unknown';
  }

  static String _capitalizeTitle(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
