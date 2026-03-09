import 'package:flutter/material.dart';
import 'ar_capture_models.dart'; // AppMode, AppLanguage

class DiagnosisScreen extends StatelessWidget {
  final AppMode mode;
  final AppLanguage language;
  final int confidence;
  final VoidCallback onRetake;
  final VoidCallback onFinish;
  final VoidCallback onOpenGeometricTool;

  const DiagnosisScreen({
    super.key,
    required this.mode,
    required this.language,
    required this.confidence,
    required this.onRetake,
    required this.onFinish,
    required this.onOpenGeometricTool,
  });

  @override
  Widget build(BuildContext context) {
    // Determine traffic light state
    String state;
    if (confidence < 40) {
      state = 'normal';
    } else if (confidence <= 80) {
      state = 'inconclusive';
    } else {
      state = 'abnormal';
    }

    final t = {
      AppLanguage.en: {
        'title': "Analysis Results",
        'modelKey': mode == AppMode.head ? 'Head Analysis AI Model' : 'Posture Analysis AI Model',
        'confidenceLabel': "CONFIDENCE",
        'normalText': "Safe Diagnosis. No significant issues detected.",
        'inconclusiveText': "Grey Zone. Results inconclusive.",
        'abnormalText': "High confidence issue detected. Verification required.",
        'btnSaveFinish': "Save & Finish",
        'btnRetake': "Retake Photo",
        'btnHome': "Back to Home",
        'btnTool': "Open Geometric Tool"
      },
      AppLanguage.si: {
        'title': "විශ්ලේෂණ ප්‍රතිඵල", 
        'modelKey': mode == AppMode.head ? 'හිස විශ්ලේෂණ AI ආකෘතිය' : 'ඉරියව් විශ්ලේෂණ AI ආකෘතිය',
        'confidenceLabel': "විශ්වාසය",
        'normalText': "ආරක්ෂිත විනිශ්චය. සැලකිය යුතු ගැටළු කිසිවක් අනාවරණය වී නොමැත.",
        'inconclusiveText': "අළු කලාපය. ප්‍රතිඵල අවිනිශ්චිතයි.",
        'abnormalText': "ඉහළ විශ්වාසනීය ගැටළුවක් අනාවරණය විය. තහවුරු කිරීම අවශ්‍ය වේ.",
        'btnSaveFinish': "සුරකින්න සහ අවසන් කරන්න",
        'btnRetake': "නැවත ඡායාරූපයක් ගන්න",
        'btnHome': "මුල් පිටුවට",
        'btnTool': "ජ්‍යාමිතික මෙවලම විවෘත කරන්න"
      }
    }[language]!;

    // Map state to visuals
    late Color stateColor;
    late IconData stateIcon;
    late String stateText;

    if (state == 'normal') {
      stateColor = Colors.greenAccent;
      stateIcon = Icons.check_circle_outline;
      stateText = t['normalText']!;
    } else if (state == 'inconclusive') {
      stateColor = Colors.amber;
      stateIcon = Icons.warning_amber_rounded;
      stateText = t['inconclusiveText']!;
    } else {
      stateColor = Colors.redAccent;
      stateIcon = Icons.error_outline_rounded;
      stateText = t['abnormalText']!;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(t['title']!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text(t['modelKey']!, style: const TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
          
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Score Circle
                Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [stateColor.withOpacity(0.8), stateColor.withOpacity(0.3)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: stateColor.withOpacity(0.5),
                        blurRadius: 40,
                        spreadRadius: 10,
                      )
                    ]
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text("$confidence%", style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                      Text(t['confidenceLabel']!, style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 48),

                // Status Text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      Icon(stateIcon, color: stateColor, size: 40),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          stateText,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          ..._buildActionButtons(state, t),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(String state, Map<String, String> t) {
    if (state == 'normal') {
      return [
        _buildPrimaryButton(icon: Icons.check, label: t['btnSaveFinish']!, onPressed: onFinish, color: Colors.indigo),
      ];
    } else if (state == 'inconclusive') {
      return [
        _buildPrimaryButton(icon: Icons.refresh, label: "${t['btnRetake']!} (Forced)", onPressed: onRetake, color: Colors.orange.shade800),
      ];
    } else {
      // state == 'abnormal'
      if (mode == AppMode.posture) {
        return [
          _buildPrimaryButton(icon: Icons.square_foot, label: t['btnTool']!, onPressed: onOpenGeometricTool, color: Colors.blueAccent),
          const SizedBox(height: 12),
          _buildSecondaryButton(icon: Icons.refresh, label: t['btnRetake']!, onPressed: onRetake),
        ];
      } else {
        return [
          _buildPrimaryButton(icon: Icons.refresh, label: t['btnRetake']!, onPressed: onRetake, color: Colors.indigo),
          const SizedBox(height: 12),
          _buildSecondaryButton(icon: Icons.home, label: t['btnHome']!, onPressed: onFinish),
        ];
      }
    }
  }

  Widget _buildPrimaryButton({required IconData icon, required String label, required VoidCallback onPressed, required Color color}) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 5,
        shadowColor: color.withOpacity(0.5),
      ),
    );
  }

  Widget _buildSecondaryButton({required IconData icon, required String label, required VoidCallback onPressed}) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white),
      label: Text(label, style: const TextStyle(fontSize: 16, color: Colors.white)),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: Colors.white30),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }
}
