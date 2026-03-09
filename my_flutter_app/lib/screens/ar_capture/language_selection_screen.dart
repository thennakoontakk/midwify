import 'package:flutter/material.dart';
import 'ar_capture_models.dart'; // To access AppLanguage

class LanguageSelectionScreen extends StatelessWidget {
  final ValueChanged<AppLanguage> onLanguageSelected;

  const LanguageSelectionScreen({
    super.key,
    required this.onLanguageSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.language,
            size: 80,
            color: Color(0xFF6366f1),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome / ආයුබෝවන්',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          const Text(
            'Select your language\nඔබගේ භාෂාව තෝරන්න',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildLanguageButton(
            title: 'English',
            subtitle: 'Proceed in English',
            onTap: () => onLanguageSelected(AppLanguage.en),
          ),
          const SizedBox(height: 16),
          _buildLanguageButton(
            title: 'සිංහල',
            subtitle: 'සිංහලෙන් ඉදිරියට යන්න',
            onTap: () => onLanguageSelected(AppLanguage.si),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton({
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 250,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b).withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF818cf8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
