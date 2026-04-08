import 'package:flutter_test/flutter_test.dart';
import 'package:midwify/services/ar_capture/ml_service.dart';

void main() {
  test('MLService can be constructed after posture pipeline changes', () {
    expect(MLService(), isA<MLService>());
  });
}
