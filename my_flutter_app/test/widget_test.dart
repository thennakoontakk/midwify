import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:my_flutter_app/main.dart';

void main() {
  testWidgets('MidwifyApp renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MidwifyApp());

    // Verify splash screen elements are present
    expect(find.text('Midwify'), findsOneWidget);
    expect(find.text('Maternal Risk Dashboard'), findsOneWidget);
  });
}
