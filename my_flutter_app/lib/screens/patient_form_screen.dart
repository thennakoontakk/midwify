import 'package:flutter/material.dart';
import '../core/app_colors.dart';
import '../services/patient_service.dart';

/// Form screen for adding or editing a patient record.
/// Pass a PatientData as route argument to edit; omit for add mode.
class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({super.key});

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;
  PatientData? _existing;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  final _nicCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emergencyCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _gravidityCtrl = TextEditingController();
  final _parityCtrl = TextEditingController();
  final _gestWeeksCtrl = TextEditingController();
  final _eddCtrl = TextEditingController();
  final _lmpCtrl = TextEditingController();
  final _bpCtrl = TextEditingController();
  final _hbCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _medHistoryCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  String _bloodGroup = '';
  String _riskLevel = 'low';
  String _diabetesStatus = 'none';
  String _status = 'active';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is PatientData && _existing == null) {
      _existing = arg;
      _nameCtrl.text = arg.fullName;
      _ageCtrl.text = arg.age > 0 ? '${arg.age}' : '';
      _nicCtrl.text = arg.nic;
      _addressCtrl.text = arg.address;
      _phoneCtrl.text = arg.phone;
      _emergencyCtrl.text = arg.emergencyContact;
      _heightCtrl.text = arg.height > 0 ? '${arg.height}' : '';
      _weightCtrl.text = arg.weight > 0 ? '${arg.weight}' : '';
      _gravidityCtrl.text = arg.gravidity > 0 ? '${arg.gravidity}' : '';
      _parityCtrl.text = arg.parity > 0 ? '${arg.parity}' : '';
      _gestWeeksCtrl.text =
          arg.gestationalWeeks > 0 ? '${arg.gestationalWeeks}' : '';
      _eddCtrl.text = arg.edd;
      _lmpCtrl.text = arg.lmp;
      _bpCtrl.text = arg.bloodPressure;
      _hbCtrl.text = arg.hemoglobin > 0 ? '${arg.hemoglobin}' : '';
      _allergiesCtrl.text = arg.allergies;
      _medHistoryCtrl.text = arg.medicalHistory;
      _notesCtrl.text = arg.notes;
      _bloodGroup = arg.bloodGroup;
      _riskLevel = arg.riskLevel;
      _diabetesStatus = arg.diabetesStatus;
      _status = arg.status;
    }
  }

  @override
  void dispose() {
    for (final c in [
      _nameCtrl, _ageCtrl, _nicCtrl, _addressCtrl, _phoneCtrl, _emergencyCtrl,
      _heightCtrl, _weightCtrl, _gravidityCtrl, _parityCtrl, _gestWeeksCtrl,
      _eddCtrl, _lmpCtrl, _bpCtrl, _hbCtrl, _allergiesCtrl, _medHistoryCtrl,
      _notesCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double _calcBmi() {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    if (h > 0 && w > 0) {
      final hm = h / 100;
      return double.parse((w / (hm * hm)).toStringAsFixed(1));
    }
    return 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      final patient = PatientData(
        fullName: _nameCtrl.text.trim(),
        age: int.tryParse(_ageCtrl.text) ?? 0,
        nic: _nicCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        emergencyContact: _emergencyCtrl.text.trim(),
        bloodGroup: _bloodGroup,
        height: double.tryParse(_heightCtrl.text) ?? 0,
        weight: double.tryParse(_weightCtrl.text) ?? 0,
        bmi: _calcBmi(),
        gravidity: int.tryParse(_gravidityCtrl.text) ?? 0,
        parity: int.tryParse(_parityCtrl.text) ?? 0,
        gestationalWeeks: int.tryParse(_gestWeeksCtrl.text) ?? 0,
        edd: _eddCtrl.text.trim(),
        lmp: _lmpCtrl.text.trim(),
        riskLevel: _riskLevel,
        bloodPressure: _bpCtrl.text.trim(),
        hemoglobin: double.tryParse(_hbCtrl.text) ?? 0,
        diabetesStatus: _diabetesStatus,
        allergies: _allergiesCtrl.text.trim(),
        medicalHistory: _medHistoryCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        status: _status,
      );

      if (_existing != null && _existing!.id != null) {
        await PatientService.updatePatient(_existing!.id!, patient);
      } else {
        await PatientService.addPatient(patient);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _existing != null;
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
          isEdit ? 'Edit Patient' : 'Add Patient',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionTitle('Personal Information'),
              _card([
                _field(_nameCtrl, 'Full Name *', validator: _required),
                _row([
                  _field(_ageCtrl, 'Age *',
                      keyboard: TextInputType.number, validator: _required),
                  _dropdown(
                    'Blood Group',
                    _bloodGroup,
                    ['', 'A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-'],
                    (v) => setState(() => _bloodGroup = v ?? ''),
                  ),
                ]),
                _field(_nicCtrl, 'NIC Number'),
                _field(_phoneCtrl, 'Phone',
                    keyboard: TextInputType.phone),
                _field(_emergencyCtrl, 'Emergency Contact',
                    keyboard: TextInputType.phone),
                _field(_addressCtrl, 'Address', maxLines: 2),
              ]),

              _sectionTitle('Physical Measurements'),
              _card([
                _row([
                  _field(_heightCtrl, 'Height (cm)',
                      keyboard: TextInputType.number),
                  _field(_weightCtrl, 'Weight (kg)',
                      keyboard: TextInputType.number),
                ]),
              ]),

              _sectionTitle('Obstetric History'),
              _card([
                _row([
                  _field(_gravidityCtrl, 'Gravidity',
                      keyboard: TextInputType.number),
                  _field(_parityCtrl, 'Parity',
                      keyboard: TextInputType.number),
                ]),
              ]),

              _sectionTitle('Current Pregnancy'),
              _card([
                _row([
                  _field(_gestWeeksCtrl, 'Gestational Weeks *',
                      keyboard: TextInputType.number, validator: _required),
                  _dropdown(
                    'Risk Level',
                    _riskLevel,
                    ['low', 'medium', 'high'],
                    (v) => setState(() => _riskLevel = v ?? 'low'),
                  ),
                ]),
                _row([
                  _field(_lmpCtrl, 'LMP (dd/mm/yyyy)'),
                  _field(_eddCtrl, 'EDD (dd/mm/yyyy)'),
                ]),
                _dropdown(
                  'Status',
                  _status,
                  ['active', 'delivered', 'transferred'],
                  (v) => setState(() => _status = v ?? 'active'),
                ),
              ]),

              _sectionTitle('Health Data'),
              _card([
                _row([
                  _field(_bpCtrl, 'Blood Pressure',
                      hint: 'e.g. 120/80'),
                  _field(_hbCtrl, 'Hemoglobin (g/dL)',
                      keyboard: TextInputType.number),
                ]),
                _dropdown(
                  'Diabetes Status',
                  _diabetesStatus,
                  ['none', 'gestational', 'pre-existing'],
                  (v) => setState(() => _diabetesStatus = v ?? 'none'),
                ),
                _field(_allergiesCtrl, 'Allergies'),
                _field(_medHistoryCtrl, 'Medical History', maxLines: 3),
              ]),

              _sectionTitle('Additional Notes'),
              _card([
                _field(_notesCtrl, 'Notes', maxLines: 4),
              ]),

              const SizedBox(height: 20),

              // Save button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                        )
                      : Text(
                          isEdit ? 'Update Patient' : 'Save Patient',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Helpers ───────────────────────────────────────────

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
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
        children: children
            .expand((w) => [w, const SizedBox(height: 12)])
            .toList()
          ..removeLast(),
      ),
    );
  }

  Widget _row(List<Widget> children) {
    return Row(
      children: children
          .expand((w) => [Expanded(child: w), const SizedBox(width: 12)])
          .toList()
        ..removeLast(),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType keyboard = TextInputType.text,
    String? hint,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _dropdown(
    String label,
    String value,
    List<String> items,
    void Function(String?) onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 13,
          color: AppColors.textSecondary,
        ),
        filled: true,
        fillColor: AppColors.inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.inputBorder),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      items: items.map((v) {
        return DropdownMenuItem(
          value: v,
          child: Text(
            v.isEmpty ? '—' : v[0].toUpperCase() + v.substring(1),
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
    );
  }
}
