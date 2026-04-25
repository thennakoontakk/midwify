import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'cranial_metrics.dart';

class HeadLandmarkerRuntimeResult {
  final List<Landmark3D> landmarks;
  final String source;
  final List<String> warnings;

  const HeadLandmarkerRuntimeResult({
    required this.landmarks,
    required this.source,
    this.warnings = const [],
  });
}

class HeadLandmarkerRuntime {
  static const MethodChannel _channel = MethodChannel('midwify/head_landmarker');
  static const String _source = 'mediapipe_face_landmarker_task';

  Future<HeadLandmarkerRuntimeResult?> detectFromPath(String imagePath) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return null;
    }

    try {
      final response = await _channel.invokeMethod<Map<Object?, Object?>>(
        'detectFromPath',
        {'imagePath': imagePath},
      );
      if (response == null) {
        return null;
      }

      final rawLandmarks = response['landmarks'];
      if (rawLandmarks is! List || rawLandmarks.isEmpty) {
        return null;
      }

      final landmarks = <Landmark3D>[];
      for (final item in rawLandmarks) {
        if (item is! Map) {
          continue;
        }

        final x = item['x'];
        final y = item['y'];
        final z = item['z'];
        if (x is! num || y is! num || z is! num) {
          continue;
        }

        landmarks.add(
          Landmark3D(
            x: x.toDouble(),
            y: y.toDouble(),
            z: z.toDouble(),
          ),
        );
      }

      if (landmarks.isEmpty) {
        return null;
      }

      final warnings = <String>[];
      final rawWarnings = response['warnings'];
      if (rawWarnings is List) {
        for (final item in rawWarnings) {
          if (item is String && item.isNotEmpty) {
            warnings.add(item);
          }
        }
      }

      return HeadLandmarkerRuntimeResult(
        landmarks: landmarks,
        source: response['source'] as String? ?? _source,
        warnings: warnings,
      );
    } on MissingPluginException {
      return null;
    } on PlatformException catch (e) {
      debugPrint('HeadLandmarkerRuntime platform error: ${e.code} ${e.message}');
      return null;
    } catch (e) {
      debugPrint('HeadLandmarkerRuntime error: $e');
      return null;
    }
  }
}
