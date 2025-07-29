// This is a basic Flutter widget test for the CRM app.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:crm_app/main.dart';

void main() {
  testWidgets('CRM app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(startScreen: SizedBox.shrink()));

    // Verify that the app loads without crashing
    expect(tester.takeException(), isNull);

    // Verify that the app is running (basic smoke test)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
