import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/screens/ar_capture/ar_capture_models.dart';
import 'package:midwify/screens/ar_capture/diagnosis_screen.dart';

void main() {
  Widget buildScreen(ARCaptureResult result) {
    return MaterialApp(
      home: DiagnosisScreen(
        mode: AppMode.posture,
        language: AppLanguage.en,
        result: result,
        onRetake: () {},
        onFinish: () {},
        onOpenGeometricTool: () {},
      ),
    );
  }

  const postureMetrics = PostureScreeningMetrics(
    shoulderTiltDeg: 2.5,
    hipTiltDeg: 1.4,
    trunkTiltDeg: 2.2,
    headTiltDeg: 1.1,
    midlineOffsetRatio: 0.06,
    visibilityQuality: 92,
    cameraRollDeg: 0.8,
  );

  testWidgets(
    'does not show posture review status for low-risk posture results',
    (tester) async {
      const result = ARCaptureResult(
        isValidImage: true,
        supportedView: true,
        qualityScore: 92,
        screeningScore: 18,
        riskBand: RiskBand.lowRisk,
        summary: 'Low-signal posture research result from body keypoints.',
        warnings: [],
        landmarkSource: 'assets/models/posture_analysis.tflite',
        postureMetrics: postureMetrics,
      );

      await tester.pumpWidget(buildScreen(result));

      expect(find.text('Review Status'), findsNothing);
      expect(find.textContaining('Pending'), findsNothing);
    },
  );

  testWidgets(
    'shows pending posture review status for refer-level posture results',
    (tester) async {
      const result = ARCaptureResult(
        isValidImage: true,
        supportedView: true,
        qualityScore: 88,
        screeningScore: 76,
        riskBand: RiskBand.refer,
        summary:
            'High-priority posture research signal from the captured body keypoints. This is still not a diagnosis.',
        warnings: [],
        landmarkSource: 'assets/models/posture_analysis.tflite',
        postureMetrics: postureMetrics,
      );

      await tester.pumpWidget(buildScreen(result));

      expect(find.text('Review Status: Pending'), findsOneWidget);
    },
  );
}
