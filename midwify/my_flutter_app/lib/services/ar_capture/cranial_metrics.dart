import 'dart:math' as math;

// =============================================================================
// Data Types
// =============================================================================

/// A normalized 3-D landmark from a face mesh style detector.
class Landmark3D {
  final double x;
  final double y;
  final double z;

  const Landmark3D({required this.x, required this.y, required this.z});

  @override
  String toString() =>
      'LM(x:${x.toStringAsFixed(4)} y:${y.toStringAsFixed(4)} z:${z.toStringAsFixed(4)})';
}

class CameraAngleResult {
  final bool isValid;
  final double zDiff;
  final String? error;

  const CameraAngleResult({
    required this.isValid,
    required this.zDiff,
    this.error,
  });
}

enum CranialRiskBand { lowRisk, review, refer }

/// Screening-oriented output for cranial asymmetry research.
class CranialResult {
  final double cranialIndex;
  final double cvai;
  final double facialSymmetryOffsetPct;
  final double cephalicProportionScore;
  final double landmarkQualityScore;
  final double topDownAngleDelta;
  final bool validCameraAngle;
  final bool supportedView;
  final int qualityScore;
  final int screeningScore;
  final CranialRiskBand riskBand;
  final List<String> warnings;
  final List<String> reasons;
  final String? cameraAngleError;

  const CranialResult({
    required this.cranialIndex,
    required this.cvai,
    required this.facialSymmetryOffsetPct,
    required this.cephalicProportionScore,
    required this.landmarkQualityScore,
    required this.topDownAngleDelta,
    required this.validCameraAngle,
    required this.supportedView,
    required this.qualityScore,
    required this.screeningScore,
    required this.riskBand,
    required this.warnings,
    required this.reasons,
    this.cameraAngleError,
  });

  bool get requiresMedicalReview => riskBand != CranialRiskBand.lowRisk;

  String? get flaggedCondition => reasons.isEmpty ? null : reasons.join(' | ');

  Map<String, dynamic> toJson() => {
        'cranialIndex': cranialIndex,
        'cvai': cvai,
        'facialSymmetryOffsetPct': facialSymmetryOffsetPct,
        'cephalicProportionScore': cephalicProportionScore,
        'landmarkQualityScore': landmarkQualityScore,
        'topDownAngleDelta': topDownAngleDelta,
        'validCameraAngle': validCameraAngle,
        'supportedView': supportedView,
        'qualityScore': qualityScore,
        'screeningScore': screeningScore,
        'riskBand': riskBand.name,
        'warnings': warnings,
        'reasons': reasons,
        'cameraAngleError': cameraAngleError,
      };
}

// =============================================================================
// Landmark index constants
// =============================================================================

const int kLmNoseTip = 1;
const int kLmGlabella = 10;
const int kLmLeftForehead = 103;
const int kLmRightTemple = 234;
const int kLmRightForehead = 332;
const int kLmLeftTemple = 454;

// =============================================================================
// Calibration constants
// =============================================================================

const double kApLengthScale = 2.8;
const double kMinAngleZDiff = 0.005;
const double kMaxTempleTiltDeg = 12.0;
const double kMaxForeheadSkewPct = 12.0;

// =============================================================================
// Math helpers
// =============================================================================

double dist3D(Landmark3D a, Landmark3D b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  final dz = b.z - a.z;
  return math.sqrt(dx * dx + dy * dy + dz * dz);
}

double dist2D(Landmark3D a, Landmark3D b) {
  final dx = b.x - a.x;
  final dy = b.y - a.y;
  return math.sqrt(dx * dx + dy * dy);
}

double angleFromHorizontalDeg(Landmark3D a, Landmark3D b) {
  final dy = b.y - a.y;
  final dx = b.x - a.x;
  if (dx.abs() < 1e-9) return 90.0;
  return math.atan2(dy, dx).abs() * 180.0 / math.pi;
}

double _clamp01(double value) => value.clamp(0.0, 1.0);

// =============================================================================
// Camera angle validation
// =============================================================================

CameraAngleResult validateCameraAngle(List<Landmark3D> landmarks) {
  assert(landmarks.length > math.max(kLmNoseTip, kLmGlabella));

  final noseTip = landmarks[kLmNoseTip];
  final forehead = landmarks[kLmGlabella];
  final zDiff = noseTip.z - forehead.z;

  if (zDiff < kMinAngleZDiff) {
    final String msg;
    if (zDiff < -kMinAngleZDiff) {
      msg =
          'Camera is below eye level. Hold it 30-45 degrees above the baby\'s head.';
    } else {
      msg =
          'Camera angle too flat. Tilt it downward so the forehead and temples stay visible.';
    }
    return CameraAngleResult(isValid: false, zDiff: zDiff, error: msg);
  }

  return CameraAngleResult(isValid: true, zDiff: zDiff);
}

// =============================================================================
// Main analysis function
// =============================================================================

CranialResult analyzeCranialMetrics(List<Landmark3D> landmarks) {
  assert(
    landmarks.length > kLmLeftTemple,
    'Need > $kLmLeftTemple landmarks; got ${landmarks.length}.',
  );

  final angleCheck = validateCameraAngle(landmarks);
  final noseTip = landmarks[kLmNoseTip];
  final glabella = landmarks[kLmGlabella];
  final leftTemple = landmarks[kLmLeftTemple];
  final rightTemple = landmarks[kLmRightTemple];
  final leftForehead = landmarks[kLmLeftForehead];
  final rightForehead = landmarks[kLmRightForehead];

  final width = dist3D(rightTemple, leftTemple);
  final glabellaToNose = dist2D(glabella, noseTip);
  final length = glabellaToNose * kApLengthScale;
  final ci = (length < 1e-9 || width < 1e-9) ? 0.0 : (width / length) * 100.0;

  final diagA = dist3D(leftForehead, rightTemple);
  final diagB = dist3D(rightForehead, leftTemple);
  final cvai = diagA < 1e-9 ? 0.0 : ((diagA - diagB).abs() / diagA) * 100.0;

  final leftTempleToNose = dist2D(leftTemple, noseTip);
  final rightTempleToNose = dist2D(rightTemple, noseTip);
  final facialSymmetryOffsetPct =
      width < 1e-9 ? 0.0 : ((leftTempleToNose - rightTempleToNose).abs() / width) * 100.0;
  final templeTiltDeg = angleFromHorizontalDeg(leftTemple, rightTemple);
  final cephalicProportionScore =
      _clamp01(1.0 - ((ci - 80.0).abs() / 20.0)) * 100.0;

  final angleScore = _clamp01(
    (angleCheck.zDiff - kMinAngleZDiff) / (kMinAngleZDiff * 5.0),
  ) * 100.0;
  final symmetryScore =
      _clamp01(1.0 - (facialSymmetryOffsetPct / 18.0)) * 100.0;
  final tiltScore = _clamp01(1.0 - (templeTiltDeg / 18.0)) * 100.0;
  final qualityScore = ((angleScore * 0.5) + (symmetryScore * 0.3) + (tiltScore * 0.2))
      .round()
      .clamp(0, 100);

  final warnings = <String>[];
  if (!angleCheck.isValid && angleCheck.error != null) {
    warnings.add(angleCheck.error!);
  }
  if (templeTiltDeg > kMaxTempleTiltDeg) {
    warnings.add('Head is rotated relative to the camera. Retake from the supported oblique top-down view.');
  }
  if (facialSymmetryOffsetPct > kMaxForeheadSkewPct) {
    warnings.add('Forehead and temple visibility are imbalanced. Ensure both sides are clearly visible.');
  }

  final supportedView =
      angleCheck.isValid &&
      templeTiltDeg <= kMaxTempleTiltDeg &&
      facialSymmetryOffsetPct <= kMaxForeheadSkewPct &&
      qualityScore >= 40;

  final reasons = <String>[];
  int screeningScore = 0;

  if (ci > 1e-9 && ci < 74.0) {
    screeningScore += 35;
    reasons.add('Cranial proportion is elongated relative to the temple width.');
  } else if (ci > 86.0) {
    screeningScore += 35;
    reasons.add('Cranial proportion is broad relative to the glabella-nose distance.');
  } else if (ci < 76.0 || ci > 84.0) {
    screeningScore += 18;
  }

  if (cvai > 7.0) {
    screeningScore += 40;
    reasons.add('Forehead-to-temple diagonal asymmetry is elevated.');
  } else if (cvai > 4.0) {
    screeningScore += 24;
    reasons.add('Mild frontal asymmetry is present across diagonal landmarks.');
  }

  if (facialSymmetryOffsetPct > 10.0) {
    screeningScore += 18;
  } else if (facialSymmetryOffsetPct > 6.0) {
    screeningScore += 10;
  }

  if (!supportedView) {
    reasons.add('Capture quality is insufficient for a reliable low-risk screen.');
  }

  screeningScore = screeningScore.clamp(0, 100);
  final riskBand = screeningScore >= 70
      ? CranialRiskBand.refer
      : screeningScore >= 35
          ? CranialRiskBand.review
          : CranialRiskBand.lowRisk;

  return CranialResult(
    cranialIndex: _r2(ci),
    cvai: _r2(cvai),
    facialSymmetryOffsetPct: _r2(facialSymmetryOffsetPct),
    cephalicProportionScore: _r2(cephalicProportionScore),
    landmarkQualityScore: _r2(qualityScore.toDouble()),
    topDownAngleDelta: _r2(angleCheck.zDiff),
    validCameraAngle: angleCheck.isValid,
    supportedView: supportedView,
    qualityScore: qualityScore,
    screeningScore: screeningScore,
    riskBand: riskBand,
    warnings: warnings,
    reasons: reasons,
    cameraAngleError: angleCheck.error,
  );
}

int cranialResultToConfidence(CranialResult result) => result.screeningScore;

double _r2(double v) => double.parse(v.toStringAsFixed(2));
