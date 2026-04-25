import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import 'ar_capture_models.dart';

class ChildDetailsData {
  final String name;
  final String age;
  ChildDetailsData({required this.name, required this.age});
}

class ChildDetailsScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<ChildDetailsData> onDetailsSubmitted;
  final VoidCallback onBack;

  const ChildDetailsScreen({
    super.key,
    required this.language,
    required this.onDetailsSubmitted,
    required this.onBack,
  });

  @override
  State<ChildDetailsScreen> createState() => _ChildDetailsScreenState();
}

class _ChildDetailsScreenState extends State<ChildDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      widget.onDetailsSubmitted(ChildDetailsData(
        name: _nameController.text.trim(),
        age: _ageController.text.trim(),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {
        'title': 'Child Details',
        'desc': 'Please enter the baby\'s details before screening.',
        'name': 'Baby Name',
        'nameHint': 'e.g. Baby John',
        'age': 'Age (in weeks/months)',
        'ageHint': 'e.g. 12 weeks',
        'continue': 'Continue to Scan',
        'required': 'This field is required'
      },
      AppLanguage.si: {
        'title': 'ළමා විස්තර',
        'desc': 'කරුණාකර පරීක්ෂාවට පෙර දරුවාගේ විස්තර ඇතුළත් කරන්න.',
        'name': 'දරුවාගේ නම',
        'nameHint': 'උදා: බබා ජෝන්',
        'age': 'වයස (සති/මාස වලින්)',
        'ageHint': 'උදා: සති 12',
        'continue': 'ස්කෑන් කිරීමට ඉදිරියට යන්න',
        'required': 'මෙම තොරතුර අනිවාර්යයි'
      },
    }[widget.language]!;

    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.primaryLight),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t['title']!,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t['desc']!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: t['name'],
                      hintText: t['nameHint'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.child_care, color: AppColors.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return t['required'];
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _ageController,
                    decoration: InputDecoration(
                      labelText: t['age'],
                      hintText: t['ageHint'],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      prefixIcon: const Icon(Icons.cake, color: AppColors.primary),
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) return t['required'];
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      t['continue']!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
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
}
