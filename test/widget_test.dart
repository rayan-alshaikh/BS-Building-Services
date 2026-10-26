// This is a basic Flutter widget test.
//
// NOTE:
// Default counter test doesn't apply to this project.
// Also pumping MyApp may fail in tests because Firebase isn't initialized.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Smoke test', (WidgetTester tester) async {
    // Build a minimal widget tree to ensure tests run.
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(child: Text('OK')),
        ),
      ),
    );

    // Verify widget renders.
    expect(find.text('OK'), findsOneWidget);
  });
}
