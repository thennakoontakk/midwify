/// Centralized string constants for the Midwify app.
/// Keeps all user-facing text in one place for easy maintenance.
class AppStrings {
  AppStrings._(); // Prevent instantiation

  // App-wide
  static const String appName = 'Midwify';
  static const String appVersion = 'v1.6.0 (Offline Auth)';

  // Splash screen
  static const String splashTagline = 'Maternal Risk Dashboard';

  // Login screen
  static const String loginTitle = 'Midwify Login';
  static const String loginSubtitle =
      'Enter your Service Registration Number to\naccess the maternal risk dashboard.';
  static const String registrationNumberLabel = 'Registration Number';
  static const String registrationNumberHint = 'e.g. MW-8055';
  static const String passwordLabel = 'Password';
  static const String passwordHint = '••••••••';
  static const String accessDashboard = 'Access Dashboard';
  static const String restrictedAccess = 'Restricted Access System';
  static const String registrationInfo =
      'New account registration is handled by the\nhospital administrator.';
  static const String contactIT =
      'Please contact IT support if you need\ncredentials.';
}
