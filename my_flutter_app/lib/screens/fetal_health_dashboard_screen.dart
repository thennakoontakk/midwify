import 'dart:math';
import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/assessment_service.dart';

/// Dashboard showing aggregated fetal health assessment data.
/// Displays real stats from Firestore: total, normal, suspect, pathological
/// counts, donut chart, and recent assessments.
class FetalHealthDashboardScreen extends StatefulWidget {
  const FetalHealthDashboardScreen({super.key});

  @override
  State<FetalHealthDashboardScreen> createState() =>
      _FetalHealthDashboardScreenState();
}

class _FetalHealthDashboardScreenState
    extends State<FetalHealthDashboardScreen> {
  bool _isLoading = true;
  Map<String, int> _stats = {};
  List<FetalHealthAssessment> _recentAssessments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final stats = await AssessmentService.getAggregatedStats();
      final assessments = await AssessmentService.getAllAssessments();
      if (mounted) {
        setState(() {
          _stats = stats;
          _recentAssessments = assessments.take(10).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Fetal Health Dashboard',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.primary),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Summary stat cards
                  _buildStatCard(
                    Icons.assignment_rounded,
                    AppColors.info,
                    AppColors.infoLight,
                    'Total Assessments',
                    '${_stats['total'] ?? 0}',
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMiniStat(
                          Icons.check_circle_rounded,
                          AppColors.success,
                          'Normal',
                          '${_stats['normal'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStat(
                          Icons.warning_rounded,
                          AppColors.warning,
                          'Suspect',
                          '${_stats['suspect'] ?? 0}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildMiniStat(
                          Icons.dangerous_rounded,
                          AppColors.danger,
                          'Pathological',
                          '${_stats['pathological'] ?? 0}',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Donut chart
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Risk Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        if ((_stats['total'] ?? 0) > 0)
                          Center(
                            child: SizedBox(
                              width: 180,
                              height: 180,
                              child: CustomPaint(
                                painter: _RealDonutPainter(
                                  normal: _stats['normal'] ?? 0,
                                  suspect: _stats['suspect'] ?? 0,
                                  pathological:
                                      _stats['pathological'] ?? 0,
                                ),
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: Text(
                                'No data yet',
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _legendItem(AppColors.success,
                                'Normal (${_stats['normal'] ?? 0})'),
                            const SizedBox(width: 12),
                            _legendItem(AppColors.warning,
                                'Suspect (${_stats['suspect'] ?? 0})'),
                            const SizedBox(width: 12),
                            _legendItem(AppColors.danger,
                                'Pathological (${_stats['pathological'] ?? 0})'),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Recent assessments
                  const Text(
                    'Recent Assessments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_recentAssessments.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Center(
                        child: Text(
                          'No assessments recorded yet.',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  else
                    ..._recentAssessments
                        .map((a) => _buildRecentTile(a)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(IconData icon, Color color, Color bgColor,
      String title, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(
      IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
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
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTile(FetalHealthAssessment a) {
    Color color;
    switch (a.prediction) {
      case 3:
        color = AppColors.danger;
        break;
      case 2:
        color = AppColors.warning;
        break;
      default:
        color = AppColors.success;
    }

    final date = a.createdAt?.toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}'
        : '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              a.prediction == 1
                  ? Icons.check_circle_rounded
                  : a.prediction == 2
                      ? Icons.warning_rounded
                      : Icons.dangerous_rounded,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  a.patientName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  dateStr,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              a.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Donut chart using real Normal/Suspect/Pathological counts.
class _RealDonutPainter extends CustomPainter {
  final int normal;
  final int suspect;
  final int pathological;

  _RealDonutPainter({
    required this.normal,
    required this.suspect,
    required this.pathological,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 30.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final total = normal + suspect + pathological;
    if (total == 0) return;

    final segments = <_Segment>[
      _Segment(normal / total, AppColors.success),
      _Segment(suspect / total, AppColors.warning),
      _Segment(pathological / total, AppColors.danger),
    ];

    double startAngle = -pi / 2;
    for (final seg in segments) {
      if (seg.fraction <= 0) continue;
      final sweepAngle = 2 * pi * seg.fraction;
      final paint = Paint()
        ..color = seg.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;
      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _RealDonutPainter old) =>
      old.normal != normal ||
      old.suspect != suspect ||
      old.pathological != pathological;
}

class _Segment {
  final double fraction;
  final Color color;
  _Segment(this.fraction, this.color);
}
