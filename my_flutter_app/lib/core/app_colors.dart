import 'package:flutter/material.dart';

/// Centralized color palette for the Midwify app.
/// All colors used throughout the app should be referenced from here.
class AppColors {
  AppColors._(); // Prevent instantiation

  // Primary brand colors
  static const Color primary = Color(0xFFE91E7B);
  static const Color primaryDark = Color(0xFFC2185B);
  static const Color primaryLight = Color(0xFFFCE4EC);

  // Shield icon background
  static const Color shieldBackground = Color(0xFFFDE8F0);
  static const Color shieldIcon = Color(0xFFE91E7B);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF1A1A1A);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);

  // Text colors
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF616161);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color textMuted = Color(0xFF9E9E9E);

  // Input field
  static const Color inputBorder = Color(0xFFE0E0E0);
  static const Color inputBackground = Color(0xFFFFFFFF);

  // Splash screen
  static const Color splashBackground = Color(0xFFE91E7B);

  // Gradient for the button
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFFE91E7B), Color(0xFFFF4081)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Dashboard colors
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
}
