"""
Export a trained scikit-learn RandomForestClassifier to a JSON file
that can be loaded by the Flutter app for offline inference.

Each tree is serialized as a list of nodes with:
  - feature_index, threshold, left_child, right_child, value (class votes)

Usage:
    python export_model_to_json.py
"""

import json
import pickle
import os
import numpy as np

# ── Feature names (same order as training) ─────────────────────────────
FEATURE_NAMES = [
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
]

FEATURE_CLINICAL_LABELS = {
    'baseline value': 'Abnormal Baseline Fetal Heart Rate',
    'accelerations': 'Reduced Fetal Heart Rate Accelerations',
    'fetal_movement': 'Reduced Fetal Movement Detected',
    'uterine_contractions': 'Abnormal Uterine Contraction Pattern',
    'light_decelerations': 'Light Decelerations Detected',
    'severe_decelerations': 'Severe Decelerations Detected',
    'prolongued_decelerations': 'Prolonged Decelerations Detected',
    'abnormal_short_term_variability': 'High Abnormal Short-Term Variability',
    'mean_value_of_short_term_variability': 'Abnormal Mean Short-Term Variability',
    'percentage_of_time_with_abnormal_long_term_variability':
        'Elevated Abnormal Long-Term Variability Percentage',
    'mean_value_of_long_term_variability': 'Abnormal Mean Long-Term Variability',
    'histogram_width': 'Abnormal FHR Histogram Width',
    'histogram_min': 'Low FHR Histogram Minimum',
    'histogram_max': 'High FHR Histogram Maximum',
    'histogram_number_of_peaks': 'Abnormal Number of Histogram Peaks',
    'histogram_number_of_zeroes': 'Abnormal Number of Histogram Zeroes',
    'histogram_mode': 'Abnormal FHR Histogram Mode',
    'histogram_mean': 'Abnormal FHR Histogram Mean',
    'histogram_median': 'Abnormal FHR Histogram Median',
    'histogram_variance': 'High FHR Histogram Variance',
    'histogram_tendency': 'Abnormal FHR Histogram Tendency',
}


def export_tree(tree):
    """Convert a single sklearn DecisionTree to a list of node dicts."""
    tree_ = tree.tree_
    nodes = []

    for i in range(tree_.node_count):
        node = {
            'feature_index': int(tree_.feature[i]),
            'threshold': float(tree_.threshold[i]),
            'left_child': int(tree_.children_left[i]),
            'right_child': int(tree_.children_right[i]),
            # value shape: (n_nodes, n_classes_in_output, n_classes)
            # For classification, value[i][0] gives the count per class
            'value': tree_.value[i][0].tolist(),
        }
        nodes.append(node)

    return nodes


def main():
    model_path = os.path.join(os.path.dirname(__file__), 'fetal_health_model.pkl')
    print(f'Loading model from: {model_path}')

    with open(model_path, 'rb') as f:
        model = pickle.load(f)

    # Export all trees
    trees = []
    for i, estimator in enumerate(model.estimators_):
        trees.append(export_tree(estimator))
    print(f'Exported {len(trees)} decision trees')

    # Get class labels from the model
    classes = model.classes_.tolist()
    print(f'Classes: {classes}')

    # Feature importances
    importances = model.feature_importances_.tolist()

    # Build output JSON
    model_json = {
        'n_estimators': len(trees),
        'n_features': len(FEATURE_NAMES),
        'classes': classes,
        'feature_names': FEATURE_NAMES,
        'feature_importances': importances,
        'feature_clinical_labels': FEATURE_CLINICAL_LABELS,
        'trees': trees,
    }

    # Save to Flutter assets directory
    flutter_assets_dir = os.path.join(
        os.path.dirname(__file__),
        '..', 'my_flutter_app', 'assets'
    )
    os.makedirs(flutter_assets_dir, exist_ok=True)

    output_path = os.path.join(flutter_assets_dir, 'fetal_health_rf_model.json')
    with open(output_path, 'w') as f:
        json.dump(model_json, f)

    file_size_mb = os.path.getsize(output_path) / (1024 * 1024)
    print(f'Model exported to: {output_path}')
    print(f'File size: {file_size_mb:.2f} MB')
    print('Done! This JSON file will be bundled as a Flutter asset.')


if __name__ == '__main__':
    main()
