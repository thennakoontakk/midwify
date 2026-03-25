import 'package:flutter/material.dart';
import 'ar_capture_models.dart'; // AppLanguage
import '../../core/app_colors.dart';

class GeometricToolScreen extends StatelessWidget {
  final AppLanguage language;
  final VoidCallback onConfirm;

  const GeometricToolScreen({
    super.key,
    required this.language,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {
        'title': "Posture Metric Verification",
        'instruction': "Adjust the vertices to align with the baby's shoulders and hips.",
        'angle1': "Shoulder Tilt: 15°",
        'angle2': "Hip Alignment: 8°",
        'confirm': "Confirm Verification"
      },
      AppLanguage.si: {
        'title': "ඉරියව් මිනුම් තහවුරු කිරීම",
        'instruction': "ළදරුවාගේ උරහිස් සහ උකුල සමඟ පෙළගැස්වීමට ශීර්ෂ සීරුමාරු කරන්න.",
        'angle1': "උරහිස් ඇලවීම: 15°",
        'angle2': "උකුල පෙළගැස්ම: 8°",
        'confirm': "තහවුරු කරන්න"
      }
    }[language]!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Text(t['title']!, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(t['instruction']!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
          
          const SizedBox(height: 16),
          
          // Tool Area Mockup
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.primary, width: 2),
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  // Placeholder representing baby capture background
                  image: NetworkImage("https://images.unsplash.com/photo-1519689680058-324335c77eba?auto=format&fit=crop&w=400&q=80"),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              ),
              child: Stack(
                children: [
                  // Mockup Geometry lines
                  Center(
                    child: Transform.rotate(
                      angle: 0.261799, // 15 degrees in rad
                      child: Container(width: double.infinity, height: 2, color: Colors.greenAccent),
                    ),
                  ),
                  Center(
                    child: Transform.rotate(
                      angle: -0.139626, // -8 degrees in rad
                      child: Container(width: double.infinity, height: 2, color: AppColors.primary),
                    ),
                  ),
                  
                  // Live Metrics Overlay
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.primaryLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(t['angle1']!, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                              Text(t['angle2']!, style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "Deviation exceeds normal threshold (>10°). Referral Recommended.",
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          )
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onConfirm,
              icon: const Icon(Icons.check_box, color: Colors.white),
              label: Text(t['confirm']!, style: const TextStyle(fontSize: 16, color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
