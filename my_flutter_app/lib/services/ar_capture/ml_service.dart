import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
// Conditional imports for platform compatibility
import 'package:tflite_flutter/tflite_flutter.dart' if (dart.library.html) 'ml_service_stub.dart';
import '../../screens/ar_capture/ar_capture_models.dart';

class MLService {
  // Singleton pattern
  static final MLService _instance = MLService._internal();
  factory MLService() => _instance;
  MLService._internal();

  /// Flag to bypass strict image validation for testing purposes.
  static bool bypassValidation = true; // Enabled by default for testing

  Interpreter? _headInterpreter;
  Interpreter? _postureInterpreter;

  // Expected input size for models (typical for MobileNet/ResNet type models)
  static const int _inputSize = 224;

  Future<void> initializeModels() async {
    if (kIsWeb) {
      debugPrint('Web platform: Using mock ML service');
      return;
    }

    try {
      _headInterpreter = await Interpreter.fromAsset('assets/models/cranial_analysis.tflite');
      debugPrint('Head model loaded successfully');
    } catch (e) {
      debugPrint('Error loading Head model: $e');
    }

    try {
      _postureInterpreter = await Interpreter.fromAsset('assets/models/posture_analysis.tflite');
      debugPrint('Posture model loaded successfully');
    } catch (e) {
      debugPrint('Error loading Posture model: $e');
    }
  }

  Future<int> runInference(String imagePath, AppMode mode) async {
    debugPrint('=== STARTING INFERENCE FOR MODE: $mode ===');
    debugPrint('Image path: "$imagePath"');
    debugPrint('Is Web: $kIsWeb');
    
    // CRITICAL: Validate image path first
    if (imagePath.isEmpty || imagePath == 'null' || imagePath == 'undefined') {
      debugPrint('ERROR: Invalid or empty image path: "$imagePath"');
      debugPrint('=== INFERENCE BLOCKED - EMPTY PATH ===');
      return 0;
    }
    
    if (kIsWeb) {
      debugPrint('Web platform: Running TensorFlow.js inference for mode: $mode');
      return await _runWebInference(imagePath, mode);
    }

    final interpreter = mode == AppMode.head ? _headInterpreter : _postureInterpreter;
    if (interpreter == null) {
      debugPrint('ERROR: Interpreter not initialized for mode: $mode');
      return 0; // Fallback
    }

    try {
      // 1. Read image from file
      final file = File(imagePath);
      
      // CRITICAL: Check if file exists
      if (!await file.exists()) {
        debugPrint('ERROR: Image file does not exist: "$imagePath"');
        debugPrint('=== INFERENCE BLOCKED - FILE NOT FOUND ===');
        return 0;
      }
      
      final imageBytes = await file.readAsBytes();
      debugPrint('Image size: ${imageBytes.length} bytes');
      
      // CRITICAL: Check if file has content
      if (imageBytes.isEmpty) {
        debugPrint('ERROR: Image file is empty: "$imagePath"');
        debugPrint('=== INFERENCE BLOCKED - EMPTY FILE ===');
        return 0;
      }
      
      // 2. Decode image using the 'image' package
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('ERROR: Failed to decode image');
        debugPrint('=== INFERENCE BLOCKED - DECODE FAILED ===');
        return 0; // Fallback
      }

      debugPrint('Image decoded: ${decodedImage.width}x${decodedImage.height}');

      // 3. VALIDATE: Check if image contains baby-like features
      debugPrint('=== RUNNING VALIDATION ===');
      final isValid = bypassValidation || _validateBabyImage(decodedImage, mode);
      debugPrint('VALIDATION RESULT: $isValid (Bypass: $bypassValidation)');
      
      if (!isValid) {
        debugPrint('VALIDATION FAILED: Image does not appear to contain baby features');
        debugPrint('=== INFERENCE BLOCKED ===');
        return 0; // Return 0 confidence for invalid images
      }

      debugPrint('=== VALIDATION PASSED - PROCEEDING WITH INFERENCE ===');

      // 4. Get input and output tensor shapes
      final inputTensor = interpreter.getInputTensor(0);
      final inputShape = inputTensor.shape; // [1, height, width, 3]
      final int modelHeight = inputShape[1];
      final int modelWidth = inputShape[2];
      
      debugPrint('=== MODEL EXPECTS INPUT: $inputShape (Type: ${inputTensor.type}) ===');

      final outputTensor = interpreter.getOutputTensor(0);
      final outputShape = outputTensor.shape;
      debugPrint('=== MODEL EXPECTS OUTPUT: $outputShape (Type: ${outputTensor.type}) ===');
      final numClasses = outputShape.last;

      // 5. Resize the image to match model input shape
      img.Image resizedImage = img.copyResize(decodedImage, width: modelWidth, height: modelHeight);

      // 6. Convert image to the correct shape and type
      final bool isFloat = inputTensor.type == TensorType.float32;
      final bool isFlattened = inputShape.length == 2;
      
      dynamic input;
      
      if (isFlattened) {
        // Handle flattened [1, size] input
        final List<num> flattened = [];
        for (int y = 0; y < modelHeight; y++) {
          for (int x = 0; x < modelWidth; x++) {
            final pixel = resizedImage.getPixel(x, y);
            if (isFloat) {
              flattened.add(pixel.r / 255.0);
              flattened.add(pixel.g / 255.0);
              flattened.add(pixel.b / 255.0);
            } else {
              flattened.add(pixel.r.toInt());
              flattened.add(pixel.g.toInt());
              flattened.add(pixel.b.toInt());
            }
          }
        }
        input = [flattened];
      } else {
        // Handle standard [1, height, width, 3] input
        input = List.generate(
          1,
          (i) => List.generate(
            modelHeight,
            (y) => List.generate(
              modelWidth,
              (x) {
                final pixel = resizedImage.getPixel(x, y);
                if (isFloat) {
                  return <double>[
                    pixel.r / 255.0,
                    pixel.g / 255.0,
                    pixel.b / 255.0,
                  ];
                } else {
                  return <int>[
                    pixel.r.toInt(),
                    pixel.g.toInt(),
                    pixel.b.toInt(),
                  ];
                }
              },
            ),
          ),
        );
      }

      // 7. Prepare generic output buffer with correct type
      final bool isOutputFloat = outputTensor.type == TensorType.float32;
      var output = isOutputFloat 
          ? List<List<double>>.generate(1, (i) => List<double>.filled(numClasses, 0.0))
          : List<List<int>>.generate(1, (i) => List<int>.filled(numClasses, 0));

      // 8. Run Inference
      debugPrint('=== INVOCATION START (Input: ${inputTensor.type}, Output: ${outputTensor.type}) ===');
      interpreter.run(input, output);
      debugPrint('=== INVOCATION END ===');

      // 9. Parse the Output
      double confidenceValue = 0.0;
      dynamic rawValue = (numClasses > 1) ? output[0][1] : output[0][0];
      
      if (isOutputFloat) {
        confidenceValue = rawValue as double;
      } else {
        // For quantized models, confidence is often 0-255
        confidenceValue = (rawValue as int) / 255.0;
      }

      // 10. Map to 0-100 integer
      int confidencePercentage = (confidenceValue * 100).round();
      debugPrint('=== FINAL RESULT: $confidencePercentage% ($confidenceValue) ===');
      
      int result = confidencePercentage.clamp(0, 100);
      if (bypassValidation && result == 0) return 1; 
      return result;
      
    } catch (e) {
      debugPrint('ERROR: Exception running inference: $e');
      debugPrint('=== INFERENCE BLOCKED - EXCEPTION ===');
      return 0; // Fallback
    }
  }

  // VALIDATION: Check if image contains baby-like features
  bool _validateBabyImage(img.Image image, AppMode mode) {
    debugPrint('=== DEBUG: Starting Image Validation ===');
    debugPrint('Image size: ${image.width}x${image.height}');
    
    // Basic validation based on image characteristics
    
    // 1. Check image size (babies typically have smaller head proportions)
    final imageRatio = image.width / image.height;
    debugPrint('Image ratio: $imageRatio');
    if (imageRatio < 0.5 || imageRatio > 2.0) {
      debugPrint('Validation FAILED: Unusual image aspect ratio');
      return false;
    }

    // 2. Check for skin tone dominance (babies have prominent skin areas)
    final skinToneRatio = _calculateSkinToneRatio(image);
    debugPrint('Skin tone ratio: $skinToneRatio');
    if (skinToneRatio < 0.35) { // Increased to 0.35 for very strict validation
      debugPrint('Validation FAILED: Low skin tone ratio ($skinToneRatio)');
      return false;
    }

    // 3. Check brightness (baby images are usually well-lit)
    final brightness = _calculateAverageBrightness(image);
    debugPrint('Average brightness: $brightness');
    if (brightness < 0.2 || brightness > 0.9) {
      debugPrint('Validation FAILED: Extreme brightness ($brightness)');
      return false;
    }

    // 4. Mode-specific validation
    if (mode == AppMode.head) {
      // For head analysis, check if central area has face-like features
      final centralSkinRatio = _getCentralSkinRatio(image);
      debugPrint('Central skin ratio: $centralSkinRatio');
      if (centralSkinRatio < 0.45) { // Increased to 0.45 for extremely strict validation
        debugPrint('Validation FAILED: Head features not detected (central ratio: $centralSkinRatio)');
        return false;
      }
    } else if (mode == AppMode.posture) {
      // For posture analysis, check for body-like proportions
      if (!_validatePostureFeatures(image)) {
        debugPrint('Validation FAILED: Posture features not detected');
        return false;
      }
    }

    debugPrint('Validation PASSED: Image appears to contain baby features');
    return true;
  }

  double _getCentralSkinRatio(img.Image image) {
    final centerX = image.width ~/ 2;
    final centerY = image.height ~/ 2;
    final radius = math.min(image.width, image.height) ~/ 4;
    
    int skinPixels = 0;
    int totalChecked = 0;
    
    for (int y = centerY - radius; y < centerY + radius; y++) {
      for (int x = centerX - radius; x < centerX + radius; x++) {
        if (x >= 0 && x < image.width && y >= 0 && y < image.height) {
          final pixel = image.getPixel(x, y);
          final r = pixel.r / 255.0;
          final g = pixel.g / 255.0;
          final b = pixel.b / 255.0;
          
          // Same extremely restrictive skin tone detection
          bool isSkinTone = false;
          
          // Very strict light skin tones
          if (r > 0.4 && g > 0.32 && b > 0.25 && r > g * 1.15 && r > b * 1.4 && g > b * 1.2) {
            isSkinTone = true;
          }
          // Very strict medium skin tones
          else if (r > 0.35 && g > 0.27 && b > 0.2 && r > g * 1.2 && r > b * 1.5) {
            isSkinTone = true;
          }
          // Very strict darker skin tones
          else if (r > 0.3 && g > 0.22 && b > 0.15 && r > g * 1.25 && r > b * 1.7) {
            isSkinTone = true;
          }
          
          if (isSkinTone) {
            skinPixels++;
          }
          totalChecked++;
        }
      }
    }
    
    final ratio = totalChecked > 0 ? skinPixels / totalChecked : 0.0;
    debugPrint('Central skin pixels: $skinPixels / $totalChecked = $ratio');
    return ratio;
  }

  double _calculateSkinToneRatio(img.Image image) {
    int skinPixels = 0;
    int totalPixels = image.width * image.height;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r / 255.0;
        final g = pixel.g / 255.0;
        final b = pixel.b / 255.0;
        
        // Extremely restrictive skin tone detection to block all non-baby images
        bool isSkinTone = false;
        
        // Very strict light skin tones
        if (r > 0.4 && g > 0.32 && b > 0.25 && r > g * 1.15 && r > b * 1.4 && g > b * 1.2) {
          isSkinTone = true;
        }
        // Very strict medium skin tones
        else if (r > 0.35 && g > 0.27 && b > 0.2 && r > g * 1.2 && r > b * 1.5) {
          isSkinTone = true;
        }
        // Very strict darker skin tones
        else if (r > 0.3 && g > 0.22 && b > 0.15 && r > g * 1.25 && r > b * 1.7) {
          isSkinTone = true;
        }
        
        if (isSkinTone) {
          skinPixels++;
        }
      }
    }
    
    final ratio = skinPixels / totalPixels;
    debugPrint('Skin pixels: $skinPixels / $totalPixels = $ratio');
    return ratio;
  }

  double _calculateAverageBrightness(img.Image image) {
    double totalBrightness = 0;
    int totalPixels = image.width * image.height;
    
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final pixel = image.getPixel(x, y);
        totalBrightness += (pixel.r + pixel.g + pixel.b) / (255.0 * 3);
      }
    }
    
    return totalBrightness / totalPixels;
  }

  bool _validatePostureFeatures(img.Image image) {
    // For posture, check for vertical body-like structure
    // This is a simplified validation - just check for minimum skin presence
    final skinToneRatio = _calculateSkinToneRatio(image);
    debugPrint('Posture validation: skin ratio = $skinToneRatio');
    return skinToneRatio > 0.30; // Increased to 0.30 for extremely strict validation
  }

  Future<int> _runWebInference(String imagePath, AppMode mode) async {
    try {
      // Create mock interpreter for web (would be real TensorFlow.js in production)
      final modelPath = mode == AppMode.head 
          ? 'assets/models/cranial_analysis.tflite'
          : 'assets/models/posture_analysis.tflite';
      
      final interpreter = await Interpreter.fromAsset(modelPath);
      
      // Load and process image from web file path
      final imageBytes = await _loadWebImageBytes(imagePath);
      if (imageBytes.isEmpty) {
        debugPrint('Failed to load web image');
        return 0;
      }
      
      // Decode and process image
      img.Image? decodedImage = img.decodeImage(imageBytes);
      if (decodedImage == null) {
        debugPrint('Failed to decode web image');
        return 0;
      }

      // VALIDATE: Check if image contains baby-like features
      if (!_validateBabyImage(decodedImage, mode)) {
        debugPrint('Web validation failed: Image does not appear to contain baby features');
        return 0; // Return 0 confidence for invalid images
      }

      // Resize the image
      img.Image resizedImage = img.copyResize(decodedImage, width: _inputSize, height: _inputSize);

      // Convert to tensor format
      var input = List.generate(
        1,
        (i) => List.generate(
          _inputSize,
          (y) => List.generate(
            _inputSize,
            (x) {
              final pixel = resizedImage.getPixel(x, y);
              return <double>[
                pixel.r / 255.0, // Red
                pixel.g / 255.0, // Green
                pixel.b / 255.0, // Blue
              ];
            },
          ),
        ),
      );

      // Run inference
      var output = List<List<double>>.generate(1, (i) => List<double>.filled(2, 0.0));
      interpreter.run(input, output);

      // Parse results
      double confidenceValue = output[0][1]; // Use second class (abnormal) confidence
      int confidencePercentage = (confidenceValue * 100).round();
      
      debugPrint('Web inference completed with confidence: $confidencePercentage% ($confidenceValue)');
      
      interpreter.close();
      return confidencePercentage.clamp(0, 100);
      
    } catch (e) {
      debugPrint('Error running web inference: $e');
      return 0;
    }
  }

  Future<Uint8List> _loadWebImageBytes(String imagePath) async {
    // For web, we need to handle image loading differently
    try {
      // If it's a data URL, extract the base64 part
      if (imagePath.startsWith('data:')) {
        final commaIndex = imagePath.indexOf(',');
        if (commaIndex != -1) {
          final base64Data = imagePath.substring(commaIndex + 1);
          return const Base64Decoder().convert(base64Data);
        }
      }
      
      // For file paths on web, we'd need to use FileReader API
      // This is a simplified version - in production you'd handle this properly
      debugPrint('Web: Loading image from path: $imagePath');
      
      // Return empty for now - in real implementation you'd load the actual image
      return Uint8List(0);
      
    } catch (e) {
      debugPrint('Error loading web image: $e');
      return Uint8List(0);
    }
  }
}
