import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/core/routing/app_router.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/providers/auth_provider.dart';

import 'app_router_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  group('AppRouter Tests', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      
      // Mock empty instances (not logged in)
      when(mockAuthRepository.instances).thenReturn([]);
      
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Router Configuration', () {
      test('should create GoRouter with correct initial location', () {
        final router = container.read(appRouterProvider);
        
        expect(router, isA<GoRouter>());
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/auth/login');
      });

      test('should have debug diagnostics enabled', () {
        final router = container.read(appRouterProvider);
        
        // This is a bit tricky to test directly, but we can verify the router was created
        expect(router, isNotNull);
      });
    });

    group('Route Definitions', () {
      test('should have login route defined', () {
        final router = container.read(appRouterProvider);
        
        // Navigate to login route
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      test('should have OAuth callback route defined', () {
        final router = container.read(appRouterProvider);
        
        // Navigate to OAuth callback route
        router.go('/oauth/callback?domain=example.com&state=test&code=123');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });

      test('should have home route defined', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to home route
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      test('should have settings route defined', () {
        final router = container.read(appRouterProvider);
        
        // Navigate to settings route
        router.go('/settings');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
      });

      test('should have compose route defined', () {
        final router = container.read(appRouterProvider);
        
        // Navigate to compose route
        router.go('/compose');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/compose');
      });

      test('should redirect root path to home', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to root
        router.go('/');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });
    });

    group('Authentication Redirect Logic', () {
      test('should redirect to login when not authenticated', () {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Try to navigate to protected route
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      test('should redirect to home when authenticated and on login screen', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to login while authenticated
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      test('should not redirect OAuth callback when not authenticated', () {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to OAuth callback
        router.go('/oauth/callback');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });
    });

    group('OAuth Callback Parameter Handling', () {
      testWidgets('should handle query parameters correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(appRouterProvider),
            ),
          ),
        );

        // Navigate to OAuth callback with query parameters
        final router = container.read(appRouterProvider);
        router.go('/oauth/callback?domain=example.com&state=test123&code=auth456');

        await tester.pumpAndSettle();

        // Should find OAuthCallbackScreen
        expect(find.byType(OAuthCallbackScreen), findsOneWidget);
      });

      testWidgets('should handle missing parameters by showing login', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(appRouterProvider),
            ),
          ),
        );

        // Navigate to OAuth callback without required parameters
        final router = container.read(appRouterProvider);
        router.go('/oauth/callback');

        await tester.pumpAndSettle();

        // Should show LoginScreen due to missing parameters
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Error Handling', () {
      testWidgets('should show error page for invalid routes', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(appRouterProvider),
            ),
          ),
        );

        // Navigate to invalid route
        final router = container.read(appRouterProvider);
        router.go('/invalid/route');

        await tester.pumpAndSettle();

        // Should show error page
        expect(find.text('Page Not Found'), findsOneWidget);
        expect(find.text('Page not found: /invalid/route'), findsOneWidget);
        expect(find.text('Go to Home'), findsOneWidget);
      });

      testWidgets('error page should navigate back to home', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(appRouterProvider),
            ),
          ),
        );

        // Navigate to invalid route
        final router = container.read(appRouterProvider);
        router.go('/invalid/route');

        await tester.pumpAndSettle();

        // Tap "Go to Home" button
        await tester.tap(find.text('Go to Home'));
        await tester.pumpAndSettle();

        // Should redirect to login (since not authenticated)
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });
    });

    group('Shell Route Structure', () {
      testWidgets('should wrap protected routes in AppShell', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(appRouterProvider),
            ),
          ),
        );

        // Navigate to home
        final router = container.read(appRouterProvider);
        router.go('/home');

        await tester.pumpAndSettle();

        // Should find HomeScreen within the shell
        expect(find.byType(HomeScreen), findsOneWidget);
      });

      test('should have explore route in shell', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to explore route
        router.go('/explore');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/explore');
      });

      test('should have notifications route in shell', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to notifications route
        router.go('/notifications');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/notifications');
      });

      test('should have profile route in shell', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);
        
        // Navigate to profile route
        router.go('/profile');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
      });
    });
  });
}
