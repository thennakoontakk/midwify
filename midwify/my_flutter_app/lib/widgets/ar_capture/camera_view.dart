import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:io' show Platform;
import 'package:google_mlkit_face_mesh_detection/google_mlkit_face_mesh_detection.dart';

import '../../services/ar_capture/ml_service.dart';
import '../../services/ar_capture/posture_screening.dart';
import '../../screens/ar_capture/ar_capture_models.dart'; // To access AppMode

const int _noseIdx = 0;
const int _leftEyeIdx = 1;
const int _rightEyeIdx = 2;
const int _leftShoulderIdx = 5;
const int _rightShoulderIdx = 6;
const int _leftHipIdx = 11;
const int _rightHipIdx = 12;

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

  // ML Kit Face Mesh Detector for real-time overlay
  final FaceMeshDetector _faceMeshDetector =
      FaceMeshDetector(option: FaceMeshDetectorOptions.faceMesh);
  List<FaceMesh> _faces = [];
  bool _isDetecting = false;
  List<PoseKeypoint> _postureKeypoints = [];

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

      _controller = CameraController(
        cameras[0],
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.yuv420
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();
      if (mounted) setState(() {});

      if (widget.mode == AppMode.posture) {
        await MLService().ensurePostureModelReady();
      }

      // Start streaming for real-time overlay in supported modes.
      if (widget.mode == AppMode.head || widget.mode == AppMode.posture) {
        _controller!.startImageStream(_processCameraImage);
      }
    } catch (e) {
      debugPrint('Error initializing camera: $e');
    }
  }

  void _processCameraImage(CameraImage image) async {
    if (_isDetecting || !mounted) return;
    _isDetecting = true;

    try {
      if (widget.mode == AppMode.head) {
        await _processHeadCameraImage(image);
      } else if (widget.mode == AppMode.posture) {
        await _processPostureCameraImage(image);
      }
    } catch (e) {
      debugPrint('Error processing camera stream: $e');
    } finally {
      _isDetecting = false;
    }
  }

  Future<void> _processHeadCameraImage(CameraImage image) async {
    final inputImage = _inputImageFromCameraImage(image);
    if (inputImage == null) {
      return;
    }

    final faces = await _faceMeshDetector.processImage(inputImage);
    if (!mounted) return;

    setState(() {
      _faces = faces;
    });
  }

  Future<void> _processPostureCameraImage(CameraImage image) async {
    final rgbFrame = _cameraImageToRgbImage(image);
    if (rgbFrame == null) {
      return;
    }

    final keypoints = await MLService().runPostureKeypointInference(rgbFrame);
    if (keypoints == null || !mounted) {
      return;
    }

    setState(() {
      _postureKeypoints = keypoints
          .map(
            (kp) => PoseKeypoint(
              y: kp[0],
              x: kp[1],
              confidence: kp[2],
            ),
          )
          .toList();
    });
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    if (Platform.isIOS) {
      final bytes = image.planes.first.bytes;
      return InputImage.fromBytes(
        bytes: bytes,
        metadata: InputImageMetadata(
          size: Size(image.width.toDouble(), image.height.toDouble()),
          rotation: InputImageRotationValue.fromRawValue(
                _controller!.description.sensorOrientation,
              ) ??
              InputImageRotation.rotation0deg,
          format: InputImageFormat.bgra8888,
          bytesPerRow: image.planes.first.bytesPerRow,
        ),
      );
    }

    final nv21Bytes = _cameraImageToNv21(image);
    if (nv21Bytes == null) {
      debugPrint(
        'CameraView: unsupported Android camera image format '
        '(planes=${image.planes.length}, format=${image.format.group})',
      );
      return null;
    }

    return InputImage.fromBytes(
      bytes: nv21Bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotationValue.fromRawValue(
              _controller!.description.sensorOrientation,
            ) ??
            InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  Uint8List? _cameraImageToNv21(CameraImage image) {
    if (image.planes.length == 1) {
      return image.planes.first.bytes;
    }

    if (image.planes.length != 3) {
      return null;
    }

    final int width = image.width;
    final int height = image.height;
    final int ySize = width * height;
    final int uvSize = width * height ~/ 2;
    final nv21 = Uint8List(ySize + uvSize);

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    var offset = 0;
    for (var row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      nv21.setRange(offset, offset + width, yPlane.bytes, rowStart);
      offset += width;
    }

    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;
    final vRowStride = vPlane.bytesPerRow;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;
    final chromaHeight = height ~/ 2;
    final chromaWidth = width ~/ 2;

    for (var row = 0; row < chromaHeight; row++) {
      final uRowStart = row * uvRowStride;
      final vRowStart = row * vRowStride;
      for (var col = 0; col < chromaWidth; col++) {
        final uIndex = uRowStart + col * uvPixelStride;
        final vIndex = vRowStart + col * vPixelStride;
        nv21[offset++] = vPlane.bytes[math.min(vIndex, vPlane.bytes.length - 1)];
        nv21[offset++] = uPlane.bytes[math.min(uIndex, uPlane.bytes.length - 1)];
      }
    }

    return nv21;
  }

  img.Image? _cameraImageToRgbImage(CameraImage image) {
    img.Image? converted;
    if (Platform.isIOS) {
      converted = _bgra8888ToImage(image);
    } else if (image.planes.length == 1) {
      converted = _nv21ToImage(image);
    } else if (image.planes.length == 3) {
      converted = _yuv420ToImage(image);
    } else {
      debugPrint(
        'CameraView: unsupported posture image format '
        '(planes=${image.planes.length}, format=${image.format.group})',
      );
      return null;
    }

    final orientation = _controller?.description.sensorOrientation ?? 0;
    if (orientation == 90) {
      return img.copyRotate(converted, angle: 90);
    }
    if (orientation == 270) {
      return img.copyRotate(converted, angle: -90);
    }
    if (orientation == 180) {
      return img.copyRotate(converted, angle: 180);
    }
    return converted;
  }

  img.Image _bgra8888ToImage(CameraImage image) {
    final plane = image.planes.first;
    final bytes = plane.bytes;
    final out = img.Image(width: image.width, height: image.height);

    for (var y = 0; y < image.height; y++) {
      for (var x = 0; x < image.width; x++) {
        final offset = y * plane.bytesPerRow + x * 4;
        final b = bytes[offset];
        final g = bytes[offset + 1];
        final r = bytes[offset + 2];
        out.setPixelRgb(x, y, r, g, b);
      }
    }

    return out;
  }

  img.Image _nv21ToImage(CameraImage image) {
    final bytes = image.planes.first.bytes;
    final width = image.width;
    final height = image.height;
    final out = img.Image(width: width, height: height);
    final frameSize = width * height;

    for (var y = 0; y < height; y++) {
      final uvRow = (y >> 1) * width;
      for (var x = 0; x < width; x++) {
        final yValue = bytes[y * width + x];
        final uvIndex = frameSize + uvRow + (x & ~1);
        final v = bytes[uvIndex];
        final u = bytes[uvIndex + 1];
        final rgb = _yuvToRgb(yValue, u, v);
        out.setPixelRgb(x, y, rgb.$1, rgb.$2, rgb.$3);
      }
    }

    return out;
  }

  img.Image _yuv420ToImage(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final out = img.Image(width: width, height: height);
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    final uPixelStride = uPlane.bytesPerPixel ?? 1;
    final vPixelStride = vPlane.bytesPerPixel ?? 1;

    for (var y = 0; y < height; y++) {
      final yRow = y * yPlane.bytesPerRow;
      final uvRow = (y >> 1) * uPlane.bytesPerRow;
      final vvRow = (y >> 1) * vPlane.bytesPerRow;
      for (var x = 0; x < width; x++) {
        final yValue = yPlane.bytes[yRow + x];
        final uvCol = (x >> 1);
        final u = uPlane.bytes[uvRow + uvCol * uPixelStride];
        final v = vPlane.bytes[vvRow + uvCol * vPixelStride];
        final rgb = _yuvToRgb(yValue, u, v);
        out.setPixelRgb(x, y, rgb.$1, rgb.$2, rgb.$3);
      }
    }

    return out;
  }

  (int, int, int) _yuvToRgb(int y, int u, int v) {
    final yy = y.toDouble();
    final uu = u.toDouble() - 128.0;
    final vv = v.toDouble() - 128.0;
    final r = (yy + 1.402 * vv).round().clamp(0, 255);
    final g = (yy - 0.344136 * uu - 0.714136 * vv).round().clamp(0, 255);
    final b = (yy + 1.772 * uu).round().clamp(0, 255);
    return (r, g, b);
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
      if (!mounted) return;
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
    if (_controller?.value.isStreamingImages == true) {
      _controller?.stopImageStream();
    }
    _controller?.dispose();
    _faceMeshDetector.close();
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
                painter: GuidelinePainter(
                  mode: widget.mode,
                  faces: _faces,
                  cameraSize: _controller?.value.previewSize,
                  postureKeypoints: _postureKeypoints,
                ),
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
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
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
        if (snapshot.connectionState == ConnectionState.done &&
            _controller != null) {
          return Stack(
            children: [
              SizedBox.expand(
                child: CameraPreview(_controller!),
              ),
              // The AR Alignment Overlay
              Positioned.fill(
                child: CustomPaint(
                  painter: GuidelinePainter(
                    mode: widget.mode,
                    faces: _faces,
                    cameraSize: _controller?.value.previewSize,
                    postureKeypoints: _postureKeypoints,
                  ),
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
  final List<FaceMesh> faces;
  final Size? cameraSize;
  final List<PoseKeypoint> postureKeypoints;

  GuidelinePainter({
    required this.mode,
    this.faces = const [],
    this.cameraSize,
    this.postureKeypoints = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    if (mode == AppMode.head) {
      // Drawing the "Safe Zone" oval for head alignment
      canvas.drawOval(
          Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2),
              width: 250,
              height: 350),
          paint);

      if (faces.isEmpty) {
        // Draw simulated mesh lines to guide the user visually if no face detected yet
        _drawHeadMeshOverlay(canvas, size, paint);
      } else {
        // Draw real face landmarks detected by ML Kit
        _drawRealFaceLandmarks(canvas, size, faces.first);
      }
    } else if (mode == AppMode.posture) {
      // Drawing a vertical line for posture alignment
      canvas.drawLine(
        Offset(size.width / 2, size.height * 0.1),
        Offset(size.width / 2, size.height * 0.9),
        paint,
      );

      if (_hasUsablePostureOverlay) {
        _drawLivePostureOverlay(canvas, size);
      } else {
        _drawPostureSkeletonOverlay(canvas, size, paint);
      }
    }
  }

  bool get _hasUsablePostureOverlay {
    if (postureKeypoints.length <= _rightHipIdx) {
      return false;
    }

    final required = [
      postureKeypoints[_leftShoulderIdx],
      postureKeypoints[_rightShoulderIdx],
      postureKeypoints[_leftHipIdx],
      postureKeypoints[_rightHipIdx],
    ];

    return required.every((kp) => kp.confidence >= 0.3);
  }

  void _drawRealFaceLandmarks(Canvas canvas, Size widgetSize, FaceMesh face) {
    if (cameraSize == null) return;

    final landmarkPaint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.fill;

    // Scaling factors between camera resolution and screen widget size
    final double scaleX = widgetSize.width /
        cameraSize!.height; // Note: height/width swapped due to portrait mode
    final double scaleY = widgetSize.height / cameraSize!.width;

    // Draw all points
    for (final point in face.points) {
      final x = point.x * scaleX;
      final y = point.y * scaleY;
      canvas.drawCircle(Offset(x, y), 1.5, landmarkPaint);
    }

    // Draw bounding box
    final rectPaint = Paint()
      ..color = Colors.red.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final boundingBox = face.boundingBox;
    final mappedRect = Rect.fromLTRB(
      boundingBox.left * scaleX,
      boundingBox.top * scaleY,
      boundingBox.right * scaleX,
      boundingBox.bottom * scaleY,
    );
    canvas.drawRect(mappedRect, rectPaint);
  }

  void _drawHeadMeshOverlay(Canvas canvas, Size size, Paint basePaint) {
    final meshPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final center = Offset(size.width / 2, size.height / 2);
    final w = 250.0 / 2;
    final h = 350.0 / 2;

    // Draw concentric ovals to simulate a 3D wireframe
    for (int i = 1; i <= 3; i++) {
      canvas.drawOval(
        Rect.fromCenter(
            center: center, width: w * 2 * (i / 3), height: h * 2 * (i / 3)),
        meshPaint,
      );
    }

    // Draw intersecting lines
    canvas.drawLine(Offset(center.dx, center.dy - h),
        Offset(center.dx, center.dy + h), meshPaint);
    canvas.drawLine(Offset(center.dx - w, center.dy),
        Offset(center.dx + w, center.dy), meshPaint);
  }

  void _drawPostureSkeletonOverlay(Canvas canvas, Size size, Paint basePaint) {
    final skeletonPaint = Paint()
      ..color = Colors.lightGreenAccent.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final jointPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Simulate Shoulder points
    final leftShoulder = Offset(centerX - 60, centerY - 80);
    final rightShoulder = Offset(centerX + 60, centerY - 80);

    // Simulate Hip points
    final leftHip = Offset(centerX - 50, centerY + 80);
    final rightHip = Offset(centerX + 50, centerY + 80);

    // Draw connections
    canvas.drawLine(
        leftShoulder, rightShoulder, skeletonPaint); // Shoulder line
    canvas.drawLine(leftHip, rightHip, skeletonPaint); // Hip line
    canvas.drawLine(leftShoulder, leftHip, skeletonPaint); // Left torso
    canvas.drawLine(rightShoulder, rightHip, skeletonPaint); // Right torso

    // Draw joints
    canvas.drawCircle(leftShoulder, 6, jointPaint);
    canvas.drawCircle(rightShoulder, 6, jointPaint);
    canvas.drawCircle(leftHip, 6, jointPaint);
    canvas.drawCircle(rightHip, 6, jointPaint);
  }

  void _drawLivePostureOverlay(Canvas canvas, Size size) {
    final skeletonPaint = Paint()
      ..color = Colors.lightGreenAccent.withOpacity(0.78)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final jointPaint = Paint()
      ..color = Colors.amberAccent.withOpacity(0.92)
      ..style = PaintingStyle.fill;

    final headPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.88)
      ..style = PaintingStyle.fill;

    final points = postureKeypoints.map((kp) => _mapPosePoint(kp, size)).toList();

    void drawConnection(int startIdx, int endIdx) {
      if (!_isPosePointVisible(startIdx) || !_isPosePointVisible(endIdx)) {
        return;
      }

      canvas.drawLine(points[startIdx], points[endIdx], skeletonPaint);
    }

    drawConnection(_leftShoulderIdx, _rightShoulderIdx);
    drawConnection(_leftHipIdx, _rightHipIdx);
    drawConnection(_leftShoulderIdx, _leftHipIdx);
    drawConnection(_rightShoulderIdx, _rightHipIdx);
    drawConnection(_noseIdx, _leftShoulderIdx);
    drawConnection(_noseIdx, _rightShoulderIdx);
    drawConnection(_leftEyeIdx, _noseIdx);
    drawConnection(_rightEyeIdx, _noseIdx);

    for (var i = 0; i < points.length; i++) {
      if (!_isPosePointVisible(i)) {
        continue;
      }

      final paint = i == _noseIdx || i == _leftEyeIdx || i == _rightEyeIdx
          ? headPaint
          : jointPaint;
      canvas.drawCircle(points[i], i == _noseIdx ? 5 : 4, paint);
    }
  }

  Offset _mapPosePoint(PoseKeypoint kp, Size size) {
    return Offset(kp.x * size.width, kp.y * size.height);
  }

  bool _isPosePointVisible(int index) {
    return index < postureKeypoints.length &&
        postureKeypoints[index].confidence >= 0.3;
  }

  @override
  bool shouldRepaint(covariant GuidelinePainter oldDelegate) {
    return oldDelegate.mode != mode ||
        oldDelegate.faces != faces ||
        oldDelegate.postureKeypoints != postureKeypoints;
  }
}
