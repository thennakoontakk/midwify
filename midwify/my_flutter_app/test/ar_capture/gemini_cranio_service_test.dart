import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/screens/ar_capture/ar_capture_models.dart';
import 'package:midwify/services/ar_capture/gemini_cranio_service.dart';

void main() {
  group('CranioAIResult', () {
    test('parses Gemini JSON payload and maps moderate risk to review band', () {
      final result = CranioAIResult.fromJson({
        'riskLevel': 'moderate',
        'riskScore': 64,
        'headShapeClassification': 'plagiocephaly',
        'confidence': 'medium',
        'keyFindings': [
          'Photo shows mild right-sided flattening confirmed by asymmetryIndex of 4.2%.',
          'Visual forehead asymmetry matches the structured geometry payload.',
        ],
        'geometrySignals': {
          'cephalicIndexRisk': 'normal',
          'asymmetryRisk': 'mild',
          'orbitalSymmetryRisk': 'normal',
        },
        'visualObservations':
            'Photo shows mild right posterior flattening with preserved frontal contour.',
        'urgency': 'soon',
        'recommendation':
            'Arrange pediatric follow-up soon and repeat the scan with a supported view if concerns remain.',
        'disclaimer':
            'This is a screening tool only. Always consult a pediatrician or craniofacial specialist for diagnosis.',
      });

      expect(result.riskBand, RiskBand.review);
      expect(result.riskScore, 64);
      expect(result.headShapeClassification, 'plagiocephaly');
      expect(result.geometrySignals.asymmetryRisk, 'mild');
    });

    test('maps high and low risk levels to existing UI bands', () {
      final high = CranioAIResult.fromJson({
        'riskLevel': 'high',
        'riskScore': 90,
        'headShapeClassification': 'scaphocephaly',
        'confidence': 'high',
        'keyFindings': const [],
        'geometrySignals': const {},
        'visualObservations': '',
        'urgency': 'urgent',
        'recommendation': '',
        'disclaimer': '',
      });
      final low = CranioAIResult.fromJson({
        'riskLevel': 'low',
        'riskScore': 12,
        'headShapeClassification': 'normal',
        'confidence': 'low',
        'keyFindings': const [],
        'geometrySignals': const {},
        'visualObservations': '',
        'urgency': 'routine',
        'recommendation': '',
        'disclaimer': '',
      });

      expect(high.riskBand, RiskBand.refer);
      expect(low.riskBand, RiskBand.lowRisk);
    });
  });

  group('GeminiCranioService', () {
    test('maps timeout failures to a user-facing fallback message', () {
      final message = GeminiCranioService.userVisibleFailureMessage(
        Exception(
          'Gemini cranial analysis failed: TimeoutException after 0:00:25.000000: Future not completed',
        ),
      );

      expect(
        message,
        'AI-assisted photo review did not respond in time, so this result uses on-device geometry only.',
      );
    });
  });
}
