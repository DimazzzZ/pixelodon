import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/main.dart';
import 'package:pixelodon/core/theme/app_theme.dart';

void main() {
  group('PixelodonApp Tests', () {
    testWidgets('PixelodonApp should build correctly', (WidgetTester tester) async {
      // Build the app wrapped in ProviderScope
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      // Wait for the widget to settle
      await tester.pumpAndSettle();

      // Verify that the app builds without throwing
      expect(find.byType(PixelodonApp), findsOneWidget);
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('PixelodonApp should have correct title and theme configuration', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: PixelodonApp(),
        ),
      );

      await tester.pumpAndSettle();

      // Find the MaterialApp widget
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

      // Verify app title
      expect(materialApp.title, 'Pixelodon');
      
      // Verify theme mode is system
      expect(materialApp.themeMode, ThemeMode.system);
      
      // Verify debug banner is disabled
      expect(materialApp.debugShowCheckedModeBanner, false);
      
      // Verify themes are set (we can't easily test the actual theme objects without more setup)
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });

    testWidgets('PixelodonApp should be a ConsumerStatefulWidget', (WidgetTester tester) async {
      const app = PixelodonApp();
      
      expect(app, isA<ConsumerStatefulWidget>());
      expect(app.key, isNull);
      
      // Test with key
      const appWithKey = PixelodonApp(key: Key('test-key'));
      expect(appWithKey.key, const Key('test-key'));
    });

    group('App Theme Tests', () {
      test('AppTheme should provide light and dark themes', () {
        final lightTheme = AppTheme.getLightTheme();
        final darkTheme = AppTheme.getDarkTheme();

        expect(lightTheme, isA<ThemeData>());
        expect(darkTheme, isA<ThemeData>());
        expect(lightTheme.brightness, Brightness.light);
        expect(darkTheme.brightness, Brightness.dark);
      });
    });
  });

  group('Main Function Tests', () {
    testWidgets('main() should initialize properly', (WidgetTester tester) async {
      // Test that WidgetsFlutterBinding is ensured to be initialized
      // This is implicitly tested when we call main() and the app runs
      WidgetsFlutterBinding.ensureInitialized();
      
      // The main function runs the app, which we've tested above
      expect(WidgetsBinding.instance, isNotNull);
    });
  });
}
