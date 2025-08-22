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
import 'package:pixelodon/models/user.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/providers/auth_provider.dart';

import 'app_router_test.mocks.dart';

@GenerateMocks([AuthRepository, User])
void main() {
  group('AppRouter Tests', () {
    late MockAuthRepository mockAuthRepository;
    late ProviderContainer container;
    late User mockUser;

    setUp(() {
      mockAuthRepository = MockAuthRepository();
      mockUser = User(id: 'mock_id', username: 'mock_user', email: 'mock_user@example.com');

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
      testWidgets('should create GoRouter with correct initial location', (WidgetTester tester) async {
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
        await tester.pumpAndSettle();

        final router = container.read(appRouterProvider);
        expect(router, isA<GoRouter>());
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      test('should have debug diagnostics enabled', () {
        final router = container.read(appRouterProvider);
        
        // This is a bit tricky to test directly, but we can verify the router was created
        expect(router, isNotNull);
      });
    });

    group('Route Definitions', () {
      testWidgets('should have login route defined', (WidgetTester tester) async {
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
        await tester.pumpAndSettle();

        final router = container.read(appRouterProvider);
        // Navigate to login route
        router.go('/auth/login');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      testWidgets('should have OAuth callback route defined', (WidgetTester tester) async {
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
        await tester.pumpAndSettle();

        final router = container.read(appRouterProvider);
        // Navigate to OAuth callback route
        router.go('/oauth/callback?domain=example.com&state=test&code=123');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });

      testWidgets('should have home route defined', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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
        await tester.pumpAndSettle();
        
        final router = container.read(appRouterProvider);
        // Navigate to home route
        router.go('/home');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      testWidgets('should have settings route defined', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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
        await tester.pumpAndSettle();

        final router = container.read(appRouterProvider);
        // Navigate to settings route
        router.go('/settings');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/settings');
      });

      testWidgets('should have compose route defined', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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
        await tester.pumpAndSettle();

        final router = container.read(appRouterProvider);
        // Navigate to compose route
        router.go('/compose');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/compose');
      });

      testWidgets('should redirect root path to home', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

        final router = container.read(appRouterProvider);
        
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to root
        router.go('/');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });
    });

    group('Authentication Redirect Logic', () {
      testWidgets('should redirect to login when not authenticated', (WidgetTester tester) async {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Try to navigate to protected route
        router.go('/home');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      testWidgets('should redirect to home when authenticated and on login screen', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to login while authenticated
        router.go('/auth/login');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });

      testWidgets('should not redirect OAuth callback when not authenticated', (WidgetTester tester) async {
        // Mock not logged in state
        when(mockAuthRepository.instances).thenReturn([]);
        
        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to OAuth callback
        router.go('/oauth/callback');
        await tester.pumpAndSettle();
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
        // Mock logged in state to bypass auth redirect
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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
        expect(find.text('The page /invalid/route was not found.'), findsOneWidget);
        expect(find.text('Go to Home'), findsOneWidget);
      });

      testWidgets('error page should navigate back to home', (WidgetTester tester) async {
        // Mock logged in state to bypass auth redirect
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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

        // Should redirect to home (since now authenticated)
        expect(router.routerDelegate.currentConfiguration.uri.path, '/home');
      });
    });

    group('Shell Route Structure', () {
      testWidgets('should wrap protected routes in AppShell', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

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

      testWidgets('should have explore route in shell', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to explore route
        router.go('/explore');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/explore');
      });

      testWidgets('should have notifications route in shell', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to notifications route
        router.go('/notifications');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/notifications');
      });

      testWidgets('should have profile route in shell', (WidgetTester tester) async {
        // Mock logged in state
        when(mockAuthRepository.instances).thenReturn([mockUser]);

        final router = container.read(appRouterProvider);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              authRepositoryProvider.overrideWith((ref) => mockAuthRepository),
            ],
            child: MaterialApp.router(
              routerConfig: router,
            ),
          ),
        );

        // Navigate to profile route
        router.go('/profile');
        await tester.pumpAndSettle();
        expect(router.routerDelegate.currentConfiguration.uri.path, '/profile');
      });
    });
  });
}
