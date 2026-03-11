import 'package:flutter/material.dart';

import 'language_selection_screen.dart';
import 'mode_selection_screen.dart';
import 'head_capture_screen.dart';
import 'posture_capture_screen.dart';
import 'diagnosis_screen.dart';
import 'geometric_tool_screen.dart';
import '../../services/ar_capture/ml_service.dart';
import '../../core/app_colors.dart';
import '../../core/app_drawer.dart';
import 'ar_capture_models.dart';

class ARCaptureMainScreen extends StatefulWidget {
  const ARCaptureMainScreen({super.key});

  @override
  State<ARCaptureMainScreen> createState() => _ARCaptureMainScreenState();
}

class _ARCaptureMainScreenState extends State<ARCaptureMainScreen> {
  ScreenState _currentScreen = ScreenState.languageSelection;
  AppMode _mode = AppMode.none;
  AppLanguage _language = AppLanguage.en;
  int? _confidence;

  @override
  void initState() {
    super.initState();
    // Ensure models are loaded when this screen is opened
    MLService().initializeModels();
  }

  void _setLanguage(AppLanguage lang) => setState(() => _language = lang);

  void _setLanguageAndNavigate(AppLanguage lang) {
    setState(() {
      _language = lang;
      _currentScreen = ScreenState.modeSelection;
    });
  }

  void _setModeAndNavigate(AppMode mode) {
    setState(() {
      _mode = mode;
      _currentScreen = ScreenState.capture;
    });
  }

  void _onCapture(int confidence) {
    setState(() {
      _confidence = confidence;
      _currentScreen = ScreenState.diagnosis;
    });
  }

  void _handleBack() {
    setState(() {
      switch (_currentScreen) {
        case ScreenState.modeSelection:
          _currentScreen = ScreenState.languageSelection;
          break;
        case ScreenState.capture:
          _currentScreen = ScreenState.modeSelection;
          break;
        case ScreenState.diagnosis:
          _currentScreen = ScreenState.capture;
          break;
        case ScreenState.geometricTool:
          _currentScreen = ScreenState.diagnosis;
          break;
        default: 
          Navigator.of(context).pop(); // Exit to dashboard
          break;
      }
    });
  }

  void _navigateHome() {
    setState(() {
      _mode = AppMode.none;
      _confidence = null;
      _currentScreen = ScreenState.modeSelection;
    });
  }

  void _openGeometricTool() {
    setState(() {
      _currentScreen = ScreenState.geometricTool;
    });
  }

  Widget _buildCurrentScreen() {
    switch (_currentScreen) {
      case ScreenState.languageSelection:
        return LanguageSelectionScreen(
          onLanguageSelected: _setLanguageAndNavigate,
        );
      case ScreenState.modeSelection:
        return ModeSelectionScreen(
          language: _language,
          onModeSelected: _setModeAndNavigate,
        );
      case ScreenState.capture:
        if (_mode == AppMode.head) {
          return HeadCaptureScreen(
            language: _language,
            onCapture: _onCapture,
          );
        } else {
          return PostureCaptureScreen(
            language: _language,
            onCapture: _onCapture,
          );
        }
      case ScreenState.diagnosis:
        return DiagnosisScreen(
          mode: _mode,
          language: _language,
          confidence: _confidence ?? 0,
          onRetake: () {
            setState(() => _currentScreen = ScreenState.capture);
          },
          onFinish: _navigateHome,
          onOpenGeometricTool: _openGeometricTool,
        );
      case ScreenState.geometricTool:
        return GeometricToolScreen(
          language: _language,
          onConfirm: _handleBack,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {'title': 'AR Capture Tools', 'offline': 'Offline Mode'},
      AppLanguage.si: {'title': 'AR රූප ග්‍රහණය', 'offline': 'නොබැඳි ප්‍රකාරය'}
    }[_language]!;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      drawer: const AppDrawer(currentRoute: '/ar-capture'),
      appBar: AppBar(
        title: Text(
          t['title']!,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: Builder(
          builder: (context) {
            if (_currentScreen == ScreenState.languageSelection) {
              return IconButton(
                icon: const Icon(Icons.menu, color: AppColors.textPrimary),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            }
            return IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: _handleBack,
            );
          },
        ),
        actions: [
          if (_currentScreen != ScreenState.languageSelection)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Row(
                children: [
                   Text(
                    _language == AppLanguage.en ? 'EN  |' : 'සිං  |',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      _setLanguage(_language == AppLanguage.en
                          ? AppLanguage.si : AppLanguage.en);
                    },
                    child: Text(
                      _language == AppLanguage.en ? 'සිං' : 'EN',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _buildCurrentScreen(),
      ),
    );
  }
}
