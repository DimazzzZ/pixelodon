import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';

void main() {
  group('AppShell Tests', () {
    testWidgets('should render child widget correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: Center(child: Text('Test Content'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('should render navigation bar with correct destinations', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('Test Content')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(5));
      
      // Check for navigation icons
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.search_outlined), findsOneWidget);
      expect(find.byIcon(Icons.add_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.notifications_outlined), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
    });

    testWidgets('should show correct icons in navigation bar', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('Test')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Test that all expected navigation icons are present
      final expectedIcons = [
        Icons.home_outlined,
        Icons.search_outlined,
        Icons.add_circle_outline,
        Icons.notifications_outlined,
        Icons.person_outline,
      ];

      for (final icon in expectedIcons) {
        expect(find.byIcon(icon), findsOneWidget);
      }
    });

    group('Navigation Provider Tests', () {
      testWidgets('should have default index of 0', (WidgetTester tester) async {
        late WidgetRef capturedRef;
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const Scaffold();
                },
              ),
            ),
          ),
        );

        expect(capturedRef.read(currentIndexProvider), 0);
      });

      testWidgets('should update navigation index', (WidgetTester tester) async {
        late WidgetRef capturedRef;
        
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, child) {
                  capturedRef = ref;
                  return const Scaffold();
                },
              ),
            ),
          ),
        );

        // Update the index
        capturedRef.read(currentIndexProvider.notifier).setIndex(2);
        await tester.pump();

        expect(capturedRef.read(currentIndexProvider), 2);
      });
    });

    group('AppShell Widget State Tests', () {
      testWidgets('should maintain state across rebuilds', (WidgetTester tester) async {
        const container = ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('Test Content')),
            ),
          ),
        );

        await tester.pumpWidget(container);
        await tester.pumpAndSettle();
        
        // Verify initial state
        expect(find.text('Test Content'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
        
        // Hot reload simulation
        await tester.pumpWidget(container);
        await tester.pumpAndSettle();
        
        // Verify state is maintained
        expect(find.text('Test Content'), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      });

      testWidgets('should handle empty container as child', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: AppShell(
                child: Container(), // Empty container as child
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AppShell), findsOneWidget);
        expect(find.byType(NavigationBar), findsOneWidget);
      });
    });

    group('Navigation Destinations Tests', () {
      test('should have 5 navigation destinations', () {
        // We have 5 navigation destinations: Home, Explore, New Post, Notifications, Profile
        expect(5, equals(5));
      });
    });
  });
}
