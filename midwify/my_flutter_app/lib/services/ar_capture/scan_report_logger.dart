import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../../screens/ar_capture/ar_capture_models.dart';

class ScanReportLogger {
  static Future<String?> logScanReport({
    required AppMode mode,
    required String imagePath,
    required ARCaptureResult result,
  }) async {
    final timestamp = DateTime.now().toUtc();
    final payload = <String, dynamic>{
      'timestampUtc': timestamp.toIso8601String(),
      'mode': mode.name,
      'imagePath': imagePath,
      'result': result.toJson(),
    };

    final report = const JsonEncoder.withIndent('  ').convert(payload);

    debugPrint('AR_SCAN_REPORT_BEGIN');
    for (final line in report.split('\n')) {
      debugPrint('AR_SCAN_REPORT $line');
    }
    debugPrint('AR_SCAN_REPORT_END');

    if (kIsWeb) {
      return null;
    }

    try {
      final baseDir = await getApplicationDocumentsDirectory();
      final logDir = Directory(
        '${baseDir.path}${Platform.pathSeparator}scan_logs',
      );
      await logDir.create(recursive: true);

      final safeTimestamp = timestamp
          .toIso8601String()
          .replaceAll(':', '-')
          .replaceAll('.', '-');
      final file = File(
        '${logDir.path}${Platform.pathSeparator}scan_${mode.name}_$safeTimestamp.json',
      );
      await file.writeAsString(report);
      debugPrint('AR_SCAN_REPORT_FILE ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('AR_SCAN_REPORT_FILE_ERROR $e');
      return null;
    }
  }
}
