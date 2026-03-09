import 'package:flutter/material.dart';
import 'ar_capture_models.dart'; // To access AppMode, AppLanguage

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
        'selectMode': "Select Analysis Mode",
        'headAnalysis': "Head Analysis",
        'postureAnalysis': "Posture Analysis",
        'headDesc': "Detect cranial asymmetry",
        'postureDesc': "Detect postural issues",
        'desc': "Choose the type of diagnostic you want to perform."
      },
      AppLanguage.si: {
        'selectMode': "විනිශ්චය ප්‍රකාරය තෝරන්න",
        'headAnalysis': "හිස විශ්ලේෂණය",
        'postureAnalysis': "ඉරියව් විශ්ලේෂණය",
        'headDesc': "කපාල අසමමිතිය හඳුනාගන්න",
        'postureDesc': "ඉරියව් ගැටළු හඳුනාගන්න",
        'desc': "ඔබට සිදු කිරීමට අවශ්‍ය රෝග විනිශ්චය වර්ගය තෝරන්න."
      }
    }[language]!;

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            t['selectMode']!,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            t['desc']!,
            style: const TextStyle(fontSize: 16, color: Colors.white70),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  icon: Icons.child_care,
                  title: t['headAnalysis']!,
                  desc: t['headDesc']!,
                  onTap: () => onModeSelected(AppMode.head),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildModeCard(
                  icon: Icons.accessibility_new,
                  title: t['postureAnalysis']!,
                  desc: t['postureDesc']!,
                  onTap: () => onModeSelected(AppMode.posture),
                ),
              ),
            ],
          ),
          const Spacer(),
          const Text(
            "Version 1.0.0 (Offline Mode Active)",
            style: TextStyle(color: Colors.white38, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required IconData icon,
    required String title,
    required String desc,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b).withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 60, color: const Color(0xFF818cf8)),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF818cf8)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: const TextStyle(fontSize: 12, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
