enum ScreenState {
  languageSelection,
  modeSelection,
  childDetails,
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
  final double? templeTiltDeg;
  final double? orbitalSymmetry;
  final double? anteriorPosteriorRatio;
  final double? templeWidth;
  final double? foreheadWidth;
  final double classifierAbnormalProbability;
  final double classifierNormalProbability;
  final String classifierDecision;
  final String aiRiskLevel;
  final int aiRiskScore;
  final String headShapeLabel;
  final List<String> keyFindings;
  final String recommendation;
  final String visualObservations;
  final String aiConfidence;
  final String aiUrgency;

  const HeadScreeningMetrics({
    required this.cranialIndex,
    required this.cranialVaultAsymmetryIndex,
    required this.facialSymmetryOffsetPct,
    required this.cephalicProportionScore,
    required this.landmarkQuality,
    required this.topDownAngleDelta,
    this.templeTiltDeg,
    this.orbitalSymmetry,
    this.anteriorPosteriorRatio,
    this.templeWidth,
    this.foreheadWidth,
    this.classifierAbnormalProbability = 0.0,
    this.classifierNormalProbability = 0.0,
    this.classifierDecision = 'Unavailable',
    this.aiRiskLevel = 'unknown',
    this.aiRiskScore = 0,
    this.headShapeLabel = 'unclassified',
    this.keyFindings = const [],
    this.recommendation = '',
    this.visualObservations = '',
    this.aiConfidence = 'low',
    this.aiUrgency = 'routine',
  });

  Map<String, dynamic> toJson() => {
        'cranialIndex': cranialIndex,
        'cranialVaultAsymmetryIndex': cranialVaultAsymmetryIndex,
        'facialSymmetryOffsetPct': facialSymmetryOffsetPct,
        'cephalicProportionScore': cephalicProportionScore,
        'landmarkQuality': landmarkQuality,
        'topDownAngleDelta': topDownAngleDelta,
        'templeTiltDeg': templeTiltDeg,
        'orbitalSymmetry': orbitalSymmetry,
        'anteriorPosteriorRatio': anteriorPosteriorRatio,
        'templeWidth': templeWidth,
        'foreheadWidth': foreheadWidth,
        'classifierAbnormalProbability': classifierAbnormalProbability,
        'classifierNormalProbability': classifierNormalProbability,
        'classifierDecision': classifierDecision,
        'aiRiskLevel': aiRiskLevel,
        'aiRiskScore': aiRiskScore,
        'headShapeLabel': headShapeLabel,
        'keyFindings': keyFindings,
        'recommendation': recommendation,
        'visualObservations': visualObservations,
        'aiConfidence': aiConfidence,
        'aiUrgency': aiUrgency,
      };
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

  Map<String, dynamic> toJson() => {
        'shoulderTiltDeg': shoulderTiltDeg,
        'hipTiltDeg': hipTiltDeg,
        'trunkTiltDeg': trunkTiltDeg,
        'headTiltDeg': headTiltDeg,
        'midlineOffsetRatio': midlineOffsetRatio,
        'visibilityQuality': visibilityQuality,
        'cameraRollDeg': cameraRollDeg,
      };
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
  final String captureImagePath;
  final bool geometricReviewConfirmed;
  final String geometricReviewNote;
  final HeadScreeningMetrics? headMetrics;
  final PostureScreeningMetrics? postureMetrics;
  final Map<String, dynamic> debugDetails;

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
    this.captureImagePath = '',
    this.geometricReviewConfirmed = false,
    this.geometricReviewNote = '',
    this.headMetrics,
    this.postureMetrics,
    this.debugDetails = const {},
  });

  factory ARCaptureResult.invalid({
    String summary = 'No usable image was captured.',
    List<String> warnings = const [],
    String landmarkSource = '',
    String captureImagePath = '',
    Map<String, dynamic> debugDetails = const {},
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
      captureImagePath: captureImagePath,
      debugDetails: debugDetails,
    );
  }

  ARCaptureResult copyWith({
    bool? isValidImage,
    bool? supportedView,
    int? qualityScore,
    int? screeningScore,
    RiskBand? riskBand,
    String? summary,
    List<String>? warnings,
    bool? researchUseOnly,
    String? landmarkSource,
    String? captureImagePath,
    bool? geometricReviewConfirmed,
    String? geometricReviewNote,
    HeadScreeningMetrics? headMetrics,
    PostureScreeningMetrics? postureMetrics,
    Map<String, dynamic>? debugDetails,
  }) {
    return ARCaptureResult(
      isValidImage: isValidImage ?? this.isValidImage,
      supportedView: supportedView ?? this.supportedView,
      qualityScore: qualityScore ?? this.qualityScore,
      screeningScore: screeningScore ?? this.screeningScore,
      riskBand: riskBand ?? this.riskBand,
      summary: summary ?? this.summary,
      warnings: warnings ?? this.warnings,
      researchUseOnly: researchUseOnly ?? this.researchUseOnly,
      landmarkSource: landmarkSource ?? this.landmarkSource,
      captureImagePath: captureImagePath ?? this.captureImagePath,
      geometricReviewConfirmed:
          geometricReviewConfirmed ?? this.geometricReviewConfirmed,
      geometricReviewNote: geometricReviewNote ?? this.geometricReviewNote,
      headMetrics: headMetrics ?? this.headMetrics,
      postureMetrics: postureMetrics ?? this.postureMetrics,
      debugDetails: debugDetails ?? this.debugDetails,
    );
  }

  Map<String, dynamic> toJson() => {
        'isValidImage': isValidImage,
        'supportedView': supportedView,
        'qualityScore': qualityScore,
        'screeningScore': screeningScore,
        'riskBand': riskBand.name,
        'riskBandLabel': riskBand.label,
        'impactLevelLabel': riskBand.impactLevelLabel,
        'summary': summary,
        'warnings': warnings,
        'researchUseOnly': researchUseOnly,
        'landmarkSource': landmarkSource,
        'captureImagePath': captureImagePath,
        'geometricReviewConfirmed': geometricReviewConfirmed,
        'geometricReviewNote': geometricReviewNote,
        'headMetrics': headMetrics?.toJson(),
        'postureMetrics': postureMetrics?.toJson(),
        'debugDetails': debugDetails,
      };
}
