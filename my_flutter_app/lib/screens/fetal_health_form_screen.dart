import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';
import '../services/fetal_health_service.dart';

/// CTG parameter input form for fetal health assessment.
/// Accepts 21 parameters organized in logical sections.
class FetalHealthFormScreen extends StatefulWidget {
  const FetalHealthFormScreen({super.key});

  @override
  State<FetalHealthFormScreen> createState() => _FetalHealthFormScreenState();
}

class _FetalHealthFormScreenState extends State<FetalHealthFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isAnalyzing = false;
  PatientData? _patient;

  @override
  void initState() {
    super.initState();
    // Create a controller for each feature
    for (final name in FetalHealthService.featureNames) {
      _controllers[name] = TextEditingController();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _patient ??= ModalRoute.of(context)?.settings.arguments as PatientData?;
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _analyze() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAnalyzing = true);

    try {
      // Build feature vector in the correct order
      final features = FetalHealthService.featureNames
          .map((name) => double.parse(_controllers[name]!.text.trim()))
          .toList();

      // Run prediction
      final result = await FetalHealthService.predict(features);

      if (mounted) {
        setState(() => _isAnalyzing = false);
        Navigator.pushNamed(
          context,
          '/fetal-health-result',
          arguments: {
            'patient': _patient,
            'features': Map<String, double>.fromIterables(
              FetalHealthService.featureNames,
              features,
            ),
            'result': result,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Prediction failed: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _clearAll() {
    for (final c in _controllers.values) {
      c.clear();
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
          'CTG Parameters',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _clearAll,
            child: const Text(
              'Clear',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Patient info header
            if (_patient != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.15),
                      child: Text(
                        _patient!.initials,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
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
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.monitor_heart_rounded,
                        color: AppColors.primary, size: 22),
                  ],
                ),
              ),

            // Form fields
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry
                      in FetalHealthService.formSections.entries) ...[
                    _buildSectionHeader(entry.key),
                    const SizedBox(height: 8),
                    ...entry.value.map((featureName) =>
                        _buildInputField(featureName)),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 80), // Space for button
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isAnalyzing ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.grey400,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 2,
              ),
              child: _isAnalyzing
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics_rounded, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Analyze Fetal Health',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    IconData icon;
    switch (title) {
      case 'Heart Rate & Movements':
        icon = Icons.favorite_rounded;
        break;
      case 'Decelerations':
        icon = Icons.trending_down_rounded;
        break;
      case 'Variability':
        icon = Icons.show_chart_rounded;
        break;
      case 'Histogram Analysis':
        icon = Icons.bar_chart_rounded;
        break;
      default:
        icon = Icons.science_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(String featureName) {
    final label =
        FetalHealthService.featureLabels[featureName] ?? featureName;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: _controllers[featureName],
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
          filled: true,
          fillColor: AppColors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.inputBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Required';
          }
          if (double.tryParse(value.trim()) == null) {
            return 'Enter a valid number';
          }
          return null;
        },
      ),
    );
  }
}
