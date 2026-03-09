import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'dart:convert';

import '../../screens/ar_capture/ar_capture_models.dart'; // To access AppMode

class CameraView extends StatefulWidget {
  final AppMode mode;
  final Function(String)? onImageCaptured; // For web platform callback

  const CameraView({super.key, required this.mode, this.onImageCaptured});

  @override
  State<CameraView> createState() => CameraViewState();
}

class CameraViewState extends State<CameraView> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeControllerFuture = _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      _controller = CameraController(cameras[0], ResolutionPreset.high);
      await _controller!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  Future<void> _captureImageWeb() async {
    if (_isProcessing || widget.onImageCaptured == null) return;
    
    setState(() => _isProcessing = true);
    
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        // Convert to data URL for web processing
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64';
        
        widget.onImageCaptured!(dataUrl);
      }
    } catch (e) {
      debugPrint('Error capturing web image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera not available. Using gallery instead.'),
          backgroundColor: Colors.orange,
        ),
      );
      
      // Fallback to gallery
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final base64 = base64Encode(bytes);
        final dataUrl = 'data:image/jpeg;base64,$base64';
        
        widget.onImageCaptured!(dataUrl);
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<XFile?> takePicture() async {
    if (kIsWeb) {
      await _captureImageWeb();
      return null;
    }

    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      return null;
    }

    try {
      await _initializeControllerFuture;
      return await _controller!.takePicture();
    } catch (e) {
      debugPrint('Error taking picture: $e');
      return null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Web platform implementation
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.grey.shade900,
              Colors.grey.shade800,
            ],
          ),
        ),
        child: Stack(
          children: [
            // Placeholder for camera view
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 80,
                    color: Colors.white.withOpacity(0.6),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Web Camera Preview',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Click the button below to capture photo',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Guidelines overlay
            Positioned.fill(
              child: CustomPaint(
                painter: GuidelinePainter(mode: widget.mode),
                child: Container(),
              ),
            ),
            
            // Capture button
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _isProcessing ? null : _captureImageWeb,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isProcessing ? Colors.grey : Colors.white,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: _isProcessing
                        ? const Center(
                            child: SizedBox(
                              width: 30,
                              height: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                              ),
                            ),
                          )
                        : Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey.shade800,
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Native platform implementation
    return FutureBuilder<void>(
      future: _initializeControllerFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && _controller != null) {
          return Stack(
            children: [
              SizedBox.expand(
                child: CameraPreview(_controller!),
              ),
              // The AR Alignment Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: GuidelinePainter(mode: widget.mode),
                  child: Container(),
                ),
              ),
            ],
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }
}

class GuidelinePainter extends CustomPainter {
  final AppMode mode;

  GuidelinePainter({required this.mode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (mode == AppMode.head) {
      // Drawing the "Safe Zone" oval for head alignment
      canvas.drawOval(
          Rect.fromCenter(center: Offset(size.width/2, size.height/2), width: 250, height: 350),
          paint
      );
    } else if (mode == AppMode.posture) {
      // Drawing a vertical line for posture alignment
      canvas.drawLine(
        Offset(size.width / 2, size.height * 0.1),
        Offset(size.width / 2, size.height * 0.9),
        paint,
      );
    }
  }
  @override
  bool shouldRepaint(covariant GuidelinePainter oldDelegate) {
    return oldDelegate.mode != mode;
  }
}
