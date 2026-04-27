import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';
import '../services/fetal_health_service.dart';

/// Human Verification Screen — displays auto-filled CTG parameters
/// extracted from the uploaded image, allowing the user to verify/edit
/// simple fields while keeping complex fields locked.
class CtgVerificationScreen extends StatefulWidget {
  const CtgVerificationScreen({super.key});

  @override
  State<CtgVerificationScreen> createState() => _CtgVerificationScreenState();
}

class _CtgVerificationScreenState extends State<CtgVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  bool _isAnalyzing = false;
  PatientData? _patient;
  Map<String, dynamic>? _extractedData;
  Map<String, Map<String, dynamic>>? _parameters;
  double? _baselineHr;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_parameters == null) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        _patient = args['patient'] as PatientData?;
        _extractedData = args['extractedData'] as Map<String, dynamic>?;
        _baselineHr = (_extractedData?['baseline_hr'] as num?)?.toDouble();

        // Parse parameters from API response
        final rawParams =
            _extractedData?['parameters'] as Map<String, dynamic>? ?? {};
        _parameters = {};
        for (final entry in rawParams.entries) {
          final paramData = entry.value as Map<String, dynamic>;
          _parameters![entry.key] = {
            'value': (paramData['value'] as num).toDouble(),
            'editable': paramData['editable'] as bool? ?? false,
            'source': paramData['source'] as String? ?? 'default',
          };
        }

        // Initialize controllers
        for (final name in FetalHealthService.featureNames) {
          final paramInfo = _parameters![name];
          final value = paramInfo?['value'] ?? 0.0;
          _controllers[name] = TextEditingController(
            text: _formatValue(name, value as double),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatValue(String featureName, double value) {
    // Determine decimal places based on feature
    if (featureName.contains('accelerations') ||
        featureName.contains('movement') ||
        featureName.contains('contractions') ||
        featureName.contains('decelerations')) {
      return value.toStringAsFixed(3);
    }
    if (featureName.contains('variability') &&
        featureName.contains('mean')) {
      return value.toStringAsFixed(1);
    }
    return value.toStringAsFixed(1);
  }

  bool _isEditable(String featureName) {
    return _parameters?[featureName]?['editable'] == true;
  }

  String _getSource(String featureName) {
    return _parameters?[featureName]?['source'] as String? ?? 'default';
  }

  Future<void> _analyzeRisk() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isAnalyzing = true);
    try {
      final features = FetalHealthService.featureNames
          .map((name) => double.parse(_controllers[name]!.text.trim()))
          .toList();

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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Prediction failed: $e'),
          backgroundColor: AppColors.danger,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_parameters == null) {
      return const Scaffold(
        body: Center(child: Text('No data available')),
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
          'Verify Extracted Data',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            // Extraction summary header
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.success.withOpacity(0.1),
                    AppColors.success.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded,
                        color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CTG Extraction Complete',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.success)),
                        const SizedBox(height: 2),
                        Text(
                          'Baseline HR: ${_baselineHr?.toStringAsFixed(1) ?? '—'} bpm  •  '
                          '${_extractedData?['extraction_method'] == 'opencv_pipeline' ? 'OpenCV Pipeline' : 'Default Values'}  •  '
                          '${_extractedData?['features_extracted'] ?? 0} features extracted',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Patient info
            if (_patient != null)
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(_patient!.initials,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_patient!.fullName,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                      Text(
                          'Week ${_patient!.gestationalWeeks}  •  Age ${_patient!.age}',
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary)),
                    ],
                  )),
                ]),
              ),

            // Legend
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  _buildLegendChip(
                      Icons.auto_fix_high_rounded, 'Extracted', AppColors.success),
                  const SizedBox(width: 8),
                  _buildLegendChip(
                      Icons.calculate_rounded, 'Calculated', AppColors.info),
                  const SizedBox(width: 8),
                  _buildLegendChip(
                      Icons.lock_rounded, 'Default', AppColors.grey500),
                ],
              ),
            ),

            // Parameter list
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  for (final entry
                      in FetalHealthService.formSections.entries) ...[
                    _buildSectionHeader(entry.key),
                    const SizedBox(height: 8),
                    ...entry.value.map((name) => _buildParameterField(name)),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 80),
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
              onPressed: _isAnalyzing ? null : _analyzeRisk,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.white,
                disabledBackgroundColor: AppColors.grey400,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
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
                      ))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.verified_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Verify & Analyze Risk',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLegendChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        ],
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
      child: Row(children: [
        Icon(icon, color: AppColors.primary, size: 18),
        const SizedBox(width: 8),
        Text(title,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ]),
    );
  }

  Widget _buildParameterField(String featureName) {
    final label =
        FetalHealthService.featureLabels[featureName] ?? featureName;
    final editable = _isEditable(featureName);
    final source = _getSource(featureName);
    final isExtracted = source == 'extracted';
    final isCalculated = source == 'calculated';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: editable ? AppColors.white : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isExtracted
                ? AppColors.success.withOpacity(0.4)
                : isCalculated
                    ? AppColors.info.withOpacity(0.4)
                    : editable
                        ? AppColors.inputBorder
                        : AppColors.grey200,
          ),
          boxShadow: editable
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            // Label
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: editable
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  // Source badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isExtracted
                          ? AppColors.success.withOpacity(0.1)
                          : isCalculated
                              ? AppColors.info.withOpacity(0.1)
                              : AppColors.grey200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isExtracted
                          ? '✦ Extracted'
                          : isCalculated
                              ? '⊕ Calculated'
                              : 'Default',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isExtracted
                            ? AppColors.success
                            : isCalculated
                                ? AppColors.info
                                : AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Value field
            SizedBox(
              width: 100,
              child: TextFormField(
                controller: _controllers[featureName],
                enabled: editable,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true, signed: true),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: editable
                      ? isExtracted
                          ? AppColors.success
                          : isCalculated
                              ? AppColors.info
                              : AppColors.primary
                      : AppColors.textSecondary,
                ),
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  filled: true,
                  fillColor: editable
                      ? isExtracted
                          ? AppColors.success.withOpacity(0.07)
                          : isCalculated
                              ? AppColors.info.withOpacity(0.07)
                              : AppColors.primary.withOpacity(0.07)
                      : AppColors.grey200,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: isExtracted
                          ? AppColors.success
                          : isCalculated
                              ? AppColors.info
                              : AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(height: 0, fontSize: 0),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Required';
                  if (double.tryParse(val.trim()) == null) return 'Invalid';
                  return null;
                },
              ),
            ),

            // Lock/edit icon
            const SizedBox(width: 8),
            Icon(
              editable
                  ? isExtracted
                      ? Icons.auto_fix_high_rounded
                      : isCalculated
                          ? Icons.calculate_rounded
                          : Icons.edit_rounded
                  : Icons.lock_rounded,
              size: 16,
              color: editable
                  ? isExtracted
                      ? AppColors.success
                      : isCalculated
                          ? AppColors.info
                          : AppColors.primary
                  : AppColors.grey400,
            ),
          ],
        ),
      ),
    );
  }
}
