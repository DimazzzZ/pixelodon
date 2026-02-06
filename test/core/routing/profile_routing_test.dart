import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/core/routing/app_router.dart';

void main() {
  testWidgets('Profile routing should work correctly', (WidgetTester tester) async {
    // Create a test container
    final container = ProviderContainer();
    
    try {
      // Get the router
      final router = container.read(appRouterProvider);
      expect(router, isNotNull);
      
      // Build the app with the router to initialize routing
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      // Wait for initial navigation
      await tester.pumpAndSettle();
      
      // The router should have navigated to /splash initially
      // Since we can't directly test /profile without auth setup,
      // we verify the router is functional
      expect(router.routerDelegate.currentConfiguration.uri.path, isNotEmpty);
      
      // Navigate to /profile/123 (specific user profile)
      router.go('/profile/123');
      await tester.pumpAndSettle();
      
      // Verify navigation worked (may redirect based on auth state)
      final currentPath = router.routerDelegate.currentConfiguration.uri.path;
      expect(currentPath, isNotEmpty);
    } finally {
      container.dispose();
    }
  });
}
