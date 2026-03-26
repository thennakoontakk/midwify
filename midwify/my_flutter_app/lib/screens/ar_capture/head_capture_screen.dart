import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../services/ar_capture/ml_service.dart';
import '../../widgets/ar_capture/camera_view.dart';
import 'ar_capture_models.dart';

class HeadCaptureScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<ARCaptureResult> onCapture;

  const HeadCaptureScreen({
    super.key,
    required this.language,
    required this.onCapture,
  });

  @override
  State<HeadCaptureScreen> createState() => _HeadCaptureScreenState();
}

class _HeadCaptureScreenState extends State<HeadCaptureScreen> {
  final GlobalKey<CameraViewState> _cameraKey = GlobalKey<CameraViewState>();
  final ImagePicker _picker = ImagePicker();
  static const List<String> _processingThoughts = [
    'Lighting from the front helps the scan read the forehead and temples.',
    'A retake from the supported angle is better than relying on a weak image.',
    'Tummy time while awake can reduce constant pressure on one side of the head.',
    'If feeding difficulty or unusual irritability is present, clinical review matters more than any app score.',
    'Clear forehead, temple, and nose visibility improves head-shape measurement quality.',
  ];

  bool _isProcessing = false;
  String? _primaryImagePath;
  Timer? _processingThoughtTimer;
  int _processingThoughtIndex = 0;

  Future<void> _processImage(
    String imagePath, {
    String? secondaryImagePath,
  }) async {
    if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image captured. Please take a photo first.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _startProcessingOverlay();

    try {
      final result = await MLService().runInference(
        imagePath,
        AppMode.head,
        secondaryImagePath: secondaryImagePath,
      );

      if (!result.isValidImage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.summary.isNotEmpty
                    ? result.summary
                    : 'No usable head image was detected. Retake with the infant in frame.',
              ),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        return;
      }

      widget.onCapture(result);
    } catch (e) {
      debugPrint('Error processing head capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      _resetPendingCaptureState();
      _stopProcessingOverlay();
    }
  }

  Future<void> _handleSelectedImage(String imagePath) async {
    if (_primaryImagePath == null) {
      setState(() => _primaryImagePath = imagePath);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Primary head capture saved. Take a second confirmation image to improve Gemini accuracy.',
          ),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final primaryImagePath = _primaryImagePath!;
    await _processImage(
      primaryImagePath,
      secondaryImagePath: imagePath,
    );
  }

  Future<void> _handleCameraCapture() async {
    final xFile = await _cameraKey.currentState?.takePicture();
    if (xFile != null) {
      await _handleSelectedImage(xFile.path);
    }
  }

  Future<void> _handleGalleryPicker() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _handleSelectedImage(image.path);
    }
  }

  void _resetPendingCaptureState() {
    if (mounted) {
      setState(() => _primaryImagePath = null);
    } else {
      _primaryImagePath = null;
    }
  }

  void _startProcessingOverlay() {
    _processingThoughtTimer?.cancel();
    final initialIndex =
        DateTime.now().millisecondsSinceEpoch % _processingThoughts.length;
    setState(() {
      _isProcessing = true;
      _processingThoughtIndex = initialIndex;
    });
    _processingThoughtTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _processingThoughtIndex =
            (_processingThoughtIndex + 1) % _processingThoughts.length;
      });
    });
  }

  void _stopProcessingOverlay() {
    _processingThoughtTimer?.cancel();
    _processingThoughtTimer = null;
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }

  @override
  void dispose() {
    _processingThoughtTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const t = {
      'title': 'Head Screening Capture',
      'instruction':
          'Capture an oblique top-down frontal view with the forehead, temples, and nose visible.',
      'instructionSecondary':
          'Primary capture saved. Take a second confirmation image from a nearby supported angle.',
      'processing': 'Running head screening...',
      'processingDetail': 'Reviewing the head image, landmarks, and geometry.',
      'stepPrimary': 'Step 1 of 2',
      'stepSecondary': 'Step 2 of 2',
      'resetPair': 'Start Over',
    };

    return Stack(
      children: [
        Positioned.fill(
          child: CameraView(
            key: _cameraKey,
            mode: AppMode.head,
            onImageCaptured: kIsWeb ? _processImage : null,
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black54,
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                Text(
                  t['title']!,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _primaryImagePath == null
                      ? t['instruction']!
                      : t['instructionSecondary']!,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    _primaryImagePath == null
                        ? t['stepPrimary']!
                        : t['stepSecondary']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (_primaryImagePath != null) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isProcessing ? null : _resetPendingCaptureState,
                    child: Text(
                      t['resetPair']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: kIsWeb
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(width: 60),
                      GestureDetector(
                        onTap: _isProcessing ? null : _handleCameraCapture,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: _isProcessing
                                ? Colors.white.withOpacity(0.65)
                                : AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: AppColors.primary,
                            size: 36,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      GestureDetector(
                        onTap: _isProcessing ? null : _handleGalleryPicker,
                        child: Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white54,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_isProcessing)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.58),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 34,
                        height: 34,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        t['processing']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t['processingDetail']!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Health Note',
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _processingThoughts[_processingThoughtIndex],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
