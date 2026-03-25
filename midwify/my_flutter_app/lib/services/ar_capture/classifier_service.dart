import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart'
    if (dart.library.html) 'ml_service_stub.dart';

import 'cranial_metrics.dart';

enum HeadClassifierDecision { unavailable, normal, uncertain, abnormal }

extension HeadClassifierDecisionPresentation on HeadClassifierDecision {
  String get label {
    switch (this) {
      case HeadClassifierDecision.normal:
        return 'Normal';
      case HeadClassifierDecision.uncertain:
        return 'Uncertain';
      case HeadClassifierDecision.abnormal:
        return 'Abnormal';
      case HeadClassifierDecision.unavailable:
        return 'Unavailable';
    }
  }
}

class HeadShapeClassification {
  final double abnormalProbability;
  final double normalProbability;
  final HeadClassifierDecision decision;
  final String source;
  final List<String> warnings;

  const HeadShapeClassification({
    required this.abnormalProbability,
    required this.normalProbability,
    required this.decision,
    required this.source,
    this.warnings = const [],
  });
}

class HeadFusionOutcome {
  final int screeningScore;
  final CranialRiskBand riskBand;
  final List<String> warnings;
  final String summary;

  const HeadFusionOutcome({
    required this.screeningScore,
    required this.riskBand,
    required this.warnings,
    required this.summary,
  });
}

HeadClassifierDecision classifyHeadProbability(double abnormalProbability) {
  if (abnormalProbability < 0.40) {
    return HeadClassifierDecision.normal;
  }
  if (abnormalProbability > 0.80) {
    return HeadClassifierDecision.abnormal;
  }
  return HeadClassifierDecision.uncertain;
}

HeadFusionOutcome fuseHeadSignals({
  required CranialResult geometry,
  required HeadShapeClassification classification,
}) {
  var screeningScore = geometry.screeningScore;
  final warnings = <String>[
    ...geometry.warnings,
    ...classification.warnings,
  ];

  switch (classification.decision) {
    case HeadClassifierDecision.normal:
      warnings.add(
        'Image classifier suggests a normal pattern, but research mode does not downgrade the geometry screen from that signal alone.',
      );
      break;
    case HeadClassifierDecision.uncertain:
      warnings.add(
        'Image classifier is inconclusive for this head photo. Retake if the result does not match the child.',
      );
      break;
    case HeadClassifierDecision.abnormal:
      screeningScore = math.min(100, screeningScore + 10);
      if (geometry.supportedView &&
          geometry.riskBand == CranialRiskBand.lowRisk &&
          classification.abnormalProbability > 0.92) {
        screeningScore = math.max(screeningScore, 40);
      }
      warnings.add(
        'Image classifier detected an abnormal pattern with ${(classification.abnormalProbability * 100).round()}% abnormal probability. In research mode this can raise a low signal to review, but it does not create a referral-level output by itself.',
      );
      break;
    case HeadClassifierDecision.unavailable:
      warnings.add('Head-shape image classifier unavailable. Using geometry screen only.');
      break;
  }

  if (!geometry.supportedView) {
    screeningScore = math.max(screeningScore, 55);
  }

  final riskBand = screeningScore >= 70
      ? CranialRiskBand.refer
      : screeningScore >= 35
          ? CranialRiskBand.review
          : CranialRiskBand.lowRisk;

  final summary = !geometry.supportedView
      ? 'Unsupported head capture view. Retake before relying on the screen.'
      : switch (riskBand) {
          CranialRiskBand.lowRisk =>
            classification.decision == HeadClassifierDecision.uncertain
                ? 'Low-signal head research result, but the image classifier was inconclusive.'
                : 'Low-signal head research result from landmarks and image classification.',
          CranialRiskBand.review =>
            classification.decision == HeadClassifierDecision.normal
                ? 'Geometry shows a review-level research signal even though the image classifier looked normal. Retake and review before drawing conclusions.'
                : classification.decision == HeadClassifierDecision.abnormal
                    ? 'Image classifier and geometry do not fully agree. Keeping this at review level in research mode and recommending a retake.'
                    : 'Review-level head research signal. Repeat capture and review the metrics.',
          CranialRiskBand.refer =>
            'High-priority head research signal supported by geometry. This is still not a diagnosis.',
        };

  return HeadFusionOutcome(
    screeningScore: screeningScore.clamp(0, 100),
    riskBand: riskBand,
    warnings: warnings,
    summary: summary,
  );
}

class ClassifierService {
  static final ClassifierService _instance = ClassifierService._internal();
  factory ClassifierService() => _instance;
  ClassifierService._internal();

  static const String _modelAsset = 'assets/models/cranial_analysis.tflite';
  static const int _inputSize = 224;

  Interpreter? _interpreter;

  Future<void> initialize() async {
    if (kIsWeb || _interpreter != null) {
      return;
    }

    try {
      _interpreter = await Interpreter.fromAsset(_modelAsset);
      debugPrint('Head-shape classifier loaded from $_modelAsset');
    } catch (e) {
      debugPrint('Error loading head-shape classifier: $e');
    }
  }

  Future<HeadShapeClassification> classifyImage(String imagePath) async {
    if (kIsWeb) {
      return const HeadShapeClassification(
        abnormalProbability: 0.0,
        normalProbability: 0.0,
        decision: HeadClassifierDecision.unavailable,
        source: _modelAsset,
        warnings: ['Head-shape classifier is unavailable on web.'],
      );
    }

    await initialize();
    if (_interpreter == null) {
      return const HeadShapeClassification(
        abnormalProbability: 0.0,
        normalProbability: 0.0,
        decision: HeadClassifierDecision.unavailable,
        source: _modelAsset,
        warnings: ['Head-shape classifier could not be initialized.'],
      );
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final decoded = img.decodeImage(bytes);
      if (decoded == null) {
        return const HeadShapeClassification(
          abnormalProbability: 0.0,
          normalProbability: 0.0,
          decision: HeadClassifierDecision.unavailable,
          source: _modelAsset,
          warnings: ['Head image could not be decoded for image classification.'],
        );
      }

      final input = _prepareInput(decoded);
      final output = List.generate(1, (_) => List<double>.filled(2, 0.0));
      _interpreter!.run(input, output);

      // Notebook training repeatedly documents the binary class order as:
      // ['Abnormal', 'Normal'].
      final abnormalProbability = output[0][0].clamp(0.0, 1.0);
      final normalProbability = output[0][1].clamp(0.0, 1.0);
      final decision = classifyHeadProbability(abnormalProbability);

      return HeadShapeClassification(
        abnormalProbability: _r2(abnormalProbability),
        normalProbability: _r2(normalProbability),
        decision: decision,
        source: _modelAsset,
      );
    } catch (e) {
      return HeadShapeClassification(
        abnormalProbability: 0.0,
        normalProbability: 0.0,
        decision: HeadClassifierDecision.unavailable,
        source: _modelAsset,
        warnings: ['Head-shape classifier failed: $e'],
      );
    }
  }

  List _prepareInput(img.Image source) {
    final resized = _smartResize(source, _inputSize);
    return List.generate(
      1,
      (_) => List.generate(
        _inputSize,
        (y) => List.generate(
          _inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return <double>[
              pixel.r.toDouble() / 255.0,
              pixel.g.toDouble() / 255.0,
              pixel.b.toDouble() / 255.0,
            ];
          },
        ),
      ),
    );
  }

  img.Image _smartResize(img.Image image, int targetSize) {
    final width = image.width;
    final height = image.height;
    final scale = math.min(targetSize / height, targetSize / width);
    final newWidth = (width * scale).round();
    final newHeight = (height * scale).round();
    final resized = img.copyResize(image, width: newWidth, height: newHeight);
    final canvas = img.Image(width: targetSize, height: targetSize);
    img.fill(canvas, color: img.ColorRgb8(0, 0, 0));
    final xOffset = ((targetSize - newWidth) / 2).round();
    final yOffset = ((targetSize - newHeight) / 2).round();
    img.compositeImage(canvas, resized, dstX: xOffset, dstY: yOffset);
    return canvas;
  }
}

double _r2(double value) => double.parse(value.toStringAsFixed(2));
