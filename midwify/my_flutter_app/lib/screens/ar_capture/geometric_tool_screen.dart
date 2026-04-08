import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'ar_capture_localization.dart';
import 'ar_capture_models.dart';

const int _leftEyeIdx = 1;
const int _rightEyeIdx = 2;
const int _leftShoulderIdx = 5;
const int _rightShoulderIdx = 6;
const int _leftHipIdx = 11;
const int _rightHipIdx = 12;

class GeometricToolScreen extends StatelessWidget {
  final AppLanguage language;
  final ARCaptureResult result;
  final ValueChanged<ARCaptureResult> onConfirm;
  final VoidCallback onRetake;

  const GeometricToolScreen({
    super.key,
    required this.language,
    required this.result,
    required this.onConfirm,
    required this.onRetake,
  });

  @override
  Widget build(BuildContext context) {
    final t = ARCaptureLocalization.geometricTool(language);
    final diagnosisStrings = ARCaptureLocalization.diagnosis(language);
    final postureMetrics = result.postureMetrics;
    final posePoints = _extractPosePoints(result.debugDetails['keypoints']);
    final hasCapturePreview = _hasLocalCapturePreview;
    final canConfirm =
        hasCapturePreview && postureMetrics != null && posePoints.isNotEmpty;

    return Container(
      color: AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t['title']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t['subtitle']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatusChip(t),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildPreviewCard(
                      t: t,
                      posePoints: posePoints,
                      postureMetrics: postureMetrics,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      t: t,
                      diagnosisStrings: diagnosisStrings,
                    ),
                    if (postureMetrics != null) ...[
                      const SizedBox(height: 16),
                      _buildMetricLegendCard(
                        t: t,
                        postureMetrics: postureMetrics,
                      ),
                    ],
                    if (result.geometricReviewNote.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildNoteCard(
                        title: t['status']!,
                        body: ARCaptureLocalization.localizeResultText(
                          language,
                          result.geometricReviewNote,
                        ),
                        accent: AppColors.info,
                        background: AppColors.infoLight,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: canConfirm
                  ? () => onConfirm(_confirmedResult(t['note']!))
                  : null,
              icon: const Icon(Icons.verified, color: Colors.white),
              label: Text(
                t['confirm']!,
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.grey400,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetake,
              icon: const Icon(Icons.refresh, color: AppColors.primary),
              label: Text(
                t['retake']!,
                style: const TextStyle(fontSize: 16, color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _hasLocalCapturePreview {
    if (kIsWeb || result.captureImagePath.isEmpty) {
      return false;
    }

    return File(result.captureImagePath).existsSync();
  }

  ARCaptureResult _confirmedResult(String note) {
    final manualReview = result.debugDetails['manualReview'];
    final manualReviewMap = manualReview is Map
        ? Map<String, dynamic>.from(manualReview)
        : <String, dynamic>{};

    return result.copyWith(
      geometricReviewConfirmed: true,
      geometricReviewNote: note,
      debugDetails: {
        ...result.debugDetails,
        'manualReview': {
          ...manualReviewMap,
          'status': 'confirmed',
          'note': note,
          'confirmedAt': DateTime.now().toIso8601String(),
        },
      },
    );
  }

  Widget _buildStatusChip(Map<String, String> t) {
    final isConfirmed = result.geometricReviewConfirmed;
    final background =
        isConfirmed ? AppColors.successLight : AppColors.warningLight;
    final foreground = isConfirmed ? AppColors.success : AppColors.warning;

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isConfirmed ? Icons.verified : Icons.pending_actions,
              size: 18,
              color: foreground,
            ),
            const SizedBox(width: 8),
            Text(
              '${t['status']!}: ${isConfirmed ? t['confirmed']! : t['pending']!}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard({
    required Map<String, String> t,
    required Map<int, _PosePoint> posePoints,
    required PostureScreeningMetrics? postureMetrics,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['capturePreview']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          if (_hasLocalCapturePreview)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: _captureAspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(
                      File(result.captureImagePath),
                      fit: BoxFit.fill,
                    ),
                    CustomPaint(
                      painter: _PostureOverlayPainter(
                        points: posePoints,
                        metrics: postureMetrics,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t['source']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primaryLight),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.image_not_supported_outlined,
                    size: 44,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    t['captureMissing']!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          Text(
            t['overlayHint']!,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required Map<String, String> t,
    required Map<String, String> diagnosisStrings,
  }) {
    final visibility = result.postureMetrics?.visibilityQuality ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['summaryTitle']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _summaryTile(
                t['riskBand']!,
                ARCaptureLocalization.localizedRiskBandLabel(
                  language,
                  result.riskBand,
                  diagnosisStrings,
                ),
              ),
              _summaryTile(
                t['screeningScore']!,
                '${result.screeningScore}${t['percent']}',
              ),
              _summaryTile(
                t['qualityScore']!,
                '${result.qualityScore}${t['percent']}',
              ),
              _summaryTile(
                t['visibility']!,
                '${visibility.toStringAsFixed(0)}${t['percent']}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricLegendCard({
    required Map<String, String> t,
    required PostureScreeningMetrics postureMetrics,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['source']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _legendTile(
                t['shoulderLine']!,
                postureMetrics.shoulderTiltDeg,
                _angleColor(postureMetrics.shoulderTiltDeg,
                    review: 4, refer: 10),
                t['degrees']!,
              ),
              _legendTile(
                t['hipLine']!,
                postureMetrics.hipTiltDeg,
                _angleColor(postureMetrics.hipTiltDeg, review: 4, refer: 10),
                t['degrees']!,
              ),
              _legendTile(
                t['trunkLine']!,
                postureMetrics.trunkTiltDeg,
                _angleColor(postureMetrics.trunkTiltDeg, review: 5, refer: 12),
                t['degrees']!,
              ),
              _legendTile(
                t['headLine']!,
                postureMetrics.headTiltDeg,
                _angleColor(postureMetrics.headTiltDeg, review: 4, refer: 12),
                t['degrees']!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNoteCard({
    required String title,
    required String body,
    required Color accent,
    required Color background,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, String value) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendTile(String label, double value, Color color, String unit) {
    return Container(
      width: 145,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${value.toStringAsFixed(2)} $unit',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  double get _captureAspectRatio {
    final inference = result.debugDetails['inference'];
    if (inference is Map) {
      final width = (inference['originalWidth'] as num?)?.toDouble();
      final height = (inference['originalHeight'] as num?)?.toDouble();
      if (width != null && height != null && width > 0 && height > 0) {
        return width / height;
      }
    }

    return 3 / 4;
  }

  Map<int, _PosePoint> _extractPosePoints(dynamic rawKeypoints) {
    if (rawKeypoints is! List) {
      return const {};
    }

    final mapped = <int, _PosePoint>{};
    for (final item in rawKeypoints) {
      if (item is! Map) {
        continue;
      }

      final index = item['index'];
      final x = item['x'];
      final y = item['y'];
      final confidence = item['confidence'];
      if (index is! int || x is! num || y is! num || confidence is! num) {
        continue;
      }

      mapped[index] = _PosePoint(
        x: x.toDouble(),
        y: y.toDouble(),
        confidence: confidence.toDouble(),
      );
    }

    return mapped;
  }

  Color _angleColor(double value,
      {required double review, required double refer}) {
    if (value >= refer) {
      return AppColors.danger;
    }
    if (value >= review) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _PosePoint {
  final double x;
  final double y;
  final double confidence;

  const _PosePoint({
    required this.x,
    required this.y,
    required this.confidence,
  });
}

class _PostureOverlayPainter extends CustomPainter {
  final Map<int, _PosePoint> points;
  final PostureScreeningMetrics? metrics;

  const _PostureOverlayPainter({
    required this.points,
    required this.metrics,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final shoulders = _connection(_leftShoulderIdx, _rightShoulderIdx, size);
    final hips = _connection(_leftHipIdx, _rightHipIdx, size);
    final head = _connection(_leftEyeIdx, _rightEyeIdx, size);

    if (shoulders != null) {
      _drawSegment(
        canvas,
        shoulders.$1,
        shoulders.$2,
        _colorFor(metrics?.shoulderTiltDeg ?? 0, review: 4, refer: 10),
      );
    }

    if (hips != null) {
      _drawSegment(
        canvas,
        hips.$1,
        hips.$2,
        _colorFor(metrics?.hipTiltDeg ?? 0, review: 4, refer: 10),
      );
    }

    if (shoulders != null && hips != null) {
      final trunkStart = Offset.lerp(shoulders.$1, shoulders.$2, 0.5)!;
      final trunkEnd = Offset.lerp(hips.$1, hips.$2, 0.5)!;
      _drawSegment(
        canvas,
        trunkStart,
        trunkEnd,
        _colorFor(metrics?.trunkTiltDeg ?? 0, review: 5, refer: 12),
      );
    }

    if (head != null) {
      _drawSegment(
        canvas,
        head.$1,
        head.$2,
        _colorFor(metrics?.headTiltDeg ?? 0, review: 4, refer: 12),
      );
    }

    for (final point in points.values) {
      if (point.confidence < 0.3) {
        continue;
      }

      final offset = Offset(point.x * size.width, point.y * size.height);
      final fill = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      final stroke = Paint()
        ..color = Colors.black.withValues(alpha: 0.75)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2;
      canvas.drawCircle(offset, 4, fill);
      canvas.drawCircle(offset, 4, stroke);
    }
  }

  _OffsetPair? _connection(int start, int end, Size size) {
    final startPoint = points[start];
    final endPoint = points[end];
    if (startPoint == null || endPoint == null) {
      return null;
    }
    if (startPoint.confidence < 0.3 || endPoint.confidence < 0.3) {
      return null;
    }

    return (
      Offset(startPoint.x * size.width, startPoint.y * size.height),
      Offset(endPoint.x * size.width, endPoint.y * size.height),
    );
  }

  void _drawSegment(Canvas canvas, Offset start, Offset end, Color color) {
    final glow = Paint()
      ..color = color.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(start, end, glow);
    canvas.drawLine(start, end, stroke);
  }

  Color _colorFor(double value,
      {required double review, required double refer}) {
    if (value >= refer) {
      return AppColors.danger;
    }
    if (value >= review) {
      return AppColors.warning;
    }
    return AppColors.success;
  }

  @override
  bool shouldRepaint(covariant _PostureOverlayPainter oldDelegate) {
    return oldDelegate.points != points || oldDelegate.metrics != metrics;
  }
}

typedef _OffsetPair = (Offset, Offset);
