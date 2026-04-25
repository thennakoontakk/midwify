import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/app_colors.dart';
import 'ar_capture_models.dart'; // To access AppMode, AppLanguage
import '../../widgets/ar_capture/camera_view.dart'; // The existing camera view
import '../../services/ar_capture/ml_service.dart'; // TFLite ML Service

class PostureCaptureScreen extends StatefulWidget {
  final AppLanguage language;
  final ValueChanged<int> onCapture;

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
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _processImage(String imagePath) async {
    debugPrint('=== POSTURE CAPTURE: Processing image ===');
    debugPrint('Image path: "$imagePath"');
    
    // CRITICAL: Validate image path before processing
    if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
      debugPrint('ERROR: Empty or invalid image path received');
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
      // Pass image to MLService
      int confidence = await MLService().runInference(imagePath, AppMode.posture);
      debugPrint('MLService returned confidence: $confidence');
      
      // Continue with normal flow
      debugPrint('=== POSTURE CAPTURE: Success - proceeding to diagnosis ===');
      widget.onCapture(confidence);
      
    } catch (e) {
      debugPrint('Error processing image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _handleCameraCapture() async {
    final xFile = await _cameraKey.currentState?.takePicture();
    if (xFile != null) {
      await _processImage(xFile.path);
    }
  }

  void _handleGalleryPicker() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      await _processImage(image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = {
      AppLanguage.en: {
        'title': "Posture Analysis Capture",
        'instruction': "Align the vertical guide with the baby's posture and keep steady.",
        'processing': "Analyzing AI Model...",
      },
      AppLanguage.si: {
        'title': "ඉරියව් විශ්ලේෂණ ඡායාරූපය",
        'instruction': "සිරස් මාර්ගෝපදේශය ළදරුවාගේ ඉරියව්ව සමඟ පෙළගස්වා ස්ථාවරව තබා ගන්න.",
        'processing': "AI ආකෘතිය විශ්ලේෂණය කරමින්...",
      }
    }[widget.language]!;

    return Stack(
      children: [
        // Camera View Background
        Positioned.fill(
          child: CameraView(
            key: _cameraKey,
            mode: AppMode.posture,
            onImageCaptured: kIsWeb ? _processImage : null,
          ),
        ),
        
        // App Bar Overlay
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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

        // Shutter Button Box
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: _isProcessing
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          t['processing']!,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  )
                : kIsWeb
                    ? const SizedBox.shrink() // Hide controls on web, camera has its own
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Invisible spacer to keep shutter centered
                          const SizedBox(width: 60), 
                          
                          // Shutter button
                          GestureDetector(
                            onTap: _handleCameraCapture,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.primary, width: 6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 36),
                            ),
                          ),
                          
                          const SizedBox(width: 20),
                          
                          // Gallery button
                          GestureDetector(
                            onTap: _handleGalleryPicker,
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white54, width: 2),
                              ),
                              child: const Icon(Icons.photo_library, color: Colors.white, size: 24),
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
