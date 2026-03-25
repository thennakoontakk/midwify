enum ScreenState {
  languageSelection,
  modeSelection,
  guide,
  capture,
  diagnosis,
  geometricTool
}

enum AppMode { head, posture, none }

enum AppLanguage { en, si }

enum RiskBand { unavailable, lowRisk, review, refer }

extension RiskBandPresentation on RiskBand {
  String get label {
    switch (this) {
      case RiskBand.lowRisk:
        return 'Low Signal';
      case RiskBand.review:
        return 'Review Signal';
      case RiskBand.refer:
        return 'High Priority';
      case RiskBand.unavailable:
        return 'Unavailable';
    }
  }

  String get impactLevelLabel {
    switch (this) {
      case RiskBand.lowRisk:
        return 'Low';
      case RiskBand.review:
        return 'Medium';
      case RiskBand.refer:
        return 'High';
      case RiskBand.unavailable:
        return 'Unavailable';
    }
  }
}

class HeadScreeningMetrics {
  final double cranialIndex;
  final double cranialVaultAsymmetryIndex;
  final double facialSymmetryOffsetPct;
  final double cephalicProportionScore;
  final double landmarkQuality;
  final double topDownAngleDelta;
  final double classifierAbnormalProbability;
  final double classifierNormalProbability;
  final String classifierDecision;

  const HeadScreeningMetrics({
    required this.cranialIndex,
    required this.cranialVaultAsymmetryIndex,
    required this.facialSymmetryOffsetPct,
    required this.cephalicProportionScore,
    required this.landmarkQuality,
    required this.topDownAngleDelta,
    this.classifierAbnormalProbability = 0.0,
    this.classifierNormalProbability = 0.0,
    this.classifierDecision = 'Unavailable',
  });
}

class PostureScreeningMetrics {
  final double shoulderTiltDeg;
  final double hipTiltDeg;
  final double trunkTiltDeg;
  final double headTiltDeg;
  final double midlineOffsetRatio;
  final double visibilityQuality;
  final double cameraRollDeg;

  const PostureScreeningMetrics({
    required this.shoulderTiltDeg,
    required this.hipTiltDeg,
    required this.trunkTiltDeg,
    required this.headTiltDeg,
    required this.midlineOffsetRatio,
    required this.visibilityQuality,
    required this.cameraRollDeg,
  });
}

class ARCaptureResult {
  final bool isValidImage;
  final bool supportedView;
  final int qualityScore;
  final int screeningScore;
  final RiskBand riskBand;
  final String summary;
  final List<String> warnings;
  final bool researchUseOnly;
  final String landmarkSource;
  final HeadScreeningMetrics? headMetrics;
  final PostureScreeningMetrics? postureMetrics;

  const ARCaptureResult({
    required this.isValidImage,
    required this.supportedView,
    required this.qualityScore,
    required this.screeningScore,
    required this.riskBand,
    required this.summary,
    required this.warnings,
    this.researchUseOnly = true,
    this.landmarkSource = '',
    this.headMetrics,
    this.postureMetrics,
  });

  factory ARCaptureResult.invalid({
    String summary = 'No usable image was captured.',
    List<String> warnings = const [],
    String landmarkSource = '',
  }) {
    return ARCaptureResult(
      isValidImage: false,
      supportedView: false,
      qualityScore: 0,
      screeningScore: 0,
      riskBand: RiskBand.unavailable,
      summary: summary,
      warnings: warnings,
      landmarkSource: landmarkSource,
    );
  }
}
