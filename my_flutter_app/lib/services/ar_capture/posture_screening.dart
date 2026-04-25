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
  final double torsoHeightRatio;
  final double shoulderWidthRatio;
  final double hipWidthRatio;
  final double torsoSideBalance;
  final double bodyCenterOffsetRatio;
  final int bodyPresenceScore;
  final int qualityScore;
  final int screeningScore;
  final bool supportedView;
  final bool captureAccepted;
  final PostureRiskBand riskBand;
  final List<String> warnings;
  final List<String> rejectionReasons;

  const PostureAssessment({
    required this.shoulderTiltDeg,
    required this.hipTiltDeg,
    required this.trunkTiltDeg,
    required this.headTiltDeg,
    required this.midlineOffsetRatio,
    required this.visibilityQuality,
    required this.cameraRollDeg,
    required this.torsoHeightRatio,
    required this.shoulderWidthRatio,
    required this.hipWidthRatio,
    required this.torsoSideBalance,
    required this.bodyCenterOffsetRatio,
    required this.bodyPresenceScore,
    required this.qualityScore,
    required this.screeningScore,
    required this.supportedView,
    required this.captureAccepted,
    required this.riskBand,
    required this.warnings,
    required this.rejectionReasons,
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
  if (keypoints.length < 13) {
    return const PostureAssessment(
      shoulderTiltDeg: 0.0,
      hipTiltDeg: 0.0,
      trunkTiltDeg: 0.0,
      headTiltDeg: 0.0,
      midlineOffsetRatio: 0.0,
      visibilityQuality: 0.0,
      cameraRollDeg: 0.0,
      torsoHeightRatio: 0.0,
      shoulderWidthRatio: 0.0,
      hipWidthRatio: 0.0,
      torsoSideBalance: 0.0,
      bodyCenterOffsetRatio: 0.0,
      bodyPresenceScore: 0,
      qualityScore: 0,
      screeningScore: 0,
      supportedView: false,
      captureAccepted: false,
      riskBand: PostureRiskBand.review,
      warnings: ['Pose output is incomplete. Retake with the full infant body visible.'],
      rejectionReasons: ['The posture model did not return the required torso landmarks.'],
    );
  }

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
  final leftTorsoConfidence =
      (pose[_leftShoulderIdx].confidence + pose[_leftHipIdx].confidence) / 2.0;
  final rightTorsoConfidence =
      (pose[_rightShoulderIdx].confidence + pose[_rightHipIdx].confidence) / 2.0;
  final torsoSideBalance = math.min(leftTorsoConfidence, rightTorsoConfidence);

  final warnings = <String>[];
  final rejectionReasons = <String>[];
  if (visibilityQuality < 0.45) {
    warnings.add(
      'Keypoint visibility is low. Keep the shoulders and hips fully visible.',
    );
  }

  final shoulderLineRaw = _signedAngleFromHorizontalDeg(
    pose[_leftShoulderIdx],
    pose[_rightShoulderIdx],
  );
  final hipLineRaw = _signedAngleFromHorizontalDeg(
    pose[_leftHipIdx],
    pose[_rightHipIdx],
  );
  final cameraRollDeg = (shoulderLineRaw + hipLineRaw) / 2.0;

  final shoulderCenterRaw = _midpoint(
    pose[_leftShoulderIdx],
    pose[_rightShoulderIdx],
  );
  final hipCenterRaw = _midpoint(
    pose[_leftHipIdx],
    pose[_rightHipIdx],
  );
  final torsoCenterRaw = _midpoint(shoulderCenterRaw, hipCenterRaw);
  final rotatedPose = _rotatePose(
    pose,
    center: torsoCenterRaw,
    degrees: cameraRollDeg,
  );

  final shoulderCenter = _midpoint(
    rotatedPose[_leftShoulderIdx],
    rotatedPose[_rightShoulderIdx],
  );
  final hipCenter = _midpoint(
    rotatedPose[_leftHipIdx],
    rotatedPose[_rightHipIdx],
  );
  final torsoHeight = (hipCenter.y - shoulderCenter.y).abs();
  final shoulderWidth =
      (rotatedPose[_rightShoulderIdx].x - rotatedPose[_leftShoulderIdx].x).abs();
  final hipWidth = (rotatedPose[_rightHipIdx].x - rotatedPose[_leftHipIdx].x).abs();
  final bodyCenterOffsetRatio = (torsoCenterRaw.x - 0.5).abs();

  if (torsoHeight < 0.08) {
    warnings.add('Torso span is too small. Move the camera closer to the baby.');
  }

  if (shoulderWidth < 0.08 || hipWidth < 0.08) {
    warnings.add('The body appears too narrow for a frontal asymmetry screen.');
  }

  final supportedView = visibilityQuality >= 0.40 &&
      torsoSideBalance >= 0.30 &&
      torsoHeight >= 0.10 &&
      shoulderWidth >= 0.10 &&
      hipWidth >= 0.08 &&
      bodyCenterOffsetRatio <= 0.22;

  final normalizedShoulderTiltDeg = _signedAngleFromHorizontalDeg(
    rotatedPose[_leftShoulderIdx],
    rotatedPose[_rightShoulderIdx],
  ).abs();
  final normalizedHipTiltDeg = _signedAngleFromHorizontalDeg(
    rotatedPose[_leftHipIdx],
    rotatedPose[_rightHipIdx],
  ).abs();
  final trunkTiltDeg =
      _angleFromVerticalDeg(
        shoulderCenter.x,
        shoulderCenter.y,
        hipCenter.x,
        hipCenter.y,
      );

  final headLeft = _bestHeadAnchor(
    rotatedPose[_leftEarIdx],
    rotatedPose[_leftEyeIdx],
  );
  final headRight = _bestHeadAnchor(
    rotatedPose[_rightEarIdx],
    rotatedPose[_rightEyeIdx],
  );
  final headTiltDeg = (headLeft != null && headRight != null)
      ? _signedAngleFromHorizontalDeg(headLeft, headRight).abs()
      : 0.0;

  if (headLeft == null || headRight == null) {
    warnings.add(
      'Head landmarks are weak. Head tilt will be less reliable on this capture.',
    );
  }

  final midlineOffsetRatio = torsoHeight < 1e-6
      ? 0.0
      : ((shoulderCenter.x - hipCenter.x).abs() / torsoHeight);

  final bodyPresenceScore = ((visibilityQuality * 100 * 0.5) +
          (_scoreForward(torsoHeight, 0.10, 0.20) * 25) +
          (_scoreForward(math.min(shoulderWidth, hipWidth), 0.08, 0.18) * 15) +
          (_scoreForward(torsoSideBalance, 0.30, 0.65) * 5) +
          ((1.0 - (bodyCenterOffsetRatio / 0.22).clamp(0.0, 1.0)) * 5))
      .round()
      .clamp(0, 100);

  if (visibilityQuality < 0.35) {
    rejectionReasons.add(
      'Body detection confidence is too low for posture screening.',
    );
  }
  if (torsoSideBalance < 0.30) {
    rejectionReasons.add(
      'One side of the torso is weakly detected. Keep both shoulders and hips visible.',
    );
  }
  if (torsoHeight < 0.10) {
    rejectionReasons.add(
      'The torso span is too small. Move the camera closer before capturing.',
    );
  }
  if (shoulderWidth < 0.10 || hipWidth < 0.08) {
    rejectionReasons.add(
      'The infant body is too narrow in frame. Capture a centered full-body view.',
    );
  }
  if (bodyCenterOffsetRatio > 0.22) {
    rejectionReasons.add(
      'The infant body is too far from the center of the frame.',
    );
  }

  final captureAccepted = supportedView && bodyPresenceScore >= 50;

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
    warnings.add(
      'Unsupported posture view. Retake with a centered frontal or top-down body view.',
    );
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
    torsoHeightRatio: _r2(torsoHeight),
    shoulderWidthRatio: _r2(shoulderWidth),
    hipWidthRatio: _r2(hipWidth),
    torsoSideBalance: _r2(torsoSideBalance * 100),
    bodyCenterOffsetRatio: _r2(bodyCenterOffsetRatio),
    bodyPresenceScore: bodyPresenceScore,
    qualityScore: qualityScore,
    screeningScore: screeningScore.clamp(0, 100),
    supportedView: supportedView,
    captureAccepted: captureAccepted,
    riskBand: riskBand,
    warnings: warnings,
    rejectionReasons: rejectionReasons,
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

List<PoseKeypoint> _rotatePose(
  List<PoseKeypoint> pose, {
  required PoseKeypoint center,
  required double degrees,
}) {
  final radians = degrees * math.pi / 180.0;
  final cosTheta = math.cos(radians);
  final sinTheta = math.sin(radians);

  return pose.map((kp) {
    final mathX = kp.x - center.x;
    final mathY = -(kp.y - center.y);

    final rotatedMathX = (mathX * cosTheta) - (mathY * sinTheta);
    final rotatedMathY = (mathX * sinTheta) + (mathY * cosTheta);

    return PoseKeypoint(
      x: rotatedMathX + center.x,
      y: center.y - rotatedMathY,
      confidence: kp.confidence,
    );
  }).toList();
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

double _scoreForward(double value, double floor, double ceiling) {
  if (value <= floor) return 0.0;
  if (value >= ceiling) return 1.0;
  return (value - floor) / (ceiling - floor);
}

double _r2(double v) => double.parse(v.toStringAsFixed(2));
