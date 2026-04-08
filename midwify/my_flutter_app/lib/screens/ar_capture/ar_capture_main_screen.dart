import 'package:flutter/material.dart';

import 'language_selection_screen.dart';
import 'mode_selection_screen.dart';
import 'how_to_scan_screen.dart';
import 'head_capture_screen.dart';
import 'posture_capture_screen.dart';
import 'diagnosis_screen.dart';
import 'geometric_tool_screen.dart';
import 'child_details_screen.dart';
import '../../core/app_drawer.dart';
import '../../core/app_colors.dart';
import '../../services/ar_capture/ml_service.dart';
import '../../services/child_report_service.dart';
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
  ARCaptureResult? _captureResult;
  ChildDetailsData? _childDetails;

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
      _currentScreen = ScreenState.childDetails;
    });
  }

  void _onChildDetailsSubmitted(ChildDetailsData details) {
    setState(() {
      _childDetails = details;
      _currentScreen = ScreenState.guide;
    });
  }

  void _proceedToCapture() {
    setState(() {
      _currentScreen = ScreenState.capture;
    });
  }

  void _onCapture(ARCaptureResult result) {
    setState(() {
      _captureResult = result;
      _currentScreen = ScreenState.diagnosis;
    });
  }

  void _handleBack() {
    setState(() {
      switch (_currentScreen) {
        case ScreenState.modeSelection:
          _currentScreen = ScreenState.languageSelection;
          break;
        case ScreenState.guide:
          _currentScreen = ScreenState.childDetails;
          break;
        case ScreenState.childDetails:
          _currentScreen = ScreenState.modeSelection;
          break;
        case ScreenState.capture:
          _currentScreen = ScreenState.guide;
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

  void _navigateHome() async {
    if (_captureResult != null && _childDetails != null) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await ChildReportService.addReport(ChildReportData(
          childName: _childDetails!.name,
          childAge: _childDetails!.age,
          mode: _mode.name,
          result: _captureResult!,
          midwifeId: '', 
        ));
      } catch (e) {
        if (mounted) Navigator.pop(context); // close dialog
        debugPrint('Failed to save child report: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Firebase Error: $e'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      if (mounted) Navigator.pop(context); // close dialog
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/dashboard');
    }
  }

  void _openGeometricTool() {
    if (_captureResult == null) {
      return;
    }

    setState(() {
      _currentScreen = ScreenState.geometricTool;
    });
  }

  void _confirmGeometricToolReview(ARCaptureResult reviewedResult) {
    setState(() {
      _captureResult = reviewedResult;
      _currentScreen = ScreenState.diagnosis;
    });
  }

  void _retakeFromGeometricTool() {
    setState(() {
      _currentScreen = ScreenState.capture;
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
      case ScreenState.childDetails:
        return ChildDetailsScreen(
          language: _language,
          onDetailsSubmitted: _onChildDetailsSubmitted,
          onBack: _handleBack,
        );
      case ScreenState.guide:
        return HowToScanScreen(
          mode: _mode,
          language: _language,
          onUnderstand: _proceedToCapture,
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
          result: _captureResult ?? ARCaptureResult.invalid(),
          onRetake: () {
            setState(() => _currentScreen = ScreenState.capture);
          },
          onFinish: _navigateHome,
          onOpenGeometricTool: _openGeometricTool,
        );
      case ScreenState.geometricTool:
        return GeometricToolScreen(
          language: _language,
          result: _captureResult ?? ARCaptureResult.invalid(),
          onConfirm: _confirmGeometricToolReview,
          onRetake: _retakeFromGeometricTool,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {
        'title': 'AR Screening Tools',
        'language': 'Language',
        'english': 'English',
        'sinhala': 'සිංහල',
      },
      AppLanguage.si: {
        'title': 'AR පරීක්ෂණ මෙවලම්',
        'language': 'භාෂාව',
        'english': 'English',
        'sinhala': 'සිංහල',
      }
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
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: PopupMenuButton<AppLanguage>(
                tooltip: t['language'],
                onSelected: _setLanguage,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: AppLanguage.en,
                    child: Text(t['english']!),
                  ),
                  PopupMenuItem(
                    value: AppLanguage.si,
                    child: Text(t['sinhala']!),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _language == AppLanguage.en
                            ? t['english']!
                            : t['sinhala']!,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildCurrentScreen(),
        ),
      ),
    );
  }
}
