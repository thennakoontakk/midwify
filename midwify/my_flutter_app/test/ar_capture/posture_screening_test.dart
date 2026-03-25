import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/services/ar_capture/posture_screening.dart';

List<List<double>> _buildPose({
  required List<double> nose,
  required List<double> leftEye,
  required List<double> rightEye,
  required List<double> leftEar,
  required List<double> rightEar,
  required List<double> leftShoulder,
  required List<double> rightShoulder,
  required List<double> leftHip,
  required List<double> rightHip,
}) {
  final pose = List.generate(17, (_) => <double>[0.0, 0.0, 0.0]);
  pose[0] = nose;
  pose[1] = leftEye;
  pose[2] = rightEye;
  pose[3] = leftEar;
  pose[4] = rightEar;
  pose[5] = leftShoulder;
  pose[6] = rightShoulder;
  pose[11] = leftHip;
  pose[12] = rightHip;
  return pose;
}

List<List<double>> _balancedPose() {
  return _buildPose(
    nose: [0.22, 0.50, 0.95],
    leftEye: [0.21, 0.46, 0.90],
    rightEye: [0.21, 0.54, 0.90],
    leftEar: [0.22, 0.42, 0.82],
    rightEar: [0.22, 0.58, 0.82],
    leftShoulder: [0.35, 0.40, 0.95],
    rightShoulder: [0.35, 0.60, 0.95],
    leftHip: [0.65, 0.42, 0.95],
    rightHip: [0.65, 0.58, 0.95],
  );
}

List<List<double>> _translatePose(
  List<List<double>> pose, {
  required double dx,
  required double dy,
}) {
  return pose
      .map((kp) => <double>[
            kp[0] + dy,
            kp[1] + dx,
            kp[2],
          ])
      .toList();
}

void main() {
  group('posture screening', () {
    test('balanced pose produces a supported low-risk screen', () {
      final result = analyzePostureKeypoints(_balancedPose());

      expect(result.supportedView, isTrue);
      expect(result.riskBand, PostureRiskBand.lowRisk);
      expect(result.screeningScore, lessThan(35));
      expect(result.shoulderTiltDeg, closeTo(0.0, 0.01));
      expect(result.hipTiltDeg, closeTo(0.0, 0.01));
    });

    test('large body tilt escalates the screening band', () {
      final result = analyzePostureKeypoints(
        _buildPose(
          nose: [0.20, 0.46, 0.95],
          leftEye: [0.18, 0.42, 0.90],
          rightEye: [0.24, 0.58, 0.90],
          leftEar: [0.18, 0.40, 0.82],
          rightEar: [0.28, 0.60, 0.82],
          leftShoulder: [0.32, 0.38, 0.95],
          rightShoulder: [0.40, 0.62, 0.95],
          leftHip: [0.64, 0.46, 0.95],
          rightHip: [0.76, 0.64, 0.95],
        ),
      );

      expect(result.screeningScore, greaterThanOrEqualTo(35));
      expect(result.riskBand.index, greaterThanOrEqualTo(PostureRiskBand.review.index));
      expect(result.shoulderTiltDeg, greaterThan(10.0));
      expect(result.hipTiltDeg, greaterThan(20.0));
    });

    test('low keypoint visibility rejects the capture', () {
      final result = analyzePostureKeypoints(
        _buildPose(
          nose: [0.22, 0.50, 0.30],
          leftEye: [0.21, 0.46, 0.30],
          rightEye: [0.21, 0.54, 0.30],
          leftEar: [0.22, 0.42, 0.25],
          rightEar: [0.22, 0.58, 0.25],
          leftShoulder: [0.35, 0.40, 0.20],
          rightShoulder: [0.35, 0.60, 0.20],
          leftHip: [0.65, 0.42, 0.20],
          rightHip: [0.65, 0.58, 0.20],
        ),
      );

      expect(result.supportedView, isFalse);
      expect(result.screeningScore, greaterThanOrEqualTo(55));
      expect(result.warnings, isNotEmpty);
    });

    test('metrics stay stable under translation', () {
      final base = analyzePostureKeypoints(_balancedPose());
      final shifted = analyzePostureKeypoints(
        _translatePose(_balancedPose(), dx: 0.08, dy: 0.05),
      );

      expect(shifted.shoulderTiltDeg, closeTo(base.shoulderTiltDeg, 0.01));
      expect(shifted.hipTiltDeg, closeTo(base.hipTiltDeg, 0.01));
      expect(shifted.midlineOffsetRatio, closeTo(base.midlineOffsetRatio, 0.01));
    });
  });
}
