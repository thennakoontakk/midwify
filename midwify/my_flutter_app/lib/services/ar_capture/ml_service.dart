import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'ml_service_stub.dart';

import '../../screens/ar_capture/ar_capture_models.dart';
import 'classifier_service.dart';
import 'cranial_analysis_service.dart';
import 'posture_screening.dart';

class MLService {
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  Interpreter? _postureInterpreter;

  static const int _moveNetSize = 256;
  static const String _postureAsset = 'assets/models/posture_analysis.tflite';

  Future<void> initializeModels() async {
    if (kIsWeb) {
      debugPrint('Web platform: posture model runtime is unavailable.');
      return;
    }

    try {
      await ClassifierService().initialize();
      _postureInterpreter = await Interpreter.fromAsset(_postureAsset);
      debugPrint('Posture pose estimator loaded from $_postureAsset');
    } catch (e) {
      debugPrint('Error loading posture model: $e');
    }
  }

  Future<void> ensurePostureModelReady() async {
    if (kIsWeb || _postureInterpreter != null) {
      return;
    }

    await initializeModels();
  }

  Future<ARCaptureResult> runInference(String imagePath, AppMode mode) async {
    debugPrint('=== INFERENCE MODE: $mode ===');

    if (imagePath.isEmpty ||
        imagePath == 'null' ||
        imagePath == 'undefined') {
      debugPrint('ERROR: Invalid image path');
      return ARCaptureResult.invalid(
        summary: 'No image path was provided for screening.',
      );
    }

    if (kIsWeb) {
      return ARCaptureResult.invalid(
        summary: 'AR screening is unavailable on web.',
      );
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('ERROR: File not found: $imagePath');
        return ARCaptureResult.invalid(
          summary: 'The captured image file could not be found.',
        );
      }

      if (mode == AppMode.head) {
        return _runHeadInference(imagePath);
      }

      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        debugPrint('ERROR: Failed to decode image');
        return ARCaptureResult.invalid(
          summary: 'The captured image could not be decoded for screening.',
        );
      }

      return _runPostureInference(decoded);
    } catch (e) {
      debugPrint('ERROR: Exception during inference: $e');
      return ARCaptureResult.invalid(
        summary: 'Screening failed while processing the captured image.',
        warnings: [e.toString()],
      );
    }
  }

  Future<ARCaptureResult> _runHeadInference(String imagePath) async {
    final imageBytes = await File(imagePath).readAsBytes();
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) {
      return ARCaptureResult.invalid(
        summary: 'The captured head image could not be decoded.',
      );
    }

    return CranialAnalysisService().analyzeFromPath(
      imagePath,
      imageWidth: decoded.width,
      imageHeight: decoded.height,
    );
  }

  Future<ARCaptureResult> _runPostureInference(img.Image decoded) async {
    final keypoints = await runPostureKeypointInference(decoded);
    if (keypoints == null) {
      return ARCaptureResult.invalid(
        summary: 'The posture screening model is not initialized.',
        landmarkSource: _postureAsset,
      );
    }
    final assessment = analyzePostureKeypoints(keypoints);

    debugPrint(
      'Posture screen: quality=${assessment.qualityScore} '
      'score=${assessment.screeningScore} '
      'supported=${assessment.supportedView}',
    );

    final riskBand = switch (assessment.riskBand) {
      PostureRiskBand.lowRisk => RiskBand.lowRisk,
      PostureRiskBand.review => RiskBand.review,
      PostureRiskBand.refer => RiskBand.refer,
    };

    final summary = !assessment.supportedView
        ? 'Unsupported posture capture view. Retake before relying on the screen.'
        : switch (riskBand) {
            RiskBand.lowRisk =>
              'Low-signal posture research result from body keypoints.',
            RiskBand.review =>
              'Review-level posture research signal. Repeat capture and review the metrics.',
            RiskBand.refer =>
              'High-priority posture research signal from the captured body keypoints. This is still not a diagnosis.',
            RiskBand.unavailable => 'Screening output unavailable.',
          };

    final warnings = <String>[
      'Research-only pipeline: MoveNet pose keypoints plus rule-based posture geometry.',
      ...assessment.warnings,
    ];

    return ARCaptureResult(
      isValidImage: true,
      supportedView: assessment.supportedView,
      qualityScore: assessment.qualityScore,
      screeningScore: assessment.screeningScore,
      riskBand: riskBand,
      summary: summary,
      warnings: warnings,
      landmarkSource: _postureAsset,
      postureMetrics: PostureScreeningMetrics(
        shoulderTiltDeg: assessment.shoulderTiltDeg,
        hipTiltDeg: assessment.hipTiltDeg,
        trunkTiltDeg: assessment.trunkTiltDeg,
        headTiltDeg: assessment.headTiltDeg,
        midlineOffsetRatio: assessment.midlineOffsetRatio,
        visibilityQuality: assessment.visibilityQuality,
        cameraRollDeg: assessment.cameraRollDeg,
      ),
    );
  }

  Future<List<List<double>>?> runPostureKeypointInference(img.Image decoded) async {
    await ensurePostureModelReady();
    if (_postureInterpreter == null) {
      return null;
    }

    final moveNetInput = _prepareMoveNetInput(decoded);
    final moveNetOutput = List.generate(
      1,
      (_) => List.generate(
        1,
        (_) => List.generate(17, (_) => List<double>.filled(3, 0.0)),
      ),
    );

    try {
      _postureInterpreter!.run(moveNetInput, moveNetOutput);
      return moveNetOutput[0][0];
    } catch (e) {
      debugPrint('MoveNet run error: $e');
      return null;
    }
  }

  List _prepareMoveNetInput(img.Image decoded) {
    final resized =
        img.copyResize(decoded, width: _moveNetSize, height: _moveNetSize);
    return List.generate(
      1,
      (_) => List.generate(
        _moveNetSize,
        (y) => List.generate(
          _moveNetSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return <int>[pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];
          },
        ),
      ),
    );
  }
}
