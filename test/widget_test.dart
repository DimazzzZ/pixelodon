// Widget tests for Pixelodon app

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pixelodon/main.dart';

void main() {
  group('Pixelodon Widget Tests', () {
    testWidgets('PixelodonApp should build correctly with ProviderScope', (WidgetTester tester) async {
      // Build the app with proper ProviderScope wrapper
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      // Wait for the widget to settle and handle any async operations
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Verify that the app builds successfully
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('PixelodonApp should have correct title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the MaterialApp and verify its title
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'Pixelodon');
    });

    testWidgets('PixelodonApp should use system theme mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the MaterialApp and verify theme mode
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, ThemeMode.system);
    });

    testWidgets('PixelodonApp should have debug banner disabled', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find the MaterialApp and verify debug banner is disabled
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.debugShowCheckedModeBanner, false);
    });
  });
}
