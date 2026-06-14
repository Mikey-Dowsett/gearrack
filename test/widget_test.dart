import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gearrack/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build the app with Material wrapper for theme access.
    await tester.pumpWidget(const MaterialApp(home: MainNavigationScreen()));

    // Verify the bottom navigation tabs are present.
    expect(find.text('Gear'), findsOneWidget);
    expect(find.text('Packs'), findsOneWidget);
  });
}
