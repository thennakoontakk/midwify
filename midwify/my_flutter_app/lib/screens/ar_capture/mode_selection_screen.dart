import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../core/app_strings.dart';
import 'ar_capture_models.dart';

class ModeSelectionScreen extends StatelessWidget {
  final AppLanguage language;
  final ValueChanged<AppMode> onModeSelected;

  const ModeSelectionScreen({
    super.key,
    required this.language,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {
        'badge': 'AR Screening Flow',
        'title': 'Select Screening Module',
        'description':
            'Choose the module you want to run. Head screening uses a paired capture. Posture screening uses a single full-body capture.',
        'offline': 'Local processing ready',
        'headTitle': 'Head Screening',
        'headDesc':
            'Capture a paired head view to review cranial shape and symmetry signals.',
        'postureTitle': 'Posture Screening',
        'postureDesc':
            'Capture one centered body view to review shoulder, hip, and trunk alignment.',
        'continue': 'Continue',
        'pairedBadge': '2-step',
        'singleBadge': '1-step',
      },
      AppLanguage.si: {
        'badge': 'AR පරීක්ෂණ ප්‍රවාහය',
        'title': 'පරීක්ෂණ මොඩියුලය තෝරන්න',
        'description':
            'ඔබට ධාවනය කිරීමට අවශ්‍ය මොඩියුලය තෝරන්න. හිස පරීක්ෂණයට යුගල ග්‍රහණයක් අවශ්‍යයි. ඉරියව් පරීක්ෂණයට එක් සම්පූර්ණ ශරීර ග්‍රහණයක් පමණක් අවශ්‍යයි.',
        'offline': 'දේශීය සැකසුම සූදානම්',
        'headTitle': 'හිස පරීක්ෂණය',
        'headDesc':
            'කපාල හැඩය සහ සමමිතික සංඥා සමාලෝචනයට යුගල හිස ග්‍රහණයක් ගන්න.',
        'postureTitle': 'ඉරියව් පරීක්ෂණය',
        'postureDesc':
            'උරහිස්, උකුල් සහ ශරීර මැද පෙළගැස්ම සමාලෝචනයට මධ්‍යගත සිරුර දසුනක් ගන්න.',
        'continue': 'ඉදිරියට යන්න',
        'pairedBadge': 'පියවර 2',
        'singleBadge': 'පියවර 1',
      },
    }[language]!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 760;
        final cardWidth = isWide
            ? (constraints.maxWidth - 64 - 18) / 2
            : constraints.maxWidth - 48;

        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t['badge']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        t['title']!,
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        t['description']!,
                        style: const TextStyle(
                          fontSize: 15,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildModeCard(
                        icon: Icons.face_4_rounded,
                        title: t['headTitle']!,
                        description: t['headDesc']!,
                        badge: t['pairedBadge']!,
                        actionLabel: t['continue']!,
                        onTap: () => onModeSelected(AppMode.head),
                      ),
                    ),
                    SizedBox(
                      width: cardWidth,
                      child: _buildModeCard(
                        icon: Icons.accessibility_new_rounded,
                        title: t['postureTitle']!,
                        description: t['postureDesc']!,
                        badge: t['singleBadge']!,
                        actionLabel: t['continue']!,
                        onTap: () => onModeSelected(AppMode.posture),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.grey100,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          t['offline']!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                      const Text(
                        '${AppStrings.appName} ${AppStrings.appVersion}',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String description,
    required String badge,
    required String actionLabel,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Ink(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.primaryLight),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, size: 30, color: AppColors.primary),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Text(
                  actionLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
