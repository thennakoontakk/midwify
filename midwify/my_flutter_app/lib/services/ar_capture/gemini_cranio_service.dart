import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import '../../screens/ar_capture/ar_capture_models.dart';
import 'cranial_metrics.dart';

class CranioGeometrySignals {
  final String cephalicIndexRisk;
  final String asymmetryRisk;
  final String orbitalSymmetryRisk;

  const CranioGeometrySignals({
    required this.cephalicIndexRisk,
    required this.asymmetryRisk,
    required this.orbitalSymmetryRisk,
  });

  factory CranioGeometrySignals.fromJson(Map<String, dynamic> json) {
    return CranioGeometrySignals(
      cephalicIndexRisk:
          (json['cephalicIndexRisk'] as String? ?? 'normal').trim(),
      asymmetryRisk: (json['asymmetryRisk'] as String? ?? 'normal').trim(),
      orbitalSymmetryRisk:
          (json['orbitalSymmetryRisk'] as String? ?? 'normal').trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cephalicIndexRisk': cephalicIndexRisk,
        'asymmetryRisk': asymmetryRisk,
        'orbitalSymmetryRisk': orbitalSymmetryRisk,
      };
}

class CranioAIResult {
  final String riskLevel;
  final int riskScore;
  final String headShapeClassification;
  final String confidence;
  final List<String> keyFindings;
  final CranioGeometrySignals geometrySignals;
  final String visualObservations;
  final String urgency;
  final String recommendation;
  final String disclaimer;
  final String modelName;
  final int imageCount;
  final Map<String, dynamic>? usageMetadata;

  const CranioAIResult({
    required this.riskLevel,
    required this.riskScore,
    required this.headShapeClassification,
    required this.confidence,
    required this.keyFindings,
    required this.geometrySignals,
    required this.visualObservations,
    required this.urgency,
    required this.recommendation,
    required this.disclaimer,
    this.modelName = '',
    this.imageCount = 1,
    this.usageMetadata,
  });

  factory CranioAIResult.fromJson(Map<String, dynamic> json) {
    final findings = <String>[];
    final rawFindings = json['keyFindings'];
    if (rawFindings is List) {
      for (final item in rawFindings) {
        if (item is String && item.trim().isNotEmpty) {
          findings.add(item.trim());
        }
      }
    }

    return CranioAIResult(
      riskLevel: (json['riskLevel'] as String? ?? 'low').trim().toLowerCase(),
      riskScore: (json['riskScore'] as num? ?? 0).round().clamp(0, 100),
      headShapeClassification:
          (json['headShapeClassification'] as String? ?? 'unclassified')
              .trim()
              .toLowerCase(),
      confidence: (json['confidence'] as String? ?? 'low').trim().toLowerCase(),
      keyFindings: findings,
      geometrySignals: CranioGeometrySignals.fromJson(
        Map<String, dynamic>.from(
          json['geometrySignals'] as Map? ?? const <String, dynamic>{},
        ),
      ),
      visualObservations: (json['visualObservations'] as String? ?? '').trim(),
      urgency: (json['urgency'] as String? ?? 'routine').trim().toLowerCase(),
      recommendation: (json['recommendation'] as String? ?? '').trim(),
      disclaimer: (json['disclaimer'] as String? ?? '').trim(),
    );
  }

  RiskBand get riskBand {
    switch (riskLevel) {
      case 'high':
        return RiskBand.refer;
      case 'moderate':
        return RiskBand.review;
      case 'low':
        return RiskBand.lowRisk;
      default:
        return RiskBand.unavailable;
    }
  }

  Map<String, dynamic> toJson() => {
        'riskLevel': riskLevel,
        'riskScore': riskScore,
        'headShapeClassification': headShapeClassification,
        'confidence': confidence,
        'keyFindings': keyFindings,
        'geometrySignals': geometrySignals.toJson(),
        'visualObservations': visualObservations,
        'urgency': urgency,
        'recommendation': recommendation,
        'disclaimer': disclaimer,
        'modelName': modelName,
        'imageCount': imageCount,
        'usageMetadata': usageMetadata,
      };

  CranioAIResult copyWith({
    String? modelName,
    int? imageCount,
    Map<String, dynamic>? usageMetadata,
  }) {
    return CranioAIResult(
      riskLevel: riskLevel,
      riskScore: riskScore,
      headShapeClassification: headShapeClassification,
      confidence: confidence,
      keyFindings: keyFindings,
      geometrySignals: geometrySignals,
      visualObservations: visualObservations,
      urgency: urgency,
      recommendation: recommendation,
      disclaimer: disclaimer,
      modelName: modelName ?? this.modelName,
      imageCount: imageCount ?? this.imageCount,
      usageMetadata: usageMetadata ?? this.usageMetadata,
    );
  }
}

class GeminiCranioService {
  static const String _modelName = 'gemini-2.5-flash';
  static const String _endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelName:generateContent';
  static const int _maxInlineDimension = 896;
  static const int _maxInlineBytesWithoutResize = 1024 * 1024;
  static const Duration _requestTimeout = Duration(seconds: 35);

  static const String _systemPrompt = '''
You are a specialist craniosynostosis screening AI embedded in a Flutter pediatric
app. You will receive a structured JSON object containing cranial geometry
measurements extracted from a baby's head image using Google MediaPipe face
landmarks and a geometry scoring engine, plus one or two photographs of the same
baby's head taken through the app camera.

You must analyze BOTH inputs together. Use the photograph to visually assess skull
shape, forehead contour, facial symmetry, visible suture ridges, orbital alignment,
and any visible asymmetries or abnormal contours. Use the measurements to
quantify what you observe and to catch subtle geometry deviations that may not be
obvious to the eye. Your combined visual and numerical analysis replaces what was
previously done by a TFLite binary classifier and a manual fusion heuristic.

If two photographs are provided, treat image 1 as the primary measurement image
and image 2 as a confirmation view of the same baby's head from a nearby angle.
Cross-check the views. If one image is weak but the other is clear, prefer the
clearer view and mention the inconsistency in keyFindings.

VISUAL ASSESSMENT GUIDELINES - what to look for in the photo:
- Overall skull silhouette: does it appear elongated, flat, triangular, or asymmetric?
- Forehead shape: is it bulging, recessed, or pointed (trigonocephaly)?
- Any visible or palpable ridge running along a suture line - this is a strong
  direct indicator of premature fusion.
- Eye socket alignment: are the orbits at the same height and depth on both sides?
- Ear position asymmetry relative to the skull.
- Occiput shape: is the back of the head unusually flat or prominent?
- Overall facial balance and midface position.
- Note: the image may have a face mesh overlay from MediaPipe - this is expected
  and should not affect your assessment. Look through the overlay to assess the
  underlying head shape.

MEASUREMENT INPUT FIELDS YOU WILL RECEIVE:
- ageWeeks: baby age in weeks (0-104)
- cephalicIndex: skull width-to-length ratio. Normal 75-85. Below 70 suggests
  scaphocephaly. Above 90 suggests brachycephaly.
- asymmetryIndex: left-right cranial asymmetry percentage. Above 3.5% notable.
  Above 6% significant.
- foreheadSkewPct: forehead skew from geometry scoring.
- templeTiltDeg: temple tilt in degrees.
- supportedView: boolean - whether camera angle was valid for reliable measurement.
  If false, geometry metrics are unreliable. Rely more on the photo and parent
  risk factors. Set confidence to low.
- faceMeshLandmarks.orbitalSymmetry: eye orbit symmetry 0 to 1. Below 0.85
  suggests orbital asymmetry which favours true synostosis over positional.
- faceMeshLandmarks.anteriorPosteriorRatio: front-to-back head ratio.
- faceMeshLandmarks.templeWidth: temple-to-temple landmark distance.
- faceMeshLandmarks.foreheadWidth: forehead width from landmarks.
- parentRiskFactors.familyHistory: first-degree relative with craniosynostosis
  raises risk approximately 25 times the population baseline.
- parentRiskFactors.visibleSutureRidge: strong direct indicator. Always set
  riskLevel to at least moderate and urgency to at least soon when true.
- parentRiskFactors.feedingDifficulties: may indicate elevated intracranial
  pressure associated with craniosynostosis.
- parentRiskFactors.unusualIrritability: may indicate intracranial pressure.
  Weight this especially when combined with other indicators.

CLINICAL CLASSIFICATION RULES:
- Scaphocephaly: cephalicIndex below 70, elongated narrow skull, sagittal suture.
- Plagiocephaly: asymmetryIndex above 5%, unilateral flattening. Low orbitalSymmetry
  favours synostotic over positional deformational.
- Trigonocephaly: triangular forehead, elevated foreheadSkewPct, metopic suture.
- Brachycephaly: cephalicIndex above 90, flat occiput, bilateral coronal sutures.
- If visibleSutureRidge is true, riskLevel must be at least moderate, urgency
  at least soon, regardless of other scores.
- If familyHistory is true, increase riskScore by at least 15 points.
- If supportedView is false, set confidence to low, note unreliable geometry in
  keyFindings, and rely primarily on visual photo assessment and parent risk factors.
- If the baby is under 8 weeks, note that suture assessment is more difficult and
  recommend follow-up imaging if any clinical doubt exists.
- If the photo quality is too poor or the head is not clearly visible, set
  confidence to low and note this in keyFindings.

IMPORTANT: Your keyFindings must always reference both what you observed visually
in the photo AND what the measurements indicate. For example: "Photo shows mild
right-side flattening confirmed by asymmetryIndex of 4.2%." This dual-evidence
approach gives parents and clinicians a transparent, trustworthy assessment.

OUTPUT: Return only a valid JSON object. No markdown fences. No explanation text.
No preamble. Exact schema:
{
  "riskLevel": "low" or "moderate" or "high",
  "riskScore": integer 0 to 100,
  "headShapeClassification": "normal" or "scaphocephaly" or "plagiocephaly" or
                              "trigonocephaly" or "brachycephaly" or "unclassified",
  "confidence": "low" or "medium" or "high",
  "keyFindings": ["string", "string", "string"],
  "geometrySignals": {
    "cephalicIndexRisk": "normal" or "mild" or "significant",
    "asymmetryRisk": "normal" or "mild" or "significant",
    "orbitalSymmetryRisk": "normal" or "mild" or "significant"
  },
  "visualObservations": "one sentence describing what was visually observed in
                          the photo that supports or modifies the measurement findings",
  "urgency": "routine" or "soon" or "urgent",
  "recommendation": "one clear parent-facing sentence about what to do next",
  "disclaimer": "This is a screening tool only. Always consult a pediatrician or
                 craniofacial specialist for diagnosis."
}
''';

  static bool _dotenvLoaded = false;

  static String userVisibleFailureMessage(Object error) {
    final message = error.toString();
    if (message.contains('TimeoutException')) {
      return 'AI-assisted photo review did not respond in time, so this result uses on-device geometry only.';
    }
    if (message.contains('GEMINI_API_KEY')) {
      return 'AI-assisted photo review is not configured in this build, so this result uses on-device geometry only.';
    }
    if (message.contains('status 401') || message.contains('status 403')) {
      return 'AI-assisted photo review was rejected by the server, so this result uses on-device geometry only.';
    }
    return 'AI-assisted photo review was unavailable for this scan, so this result uses on-device geometry only.';
  }

  Future<CranioAIResult> analyzeWithAI({
    required AppLanguage language,
    required String imagePath,
    String? secondaryImagePath,
    required CranialResult geometry,
    required HeadScreeningMetrics metrics,
    required int ageWeeks,
    required bool familyHistory,
    required bool visibleSutureRidge,
    required bool feedingDifficulties,
    required bool unusualIrritability,
  }) async {
    try {
      debugPrint('[HEAD_AI] Loading Gemini configuration');
      await _ensureDotenvLoaded();

      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null ||
          apiKey.trim().isEmpty ||
          apiKey.trim() == 'your_key_here') {
        throw StateError(
          'GEMINI_API_KEY is missing or still set to the placeholder value.',
        );
      }

      debugPrint('[HEAD_AI] Preparing Gemini inline image');
      final encodedImages = <_EncodedImage>[
        _prepareInlineImage(imagePath),
        if (secondaryImagePath != null && secondaryImagePath.trim().isNotEmpty)
          _prepareInlineImage(secondaryImagePath),
      ];
      final languageInstruction = language == AppLanguage.si
          ? 'Return keyFindings, visualObservations, recommendation, and disclaimer in Sinhala. Keep riskLevel, riskScore, headShapeClassification, confidence, urgency, and geometrySignals enum values in English exactly as defined in the schema.'
          : 'Return all user-facing prose fields in English. Keep riskLevel, riskScore, headShapeClassification, confidence, urgency, and geometrySignals enum values in English exactly as defined in the schema.';
      final payload = _buildMeasurementsPayload(
        geometry: geometry,
        metrics: metrics,
        ageWeeks: ageWeeks,
        familyHistory: familyHistory,
        visibleSutureRidge: visibleSutureRidge,
        feedingDifficulties: feedingDifficulties,
        unusualIrritability: unusualIrritability,
        imageCount: encodedImages.length,
      );

      final requestBody = <String, dynamic>{
        'systemInstruction': {
          'parts': [
            {'text': _systemPrompt},
          ],
        },
        'generationConfig': {
          'responseMimeType': 'application/json',
          'temperature': 0.1,
        },
        'contents': [
          {
            'parts': [
              for (final encodedImage in encodedImages)
                {
                  'inline_data': {
                    'mime_type': encodedImage.mimeType,
                    'data': encodedImage.base64Data,
                  },
                },
              {
                'text':
                    '$languageInstruction Analyze these baby head images and the following cranial scan measurements together. Image 1 is the primary capture used for geometry. Image 2, when present, is a confirmation view. Return JSON only:\n${jsonEncode(payload)}',
              },
            ],
          },
        ],
      };

      debugPrint('[HEAD_AI] Posting multimodal request to Gemini');
      final response = await http
          .post(
            Uri.parse('$_endpoint?key=$apiKey'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(_requestTimeout);

      debugPrint(
        '[HEAD_AI] Gemini response status ${response.statusCode}',
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Gemini API request failed with status ${response.statusCode}: ${response.body}',
        );
      }

      final rawText = _extractResponseText(response.body);
      final cleaned = _stripMarkdownFences(rawText);
      final decoded = jsonDecode(cleaned);
      if (decoded is! Map) {
        throw FormatException(
          'Gemini response JSON root was not an object: $cleaned',
        );
      }

      return CranioAIResult.fromJson(Map<String, dynamic>.from(decoded))
          .copyWith(
        modelName: _modelName,
        imageCount: encodedImages.length,
        usageMetadata: _extractUsageMetadata(response.body),
      );
    } catch (e) {
      throw Exception('Gemini cranial analysis failed: $e');
    }
  }

  String get modelName => _modelName;

  Future<void> _ensureDotenvLoaded() async {
    if (_dotenvLoaded) {
      return;
    }
    await dotenv.load(fileName: 'app.env');
    _dotenvLoaded = true;
  }

  _EncodedImage _prepareInlineImage(String imagePath) {
    final file = File(imagePath);
    final originalBytes = file.readAsBytesSync();
    final fallbackMimeType = _detectMimeType(imagePath);

    try {
      final decoded = img.decodeImage(originalBytes);
      if (decoded == null) {
        throw StateError('Image decode returned null.');
      }

      final maxDimension = math.max(decoded.width, decoded.height);
      final shouldResize =
          maxDimension > _maxInlineDimension ||
          originalBytes.length > _maxInlineBytesWithoutResize;
      if (!shouldResize) {
        debugPrint(
          '[HEAD_AI] Using original capture for Gemini inline image (${originalBytes.length} bytes)',
        );
        return _EncodedImage(
          mimeType: fallbackMimeType,
          base64Data: base64Encode(originalBytes),
        );
      }

      final processed = maxDimension > _maxInlineDimension
          ? img.copyResize(
              decoded,
              width:
                  decoded.width >= decoded.height ? _maxInlineDimension : null,
              height:
                  decoded.height > decoded.width ? _maxInlineDimension : null,
            )
          : decoded;

      final resizedBytes = img.encodeJpg(processed, quality: 82);
      debugPrint(
        '[HEAD_AI] Resized Gemini inline image to ${processed.width}x${processed.height} (${resizedBytes.length} bytes)',
      );
      return _EncodedImage(
        mimeType: 'image/jpeg',
        base64Data: base64Encode(resizedBytes),
      );
    } catch (e) {
      debugPrint('GeminiCranioService image resize warning: $e');
      return _EncodedImage(
        mimeType: fallbackMimeType,
        base64Data: base64Encode(originalBytes),
      );
    }
  }

  String _detectMimeType(String imagePath) {
    final lower = imagePath.toLowerCase();
    if (lower.endsWith('.png')) {
      return 'image/png';
    }
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    return 'image/jpeg';
  }

  Map<String, dynamic> _buildMeasurementsPayload({
    required CranialResult geometry,
    required HeadScreeningMetrics metrics,
    required int ageWeeks,
    required bool familyHistory,
    required bool visibleSutureRidge,
    required bool feedingDifficulties,
    required bool unusualIrritability,
    required int imageCount,
  }) {
    return <String, dynamic>{
      'captureSet': {
        'imageCount': imageCount,
        'secondaryConfirmationProvided': imageCount > 1,
      },
      'ageWeeks': ageWeeks,
      'cephalicIndex': geometry.cranialIndex,
      'asymmetryIndex': geometry.cvai,
      'foreheadSkewPct': geometry.facialSymmetryOffsetPct,
      'templeTiltDeg': metrics.templeTiltDeg,
      'supportedView': geometry.supportedView,
      'cephalicProportionScore': geometry.cephalicProportionScore,
      'qualityScore': geometry.qualityScore,
      'screeningScore': geometry.screeningScore,
      'topDownAngleDelta': geometry.topDownAngleDelta,
      'landmarkQuality': geometry.landmarkQualityScore,
      'geometryWarnings': geometry.warnings,
      'geometryReasons': geometry.reasons,
      'faceMeshLandmarks': {
        'orbitalSymmetry': metrics.orbitalSymmetry,
        'anteriorPosteriorRatio': metrics.anteriorPosteriorRatio,
        'templeWidth': metrics.templeWidth,
        'foreheadWidth': metrics.foreheadWidth,
      },
      'parentRiskFactors': {
        'familyHistory': familyHistory,
        'visibleSutureRidge': visibleSutureRidge,
        'feedingDifficulties': feedingDifficulties,
        'unusualIrritability': unusualIrritability,
      },
      'dataCompleteness': {
        'parentRiskFactorsCapturedInAppFlow': false,
        'notes': [
          'This Flutter flow does not currently collect parent risk factors or age from the capture UI.',
          'Default values may be present for ageWeeks and parentRiskFactors when the app has not captured them yet.',
          'Null metric fields indicate values not available from the current geometry DTO without changing the preserved measurement engine.',
        ],
      },
    };
  }

  String _extractResponseText(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      throw FormatException(
        'Unexpected Gemini response envelope: $responseBody',
      );
    }

    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw FormatException('Gemini returned no candidates: $responseBody');
    }

    final firstCandidate = candidates.first;
    if (firstCandidate is! Map) {
      throw FormatException(
        'Gemini candidate had unexpected shape: $responseBody',
      );
    }

    final content = firstCandidate['content'];
    if (content is! Map) {
      throw FormatException('Gemini candidate content missing: $responseBody');
    }

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw FormatException('Gemini candidate parts missing: $responseBody');
    }

    final buffer = StringBuffer();
    for (final part in parts) {
      if (part is Map && part['text'] is String) {
        buffer.write(part['text'] as String);
      }
    }

    final text = buffer.toString().trim();
    if (text.isEmpty) {
      throw FormatException('Gemini returned no text payload: $responseBody');
    }

    return text;
  }

  Map<String, dynamic>? _extractUsageMetadata(String responseBody) {
    final decoded = jsonDecode(responseBody);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }

    final usageMetadata = decoded['usageMetadata'];
    if (usageMetadata is Map) {
      return Map<String, dynamic>.from(usageMetadata);
    }

    return null;
  }

  String _stripMarkdownFences(String value) {
    var cleaned = value.trim();
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'^```[a-zA-Z0-9_-]*\s*'), '');
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.replaceFirst(RegExp(r'\s*```$'), '');
    }
    return cleaned.trim();
  }
}

class _EncodedImage {
  final String mimeType;
  final String base64Data;

  const _EncodedImage({
    required this.mimeType,
    required this.base64Data,
  });
}
