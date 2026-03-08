import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';
import '../services/assessment_service.dart';

/// Displays the assessment history for a specific patient.
class FetalHealthHistoryScreen extends StatefulWidget {
  const FetalHealthHistoryScreen({super.key});

  @override
  State<FetalHealthHistoryScreen> createState() =>
      _FetalHealthHistoryScreenState();
}

class _FetalHealthHistoryScreenState extends State<FetalHealthHistoryScreen> {
  List<FetalHealthAssessment> _assessments = [];
  bool _isLoading = true;
  PatientData? _patient;
  int? _expandedIndex;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      _patient = ModalRoute.of(context)?.settings.arguments as PatientData?;
      if (_patient != null) _loadHistory();
    }
  }

  Future<void> _loadHistory() async {
    if (_patient?.id == null) return;
    setState(() => _isLoading = true);
    try {
      final assessments =
          await AssessmentService.getAssessmentsForPatient(_patient!.id!);
      if (mounted) {
        setState(() {
          _assessments = assessments;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Color _riskColor(int prediction) {
    switch (prediction) {
      case 3:
        return AppColors.danger;
      case 2:
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  IconData _riskIcon(int prediction) {
    switch (prediction) {
      case 3:
        return Icons.dangerous_rounded;
      case 2:
        return Icons.warning_rounded;
      default:
        return Icons.check_circle_rounded;
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
        title: Text(
          '${_patient?.fullName ?? 'Patient'} — History',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _assessments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history_rounded,
                          size: 48, color: AppColors.grey400),
                      const SizedBox(height: 12),
                      const Text(
                        'No assessments yet.\nPerform a scan to see history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _assessments.length,
                  itemBuilder: (context, index) =>
                      _buildAssessmentCard(index),
                ),
    );
  }

  Widget _buildAssessmentCard(int index) {
    final a = _assessments[index];
    final color = _riskColor(a.prediction);
    final isExpanded = _expandedIndex == index;

    // Format date
    final date = a.createdAt?.toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 1,
      color: AppColors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          setState(() {
            _expandedIndex = isExpanded ? null : index;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(_riskIcon(a.prediction),
                        color: color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              a.label,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: color,
                              ),
                            ),
                            if (a.wasOffline) ...[
                              const SizedBox(width: 6),
                              const Icon(Icons.cloud_off_rounded,
                                  size: 14, color: AppColors.info),
                            ],
                          ],
                        ),
                        Text(
                          dateStr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Confidence badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${(a.confidence * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppColors.grey500,
                  ),
                ],
              ),

              // Expanded details
              if (isExpanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // XAI Reasons
                if (a.xaiReasons.isNotEmpty) ...[
                  const Text(
                    'Diagnostic Reasons',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...a.xaiReasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.arrow_right_rounded,
                                size: 18, color: color),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                '${reason['description']} (Value: ${reason['value']})',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 8),
                ],

                // CTG parameters summary
                const Text(
                  'CTG Parameters',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: a.ctgParameters.entries.map((e) {
                    final shortName = e.key.length > 18
                        ? '${e.key.substring(0, 16)}…'
                        : e.key;
                    return Chip(
                      materialTapTargetSize:
                          MaterialTapTargetSize.shrinkWrap,
                      label: Text(
                        '$shortName: ${e.value}',
                        style: const TextStyle(fontSize: 10),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      backgroundColor: AppColors.grey100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side:
                            const BorderSide(color: AppColors.grey200),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
