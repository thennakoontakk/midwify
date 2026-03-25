import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/services/ar_capture/classifier_service.dart';
import 'package:midwify/services/ar_capture/cranial_metrics.dart';

const _baseGeometry = CranialResult(
  cranialIndex: 80.0,
  cvai: 2.0,
  facialSymmetryOffsetPct: 2.0,
  cephalicProportionScore: 95.0,
  landmarkQualityScore: 82.0,
  topDownAngleDelta: 0.08,
  validCameraAngle: true,
  supportedView: true,
  qualityScore: 82,
  screeningScore: 22,
  riskBand: CranialRiskBand.lowRisk,
  warnings: [],
  reasons: [],
);

void main() {
  group('classifyHeadProbability', () {
    test('maps notebook low threshold to normal', () {
      expect(classifyHeadProbability(0.20), HeadClassifierDecision.normal);
    });

    test('maps notebook grey zone to uncertain', () {
      expect(classifyHeadProbability(0.60), HeadClassifierDecision.uncertain);
    });

    test('maps notebook high threshold to abnormal', () {
      expect(classifyHeadProbability(0.90), HeadClassifierDecision.abnormal);
    });
  });

  group('fuseHeadSignals', () {
    test('normal classifier does not downgrade a mild geometry review', () {
      const geometry = CranialResult(
        cranialIndex: 84.5,
        cvai: 4.4,
        facialSymmetryOffsetPct: 6.4,
        cephalicProportionScore: 78.0,
        landmarkQualityScore: 78.0,
        topDownAngleDelta: 0.07,
        validCameraAngle: true,
        supportedView: true,
        qualityScore: 78,
        screeningScore: 38,
        riskBand: CranialRiskBand.review,
        warnings: [],
        reasons: ['Mild frontal asymmetry is present across diagonal landmarks.'],
      );

      const classification = HeadShapeClassification(
        abnormalProbability: 0.18,
        normalProbability: 0.82,
        decision: HeadClassifierDecision.normal,
        source: 'assets/models/cranial_analysis.tflite',
      );

      final fused = fuseHeadSignals(
        geometry: geometry,
        classification: classification,
      );

      expect(fused.screeningScore, greaterThanOrEqualTo(35));
      expect(fused.riskBand, CranialRiskBand.review);
    });

    test('abnormal classifier escalates a low-risk geometry screen', () {
      const classification = HeadShapeClassification(
        abnormalProbability: 0.93,
        normalProbability: 0.07,
        decision: HeadClassifierDecision.abnormal,
        source: 'assets/models/cranial_analysis.tflite',
      );

      final fused = fuseHeadSignals(
        geometry: _baseGeometry,
        classification: classification,
      );

      expect(fused.screeningScore, greaterThanOrEqualTo(40));
      expect(fused.riskBand, isNot(CranialRiskBand.lowRisk));
    });

    test('abnormal classifier does not force refer on mild geometry review', () {
      const geometry = CranialResult(
        cranialIndex: 83.5,
        cvai: 4.6,
        facialSymmetryOffsetPct: 6.2,
        cephalicProportionScore: 81.0,
        landmarkQualityScore: 79.0,
        topDownAngleDelta: 0.08,
        validCameraAngle: true,
        supportedView: true,
        qualityScore: 79,
        screeningScore: 40,
        riskBand: CranialRiskBand.review,
        warnings: [],
        reasons: ['Mild frontal asymmetry is present across diagonal landmarks.'],
      );

      const classification = HeadShapeClassification(
        abnormalProbability: 0.88,
        normalProbability: 0.12,
        decision: HeadClassifierDecision.abnormal,
        source: 'assets/models/cranial_analysis.tflite',
      );

      final fused = fuseHeadSignals(
        geometry: geometry,
        classification: classification,
      );

      expect(fused.screeningScore, lessThan(70));
      expect(fused.riskBand, CranialRiskBand.review);
    });

    test('unsupported geometry remains at least review-level', () {
      const geometry = CranialResult(
        cranialIndex: 80.0,
        cvai: 2.0,
        facialSymmetryOffsetPct: 2.0,
        cephalicProportionScore: 95.0,
        landmarkQualityScore: 22.0,
        topDownAngleDelta: 0.001,
        validCameraAngle: false,
        supportedView: false,
        qualityScore: 22,
        screeningScore: 12,
        riskBand: CranialRiskBand.lowRisk,
        warnings: ['Camera angle too flat.'],
        reasons: ['Capture quality is insufficient for a reliable low-risk screen.'],
        cameraAngleError: 'Camera angle too flat.',
      );

      const classification = HeadShapeClassification(
        abnormalProbability: 0.15,
        normalProbability: 0.85,
        decision: HeadClassifierDecision.normal,
        source: 'assets/models/cranial_analysis.tflite',
      );

      final fused = fuseHeadSignals(
        geometry: geometry,
        classification: classification,
      );

      expect(fused.screeningScore, greaterThanOrEqualTo(55));
      expect(fused.riskBand, isNot(CranialRiskBand.lowRisk));
      expect(fused.summary, contains('Unsupported'));
    });
  });
}
