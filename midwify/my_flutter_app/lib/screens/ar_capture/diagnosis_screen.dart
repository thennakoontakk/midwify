import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'ar_capture_models.dart';

class DiagnosisScreen extends StatelessWidget {
  final AppMode mode;
  final AppLanguage language;
  final ARCaptureResult result;
  final VoidCallback onRetake;
  final VoidCallback onFinish;
  final VoidCallback onOpenGeometricTool;

  const DiagnosisScreen({
    super.key,
    required this.mode,
    required this.language,
    required this.result,
    required this.onRetake,
    required this.onFinish,
    required this.onOpenGeometricTool,
  });

  @override
  Widget build(BuildContext context) {
    final t = _strings(language);

    if (!result.isValidImage) {
      return _buildInvalidScreen(t);
    }

    final accent = _riskColor(result.riskBand, result.supportedView);
    final icon = _riskIcon(result.riskBand, result.supportedView);

    return Container(
      color: AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              mode == AppMode.head ? t['headModel']! : t['postureModel']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeroCard(
                      accent: accent,
                      icon: icon,
                      t: t,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(t),
                    const SizedBox(height: 16),
                    if (mode == AppMode.head && result.headMetrics != null)
                      _buildHeadMetricsCard(t, result.headMetrics!),
                    if (mode == AppMode.head && result.headMetrics != null) ...[
                      const SizedBox(height: 16),
                      _buildHeadAiDetailsCard(t, result.headMetrics!),
                    ],
                    if (mode == AppMode.posture &&
                        result.postureMetrics != null)
                      _buildPostureMetricsCard(t, result.postureMetrics!),
                    if (_hasWarnings) ...[
                      const SizedBox(height: 16),
                      _buildWarningsCard(t),
                    ],
                    const SizedBox(height: 16),
                    _buildDisclaimerCard(t),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ..._buildActionButtons(t),
          ],
        ),
      ),
    );
  }

  bool get _hasWarnings => result.warnings.isNotEmpty || !result.supportedView;

  Map<String, String> _strings(AppLanguage language) {
    const english = {
      'title': 'Research Results',
      'headModel': 'Head Research Pipeline',
      'postureModel': 'Posture Research Pipeline',
      'captureQuality': 'Capture Quality',
      'screeningScore': 'Research Score',
      'riskBand': 'Signal Band',
      'impactLevel': 'Research Signal',
      'supportedView': 'Supported View',
      'yes': 'Yes',
      'no': 'No',
      'summary': 'Summary',
      'warnings': 'Warnings',
      'headMetrics': 'Head Metrics',
      'postureMetrics': 'Posture Metrics',
      'researchDisclaimer':
          'Experimental research output only. Not validated for diagnosis, referral, or treatment decisions.',
      'landmarkSource': 'Landmark Source',
      'retake': 'Retake Photo',
      'finish': 'Back to Home',
      'tool': 'Open Geometric Tool',
      'invalid':
          'No usable infant image was detected for screening. Retake the photo with the infant clearly visible.',
      'invalidTitle': 'Screening Unavailable',
      'ci': 'Cranial Index',
      'cvai': 'Cranial Vault Asymmetry Index',
      'symmetry': 'Facial Symmetry Offset',
      'headQuality': 'Landmark Quality',
      'angleDelta': 'Top-Down Angle Delta',
      'imageClassifier': 'Image Classifier',
      'abnormalProb': 'Abnormal Probability',
      'normalProb': 'Normal Probability',
      'aiDetails': 'AI Details',
      'headShape': 'Head Shape',
      'aiRiskLevel': 'AI Risk Level',
      'aiConfidence': 'AI Confidence',
      'aiUrgency': 'AI Urgency',
      'visualObservation': 'Visual Observation',
      'recommendationTitle': 'Recommendation',
      'keyFindings': 'Key Findings',
      'aiProvider': 'AI Provider',
      'inputImages': 'Input Images',
      'totalTokens': 'Total Tokens',
      'promptTokens': 'Prompt Tokens',
      'fallbackMode': 'Fallback Mode',
      'cephalicRisk': 'Cephalic Index Risk',
      'asymmetryRisk': 'Asymmetry Risk',
      'orbitalRisk': 'Orbital Symmetry Risk',
      'aiError': 'AI Error',
      'shoulderTilt': 'Shoulder Tilt',
      'hipTilt': 'Hip Tilt',
      'trunkTilt': 'Trunk Tilt',
      'headTilt': 'Head Tilt',
      'midlineOffset': 'Midline Offset',
      'visibility': 'Visibility Quality',
      'cameraRoll': 'Camera Roll',
      'percent': '%',
      'degrees': 'deg',
      'ratio': 'ratio',
    };

    return language == AppLanguage.en ? english : english;
  }

  Widget _buildHeroCard({
    required Color accent,
    required IconData icon,
    required Map<String, String> t,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withOpacity(0.14),
            ),
            child: Icon(icon, size: 48, color: accent),
          ),
          const SizedBox(height: 16),
          Text(
            result.riskBand.impactLevelLabel,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: accent,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t['impactLevel']!,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            result.summary,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _scoreTile(
                  t['captureQuality']!,
                  '${result.qualityScore}${t['percent']}',
                  accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _scoreTile(
                  t['screeningScore']!,
                  '${result.screeningScore}${t['percent']}',
                  accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, String> t) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['summary']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _summaryRow(t['impactLevel']!, result.riskBand.impactLevelLabel),
          _summaryRow(t['riskBand']!, result.riskBand.label),
          _summaryRow(
            t['supportedView']!,
            result.supportedView ? t['yes']! : t['no']!,
          ),
          _summaryRow(t['landmarkSource']!, result.landmarkSource),
          const SizedBox(height: 6),
          Text(
            _impactDescription(),
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadMetricsCard(
    Map<String, String> t,
    HeadScreeningMetrics metrics,
  ) {
    return _metricsCard(
      title: t['headMetrics']!,
      children: [
        _metricTile(t['ci']!, '${metrics.cranialIndex.toStringAsFixed(2)}'),
        _metricTile(
          t['cvai']!,
          '${metrics.cranialVaultAsymmetryIndex.toStringAsFixed(2)} ${t['percent']}',
        ),
        _metricTile(
          t['symmetry']!,
          '${metrics.facialSymmetryOffsetPct.toStringAsFixed(2)} ${t['percent']}',
        ),
        _metricTile(
          t['headQuality']!,
          '${metrics.landmarkQuality.toStringAsFixed(0)} ${t['percent']}',
        ),
        _metricTile(
          'Cephalic Proportion Score',
          '${metrics.cephalicProportionScore.toStringAsFixed(2)} ${t['percent']}',
        ),
        _metricTile(
          t['angleDelta']!,
          metrics.topDownAngleDelta.toStringAsFixed(3),
        ),
        _metricTile(
          t['imageClassifier']!,
          metrics.classifierDecision,
        ),
        _metricTile(
          t['abnormalProb']!,
          '${metrics.classifierAbnormalProbability.toStringAsFixed(0)} ${t['percent']}',
        ),
        _metricTile(
          t['normalProb']!,
          '${metrics.classifierNormalProbability.toStringAsFixed(0)} ${t['percent']}',
        ),
      ],
    );
  }

  Widget _buildPostureMetricsCard(
    Map<String, String> t,
    PostureScreeningMetrics metrics,
  ) {
    return _metricsCard(
      title: t['postureMetrics']!,
      children: [
        _metricTile(
          t['shoulderTilt']!,
          '${metrics.shoulderTiltDeg.toStringAsFixed(2)} ${t['degrees']}',
        ),
        _metricTile(
          t['hipTilt']!,
          '${metrics.hipTiltDeg.toStringAsFixed(2)} ${t['degrees']}',
        ),
        _metricTile(
          t['trunkTilt']!,
          '${metrics.trunkTiltDeg.toStringAsFixed(2)} ${t['degrees']}',
        ),
        _metricTile(
          t['headTilt']!,
          '${metrics.headTiltDeg.toStringAsFixed(2)} ${t['degrees']}',
        ),
        _metricTile(
          t['midlineOffset']!,
          '${metrics.midlineOffsetRatio.toStringAsFixed(2)} ${t['ratio']}',
        ),
        _metricTile(
          t['visibility']!,
          '${metrics.visibilityQuality.toStringAsFixed(0)} ${t['percent']}',
        ),
        _metricTile(
          t['cameraRoll']!,
          '${metrics.cameraRollDeg.toStringAsFixed(2)} ${t['degrees']}',
        ),
      ],
    );
  }

  Widget _buildHeadAiDetailsCard(
    Map<String, String> t,
    HeadScreeningMetrics metrics,
  ) {
    final geometrySignals = result.debugDetails['geometrySignals'];
    final aiProvider = result.debugDetails['aiProvider'] as String?;
    final aiImageCount = result.debugDetails['aiImageCount'];
    final aiUsageMetadata = result.debugDetails['aiUsageMetadata'];
    final fallbackMode = result.debugDetails['fallbackMode'] as String?;
    final aiError = result.debugDetails['aiError'] as String?;

    final signalMap = geometrySignals is Map
        ? Map<String, dynamic>.from(geometrySignals)
        : const <String, dynamic>{};
    final usageMap = aiUsageMetadata is Map
        ? Map<String, dynamic>.from(aiUsageMetadata)
        : const <String, dynamic>{};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['aiDetails']!,
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
              _metricTile(t['headShape']!, metrics.headShapeLabel),
              _metricTile(t['aiRiskLevel']!, metrics.aiRiskLevel),
              _metricTile(t['aiConfidence']!, metrics.aiConfidence),
              _metricTile(t['aiUrgency']!, metrics.aiUrgency),
              if (aiProvider != null && aiProvider.isNotEmpty)
                _metricTile(t['aiProvider']!, aiProvider),
              if (aiImageCount != null)
                _metricTile(t['inputImages']!, aiImageCount.toString()),
              if (usageMap['totalTokenCount'] != null)
                _metricTile(
                  t['totalTokens']!,
                  usageMap['totalTokenCount'].toString(),
                ),
              if (usageMap['promptTokenCount'] != null)
                _metricTile(
                  t['promptTokens']!,
                  usageMap['promptTokenCount'].toString(),
                ),
              if (fallbackMode != null && fallbackMode.isNotEmpty)
                _metricTile(t['fallbackMode']!, fallbackMode),
              if (signalMap['cephalicIndexRisk'] != null)
                _metricTile(
                  t['cephalicRisk']!,
                  signalMap['cephalicIndexRisk'].toString(),
                ),
              if (signalMap['asymmetryRisk'] != null)
                _metricTile(
                  t['asymmetryRisk']!,
                  signalMap['asymmetryRisk'].toString(),
                ),
              if (signalMap['orbitalSymmetryRisk'] != null)
                _metricTile(
                  t['orbitalRisk']!,
                  signalMap['orbitalSymmetryRisk'].toString(),
                ),
            ],
          ),
          if (metrics.visualObservations.isNotEmpty) ...[
            const SizedBox(height: 16),
            _detailBlock(
              t['visualObservation']!,
              metrics.visualObservations,
            ),
          ],
          if (metrics.recommendation.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailBlock(
              t['recommendationTitle']!,
              metrics.recommendation,
            ),
          ],
          if (metrics.keyFindings.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              t['keyFindings']!,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            for (final finding in metrics.keyFindings)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.circle,
                        size: 8,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        finding,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (aiError != null && aiError.isNotEmpty) ...[
            const SizedBox(height: 12),
            _detailBlock(
              t['aiError']!,
              aiError,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWarningsCard(Map<String, String> t) {
    final warnings = <String>[
      if (!result.supportedView)
        'The capture did not match the supported screening view.',
      ...result.warnings,
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFFD591)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t['warnings']!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          for (final warning in warnings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 3),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Colors.orange,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      warning,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDisclaimerCard(Map<String, String> t) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Text(
        t['researchDisclaimer']!,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildInvalidScreen(Map<String, String> t) {
    return Container(
      color: AppColors.scaffoldBackground,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t['invalidTitle']!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.withOpacity(0.18),
                    ),
                    child: const Icon(
                      Icons.hide_image_outlined,
                      size: 56,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Text(
                      result.summary.isNotEmpty ? result.summary : t['invalid']!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (result.warnings.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _buildWarningsCard(t),
                  ],
                ],
              ),
            ),
            _buildPrimaryButton(
              icon: Icons.refresh,
              label: t['retake']!,
              onPressed: onRetake,
              color: AppColors.primary,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActionButtons(Map<String, String> t) {
    if (!result.supportedView || result.riskBand == RiskBand.review) {
      return [
        _buildPrimaryButton(
          icon: Icons.refresh,
          label: t['retake']!,
          onPressed: onRetake,
          color: Colors.orange.shade800,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(
          icon: Icons.home,
          label: t['finish']!,
          onPressed: onFinish,
        ),
      ];
    }

    if (result.riskBand == RiskBand.refer && mode == AppMode.posture) {
      return [
        _buildPrimaryButton(
          icon: Icons.square_foot,
          label: t['tool']!,
          onPressed: onOpenGeometricTool,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 12),
        _buildSecondaryButton(
          icon: Icons.refresh,
          label: t['retake']!,
          onPressed: onRetake,
        ),
      ];
    }

    return [
      _buildPrimaryButton(
        icon: result.riskBand == RiskBand.lowRisk ? Icons.check : Icons.home,
        label: t['finish']!,
        onPressed: onFinish,
        color: result.riskBand == RiskBand.lowRisk
            ? Colors.indigo
            : AppColors.primary,
      ),
      if (result.riskBand == RiskBand.refer) ...[
        const SizedBox(height: 12),
        _buildSecondaryButton(
          icon: Icons.refresh,
          label: t['retake']!,
          onPressed: onRetake,
        ),
      ],
    ];
  }

  Widget _metricsCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primaryLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
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
            children: children,
          ),
        ],
      ),
    );
  }

  Widget _metricTile(String label, String value) {
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

  Widget _scoreTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailBlock(String label, String value) {
    return Container(
      width: double.infinity,
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
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
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

  Widget _summaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: AppColors.primary),
      label: Text(
        label,
        style: const TextStyle(fontSize: 16, color: AppColors.primary),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.primary),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }

  Color _riskColor(RiskBand band, bool supportedView) {
    if (!supportedView) return Colors.orange;
    switch (band) {
      case RiskBand.lowRisk:
        return Colors.green;
      case RiskBand.review:
        return Colors.orange;
      case RiskBand.refer:
        return Colors.redAccent;
      case RiskBand.unavailable:
        return Colors.grey;
    }
  }

  IconData _riskIcon(RiskBand band, bool supportedView) {
    if (!supportedView) return Icons.camera_alt_outlined;
    switch (band) {
      case RiskBand.lowRisk:
        return Icons.check_circle_outline;
      case RiskBand.review:
        return Icons.warning_amber_rounded;
      case RiskBand.refer:
        return Icons.error_outline_rounded;
      case RiskBand.unavailable:
        return Icons.help_outline;
    }
  }

  String _impactDescription() {
    if (!result.supportedView) {
      return 'The capture quality was not strong enough to estimate a reliable research signal. Retake the image before relying on this output.';
    }

    if (mode == AppMode.head) {
      switch (result.riskBand) {
        case RiskBand.lowRisk:
          return 'Low head-shape research signal in this capture.';
        case RiskBand.review:
          return 'Moderate head-shape research signal. Repeat capture and review carefully.';
        case RiskBand.refer:
          return 'High-priority head research signal. This may justify further study, not a diagnosis.';
        case RiskBand.unavailable:
          return 'No head research signal is available for this capture.';
      }
    }

    switch (result.riskBand) {
      case RiskBand.lowRisk:
        return 'Low posture research signal in this capture.';
      case RiskBand.review:
        return 'Moderate posture research signal. Repeat capture and review carefully.';
      case RiskBand.refer:
        return 'High-priority posture research signal. This may justify further study, not a diagnosis.';
      case RiskBand.unavailable:
        return 'No posture research signal is available for this capture.';
    }
  }
}
