import 'dart:io';
import 'dart:math' as math;

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
  Map<String, dynamic> _postureModelContract = const {};
  Map<String, dynamic> _lastPostureInferenceDebug = const {};

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
      _postureModelContract = _readPostureModelContract();
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
    AppLanguage language = AppLanguage.en,
    String? secondaryImagePath,
  }) async {
    debugPrint('=== INFERENCE MODE: $mode ===');

    ARCaptureResult result;
    if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
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
          language: language,
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

      result = await _runPostureInference(decoded, imagePath: imagePath);
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
    AppLanguage language = AppLanguage.en,
    String? secondaryImagePath,
  }) async {
    return CranialAnalysisService().analyzeFromPath(
      imagePath,
      language: language,
      secondaryImagePath: secondaryImagePath,
    );
  }

  Future<ARCaptureResult> _runPostureInference(
    img.Image decoded, {
    required String imagePath,
  }) async {
    final keypoints = await runPostureKeypointInference(decoded);
    if (keypoints == null) {
      return ARCaptureResult.invalid(
        summary: 'The posture screening model is not initialized.',
        landmarkSource: _postureAsset,
        captureImagePath: imagePath,
        debugDetails: {
          'mode': AppMode.posture.name,
          'reason': 'posture_model_not_initialized',
          'landmarkSource': _postureAsset,
          'modelContract': _postureModelContract,
          'inference': _lastPostureInferenceDebug,
        },
      );
    }
    final assessment = analyzePostureKeypoints(keypoints);

    debugPrint(
      'Posture screen: quality=${assessment.qualityScore} '
      'score=${assessment.screeningScore} '
      'supported=${assessment.supportedView} '
      'accepted=${assessment.captureAccepted}',
    );

    final debugDetails = {
      'mode': 'posture',
      'modelContract': _postureModelContract,
      'inference': _lastPostureInferenceDebug,
      'postureAssessment': {
        'shoulderTiltDeg': assessment.shoulderTiltDeg,
        'hipTiltDeg': assessment.hipTiltDeg,
        'trunkTiltDeg': assessment.trunkTiltDeg,
        'headTiltDeg': assessment.headTiltDeg,
        'midlineOffsetRatio': assessment.midlineOffsetRatio,
        'visibilityQuality': assessment.visibilityQuality,
        'cameraRollDeg': assessment.cameraRollDeg,
        'torsoHeightRatio': assessment.torsoHeightRatio,
        'shoulderWidthRatio': assessment.shoulderWidthRatio,
        'hipWidthRatio': assessment.hipWidthRatio,
        'torsoSideBalance': assessment.torsoSideBalance,
        'bodyCenterOffsetRatio': assessment.bodyCenterOffsetRatio,
        'bodyPresenceScore': assessment.bodyPresenceScore,
        'qualityScore': assessment.qualityScore,
        'screeningScore': assessment.screeningScore,
        'supportedView': assessment.supportedView,
        'captureAccepted': assessment.captureAccepted,
        'riskBand': assessment.riskBand.name,
        'warnings': assessment.warnings,
        'rejectionReasons': assessment.rejectionReasons,
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
    };

    if (!assessment.captureAccepted) {
      return ARCaptureResult.invalid(
        summary:
            'No reliable posture capture was detected. Retake with the infant body centered and both shoulders and hips clearly visible.',
        warnings: [
          'Research-only pipeline: MoveNet pose keypoints plus rule-based posture geometry.',
          ...assessment.warnings,
          ...assessment.rejectionReasons,
        ],
        landmarkSource: _postureAsset,
        captureImagePath: imagePath,
        debugDetails: {
          ...debugDetails,
          'reason': 'posture_capture_rejected',
        },
      );
    }

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
      captureImagePath: imagePath,
      debugDetails: debugDetails,
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

  Future<List<List<double>>?> runPostureKeypointInference(
      img.Image decoded) async {
    await ensurePostureModelReady();
    if (_postureInterpreter == null) {
      return null;
    }

    final contract = _postureModelContract.isEmpty
        ? _readPostureModelContract()
        : _postureModelContract;
    final inputShape = (contract['inputShape'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        <int>[1, _moveNetSize, _moveNetSize, 3];
    final outputShape = (contract['outputShape'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList() ??
        <int>[1, 1, 17, 3];
    final inputType = (contract['inputType'] as String?) ?? 'int32';

    final preparedInput = _prepareMoveNetInput(
      decoded,
      targetHeight: inputShape.length > 1 ? inputShape[1] : _moveNetSize,
      targetWidth: inputShape.length > 2 ? inputShape[2] : _moveNetSize,
      inputType: inputType,
    );
    final moveNetOutput = _createZeroTensorBuffer(outputShape);

    try {
      _postureInterpreter!.run(preparedInput.tensor, moveNetOutput);
      final rawKeypoints = _extractPostureKeypoints(moveNetOutput);
      final keypoints = _mapKeypointsBackToOriginalFrame(
        rawKeypoints,
        preparedInput,
      );
      _lastPostureInferenceDebug = {
        'inputType': inputType,
        'inputShape': inputShape,
        'outputShape': outputShape,
        'originalWidth': decoded.width,
        'originalHeight': decoded.height,
        'networkWidth': preparedInput.networkWidth,
        'networkHeight': preparedInput.networkHeight,
        'resizedWidth': preparedInput.resizedWidth,
        'resizedHeight': preparedInput.resizedHeight,
        'padLeft': preparedInput.padLeft,
        'padTop': preparedInput.padTop,
        'usedPaddedResize': true,
      };
      return keypoints;
    } catch (e) {
      debugPrint('MoveNet run error: $e');
      _lastPostureInferenceDebug = {
        'error': e.toString(),
        'modelContract': contract,
      };
      return null;
    }
  }

  Map<String, dynamic> _readPostureModelContract() {
    if (_postureInterpreter == null) {
      return const {};
    }

    final input = _postureInterpreter!.getInputTensor(0);
    final output = _postureInterpreter!.getOutputTensor(0);
    return {
      'inputShape': input.shape,
      'inputType': _tensorTypeName(input.type),
      'outputShape': output.shape,
      'outputType': _tensorTypeName(output.type),
    };
  }

  _PreparedPostureInput _prepareMoveNetInput(
    img.Image decoded, {
    required int targetHeight,
    required int targetWidth,
    required String inputType,
  }) {
    final safeTargetHeight = targetHeight > 0 ? targetHeight : _moveNetSize;
    final safeTargetWidth = targetWidth > 0 ? targetWidth : _moveNetSize;
    final scale = math.min(
      safeTargetWidth / decoded.width,
      safeTargetHeight / decoded.height,
    );
    final resizedWidth = math.max(1, (decoded.width * scale).round());
    final resizedHeight = math.max(1, (decoded.height * scale).round());
    final padLeft = ((safeTargetWidth - resizedWidth) / 2).floor();
    final padTop = ((safeTargetHeight - resizedHeight) / 2).floor();

    final resized = img.copyResize(
      decoded,
      width: resizedWidth,
      height: resizedHeight,
      interpolation: img.Interpolation.linear,
    );
    final padded = img.Image(width: safeTargetWidth, height: safeTargetHeight);
    img.fill(padded, color: img.ColorRgb8(0, 0, 0));
    img.compositeImage(
      padded,
      resized,
      dstX: padLeft,
      dstY: padTop,
    );

    final useFloatInput = switch (inputType) {
      'float16' || 'float32' || 'float64' => true,
      _ => false,
    };

    final tensor = List.generate(
      1,
      (_) => List.generate(
        safeTargetHeight,
        (y) => List.generate(
          safeTargetWidth,
          (x) {
            final pixel = padded.getPixel(x, y);
            if (useFloatInput) {
              return <double>[
                pixel.r.toDouble(),
                pixel.g.toDouble(),
                pixel.b.toDouble(),
              ];
            }

            return <int>[
              pixel.r.toInt(),
              pixel.g.toInt(),
              pixel.b.toInt(),
            ];
          },
        ),
      ),
    );

    return _PreparedPostureInput(
      tensor: tensor,
      originalWidth: decoded.width,
      originalHeight: decoded.height,
      networkWidth: safeTargetWidth,
      networkHeight: safeTargetHeight,
      resizedWidth: resizedWidth,
      resizedHeight: resizedHeight,
      padLeft: padLeft,
      padTop: padTop,
    );
  }

  dynamic _createZeroTensorBuffer(List<int> shape) {
    if (shape.isEmpty) {
      return 0.0;
    }
    if (shape.length == 1) {
      return List<double>.filled(shape.first, 0.0);
    }

    return List.generate(
      shape.first,
      (_) => _createZeroTensorBuffer(shape.sublist(1)),
    );
  }

  List<List<double>> _extractPostureKeypoints(dynamic outputTensor) {
    dynamic cursor = outputTensor;
    while (cursor is List && cursor.length == 1) {
      cursor = cursor.first;
    }

    if (cursor is! List || cursor.length < 17) {
      throw StateError('Unexpected posture model output shape: $cursor');
    }

    return cursor.take(17).map<List<double>>((entry) {
      final values = (entry as List).take(3).toList();
      return <double>[
        (values[0] as num).toDouble(),
        (values[1] as num).toDouble(),
        (values[2] as num).toDouble(),
      ];
    }).toList();
  }

  List<List<double>> _mapKeypointsBackToOriginalFrame(
    List<List<double>> keypoints,
    _PreparedPostureInput preparedInput,
  ) {
    final networkWidth = preparedInput.networkWidth.toDouble();
    final networkHeight = preparedInput.networkHeight.toDouble();
    final resizedWidth = preparedInput.resizedWidth.toDouble();
    final resizedHeight = preparedInput.resizedHeight.toDouble();

    return keypoints.map((kp) {
      final paddedY = kp[0] * networkHeight;
      final paddedX = kp[1] * networkWidth;

      final normalizedY = resizedHeight <= 0
          ? kp[0]
          : ((paddedY - preparedInput.padTop) / resizedHeight).clamp(0.0, 1.0);
      final normalizedX = resizedWidth <= 0
          ? kp[1]
          : ((paddedX - preparedInput.padLeft) / resizedWidth).clamp(0.0, 1.0);

      return <double>[
        (normalizedY as num).toDouble(),
        (normalizedX as num).toDouble(),
        kp[2],
      ];
    }).toList();
  }

  String _tensorTypeName(Object type) => type.toString().split('.').last;

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

class _PreparedPostureInput {
  final dynamic tensor;
  final int originalWidth;
  final int originalHeight;
  final int networkWidth;
  final int networkHeight;
  final int resizedWidth;
  final int resizedHeight;
  final int padLeft;
  final int padTop;

  const _PreparedPostureInput({
    required this.tensor,
    required this.originalWidth,
    required this.originalHeight,
    required this.networkWidth,
    required this.networkHeight,
    required this.resizedWidth,
    required this.resizedHeight,
    required this.padLeft,
    required this.padTop,
  });
}
