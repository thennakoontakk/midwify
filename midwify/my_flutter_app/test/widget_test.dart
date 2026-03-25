import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:midwify/main.dart';

void main() {
  testWidgets('MidwifyApp renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MidwifyApp());

    // Verify splash screen elements are present
    expect(find.text('Midwify'), findsOneWidget);
    expect(find.text('Maternal Risk Dashboard'), findsOneWidget);

    // Wait for the splash screen timer to finish
    await tester.pumpAndSettle(const Duration(seconds: 3));
  });
}
