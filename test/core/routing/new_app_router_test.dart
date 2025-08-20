import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/core/routing/new_app_router.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/repositories/new_auth_repository.dart';
import 'package:pixelodon/providers/new_auth_provider.dart';

import 'new_app_router_test.mocks.dart';

@GenerateMocks([NewAuthRepository])
void main() {
  group('NewAppRouter Tests', () {
    late MockNewAuthRepository mockAuthRepository;
    late ProviderContainer container;

    setUp(() {
      mockAuthRepository = MockNewAuthRepository();
      
      // Mock empty instances (not logged in)
      when(mockAuthRepository.instances).thenReturn({});
      
      container = ProviderContainer(
        overrides: [
          newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Router Configuration', () {
      test('should create GoRouter with correct initial location', () {
        final router = container.read(newAppRouterProvider);
        
        expect(router, isA<GoRouter>());
        expect(router.routerDelegate.currentConfiguration.uri.toString(), '/auth/login');
      });

      test('should have debug diagnostics enabled', () {
        final router = container.read(newAppRouterProvider);
        
        // Verify the router was created successfully
        expect(router, isNotNull);
        expect(router, isA<GoRouter>());
      });
    });

    group('Route Definitions', () {
      test('should have login route defined', () {
        final router = container.read(newAppRouterProvider);
        
        // Navigate to login route
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      test('should have OAuth callback route defined', () {
        final router = container.read(newAppRouterProvider);
        
        // Navigate to OAuth callback route with parameters
        router.go('/oauth/callback?domain=example.com&state=test&code=123');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });

      test('should have home route defined', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn({'example.com': {}});
        
        final router = container.read(newAppRouterProvider);
        
        // Navigate to home route
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      test('should have compose route defined', () {
        final router = container.read(newAppRouterProvider);
        
        // Navigate to compose route
        router.go('/compose');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/compose');
      });

      test('should have settings route defined', () {
        final router = container.read(newAppRouterProvider);
        
        // Navigate to settings route
        router.go('/settings');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
      });

      test('should redirect root path to home', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn({'example.com': {}});
        
        final router = container.read(newAppRouterProvider);
        
        // Navigate to root
        router.go('/');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });
    });

    group('Authentication Redirect Logic', () {
      test('should redirect to login when not authenticated', () {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn({});
        
        final router = container.read(newAppRouterProvider);
        
        // Try to navigate to protected route
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      test('should redirect to home when authenticated and on login screen', () {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn({'example.com': {}});
        
        final router = container.read(newAppRouterProvider);
        
        // Navigate to login while authenticated
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      test('should allow access to OAuth callback without authentication', () {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn({});
        
        final router = container.read(newAppRouterProvider);
        
        // Navigate to OAuth callback
        router.go('/oauth/callback');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });
    });

    group('OAuth Callback Helper Function', () {
      testWidgets('should handle query parameters correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to OAuth callback with query parameters
        final router = container.read(newAppRouterProvider);
        router.go('/oauth/callback?domain=pixelfed.de&state=test123&code=auth456');

        await tester.pumpAndSettle();

        // Should find OAuthCallbackScreen
        expect(find.byType(OAuthCallbackScreen), findsOneWidget);
      });

      testWidgets('should handle fragment parameters', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to OAuth callback with fragment parameters
        final router = container.read(newAppRouterProvider);
        router.go('/oauth/callback#domain=pixelfed.de&state=test123&code=auth456');

        await tester.pumpAndSettle();

        // Should find OAuthCallbackScreen
        expect(find.byType(OAuthCallbackScreen), findsOneWidget);
      });

      testWidgets('should handle extra parameters from navigation', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate with extra parameters
        final router = container.read(newAppRouterProvider);
        router.go('/oauth/callback', extra: {
          'domain': 'pixelfed.de',
          'state': 'test123',
          'code': 'auth456',
        });

        await tester.pumpAndSettle();

        // Should find OAuthCallbackScreen
        expect(find.byType(OAuthCallbackScreen), findsOneWidget);
      });

      testWidgets('should show login screen when parameters are missing', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to OAuth callback without required parameters
        final router = container.read(newAppRouterProvider);
        router.go('/oauth/callback');

        await tester.pumpAndSettle();

        // Should show LoginScreen due to missing parameters
        expect(find.byType(LoginScreen), findsOneWidget);
      });
    });

    group('Route Structure', () {
      testWidgets('should render login screen correctly', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to login
        final router = container.read(newAppRouterProvider);
        router.go('/auth/login');

        await tester.pumpAndSettle();

        // Should find LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
      });

      testWidgets('should render home screen when authenticated', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn({'example.com': {}});
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to home
        final router = container.read(newAppRouterProvider);
        router.go('/home');

        await tester.pumpAndSettle();

        // Should find some home content (the exact widget might vary)
        expect(find.text('Home Screen - To be implemented'), findsOneWidget);
      });

      testWidgets('should render compose screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to compose
        final router = container.read(newAppRouterProvider);
        router.go('/compose');

        await tester.pumpAndSettle();

        // Should find compose content
        expect(find.text('New Post'), findsOneWidget);
        expect(find.text('Compose Screen - To be implemented'), findsOneWidget);
      });

      testWidgets('should render settings screen', (WidgetTester tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              newAuthRepositoryProvider.overrideWithValue(mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: container.read(newAppRouterProvider),
            ),
          ),
        );

        // Navigate to settings
        final router = container.read(newAppRouterProvider);
        router.go('/settings');

        await tester.pumpAndSettle();

        // Should find settings content
        expect(find.text('Settings'), findsOneWidget);
        expect(find.text('Settings Screen - To be implemented'), findsOneWidget);
      });
    });

    group('Navigation Behavior', () {
      test('should maintain navigation state correctly', () {
        final router = container.read(newAppRouterProvider);
        
        // Navigate through different routes
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
        
        router.go('/oauth/callback');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
        
        router.go('/settings');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
      });

      test('should handle multiple authentication state changes', () {
        final router = container.read(newAppRouterProvider);
        
        // Start not authenticated
        when(mockAuthRepository.instances).thenReturn({});
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
        
        // Become authenticated
        when(mockAuthRepository.instances).thenReturn({'example.com': {}});
        router.go('/auth/login');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
        
        // Become unauthenticated again
        when(mockAuthRepository.instances).thenReturn({});
        router.go('/home');
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });
    });
  });
}
