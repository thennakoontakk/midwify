import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

/// Pure Dart Random Forest inference engine.
/// Loads the exported JSON model and runs predictions entirely offline.
class OfflineModelService {
  static Map<String, dynamic>? _modelData;
  static bool _isLoaded = false;

  /// Load the RF model JSON from app assets.
  static Future<void> loadModel() async {
    if (_isLoaded) return;
    final jsonStr =
        await rootBundle.loadString('assets/fetal_health_rf_model.json');
    _modelData = json.decode(jsonStr) as Map<String, dynamic>;
    _isLoaded = true;
  }

  /// Check if the model is loaded.
  static bool get isLoaded => _isLoaded;

  /// Get feature names from the model.
  static List<String> get featureNames {
    if (_modelData == null) return [];
    return List<String>.from(_modelData!['feature_names']);
  }

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

  /// Run prediction on a feature vector (21 doubles).
  /// Returns a map with: prediction, label, confidence, xai_reasons.
  static Map<String, dynamic> predict(List<double> features) {
    if (_modelData == null) {
      throw Exception('Model not loaded. Call loadModel() first.');
    }

    final classes =
        List<double>.from(_modelData!['classes'].map((e) => (e as num).toDouble()));
    final trees = _modelData!['trees'] as List;
    final nClasses = classes.length;

    // Accumulate votes from all trees
    final votes = List<double>.filled(nClasses, 0.0);

    for (final tree in trees) {
      final nodes = tree as List;
      final leafValues = _traverseTree(nodes, features);

      // leafValues is the vote count per class from this tree
      final total = leafValues.fold<double>(0, (a, b) => a + b);
      if (total > 0) {
        for (int i = 0; i < nClasses && i < leafValues.length; i++) {
          votes[i] += leafValues[i] / total;
        }
      }
    }

    // Normalize to get probabilities
    final totalVotes = votes.fold<double>(0, (a, b) => a + b);
    final probabilities = totalVotes > 0
        ? votes.map((v) => v / totalVotes).toList()
        : List<double>.filled(nClasses, 1.0 / nClasses);

    // Find the class with highest probability
    int maxIdx = 0;
    for (int i = 1; i < probabilities.length; i++) {
      if (probabilities[i] > probabilities[maxIdx]) {
        maxIdx = i;
      }
    }

    final prediction = classes[maxIdx].toInt();
    final confidence = probabilities[maxIdx];

    // Labels
    final labels = {1: 'Normal', 2: 'Suspect', 3: 'Pathological'};

    // Generate XAI reasons
    final xaiReasons = _generateXaiReasons(features, prediction);

    return {
      'prediction': prediction,
      'label': labels[prediction] ?? 'Unknown',
      'confidence': double.parse(confidence.toStringAsFixed(4)),
      'xai_reasons': xaiReasons,
    };
  }

  /// Traverse a single decision tree to get leaf node class votes.
  static List<double> _traverseTree(List nodes, List<double> features) {
    int nodeIdx = 0;

    while (true) {
      final node = nodes[nodeIdx] as Map<String, dynamic>;
      final leftChild = node['left_child'] as int;
      final rightChild = node['right_child'] as int;

      // Leaf node: left_child == right_child == -1 in sklearn
      // Actually sklearn uses TREE_LEAF = -1
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

  /// Generate XAI reasons for non-Normal predictions.
  static List<Map<String, dynamic>> _generateXaiReasons(
      List<double> features, int prediction) {
    if (prediction == 1) return []; // Normal, no reasons needed

    final fNames = featureNames;
    final importances = featureImportances;
    final clinicalLabels = featureClinicalLabels;

    // Create indexed list and sort by importance
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

    // Take top 5 features with importance > 0.02
    final reasons = <Map<String, dynamic>>[];
    for (final feat in indexed) {
      if (reasons.length >= 5) break;
      if ((feat['importance'] as double) > 0.02) {
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
}
