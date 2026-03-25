import 'dart:math' as math;

enum PostureRiskBand { lowRisk, review, refer }

class PoseKeypoint {
  final double y;
  final double x;
  final double confidence;

  const PoseKeypoint({
    required this.y,
    required this.x,
    required this.confidence,
  });
}

class PostureAssessment {
  final double shoulderTiltDeg;
  final double hipTiltDeg;
  final double trunkTiltDeg;
  final double headTiltDeg;
  final double midlineOffsetRatio;
  final double visibilityQuality;
  final double cameraRollDeg;
  final int qualityScore;
  final int screeningScore;
  final bool supportedView;
  final PostureRiskBand riskBand;
  final List<String> warnings;

  const PostureAssessment({
    required this.shoulderTiltDeg,
    required this.hipTiltDeg,
    required this.trunkTiltDeg,
    required this.headTiltDeg,
    required this.midlineOffsetRatio,
    required this.visibilityQuality,
    required this.cameraRollDeg,
    required this.qualityScore,
    required this.screeningScore,
    required this.supportedView,
    required this.riskBand,
    required this.warnings,
  });
}

const int _noseIdx = 0;
const int _leftEyeIdx = 1;
const int _rightEyeIdx = 2;
const int _leftEarIdx = 3;
const int _rightEarIdx = 4;
const int _leftShoulderIdx = 5;
const int _rightShoulderIdx = 6;
const int _leftHipIdx = 11;
const int _rightHipIdx = 12;

PostureAssessment analyzePostureKeypoints(List<List<double>> keypoints) {
  final pose = keypoints
      .map((kp) => PoseKeypoint(
            y: kp[0],
            x: kp[1],
            confidence: kp[2],
          ))
      .toList();

  final required = [
    pose[_leftShoulderIdx],
    pose[_rightShoulderIdx],
    pose[_leftHipIdx],
    pose[_rightHipIdx],
  ];
  final visibilityQuality =
      required.map((kp) => kp.confidence).reduce((a, b) => a + b) /
          required.length;

  final warnings = <String>[];
  if (visibilityQuality < 0.45) {
    warnings.add('Keypoint visibility is low. Keep the shoulders and hips fully visible.');
  }

  final shoulderLine = _signedAngleFromHorizontalDeg(
    pose[_leftShoulderIdx],
    pose[_rightShoulderIdx],
  );
  final hipLine = _signedAngleFromHorizontalDeg(
    pose[_leftHipIdx],
    pose[_rightHipIdx],
  );
  final cameraRollDeg = (shoulderLine + hipLine) / 2.0;

  final shoulderCenter = _midpoint(
    pose[_leftShoulderIdx],
    pose[_rightShoulderIdx],
  );
  final hipCenter = _midpoint(
    pose[_leftHipIdx],
    pose[_rightHipIdx],
  );
  final torsoHeight = (hipCenter.y - shoulderCenter.y).abs();
  final shoulderWidth =
      (pose[_rightShoulderIdx].x - pose[_leftShoulderIdx].x).abs();
  final hipWidth = (pose[_rightHipIdx].x - pose[_leftHipIdx].x).abs();

  if (torsoHeight < 0.08) {
    warnings.add('Torso span is too small. Move the camera closer to the baby.');
  }

  if (shoulderWidth < 0.08 || hipWidth < 0.08) {
    warnings.add('The body appears too narrow for a frontal asymmetry screen.');
  }

  final supportedView = visibilityQuality >= 0.45 &&
      torsoHeight >= 0.08 &&
      shoulderWidth >= 0.08 &&
      hipWidth >= 0.08;

  final normalizedShoulderTiltDeg = shoulderLine.abs();
  final normalizedHipTiltDeg = hipLine.abs();
  final trunkTiltDeg =
      _angleFromVerticalDeg(shoulderCenter.x, shoulderCenter.y, hipCenter.x, hipCenter.y);

  final headLeft = _bestHeadAnchor(pose[_leftEarIdx], pose[_leftEyeIdx]);
  final headRight = _bestHeadAnchor(pose[_rightEarIdx], pose[_rightEyeIdx]);
  final headTiltDeg = (headLeft != null && headRight != null)
      ? _signedAngleFromHorizontalDeg(headLeft, headRight).abs()
      : 0.0;

  final midlineOffsetRatio = torsoHeight < 1e-6
      ? 0.0
      : ((shoulderCenter.x - hipCenter.x).abs() / torsoHeight);

  final qualityScore = ((visibilityQuality * 65) +
          (_scoreInverse(normalizedShoulderTiltDeg, 20) * 15) +
          (_scoreInverse(normalizedHipTiltDeg, 20) * 15) +
          (_scoreInverse(trunkTiltDeg, 25) * 5))
      .round()
      .clamp(0, 100);

  int screeningScore = 0;
  screeningScore += _scoreFromAngle(normalizedShoulderTiltDeg, soft: 4, hard: 10, max: 25);
  screeningScore += _scoreFromAngle(normalizedHipTiltDeg, soft: 4, hard: 10, max: 25);
  screeningScore += _scoreFromAngle(trunkTiltDeg, soft: 5, hard: 12, max: 30);
  screeningScore += _scoreFromAngle(headTiltDeg, soft: 4, hard: 12, max: 15);
  screeningScore += _scoreFromRatio(midlineOffsetRatio, soft: 0.08, hard: 0.16, max: 15);

  if (!supportedView) {
    screeningScore = math.max(screeningScore, 55);
    warnings.add('Unsupported posture view. Retake with a centered frontal or top-down body view.');
  }

  final riskBand = screeningScore >= 70
      ? PostureRiskBand.refer
      : screeningScore >= 35
          ? PostureRiskBand.review
          : PostureRiskBand.lowRisk;

  return PostureAssessment(
    shoulderTiltDeg: _r2(normalizedShoulderTiltDeg),
    hipTiltDeg: _r2(normalizedHipTiltDeg),
    trunkTiltDeg: _r2(trunkTiltDeg),
    headTiltDeg: _r2(headTiltDeg),
    midlineOffsetRatio: _r2(midlineOffsetRatio),
    visibilityQuality: _r2(visibilityQuality * 100),
    cameraRollDeg: _r2(cameraRollDeg),
    qualityScore: qualityScore,
    screeningScore: screeningScore.clamp(0, 100),
    supportedView: supportedView,
    riskBand: riskBand,
    warnings: warnings,
  );
}

PoseKeypoint _midpoint(PoseKeypoint a, PoseKeypoint b) {
  return PoseKeypoint(
    y: (a.y + b.y) / 2.0,
    x: (a.x + b.x) / 2.0,
    confidence: (a.confidence + b.confidence) / 2.0,
  );
}

PoseKeypoint? _bestHeadAnchor(PoseKeypoint primary, PoseKeypoint secondary) {
  if (primary.confidence >= 0.35) return primary;
  if (secondary.confidence >= 0.35) return secondary;
  return null;
}

double _signedAngleFromHorizontalDeg(PoseKeypoint a, PoseKeypoint b) {
  final dy = b.y - a.y;
  final dx = b.x - a.x;
  if (dx.abs() < 1e-9) return 90.0;
  return math.atan2(dy, dx) * 180.0 / math.pi;
}

double _angleFromVerticalDeg(
  double x1,
  double y1,
  double x2,
  double y2,
) {
  final dx = x2 - x1;
  final dy = y2 - y1;
  if (dy.abs() < 1e-9) return 90.0;
  return math.atan2(dx.abs(), dy.abs()) * 180.0 / math.pi;
}

double _scoreInverse(double value, double cap) {
  final normalized = 1.0 - (value / cap);
  return normalized.clamp(0.0, 1.0);
}

int _scoreFromAngle(double value, {required double soft, required double hard, required int max}) {
  if (value <= soft) return 0;
  if (value >= hard) return max;
  return (((value - soft) / (hard - soft)) * max).round();
}

int _scoreFromRatio(double value, {required double soft, required double hard, required int max}) {
  if (value <= soft) return 0;
  if (value >= hard) return max;
  return (((value - soft) / (hard - soft)) * max).round();
}

double _r2(double v) => double.parse(v.toStringAsFixed(2));
