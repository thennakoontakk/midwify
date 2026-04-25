import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import 'ar_capture_models.dart';

class HowToScanScreen extends StatelessWidget {
  final AppMode mode;
  final AppLanguage language;
  final VoidCallback onUnderstand;

  const HowToScanScreen({
    super.key,
    required this.mode,
    required this.language,
    required this.onUnderstand,
  });

  @override
  Widget build(BuildContext context) {
    final isEnglish = language == AppLanguage.en;
    final isHead = mode == AppMode.head;

    final t = isHead
        ? {
            'badge':
                isEnglish ? 'Head Screening Guide' : 'හිස පරීක්ෂණ මාර්ගෝපදේශය',
            'title': isEnglish
                ? 'Set Up A Clear Head Capture'
                : 'පැහැදිලි හිස ග්‍රහණයක් සකස් කරන්න',
            'description': isEnglish
                ? 'Follow these steps carefully to reduce retakes and improve head-shape measurements.'
                : 'නැවත ග්‍රහණ අවම කර හිස හැඩ මිනුම් වැඩිදියුණු කිරීමට මෙම පියවර සැලකිලිමත්ව අනුගමනය කරන්න.',
            'button':
                isEnglish ? 'Start Head Screening' : 'හිස පරීක්ෂණය ආරම්භ කරන්න',
            'steps': [
              {
                'title': isEnglish ? 'Camera angle' : 'කැමරා කෝණය',
                'description': isEnglish
                    ? 'Hold the camera at a slight top-down angle, around 30-45 degrees above the baby’s head.'
                    : 'ළදරුවාගේ හිසට ඉහළින් අංශක 30-45 පමණ සුළු ඉහළ කෝණයකින් කැමරාව තබාගන්න.',
                'icon': Icons.camera_alt_rounded,
              },
              {
                'title': isEnglish
                    ? 'Keep the whole face visible'
                    : 'සම්පූර්ණ මුහුණ පෙනෙන ලෙස තබන්න',
                'description': isEnglish
                    ? 'The forehead, temples, nose, and chin should stay inside the frame without clipping.'
                    : 'නළල, දෙපස, නාසය සහ නිකට කැපී යාමකින් තොරව රාමුව තුළ පෙනිය යුතුය.',
                'icon': Icons.face_4_rounded,
              },
              {
                'title':
                    isEnglish ? 'Use even lighting' : 'සමාන ආලෝකය භාවිත කරන්න',
                'description': isEnglish
                    ? 'Avoid harsh shadows so the facial landmarks can be mapped more reliably.'
                    : 'මුහුණු ලෑන්ඩ්මාර්ක් වඩාත් විශ්වාසදායකව හඳුනාගැනීමට දැඩි සෙවනැලි වලක්වන්න.',
                'icon': Icons.wb_sunny_outlined,
              },
            ],
          }
        : {
            'badge': isEnglish
                ? 'Posture Screening Guide'
                : 'ඉරියව් පරීක්ෂණ මාර්ගෝපදේශය',
            'title': isEnglish
                ? 'Set Up A Clear Body Capture'
                : 'පැහැදිලි ශරීර ග්‍රහණයක් සකස් කරන්න',
            'description': isEnglish
                ? 'Follow these steps carefully to improve shoulder, hip, and trunk alignment review.'
                : 'උරහිස්, උකුල් සහ ශරීර මැද පෙළගැස්ම වඩාත් හොඳින් සමාලෝචනය කිරීමට මෙම පියවර සැලකිලිමත්ව අනුගමනය කරන්න.',
            'button': isEnglish
                ? 'Start Posture Screening'
                : 'ඉරියව් පරීක්ෂණය ආරම්භ කරන්න',
            'steps': [
              {
                'title': isEnglish
                    ? 'Show the full torso'
                    : 'සම්පූර්ණ කඳ පෙනෙන ලෙස තබන්න',
                'description': isEnglish
                    ? 'Keep both shoulders, both hips, and the full trunk visible in the frame.'
                    : 'උරහිස් දෙක, උකුල් දෙක සහ සම්පූර්ණ කඳ රාමුව තුළ පැහැදිලිව පෙනෙන ලෙස තබන්න.',
                'icon': Icons.accessibility_new_rounded,
              },
              {
                'title': isEnglish
                    ? 'Use a flat surface'
                    : 'සමතලා මතුපිටක් භාවිත කරන්න',
                'description': isEnglish
                    ? 'Place the baby on a flat, firm surface so the body can rest as straight as possible.'
                    : 'ශරීරය හැකි තරම් කෙළින් විවේක ගත හැකි ලෙස ළදරුවා සමතලා, ස්ථිර මතුපිටක් මත තබන්න.',
                'icon': Icons.straighten_rounded,
              },
              {
                'title':
                    isEnglish ? 'Capture from above' : 'ඉහළින් ග්‍රහණය කරන්න',
                'description': isEnglish
                    ? 'Hold the camera directly above the baby for clearer shoulder and hip alignment.'
                    : 'උරහිස් සහ උකුල් පෙළගැස්ම පැහැදිලිව දැකගැනීමට කැමරාව ළදරුවාට සෘජුවම ඉහළින් තබාගන්න.',
                'icon': Icons.photo_camera_back_rounded,
              },
            ],
          };

    final steps = (t['steps']! as List<Map<String, Object>>);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                      t['badge']! as String,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    t['title']! as String,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    t['description']! as String,
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
            const SizedBox(height: 20),
            for (var i = 0; i < steps.length; i++) ...[
              _buildGuideCard(
                stepNumber: i + 1,
                icon: steps[i]['icon']! as IconData,
                title: steps[i]['title']! as String,
                description: steps[i]['description']! as String,
              ),
              if (i != steps.length - 1) const SizedBox(height: 14),
            ],
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onUnderstand,
              icon:
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white),
              label: Text(
                t['button']! as String,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideCard({
    required int stepNumber,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.primaryLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, size: 24, color: AppColors.primary),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$stepNumber',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
