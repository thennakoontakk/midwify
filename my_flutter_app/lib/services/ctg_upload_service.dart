import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Service to upload CTG strip images to the Flask backend for extraction.
class CtgUploadService {
  // Must match the Flask backend URL used in FetalHealthService
  static const String _baseUrl = 'http://192.168.8.176:5000';

  /// Upload a CTG strip image and get extracted parameters.
  ///
  /// Returns a Map with:
  ///   - 'valid': bool
  ///   - 'baseline_hr': double
  ///   - 'parameters': Map<String, Map<String, dynamic>>
  ///
  /// Throws on network/server errors.
  static Future<Map<String, dynamic>> uploadCtgImage(File imageFile) async {
    try {
      final uri = Uri.parse('$_baseUrl/upload-ctg');
      final request = http.MultipartRequest('POST', uri);

      // Attach the image file
      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          filename: imageFile.path.split(Platform.pathSeparator).last,
        ),
      );

      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
      );

      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return data;
      } else if (response.statusCode == 400) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(data['error'] ?? 'Invalid image');
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception(
        'Cannot connect to server. Please check that the backend is running.',
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Upload failed: $e');
    }
  }
}
