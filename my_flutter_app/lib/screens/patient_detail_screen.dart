import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';

/// Read-only patient detail screen with card-based layout.
/// Receives a PatientData via route arguments.
class PatientDetailScreen extends StatelessWidget {
  const PatientDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final patient = ModalRoute.of(context)!.settings.arguments as PatientData;

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
            onPressed: () => _confirmDelete(context, patient),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.pushNamed(
            context,
            '/patient-form',
            arguments: patient,
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
                    backgroundColor: _riskColor(patient.riskLevel)
                        .withOpacity(0.15),
                    child: Text(
                      patient.initials,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: _riskColor(patient.riskLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    patient.fullName,
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
                      color: _riskColor(patient.riskLevel).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${patient.riskLevel.toUpperCase()} RISK',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _riskColor(patient.riskLevel),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Status: ${patient.status}  •  ID: ${patient.id?.substring(0, 8) ?? '—'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            _section('Personal Information', [
              _row('Age', '${patient.age} years'),
              _row('NIC', patient.nic),
              _row('Phone', patient.phone),
              _row('Emergency Contact', patient.emergencyContact),
              _row('Blood Group', patient.bloodGroup),
              _row('Address', patient.address),
            ]),

            _section('Physical Measurements', [
              _row('Height', '${patient.height} cm'),
              _row('Weight', '${patient.weight} kg'),
              _row('BMI', '${patient.bmi}'),
            ]),

            _section('Obstetric History', [
              _row('Gravidity', '${patient.gravidity}'),
              _row('Parity', '${patient.parity}'),
            ]),

            _section('Current Pregnancy', [
              _row('Gestational Weeks', '${patient.gestationalWeeks}'),
              _row('LMP', patient.lmp),
              _row('EDD', patient.edd),
              _row('Risk Level', patient.riskLevel),
            ]),

            _section('Health Data', [
              _row('Blood Pressure', patient.bloodPressure),
              _row('Hemoglobin', '${patient.hemoglobin} g/dL'),
              _row('Diabetes', patient.diabetesStatus),
              _row('Allergies', patient.allergies),
              _row('Medical History', patient.medicalHistory),
            ]),

            if (patient.notes.isNotEmpty)
              _section('Notes', [
                _row('', patient.notes),
              ]),

            const SizedBox(height: 80), // space for FAB
          ],
        ),
      ),
    );
  }

  // ─── Helpers ─────────────────────────────────────

  Color _riskColor(String risk) {
    switch (risk) {
      case 'high':
        return AppColors.danger;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
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

  Future<void> _confirmDelete(
      BuildContext context, PatientData patient) async {
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
            child: const Text('Delete',
                style: TextStyle(color: AppColors.danger)),
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
