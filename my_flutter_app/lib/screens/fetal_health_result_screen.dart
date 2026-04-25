import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';
import '../services/fetal_health_service.dart';
import '../services/assessment_service.dart';

/// Displays the fetal health prediction result with:
/// - Color-coded risk card (Normal/Suspect/Pathological)
/// - Confidence score as circular progress
/// - XAI diagnostic reasons
/// - Save report and view history buttons
class FetalHealthResultScreen extends StatefulWidget {
  const FetalHealthResultScreen({super.key});

  @override
  State<FetalHealthResultScreen> createState() =>
      _FetalHealthResultScreenState();
}

class _FetalHealthResultScreenState extends State<FetalHealthResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _confidenceAnim;
  bool _isSaving = false;
  bool _isSaved = false;

  PatientData? _patient;
  FetalHealthResult? _result;
  Map<String, double>? _features;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_result == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _patient = args['patient'] as PatientData?;
        _result = args['result'] as FetalHealthResult?;
        _features = args['features'] as Map<String, double>?;
        _animController.forward();
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color get _riskColor {
    switch (_result?.prediction) {
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.warning;
      case 3:
        return AppColors.danger;
      default:
        return AppColors.grey400;
    }
  }

  Color get _riskBgColor {
    switch (_result?.prediction) {
      case 1:
        return AppColors.successLight;
      case 2:
        return AppColors.warningLight;
      case 3:
        return AppColors.dangerLight;
      default:
        return AppColors.grey100;
    }
  }

  IconData get _riskIcon {
    switch (_result?.prediction) {
      case 1:
        return Icons.check_circle_rounded;
      case 2:
        return Icons.warning_rounded;
      case 3:
        return Icons.dangerous_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Future<void> _saveReport() async {
    if (_patient == null || _result == null || _features == null) return;

    setState(() => _isSaving = true);
    try {
      final assessment = FetalHealthAssessment(
        patientId: _patient!.id ?? '',
        patientName: _patient!.fullName,
        midwifeId: '',
        ctgParameters: _features!,
        prediction: _result!.prediction,
        label: _result!.label,
        confidence: _result!.confidence,
        xaiReasons: _result!.xaiReasons,
        wasOffline: _result!.isOffline,
      );

      await AssessmentService.saveAssessment(assessment);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _isSaved = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report saved successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_result == null) {
      return const Scaffold(
        body: Center(child: Text('No result data')),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Assessment Result',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Main Result Card ──
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _riskBgColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _riskColor.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  // Offline badge
                  if (_result!.isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded,
                              size: 14, color: AppColors.info),
                          SizedBox(width: 6),
                          Text(
                            'Offline Prediction',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),

                  Icon(_riskIcon, color: _riskColor, size: 56),
                  const SizedBox(height: 12),
                  Text(
                    _result!.label,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: _riskColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Fetal Health Risk Level',
                    style: TextStyle(
                      fontSize: 13,
                      color: _riskColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Confidence ring
                  AnimatedBuilder(
                    animation: _confidenceAnim,
                    builder: (context, child) {
                      return SizedBox(
                        width: 100,
                        height: 100,
                        child: CustomPaint(
                          painter: _ConfidenceRingPainter(
                            progress: _confidenceAnim.value *
                                _result!.confidence,
                            color: _riskColor,
                          ),
                          child: Center(
                            child: Text(
                              '${(_confidenceAnim.value * _result!.confidence * 100).toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: _riskColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Confidence Score',
                    style: TextStyle(
                      fontSize: 12,
                      color: _riskColor.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Patient info
            if (_patient != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: _riskColor.withOpacity(0.12),
                      child: Text(
                        _patient!.initials,
                        style: TextStyle(
                          color: _riskColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _patient!.fullName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Week ${_patient!.gestationalWeeks}  •  Age ${_patient!.age}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── XAI Reasons ──
            if (_result!.xaiReasons.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.psychology_rounded,
                            color: AppColors.primary, size: 20),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Diagnostic Reasons (AI Explainability)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ..._result!.xaiReasons.map((reason) {
                      final importance =
                          ((reason['importance'] as num?)?.toDouble() ?? 0) *
                              100;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _riskBgColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: _riskColor.withOpacity(0.15)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.warning_amber_rounded,
                                color: _riskColor, size: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    reason['description'] ?? '',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _riskColor,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Value: ${reason['value']}  •  Impact: ${importance.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      if (_patient != null) {
                        Navigator.pushNamed(
                          context,
                          '/fetal-health-history',
                          arguments: _patient,
                        );
                      }
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side:
                          const BorderSide(color: AppColors.inputBorder),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isSaving || _isSaved) ? null : _saveReport,
                    icon: Icon(
                      _isSaved
                          ? Icons.check_rounded
                          : Icons.save_rounded,
                      size: 18,
                    ),
                    label: Text(_isSaved ? 'Saved' : 'Save Report'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isSaved
                          ? AppColors.success
                          : AppColors.primary,
                      foregroundColor: AppColors.white,
                      disabledBackgroundColor:
                          _isSaved ? AppColors.success : AppColors.grey400,
                      disabledForegroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// Paints a circular confidence ring.
class _ConfidenceRingPainter extends CustomPainter {
  final double progress;
  final Color color;

  _ConfidenceRingPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 6;

    // Background ring
    final bgPaint = Paint()
      ..color = color.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfidenceRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
