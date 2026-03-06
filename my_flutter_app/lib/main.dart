import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patients_screen.dart';
import 'screens/patient_form_screen.dart';
import 'screens/patient_detail_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
        '/dashboard': (context) => const DashboardScreen(),
        '/patients': (context) => const PatientsScreen(),
        '/patient-form': (context) => const PatientFormScreen(),
        '/patient-detail': (context) => const PatientDetailScreen(),
      },
    );
  }
}

