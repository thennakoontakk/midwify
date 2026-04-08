import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/app_colors.dart';
import '../../services/ar_capture/ml_service.dart';
import '../../widgets/ar_capture/camera_view.dart';
import 'ar_capture_localization.dart';
import 'ar_capture_models.dart';

class PostureCaptureScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<ARCaptureResult> onCapture;

  const PostureCaptureScreen({
    super.key,
    required this.language,
    required this.onCapture,
  });

  @override
  State<PostureCaptureScreen> createState() => _PostureCaptureScreenState();
}

class _PostureCaptureScreenState extends State<PostureCaptureScreen> {
  final GlobalKey<CameraViewState> _cameraKey = GlobalKey<CameraViewState>();
  final ImagePicker _picker = ImagePicker();
  static const Duration _minimumLoadingDuration = Duration(seconds: 3);
  bool _isProcessing = false;
  Timer? _processingThoughtTimer;
  int _processingThoughtIndex = 0;

  List<String> get _processingThoughts =>
      ARCaptureLocalization.postureProcessingThoughts(widget.language);

  Future<void> _processImage(String imagePath) async {
    final t = ARCaptureLocalization.postureCapture(widget.language);
    if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(t['noImage']!),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _startProcessingOverlay();

    try {
      final inferenceFuture = MLService().runInference(
        imagePath,
        AppMode.posture,
        language: widget.language,
      );
      final completed = await Future.wait<dynamic>([
        inferenceFuture,
        Future<void>.delayed(_minimumLoadingDuration),
      ]);
      final result = completed.first as ARCaptureResult;

      if (!result.isValidImage) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                result.summary.isNotEmpty
                    ? ARCaptureLocalization.localizeResultText(
                        widget.language,
                        result.summary,
                      )
                    : t['invalidFallback']!,
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
      debugPrint('Error processing posture capture: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${t['errorPrefix']} $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _stopProcessingOverlay();
    }
  }

  Future<void> _handleCameraCapture() async {
    final xFile = await _cameraKey.currentState?.takePicture();
    if (xFile != null) {
      await _processImage(xFile.path);
    }
  }

  Future<void> _handleGalleryPicker() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processImage(image.path);
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
      if (!mounted) {
        return;
      }
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
    final t = ARCaptureLocalization.postureCapture(widget.language);

    return Stack(
      children: [
        Positioned.fill(
          child: CameraView(
            key: _cameraKey,
            mode: AppMode.posture,
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
                  t['instruction']!,
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
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    t['singleStep']!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
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
                                ? Colors.white.withValues(alpha: 0.65)
                                : AppColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary,
                              width: 6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
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
              color: Colors.black.withValues(alpha: 0.58),
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
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          children: [
                            Text(
                              t['healthNote']!,
                              style: const TextStyle(
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
