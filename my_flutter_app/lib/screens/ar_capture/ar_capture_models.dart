enum ScreenState { languageSelection, modeSelection, capture, diagnosis, geometricTool }
enum AppMode { head, posture, none }
enum AppLanguage { en, si }
enum RiskBand { lowRisk, review, refer, unavailable }

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
  final double? classifierAbnormalProbability;
  final double? classifierNormalProbability;
  final String? classifierDecision;
  final String? aiRiskLevel;
  final int? aiRiskScore;
  final String? headShapeLabel;
  final List<String>? keyFindings;
  final String? recommendation;
  final String? visualObservations;
  final String? aiConfidence;
  final String? aiUrgency;

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
    this.classifierAbnormalProbability,
    this.classifierNormalProbability,
    this.classifierDecision,
    this.aiRiskLevel,
    this.aiRiskScore,
    this.headShapeLabel,
    this.keyFindings,
    this.recommendation,
    this.visualObservations,
    this.aiConfidence,
    this.aiUrgency,
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
  final String? landmarkSource;
  final Map<String, dynamic>? debugDetails;
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
    this.landmarkSource,
    this.debugDetails,
    this.headMetrics,
    this.postureMetrics,
  });

  factory ARCaptureResult.invalid({
    required String summary,
    List<String> warnings = const [],
    String? landmarkSource,
    Map<String, dynamic>? debugDetails,
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
      debugDetails: debugDetails,
    );
  }

  Map<String, dynamic> toJson() => {
        'isValidImage': isValidImage,
        'supportedView': supportedView,
        'qualityScore': qualityScore,
        'screeningScore': screeningScore,
        'riskBand': riskBand.name,
        'summary': summary,
        'warnings': warnings,
        'landmarkSource': landmarkSource,
        'debugDetails': debugDetails,
        'headMetrics': headMetrics?.toJson(),
        'postureMetrics': postureMetrics?.toJson(),
      };
}
