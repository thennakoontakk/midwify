import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';
import '../../screens/ar_capture/ar_capture_models.dart';
import 'classifier_service.dart';
import 'cranial_metrics.dart';
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

  static const String _configuredTaskAsset = 'assets/models/face_landmarker.task';
  static const String _taskRuntimeSource = 'mediapipe_face_landmarker_task';
  static const String _fallbackSource = 'mlkit_face_mesh_fallback';

  FaceMeshDetector? _detector;
  final HeadLandmarkerRuntime _headLandmarkerRuntime = HeadLandmarkerRuntime();

  FaceMeshDetector get _faceMeshDetector {
    _detector ??= FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
    return _detector!;
  }

  Future<ARCaptureResult> analyzeFromPath(
    String imagePath, {
    required int imageWidth,
    required int imageHeight,
  }) async {
    if (kIsWeb) {
      debugPrint('CranialAnalysisService: web not supported');
      return ARCaptureResult.invalid(
        summary: 'Head screening is unavailable on web.',
      );
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        return ARCaptureResult.invalid(
          summary: 'No image file was found for head screening.',
        );
      }

      var landmarkSource = _fallbackSource;
      final landmarkWarnings = <String>[];
      List<Landmark3D>? landmarks;

      final runtimeResult = await _headLandmarkerRuntime.detectFromPath(imagePath);
      if (runtimeResult != null && runtimeResult.landmarks.length > kLmLeftTemple) {
        landmarks = runtimeResult.landmarks;
        landmarkSource = runtimeResult.source;
        landmarkWarnings.addAll(runtimeResult.warnings);
      }

      if (landmarks == null) {
        final inputImage = InputImage.fromFilePath(imagePath);
        final faces = await _faceMeshDetector.processImage(inputImage);
        if (faces.isEmpty) {
          return ARCaptureResult.invalid(
            summary: 'No infant face landmarks were detected.',
            warnings: const ['Retake from the supported oblique top-down frontal view.'],
            landmarkSource: _fallbackSource,
          );
        }

        landmarks = _extractLandmarks(faces.first, imageWidth, imageHeight);
        if (landmarks == null) {
          return ARCaptureResult.invalid(
            summary: 'Face landmarks were incomplete for head screening.',
            warnings: const ['Ensure the forehead, temples, and nose are all visible.'],
            landmarkSource: _fallbackSource,
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

      final cranialResult = analyzeCranialMetrics(landmarks);
      final classification = await ClassifierService().classifyImage(imagePath);
      final fusion = fuseHeadSignals(
        geometry: cranialResult,
        classification: classification,
      );
      final warnings = <String>[
        'Research-only pipeline: ${landmarkSource == _taskRuntimeSource ? 'MediaPipe face landmarker task' : 'fallback face landmarks'} plus a binary Normal/Abnormal image classifier.',
        ...landmarkWarnings,
        ...fusion.warnings,
      ];

      final riskBand = switch (fusion.riskBand) {
        CranialRiskBand.lowRisk => RiskBand.lowRisk,
        CranialRiskBand.review => RiskBand.review,
        CranialRiskBand.refer => RiskBand.refer,
      };

      return ARCaptureResult(
        isValidImage: true,
        supportedView: cranialResult.supportedView,
        qualityScore: cranialResult.qualityScore,
        screeningScore: fusion.screeningScore,
        riskBand: riskBand,
        summary: fusion.summary,
        warnings: warnings,
        landmarkSource: '$landmarkSource + ${classification.source}',
        headMetrics: HeadScreeningMetrics(
          cranialIndex: cranialResult.cranialIndex,
          cranialVaultAsymmetryIndex: cranialResult.cvai,
          facialSymmetryOffsetPct: cranialResult.facialSymmetryOffsetPct,
          cephalicProportionScore: cranialResult.cephalicProportionScore,
          landmarkQuality: cranialResult.landmarkQualityScore,
          topDownAngleDelta: cranialResult.topDownAngleDelta,
          classifierAbnormalProbability: classification.abnormalProbability * 100,
          classifierNormalProbability: classification.normalProbability * 100,
          classifierDecision: classification.decision.label,
        ),
      );
    } catch (e, st) {
      debugPrint('CranialAnalysisService error: $e\n$st');
      return ARCaptureResult.invalid(
        summary: 'Head screening failed during landmark extraction.',
        warnings: [e.toString()],
        landmarkSource: _fallbackSource,
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
}
