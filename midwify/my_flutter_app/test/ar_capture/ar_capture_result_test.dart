import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/screens/ar_capture/ar_capture_models.dart';

void main() {
  test('ARCaptureResult copyWith preserves posture data and verification state',
      () {
    const original = ARCaptureResult(
      isValidImage: true,
      supportedView: true,
      qualityScore: 82,
      screeningScore: 76,
      riskBand: RiskBand.refer,
      summary:
          'High-priority posture research signal from the captured body keypoints. This is still not a diagnosis.',
      warnings: [
        'Research-only pipeline: MoveNet pose keypoints plus rule-based posture geometry.'
      ],
      landmarkSource: 'assets/models/posture_analysis.tflite',
      captureImagePath: 'C:/tmp/posture.jpg',
      postureMetrics: PostureScreeningMetrics(
        shoulderTiltDeg: 7.2,
        hipTiltDeg: 5.4,
        trunkTiltDeg: 8.1,
        headTiltDeg: 3.6,
        midlineOffsetRatio: 0.11,
        visibilityQuality: 88,
        cameraRollDeg: 1.1,
      ),
      debugDetails: {
        'manualReview': {'status': 'pending'},
      },
    );

    final updated = original.copyWith(
      geometricReviewConfirmed: true,
      geometricReviewNote:
          'Geometric review confirmed against the captured body landmarks.',
      debugDetails: {
        ...original.debugDetails,
        'manualReview': {
          'status': 'confirmed',
        },
      },
    );

    expect(updated.captureImagePath, 'C:/tmp/posture.jpg');
    expect(updated.postureMetrics, isNotNull);
    expect(updated.geometricReviewConfirmed, isTrue);
    expect(
      updated.geometricReviewNote,
      'Geometric review confirmed against the captured body landmarks.',
    );
    expect(
      (updated.debugDetails['manualReview'] as Map<String, dynamic>)['status'],
      'confirmed',
    );
  });
}
