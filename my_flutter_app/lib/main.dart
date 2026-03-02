import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MidwifyApp());
}

/// Root widget for the Midwify application.
/// Configures theming and routing for the entire app.
class MidwifyApp extends StatelessWidget {
  const MidwifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Midwify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Start with the splash screen
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}
