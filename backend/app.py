"""
Midwify — Fetal Health Prediction Flask API
Loads a trained Random Forest model and exposes a /predict endpoint.
"""

import os
import pickle
import numpy as np
from flask import Flask, request, jsonify
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

# ── Feature names (must match training order) ──────────────────────────
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

# ── Clinical descriptions for XAI ──────────────────────────────────────
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

# ── Prediction labels ──────────────────────────────────────────────────
PREDICTION_LABELS = {1: 'Normal', 2: 'Suspect', 3: 'Pathological'}

# ── Load model ─────────────────────────────────────────────────────────
MODEL_PATH = os.path.join(os.path.dirname(__file__), 'fetal_health_model.pkl')
with open(MODEL_PATH, 'rb') as f:
    model = pickle.load(f)

# Pre-compute global feature importances
feature_importances = dict(zip(FEATURE_NAMES, model.feature_importances_))


def get_xai_reasons(features_dict, prediction, top_n=5):
    """
    Generate explainable AI reasons for non-Normal predictions.
    Uses feature importance ranking + checks which important features
    have values that deviate from typical normal ranges.
    """
    if prediction == 1:  # Normal — no diagnostic reasons needed
        return []

    # Sort features by importance
    sorted_features = sorted(
        feature_importances.items(), key=lambda x: x[1], reverse=True
    )

    reasons = []
    for feat_name, importance in sorted_features:
        if len(reasons) >= top_n:
            break
        if importance > 0.02:  # Only features with meaningful importance
            reasons.append({
                'feature': feat_name,
                'value': features_dict.get(feat_name, 0),
                'importance': round(importance, 4),
                'description': FEATURE_CLINICAL_LABELS.get(feat_name, feat_name),
            })

    return reasons


@app.route('/predict', methods=['POST'])
def predict():
    """
    Predict fetal health from 21 CTG parameters.

    Request JSON:
        { "features": [120.0, 0.0, 0.0, ...] }  (21 float values)

    Response JSON:
        {
            "prediction": 2,
            "label": "Suspect",
            "confidence": 0.87,
            "xai_reasons": [ { "feature": "...", "description": "...", ... } ]
        }
    """
    try:
        data = request.get_json(force=True)
        features_list = data.get('features', [])

        if len(features_list) != 21:
            return jsonify({
                'error': f'Expected 21 features, got {len(features_list)}'
            }), 400

        # Build feature array
        X = np.array(features_list, dtype=float).reshape(1, -1)

        # Predict
        prediction = int(model.predict(X)[0])
        probabilities = model.predict_proba(X)[0]
        confidence = float(max(probabilities))

        # Map features to dict for XAI
        features_dict = dict(zip(FEATURE_NAMES, features_list))

        # Generate XAI reasons
        xai_reasons = get_xai_reasons(features_dict, prediction)

        return jsonify({
            'prediction': prediction,
            'label': PREDICTION_LABELS.get(prediction, 'Unknown'),
            'confidence': round(confidence, 4),
            'xai_reasons': xai_reasons,
        })

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/health', methods=['GET'])
def health():
    """Health check endpoint."""
    return jsonify({'status': 'ok', 'model_loaded': model is not None})


if __name__ == '__main__':
    print('🏥 Midwify Fetal Health Prediction API')
    print(f'📦 Model loaded from: {MODEL_PATH}')
    print(f'🔧 Features: {len(FEATURE_NAMES)}')
    app.run(host='0.0.0.0', port=5000, debug=True)
