import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import 'package:image/image.dart' as img;
import '../../screens/ar_capture/ar_capture_models.dart';
import 'cranial_metrics.dart';
import 'gemini_cranio_service.dart';
import 'head_landmarker_runtime.dart';

/// Research-oriented cranial screening service.
///
/// On Android, captured-image analysis prefers the bundled
/// `face_landmarker.task` MediaPipe Tasks runtime. The existing ML Kit
/// face-mesh detector remains as a fallback and continues to power the
/// live camera overlay until that path is migrated separately.
class CranialAnalysisService {
  static final CranialAnalysisService _instance =
      CranialAnalysisService._internal();
  factory CranialAnalysisService() => _instance;
  CranialAnalysisService._internal();

  static const String _configuredTaskAsset =
      'assets/models/face_landmarker.task';
  static const String _taskRuntimeSource = 'mediapipe_face_landmarker_task';
  static const String _fallbackSource = 'mlkit_face_mesh_fallback';
  static const int _maxWorkingImageDimension = 1024;
  static const int _largeImageByteThreshold = 1024 * 1024;
  static const String _geometryFallbackSource = 'geometry_only_fallback';

  FaceMeshDetector? _detector;
  final HeadLandmarkerRuntime _headLandmarkerRuntime = HeadLandmarkerRuntime();

  FaceMeshDetector get _faceMeshDetector {
    _detector ??= FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
    return _detector!;
  }

  Future<ARCaptureResult> analyzeFromPath(
    String imagePath, {
    AppLanguage language = AppLanguage.en,
    String? secondaryImagePath,
  }) async {
    if (kIsWeb) {
      debugPrint('CranialAnalysisService: web not supported');
      return ARCaptureResult.invalid(
        summary: 'Head screening is unavailable on web.',
        debugDetails: {
          'mode': 'head',
          'reason': 'web_not_supported',
        },
      );
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ARCaptureResult.invalid(
          summary: 'No image file was found for head screening.',
          debugDetails: {
            'mode': 'head',
            'reason': 'image_missing',
            'imagePath': imagePath,
          },
        );
      }

      debugPrint('[HEAD_AI] Starting head analysis for $imagePath');
      final preparedImage = await _prepareWorkingImage(file);
      final analysisImagePath = preparedImage.path;
      _PreparedHeadImage? preparedSecondaryImage;
      var landmarkSource = _fallbackSource;
      final landmarkWarnings = <String>[];
      List<Landmark3D>? landmarks;

      if (secondaryImagePath != null && secondaryImagePath.trim().isNotEmpty) {
        final secondaryFile = File(secondaryImagePath);
        if (await secondaryFile.exists()) {
          preparedSecondaryImage = await _prepareWorkingImage(secondaryFile);
        } else {
          landmarkWarnings.add(
            'Secondary confirmation image was requested but the file was missing. Continuing with the primary image only.',
          );
        }
      }

      if (preparedImage.wasResized) {
        landmarkWarnings.add(
          'Head image was downscaled to ${preparedImage.width}x${preparedImage.height} before analysis to reduce on-device memory pressure.',
        );
      }
      if (preparedSecondaryImage?.wasResized == true) {
        landmarkWarnings.add(
          'Secondary head image was downscaled to ${preparedSecondaryImage!.width}x${preparedSecondaryImage.height} before Gemini analysis.',
        );
      }

      debugPrint('[HEAD_AI] Running MediaPipe task runtime');
      final runtimeResult = await _headLandmarkerRuntime.detectFromPath(
        analysisImagePath,
      );
      if (runtimeResult != null &&
          runtimeResult.landmarks.length > kLmLeftTemple) {
        // MediaPipe face-landmarker z is typically negative for points closer
        // to camera; the existing cranial camera-angle heuristics were tuned
        // on the opposite sign convention. Normalize z to keep scoring stable.
        landmarks = runtimeResult.landmarks
            .map((lm) => Landmark3D(x: lm.x, y: lm.y, z: -lm.z))
            .toList();
        landmarkSource = runtimeResult.source;
        landmarkWarnings.addAll(runtimeResult.warnings);
        debugPrint(
          '[HEAD_AI] MediaPipe runtime produced ${landmarks.length} landmarks',
        );
      }

      if (landmarks == null) {
        debugPrint('[HEAD_AI] Falling back to ML Kit face mesh');
        final inputImage = InputImage.fromFilePath(analysisImagePath);
        final faces = await _faceMeshDetector.processImage(inputImage);
        if (faces.isEmpty) {
          return ARCaptureResult.invalid(
            summary: 'No infant face landmarks were detected.',
            warnings: const [
              'Retake from the supported oblique top-down frontal view.'
            ],
            landmarkSource: _fallbackSource,
            debugDetails: {
              'mode': 'head',
              'imagePath': imagePath,
              'landmarkRuntime': {
                'configuredTaskAsset': _configuredTaskAsset,
                'runtimeSource': runtimeResult?.source,
                'runtimeWarnings': runtimeResult?.warnings ?? const <String>[],
              },
              'reason': 'no_face_landmarks_detected',
            },
          );
        }

        final dimensions = preparedImage.dimensions ??
            await _resolveImageDimensions(analysisImagePath);
        if (dimensions == null) {
          return ARCaptureResult.invalid(
            summary: 'The captured head image could not be decoded.',
            warnings: const ['Retake the image and try again.'],
            landmarkSource: _fallbackSource,
            debugDetails: {
              'mode': 'head',
              'imagePath': imagePath,
              'analysisImagePath': analysisImagePath,
              'reason': 'decode_failed',
            },
          );
        }

        landmarks =
            _extractLandmarks(faces.first, dimensions.$1, dimensions.$2);
        if (landmarks == null) {
          return ARCaptureResult.invalid(
            summary: 'Face landmarks were incomplete for head screening.',
            warnings: const [
              'Ensure the forehead, temples, and nose are all visible.'
            ],
            landmarkSource: _fallbackSource,
            debugDetails: {
              'mode': 'head',
              'imagePath': imagePath,
              'landmarkRuntime': {
                'configuredTaskAsset': _configuredTaskAsset,
                'runtimeSource': runtimeResult?.source,
                'runtimeWarnings': runtimeResult?.warnings ?? const <String>[],
              },
              'reason': 'incomplete_face_landmarks',
            },
          );
        }

        if (runtimeResult == null) {
          landmarkWarnings.add(
            'Configured $_configuredTaskAsset runtime is unavailable in this build; using $_fallbackSource.',
          );
        } else {
          landmarkWarnings.add(
            'Configured $_configuredTaskAsset did not return usable landmarks for this image; using $_fallbackSource.',
          );
        }
      }

      final headPresence = _validateHeadPresence(landmarks);
      if (!headPresence.isValid) {
        debugPrint('[HEAD_AI] Rejecting capture: ${headPresence.reason}');
        return ARCaptureResult.invalid(
          summary:
              'No clear baby head was detected in this image. Avoid background objects and retake with the head filling more of the guide.',
          warnings: [
            headPresence.reason,
            'Keep the baby\'s forehead, temples, and nose clearly visible and reduce background clutter.',
          ],
          landmarkSource: landmarkSource,
          debugDetails: {
            'mode': 'head',
            'imagePath': imagePath,
            'analysisImagePath': analysisImagePath,
            'reason': 'head_presence_rejected',
            'headPresence': headPresence.toJson(),
          },
        );
      }

      debugPrint('[HEAD_AI] Running cranial geometry scorer');
      final cranialResult = analyzeCranialMetrics(landmarks);
      final derivedMetrics = _buildHeadMetrics(
        cranialResult: cranialResult,
        landmarks: landmarks,
      );
      final geminiService = GeminiCranioService();
      final debugDetails = <String, dynamic>{
        'mode': 'head',
        'imagePath': imagePath,
        'landmarkRuntime': {
          'configuredTaskAsset': _configuredTaskAsset,
          'selectedSource': landmarkSource,
          'runtimeWarnings': landmarkWarnings,
          'landmarkCount': landmarks.length,
          'zNormalizationApplied': landmarkSource == _taskRuntimeSource,
          'imageWidth': preparedImage.width,
          'imageHeight': preparedImage.height,
          'analysisImagePath': analysisImagePath,
          'originalImagePath': imagePath,
          'downscaledForAnalysis': preparedImage.wasResized,
          'secondaryImagePath': preparedSecondaryImage?.path,
          'secondaryOriginalImagePath': secondaryImagePath,
          'secondaryImageUsed': preparedSecondaryImage != null,
        },
        'headPresence': headPresence.toJson(),
        'geometry': cranialResult.toJson(),
        'inputContext': {
          'ageWeeks': -1,
          'familyHistory': false,
          'visibleSutureRidge': false,
          'feedingDifficulties': false,
          'unusualIrritability': false,
          'defaultsUsed': true,
        },
      };

      try {
        debugPrint('[HEAD_AI] Running Gemini multimodal analysis');
        final aiResult = await geminiService.analyzeWithAI(
          language: language,
          imagePath: analysisImagePath,
          secondaryImagePath: preparedSecondaryImage?.path,
          geometry: cranialResult,
          metrics: derivedMetrics,
          ageWeeks: -1,
          familyHistory: false,
          visibleSutureRidge: false,
          feedingDifficulties: false,
          unusualIrritability: false,
        );
        debugDetails.addAll({
          'aiResult': aiResult.toJson(),
          'visualObservations': aiResult.visualObservations,
          'confidence': aiResult.confidence,
          'urgency': aiResult.urgency,
          'geometrySignals': aiResult.geometrySignals.toJson(),
          'disclaimer': aiResult.disclaimer,
          'aiProvider': geminiService.modelName,
          'aiImageCount': aiResult.imageCount,
          'aiUsageMetadata': aiResult.usageMetadata,
        });
        return _buildAiResult(
          aiResult: aiResult,
          cranialResult: cranialResult,
          derivedMetrics: derivedMetrics,
          landmarkSource: landmarkSource,
          landmarkWarnings: landmarkWarnings,
          debugDetails: debugDetails,
        );
      } catch (aiError, aiStack) {
        debugPrint('Gemini head analysis failed: $aiError\n$aiStack');
        final aiFallbackMessage =
            GeminiCranioService.userVisibleFailureMessage(aiError);
        debugDetails.addAll({
          'aiError': aiError.toString(),
          'aiFallbackMessage': aiFallbackMessage,
          'aiProvider': geminiService.modelName,
          'fallbackMode': _geometryFallbackSource,
        });
        return _buildGeometryFallbackResult(
          cranialResult: cranialResult,
          derivedMetrics: derivedMetrics,
          landmarkSource: landmarkSource,
          landmarkWarnings: landmarkWarnings,
          aiFallbackMessage: aiFallbackMessage,
          debugDetails: debugDetails,
        );
      }
    } catch (e, st) {
      debugPrint('CranialAnalysisService error: $e\n$st');
      return ARCaptureResult.invalid(
        summary: 'Head screening failed before the analysis could complete.',
        warnings: [e.toString()],
        landmarkSource: _fallbackSource,
        debugDetails: {
          'mode': 'head',
          'imagePath': imagePath,
          'reason': 'exception',
          'error': e.toString(),
        },
      );
    }
  }

  void dispose() {
    _detector?.close();
    _detector = null;
  }

  List<Landmark3D>? _extractLandmarks(
    FaceMesh face,
    int imageWidth,
    int imageHeight,
  ) {
    const requiredIndices = [
      kLmNoseTip,
      kLmGlabella,
      kLmLeftForehead,
      kLmRightTemple,
      kLmRightForehead,
      kLmLeftTemple,
    ];

    final imgW = imageWidth.toDouble();
    final imgH = imageHeight.toDouble();
    final landmarks = List<Landmark3D>.filled(
      468,
      const Landmark3D(x: 0.0, y: 0.0, z: 0.0),
    );

    for (final pt in face.points) {
      if (pt.index >= 0 && pt.index < 468) {
        landmarks[pt.index] = Landmark3D(
          x: pt.x / imgW,
          y: pt.y / imgH,
          z: pt.z,
        );
      }
    }

    for (final idx in requiredIndices) {
      final lm = landmarks[idx];
      if (lm.x == 0.0 && lm.y == 0.0) {
        return null;
      }
    }

    return landmarks;
  }

  HeadScreeningMetrics _buildHeadMetrics({
    required CranialResult cranialResult,
    required List<Landmark3D> landmarks,
  }) {
    final leftTemple = landmarks[kLmLeftTemple];
    final rightTemple = landmarks[kLmRightTemple];
    final leftForehead = landmarks[kLmLeftForehead];
    final rightForehead = landmarks[kLmRightForehead];
    final glabella = landmarks[kLmGlabella];
    final noseTip = landmarks[kLmNoseTip];

    final templeWidth = dist3D(rightTemple, leftTemple);
    final foreheadWidth = dist3D(rightForehead, leftForehead);
    final anteriorPosteriorLength = dist2D(glabella, noseTip) * kApLengthScale;
    final anteriorPosteriorRatio = templeWidth < 1e-9
        ? null
        : double.parse(
            (anteriorPosteriorLength / templeWidth).toStringAsFixed(2),
          );

    return HeadScreeningMetrics(
      cranialIndex: cranialResult.cranialIndex,
      cranialVaultAsymmetryIndex: cranialResult.cvai,
      facialSymmetryOffsetPct: cranialResult.facialSymmetryOffsetPct,
      cephalicProportionScore: cranialResult.cephalicProportionScore,
      landmarkQuality: cranialResult.landmarkQualityScore,
      topDownAngleDelta: cranialResult.topDownAngleDelta,
      templeTiltDeg: double.parse(
        angleFromHorizontalDeg(leftTemple, rightTemple).toStringAsFixed(2),
      ),
      orbitalSymmetry: null,
      anteriorPosteriorRatio: anteriorPosteriorRatio,
      templeWidth: double.parse(templeWidth.toStringAsFixed(4)),
      foreheadWidth: double.parse(foreheadWidth.toStringAsFixed(4)),
    );
  }

  ARCaptureResult _buildAiResult({
    required CranioAIResult aiResult,
    required CranialResult cranialResult,
    required HeadScreeningMetrics derivedMetrics,
    required String landmarkSource,
    required List<String> landmarkWarnings,
    required Map<String, dynamic> debugDetails,
  }) {
    final warnings = <String>[
      'Research-only pipeline: ${landmarkSource == _taskRuntimeSource ? 'MediaPipe face landmarker task' : 'fallback face landmarks'} plus ${GeminiCranioService().modelName} multimodal image and geometry assessment.',
      if (aiResult.imageCount > 1)
        'Gemini compared ${aiResult.imageCount} head images for this result.',
      'Parent risk factors and age are not collected in this capture flow yet; Gemini used default context values.',
      ...landmarkWarnings,
      ...cranialResult.warnings,
      ...aiResult.keyFindings,
      if (aiResult.visualObservations.isNotEmpty)
        'Visual observation: ${aiResult.visualObservations}',
      if (aiResult.recommendation.isNotEmpty)
        'Recommendation: ${aiResult.recommendation}',
      'AI confidence: ${aiResult.confidence}. Urgency: ${aiResult.urgency}.',
    ];

    return ARCaptureResult(
      isValidImage: true,
      supportedView: cranialResult.supportedView,
      qualityScore: cranialResult.qualityScore,
      screeningScore: aiResult.riskScore,
      riskBand: aiResult.riskBand,
      summary: aiResult.visualObservations.isNotEmpty
          ? aiResult.visualObservations
          : aiResult.recommendation,
      warnings: warnings,
      landmarkSource: '$landmarkSource + ${GeminiCranioService().modelName}',
      debugDetails: debugDetails,
      headMetrics: HeadScreeningMetrics(
        cranialIndex: cranialResult.cranialIndex,
        cranialVaultAsymmetryIndex: cranialResult.cvai,
        facialSymmetryOffsetPct: cranialResult.facialSymmetryOffsetPct,
        cephalicProportionScore: cranialResult.cephalicProportionScore,
        landmarkQuality: cranialResult.landmarkQualityScore,
        topDownAngleDelta: cranialResult.topDownAngleDelta,
        templeTiltDeg: derivedMetrics.templeTiltDeg,
        orbitalSymmetry: derivedMetrics.orbitalSymmetry,
        anteriorPosteriorRatio: derivedMetrics.anteriorPosteriorRatio,
        templeWidth: derivedMetrics.templeWidth,
        foreheadWidth: derivedMetrics.foreheadWidth,
        classifierAbnormalProbability: aiResult.riskScore.toDouble(),
        classifierNormalProbability: 100 - aiResult.riskScore.toDouble(),
        classifierDecision: aiResult.headShapeClassification,
        aiRiskLevel: aiResult.riskLevel,
        aiRiskScore: aiResult.riskScore,
        headShapeLabel: aiResult.headShapeClassification,
        keyFindings: aiResult.keyFindings,
        recommendation: aiResult.recommendation,
        visualObservations: aiResult.visualObservations,
        aiConfidence: aiResult.confidence,
        aiUrgency: aiResult.urgency,
      ),
    );
  }

  ARCaptureResult _buildGeometryFallbackResult({
    required CranialResult cranialResult,
    required HeadScreeningMetrics derivedMetrics,
    required String landmarkSource,
    required List<String> landmarkWarnings,
    required String aiFallbackMessage,
    required Map<String, dynamic> debugDetails,
  }) {
    final riskBand = !cranialResult.supportedView
        ? RiskBand.unavailable
        : switch (cranialResult.riskBand) {
            CranialRiskBand.lowRisk => RiskBand.lowRisk,
            CranialRiskBand.review => RiskBand.review,
            CranialRiskBand.refer => RiskBand.refer,
          };

    final summary = !cranialResult.supportedView
        ? 'Unsupported head capture view. Retake before relying on the screen.'
        : switch (riskBand) {
            RiskBand.lowRisk =>
              'Low-signal head research result from landmark geometry only.',
            RiskBand.review =>
              'Review-level head research signal from landmark geometry. Gemini AI was unavailable for this scan.',
            RiskBand.refer =>
              'High-priority head research signal from landmark geometry. Gemini AI was unavailable for this scan.',
            RiskBand.unavailable => 'Head screening output unavailable.',
          };

    final warnings = <String>[
      'Research-only pipeline: ${landmarkSource == _taskRuntimeSource ? 'MediaPipe face landmarker task' : 'fallback face landmarks'} geometry scoring fallback was used because Gemini AI analysis failed.',
      aiFallbackMessage,
      ...landmarkWarnings,
      ...cranialResult.warnings,
      ...cranialResult.reasons,
    ];

    return ARCaptureResult(
      isValidImage: true,
      supportedView: cranialResult.supportedView,
      qualityScore: cranialResult.qualityScore,
      screeningScore: cranialResult.screeningScore,
      riskBand: riskBand,
      summary: summary,
      warnings: warnings,
      landmarkSource: '$landmarkSource + $_geometryFallbackSource',
      debugDetails: debugDetails,
      headMetrics: HeadScreeningMetrics(
        cranialIndex: cranialResult.cranialIndex,
        cranialVaultAsymmetryIndex: cranialResult.cvai,
        facialSymmetryOffsetPct: cranialResult.facialSymmetryOffsetPct,
        cephalicProportionScore: cranialResult.cephalicProportionScore,
        landmarkQuality: cranialResult.landmarkQualityScore,
        topDownAngleDelta: cranialResult.topDownAngleDelta,
        templeTiltDeg: derivedMetrics.templeTiltDeg,
        orbitalSymmetry: derivedMetrics.orbitalSymmetry,
        anteriorPosteriorRatio: derivedMetrics.anteriorPosteriorRatio,
        templeWidth: derivedMetrics.templeWidth,
        foreheadWidth: derivedMetrics.foreheadWidth,
        classifierAbnormalProbability: cranialResult.screeningScore.toDouble(),
        classifierNormalProbability:
            100 - cranialResult.screeningScore.toDouble(),
        classifierDecision: 'geometry_fallback',
        aiRiskLevel: 'geometry_fallback',
        aiRiskScore: cranialResult.screeningScore,
        headShapeLabel: 'unclassified',
        keyFindings: List<String>.from(cranialResult.reasons),
        recommendation: !cranialResult.supportedView
            ? 'Retake the head image from the supported oblique top-down view before relying on the result.'
            : 'Repeat the scan and review the geometry metrics. If there is ongoing concern, consult a pediatrician.',
        visualObservations: '',
        aiConfidence: cranialResult.supportedView ? 'medium' : 'low',
        aiUrgency: riskBand == RiskBand.refer ? 'soon' : 'routine',
      ),
    );
  }

  Future<_PreparedHeadImage> _prepareWorkingImage(File originalFile) async {
    final fileSize = await originalFile.length();
    if (fileSize <= _largeImageByteThreshold) {
      return _PreparedHeadImage(
        path: originalFile.path,
        width: null,
        height: null,
        wasResized: false,
      );
    }

    debugPrint(
      '[HEAD_AI] Downscaling large input ($fileSize bytes) before native analysis',
    );
    final originalBytes = await originalFile.readAsBytes();
    final decoded = img.decodeImage(originalBytes);
    if (decoded == null) {
      return _PreparedHeadImage(
        path: originalFile.path,
        width: null,
        height: null,
        wasResized: false,
      );
    }

    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? _maxWorkingImageDimension : null,
      height: decoded.height > decoded.width ? _maxWorkingImageDimension : null,
    );
    final resizedBytes = img.encodeJpg(resized, quality: 85);
    final workingPath =
        '${originalFile.parent.path}${Platform.pathSeparator}head_ai_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(workingPath).writeAsBytes(resizedBytes, flush: true);

    return _PreparedHeadImage(
      path: workingPath,
      width: resized.width,
      height: resized.height,
      wasResized: true,
    );
  }

  Future<(int, int)?> _resolveImageDimensions(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return null;
    }
    return (decoded.width, decoded.height);
  }

  _HeadPresenceCheck _validateHeadPresence(List<Landmark3D> landmarks) {
    final xs = <double>[];
    final ys = <double>[];
    for (final landmark in landmarks) {
      if (landmark.x >= 0.0 &&
          landmark.x <= 1.0 &&
          landmark.y >= 0.0 &&
          landmark.y <= 1.0) {
        xs.add(landmark.x);
        ys.add(landmark.y);
      }
    }

    if (xs.length < 32 || ys.length < 32) {
      return const _HeadPresenceCheck.invalid(
        'Detected landmarks were too sparse to confirm a baby head.',
      );
    }

    final minX = xs.reduce((a, b) => a < b ? a : b);
    final maxX = xs.reduce((a, b) => a > b ? a : b);
    final minY = ys.reduce((a, b) => a < b ? a : b);
    final maxY = ys.reduce((a, b) => a > b ? a : b);
    final boxWidth = maxX - minX;
    final boxHeight = maxY - minY;
    final boxArea = boxWidth * boxHeight;
    final centerX = (minX + maxX) / 2.0;
    final centerY = (minY + maxY) / 2.0;

    final templeSpan =
        dist2D(landmarks[kLmLeftTemple], landmarks[kLmRightTemple]);
    final foreheadSpan =
        dist2D(landmarks[kLmLeftForehead], landmarks[kLmRightForehead]);
    final noseDepth = dist2D(landmarks[kLmGlabella], landmarks[kLmNoseTip]);

    final metrics = {
      'boxWidth': double.parse(boxWidth.toStringAsFixed(3)),
      'boxHeight': double.parse(boxHeight.toStringAsFixed(3)),
      'boxArea': double.parse(boxArea.toStringAsFixed(3)),
      'centerX': double.parse(centerX.toStringAsFixed(3)),
      'centerY': double.parse(centerY.toStringAsFixed(3)),
      'templeSpan': double.parse(templeSpan.toStringAsFixed(3)),
      'foreheadSpan': double.parse(foreheadSpan.toStringAsFixed(3)),
      'noseDepth': double.parse(noseDepth.toStringAsFixed(3)),
    };

    if (boxWidth < 0.18 ||
        boxHeight < 0.18 ||
        boxArea < 0.045 ||
        templeSpan < 0.12 ||
        foreheadSpan < 0.08 ||
        noseDepth < 0.03) {
      return _HeadPresenceCheck.invalid(
        'The detected face region is too small or too weak for reliable head screening.',
        metrics: metrics,
      );
    }

    if (minX < 0.01 || maxX > 0.99 || minY < 0.01 || maxY > 0.99) {
      return _HeadPresenceCheck.invalid(
        'The head is clipped by the image edges. Retake with the full head inside the guide.',
        metrics: metrics,
      );
    }

    return _HeadPresenceCheck.valid(metrics: metrics);
  }
}

class _PreparedHeadImage {
  final String path;
  final int? width;
  final int? height;
  final bool wasResized;

  const _PreparedHeadImage({
    required this.path,
    required this.width,
    required this.height,
    required this.wasResized,
  });

  (int, int)? get dimensions {
    if (width == null || height == null) {
      return null;
    }
    return (width!, height!);
  }
}

class _HeadPresenceCheck {
  final bool isValid;
  final String reason;
  final Map<String, dynamic> metrics;

  const _HeadPresenceCheck._({
    required this.isValid,
    required this.reason,
    required this.metrics,
  });

  const _HeadPresenceCheck.valid({
    Map<String, dynamic> metrics = const {},
  }) : this._(
          isValid: true,
          reason: 'ok',
          metrics: metrics,
        );

  const _HeadPresenceCheck.invalid(
    String reason, {
    Map<String, dynamic> metrics = const {},
  }) : this._(
          isValid: false,
          reason: reason,
          metrics: metrics,
        );

  Map<String, dynamic> toJson() => {
        'isValid': isValid,
        'reason': reason,
        'metrics': metrics,
      };
}
