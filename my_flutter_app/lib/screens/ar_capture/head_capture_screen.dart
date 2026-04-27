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
  bool _isProcessing = false;

  Future<void> _processImage(String imagePath) async {
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

    setState(() => _isProcessing = true);

    try {
      final result = await MLService().runInference(imagePath, AppMode.head);

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
      if (mounted) setState(() => _isProcessing = false);
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

  @override
  Widget build(BuildContext context) {
    const t = {
      'title': 'Head Screening Capture',
      'instruction':
          'Capture an oblique top-down frontal view with the forehead, temples, and nose visible.',
      'processing': 'Running head screening...',
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
                  t['instruction']!,
                  style: const TextStyle(fontSize: 14, color: Colors.white70),
                  textAlign: TextAlign.center,
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
            child: _isProcessing
                ? Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t['processing']!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                : kIsWeb
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(width: 60),
                          GestureDetector(
                            onTap: _handleCameraCapture,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.white,
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
                            onTap: _handleGalleryPicker,
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
      ],
    );
  }
}
