import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';
import '../services/assessment_service.dart';
import '../services/maternal_health_service.dart';

/// Patient detail screen showing personal info and recent assessment history.
class PatientDetailScreen extends StatefulWidget {
  const PatientDetailScreen({super.key});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  List<FetalHealthAssessment> _recentFetalAssessments = [];
  List<MaternalHealthAssessment> _recentMaternalAssessments = [];
  bool _isLoadingAssessments = true;
  PatientData? _patient;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_patient == null) {
      _patient = ModalRoute.of(context)!.settings.arguments as PatientData;
      _loadAssessments();
    }
  }

  Future<void> _loadAssessments() async {
    if (_patient?.id == null) return;
    setState(() => _isLoadingAssessments = true);
    try {
      // Parallel fetch
      final results = await Future.wait([
        AssessmentService.getAssessmentsForPatient(_patient!.id!),
        MaternalHealthService.getAssessmentsForPatient(_patient!.id!),
      ]);

      if (mounted) {
        setState(() {
          _recentFetalAssessments = (results[0] as List<FetalHealthAssessment>).take(3).toList();
          _recentMaternalAssessments = (results[1] as List<MaternalHealthAssessment>).take(3).toList();
          _isLoadingAssessments = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingAssessments = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_patient == null) return const Scaffold();

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
          'Patient Details',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            onPressed: () => _confirmDelete(context, _patient!),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/patient-form',
            arguments: _patient,
          );
          if (result == true && context.mounted) {
            Navigator.pop(context, true); // refresh list
          }
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.edit, color: AppColors.white),
        label: const Text('Edit', style: TextStyle(color: AppColors.white)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: _cardDecoration(),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: _riskColor(_patient!.riskLevel)
                        .withOpacity(0.15),
                    child: Text(
                      _patient!.initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _riskColor(_patient!.riskLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _patient!.fullName,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: _riskColor(_patient!.riskLevel).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_patient!.riskLevel.toUpperCase()} RISK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _riskColor(_patient!.riskLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${_patient!.status}  •  ID: ${_patient!.id?.substring(0, 8) ?? '—'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Assessment Sections
            _buildMaternalAssessmentSection(),
            const SizedBox(height: 16),
            _buildFetalAssessmentSection(),
            const SizedBox(height: 16),

            _section('Personal Information', [
              _row('Age', '${_patient!.age} years'),
              _row('NIC', _patient!.nic),
              _row('Phone', _patient!.phone),
              _row('Emergency Contact', _patient!.emergencyContact),
              _row('Blood Group', _patient!.bloodGroup),
              _row('Address', _patient!.address),
            ]),

            _section('Physical Measurements', [
              _row('Height', '${_patient!.height} cm'),
              _row('Weight', '${_patient!.weight} kg'),
              _row('BMI', '${_patient!.bmi}'),
            ]),

            _section('Obstetric History', [
              _row('Gravidity', '${_patient!.gravidity}'),
              _row('Parity', '${_patient!.parity}'),
            ]),

            _section('Current Pregnancy', [
              _row('Gestational Weeks', '${_patient!.gestationalWeeks}'),
              _row('LMP', _patient!.lmp),
              _row('EDD', _patient!.edd),
              _row('Risk Level', _patient!.riskLevel),
            ]),

            _section('Health Data', [
              _row('Blood Pressure', _patient!.bloodPressure),
              _row('Hemoglobin', '${_patient!.hemoglobin} g/dL'),
              _row('Diabetes', _patient!.diabetesStatus),
              _row('Allergies', _patient!.allergies),
              _row('Medical History', _patient!.medicalHistory),
            ]),

            if (_patient!.notes.isNotEmpty)
              _section('Notes', [
                _row('', _patient!.notes),
              ]),

            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
    );
  }

  // ─── Widgets ─────────────────────────────────────

  Widget _buildFetalAssessmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Fetal Assessments',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              if (!_isLoadingAssessments && _recentFetalAssessments.isNotEmpty)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/fetal-history',
                      arguments: _patient,
                    );
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('View All', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingAssessments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_recentFetalAssessments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No fetal assessments recorded yet.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._recentFetalAssessments.map((a) => _buildFetalTile(a)),
        ],
      ),
    );
  }

  Widget _buildMaternalAssessmentSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Maternal Health',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFE91E7B), // Maternal theme color
                ),
              ),
              if (!_isLoadingAssessments && _recentMaternalAssessments.isNotEmpty)
                TextButton(
                  onPressed: () {
                    // Navigate to maternal history or just show these 3
                    // For now, maternal doesn't have a separate history screen developed yet,
                    // but we can potentially reuse the result screen if tapped.
                  },
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('View Latest', style: TextStyle(fontSize: 12)),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_isLoadingAssessments)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: SizedBox(
                    width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            )
          else if (_recentMaternalAssessments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No maternal assessments recorded yet.',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted),
                ),
              ),
            )
          else
            ..._recentMaternalAssessments.map((a) => _buildMaternalTile(a)),
        ],
      ),
    );
  }

  Widget _buildFetalTile(FetalHealthAssessment a) {
    final date = a.createdAt?.toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'Recent';

    final color = _riskColorFromPrediction(a.prediction);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/fetal-history', arguments: _patient);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_fetalIcon(a.prediction), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              '${(a.confidence * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  Widget _buildMaternalTile(MaternalHealthAssessment a) {
    final date = a.createdAt?.toDate();
    final dateStr = date != null
        ? '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}'
        : 'Recent';

    final color = a.result.predictionScore >= 6 
      ? AppColors.danger 
      : (a.result.predictionScore >= 3 ? AppColors.warning : AppColors.success);

    return InkWell(
      onTap: () {
        Navigator.pushNamed(context, '/maternal-health-result', arguments: {
          'result': a.result,
          'patientName': a.patientName,
          'patientId': a.patientId,
          'vitals': a.vitals,
        });
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(_maternalIcon(a.result.predictionScore), size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    a.result.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    dateStr,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            Text(
              'Score: ${a.result.predictionScore}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const Icon(Icons.chevron_right, size: 18, color: AppColors.grey400),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────

  Color _riskColor(String risk) {
    switch (risk) {
      case 'high': return AppColors.danger;
      case 'medium': return AppColors.warning;
      default: return AppColors.success;
    }
  }

  Color _riskColorFromPrediction(int prediction) {
    switch (prediction) {
      case 3: return AppColors.danger;
      case 2: return AppColors.warning;
      default: return AppColors.success;
    }
  }

  IconData _fetalIcon(int prediction) {
    switch (prediction) {
      case 3: return Icons.dangerous_rounded;
      case 2: return Icons.warning_rounded;
      default: return Icons.check_circle_rounded;
    }
  }

  IconData _maternalIcon(int score) {
    if (score >= 6) return Icons.priority_high_rounded;
    if (score >= 3) return Icons.report_problem_rounded;
    return Icons.health_and_safety_rounded;
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );

  Widget _section(String title, List<Widget> rows) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            ...rows,
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    if (value.isEmpty || value == '0' || value == '0.0') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label.isNotEmpty) ...[
            SizedBox(
              width: 140,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, PatientData patient) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Patient'),
        content: Text('Are you sure you want to delete ${patient.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );

    if (confirmed == true && patient.id != null) {
      await PatientService.deletePatient(patient.id!);
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    }
  }
}
