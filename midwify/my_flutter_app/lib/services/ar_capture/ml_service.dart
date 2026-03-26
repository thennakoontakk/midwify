import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'ml_service_stub.dart';

import '../../screens/ar_capture/ar_capture_models.dart';
import 'classifier_service.dart';
import 'cranial_analysis_service.dart';
import 'posture_screening.dart';
import 'scan_report_logger.dart';

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

  Future<ARCaptureResult> runInference(
    String imagePath,
    AppMode mode, {
    String? secondaryImagePath,
  }) async {
    debugPrint('=== INFERENCE MODE: $mode ===');

    ARCaptureResult result;
    if (imagePath.isEmpty ||
        imagePath == 'null' ||
        imagePath == 'undefined') {
      debugPrint('ERROR: Invalid image path');
      result = ARCaptureResult.invalid(
        summary: 'No image path was provided for screening.',
        debugDetails: {
          'mode': mode.name,
          'reason': 'invalid_image_path',
          'imagePath': imagePath,
        },
      );
      await _logScanReport(mode, imagePath, result);
      return result;
    }

    if (kIsWeb) {
      result = ARCaptureResult.invalid(
        summary: 'AR screening is unavailable on web.',
        debugDetails: {
          'mode': mode.name,
          'reason': 'web_not_supported',
          'imagePath': imagePath,
        },
      );
      await _logScanReport(mode, imagePath, result);
      return result;
    }

    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        debugPrint('ERROR: File not found: $imagePath');
        result = ARCaptureResult.invalid(
          summary: 'The captured image file could not be found.',
          debugDetails: {
            'mode': mode.name,
            'reason': 'file_not_found',
            'imagePath': imagePath,
          },
        );
        await _logScanReport(mode, imagePath, result);
        return result;
      }

      if (mode == AppMode.head) {
        result = await _runHeadInference(
          imagePath,
          secondaryImagePath: secondaryImagePath,
        );
        await _logScanReport(mode, imagePath, result);
        return result;
      }

      final imageBytes = await file.readAsBytes();
      final decoded = img.decodeImage(imageBytes);
      if (decoded == null) {
        debugPrint('ERROR: Failed to decode image');
        result = ARCaptureResult.invalid(
          summary: 'The captured image could not be decoded for screening.',
          debugDetails: {
            'mode': mode.name,
            'reason': 'decode_failed',
            'imagePath': imagePath,
          },
        );
        await _logScanReport(mode, imagePath, result);
        return result;
      }

      result = await _runPostureInference(decoded);
      await _logScanReport(mode, imagePath, result);
      return result;
    } catch (e) {
      debugPrint('ERROR: Exception during inference: $e');
      result = ARCaptureResult.invalid(
        summary: 'Screening failed while processing the captured image.',
        warnings: [e.toString()],
        debugDetails: {
          'mode': mode.name,
          'reason': 'exception',
          'imagePath': imagePath,
          'error': e.toString(),
        },
      );
      await _logScanReport(mode, imagePath, result);
      return result;
    }
  }

  Future<ARCaptureResult> _runHeadInference(
    String imagePath, {
    String? secondaryImagePath,
  }) async {
    return CranialAnalysisService().analyzeFromPath(
      imagePath,
      secondaryImagePath: secondaryImagePath,
    );
  }

  Future<ARCaptureResult> _runPostureInference(img.Image decoded) async {
    final keypoints = await runPostureKeypointInference(decoded);
    if (keypoints == null) {
      return ARCaptureResult.invalid(
        summary: 'The posture screening model is not initialized.',
        landmarkSource: _postureAsset,
        debugDetails: {
          'mode': AppMode.posture.name,
          'reason': 'posture_model_not_initialized',
          'landmarkSource': _postureAsset,
        },
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
      debugDetails: {
        'mode': 'posture',
        'postureAssessment': {
          'shoulderTiltDeg': assessment.shoulderTiltDeg,
          'hipTiltDeg': assessment.hipTiltDeg,
          'trunkTiltDeg': assessment.trunkTiltDeg,
          'headTiltDeg': assessment.headTiltDeg,
          'midlineOffsetRatio': assessment.midlineOffsetRatio,
          'visibilityQuality': assessment.visibilityQuality,
          'cameraRollDeg': assessment.cameraRollDeg,
          'qualityScore': assessment.qualityScore,
          'screeningScore': assessment.screeningScore,
          'supportedView': assessment.supportedView,
          'riskBand': assessment.riskBand.name,
          'warnings': assessment.warnings,
        },
        'keypoints': keypoints
            .asMap()
            .entries
            .map((entry) => {
                  'index': entry.key,
                  'y': entry.value[0],
                  'x': entry.value[1],
                  'confidence': entry.value[2],
                })
            .toList(),
      },
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

  Future<void> _logScanReport(
    AppMode mode,
    String imagePath,
    ARCaptureResult result,
  ) async {
    await ScanReportLogger.logScanReport(
      mode: mode,
      imagePath: imagePath,
      result: result,
    );
  }
}
