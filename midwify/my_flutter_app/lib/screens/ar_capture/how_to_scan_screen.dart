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
    final bool isEn = language == AppLanguage.en;
    final bool isHead = mode == AppMode.head;

    final String title = isHead
        ? (isEn
            ? "How to Scan: Head Analysis"
            : "ස්කෑන් කරන්නේ කෙසේද: හිස විශ්ලේෂණය")
        : (isEn
            ? "How to Scan: Posture Analysis"
            : "ස්කෑන් කරන්නේ කෙසේද: ඉරියව් විශ්ලේෂණය");

    final String desc = isHead
        ? (isEn
            ? "For accurate cranial metrics, please follow these guidelines carefully."
            : "නිවැරදි කපාල මිනුම් සඳහා කරුණාකර මෙම මාර්ගෝපදේශ ප්‍රවේශමෙන් අනුගමනය කරන්න.")
        : (isEn
            ? "For accurate posture analysis, please follow these guidelines carefully."
            : "නිවැරදි ඉරියව් විශ්ලේෂණය සඳහා කරුණාකර මෙම මාර්ගෝපදේශ ප්‍රවේශමෙන් අනුගමනය කරන්න.");

    final String btnText = isEn ? "I Understand ->" : "මට තේරෙනවා ->";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Expanded(
            child: isHead ? _buildHeadGuide(isEn) : _buildPostureGuide(isEn),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: onUnderstand,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: Text(
              btnText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadGuide(bool isEn) {
    return ListView(
      children: [
        _buildGuideItem(
          icon: Icons.camera_front,
          title: isEn ? "1. Camera Angle" : "1. කැමරා කෝණය",
          description: isEn
              ? "Hold the camera at a slight top-down angle (30-45 degrees above the baby's head). The forehead must be clearly visible."
              : "ළදරුවාගේ හිසට ඉහළින් අංශක 30-45 ක කෝණයකින් කැමරාව තබාගන්න. නළල පැහැදිලිව පෙනිය යුතුය.",
        ),
        _buildGuideItem(
          icon: Icons.face,
          title: isEn ? "2. Full Face in Frame" : "2. සම්පූර්ණ මුහුණ රාමුව තුළ",
          description: isEn
              ? "Ensure the baby's entire face (from chin to top of forehead) is inside the camera frame."
              : "ළදරුවාගේ සම්පූර්ණ මුහුණ (නිකට සිට නළල මුදුන දක්වා) කැමරා රාමුව තුළ ඇති බවට වග බලා ගන්න.",
        ),
        _buildGuideItem(
          icon: Icons.wb_sunny_outlined,
          title: isEn ? "3. Good Lighting" : "3. හොඳ ආලෝකකරණයක්",
          description: isEn
              ? "Ensure the room is well-lit so facial landmarks can be accurately mapped."
              : "මුහුණේ ලක්ෂණ නිවැරදිව සිතියම් ගත කිරීම සඳහා කාමරය හොඳින් ආලෝකමත් කර ඇති බවට වග බලා ගන්න.",
        ),
      ],
    );
  }

  Widget _buildPostureGuide(bool isEn) {
    return ListView(
      children: [
        _buildGuideItem(
          icon: Icons.accessibility_new,
          title: isEn ? "1. Full Body Visible" : "1. සම්පූර්ණ සිරුර පෙනෙන සේ",
          description: isEn
              ? "Ensure the baby's entire body (shoulders to hips) is visible in the frame."
              : "ළදරුවාගේ සම්පූර්ණ සිරුර (උරහිස් සිට උකුල දක්වා) රාමුව තුළ පෙනෙන බවට වග බලා ගන්න.",
        ),
        _buildGuideItem(
          icon: Icons.straighten,
          title: isEn ? "2. Flat Surface" : "2. සමතලා මතුපිටක්",
          description: isEn
              ? "Place the baby on a flat, firm surface. Ensure they are lying as straight as possible."
              : "ළදරුවා සමතලා, ස්ථිර මතුපිටක් මත තබන්න. හැකි තරම් කෙළින් වැතිර සිටින බවට වග බලා ගන්න.",
        ),
        _buildGuideItem(
          icon: Icons.camera_alt,
          title: isEn ? "3. Direct Overhead Angle" : "3. සෘජුව ඉහළින් ඇති කෝණය",
          description: isEn
              ? "Hold the camera directly above the baby (90-degree angle) for accurate shoulder and hip measurements."
              : "නිවැරදි උරහිස් සහ උකුල් මිනුම් සඳහා කැමරාව ළදරුවාට සෘජුවම ඉහළින් (අංශක 90 කෝණයකින්) තබාගන්න.",
        ),
      ],
    );
  }

  Widget _buildGuideItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.4,
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
