import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/core/routing/app_router.dart';
import 'package:pixelodon/features/splash/screens/splash_screen.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/services/auth_service.dart';

import '../../test_support/platform_mocks.dart';

import 'app_router_test.mocks.dart';

@GenerateNiceMocks([MockSpec<AuthService>()])
void main() {
  // Set up platform channel mocks before all tests
  setUpAll(() {
    setupPlatformChannelMocks();
    // Enable test mode to skip splash screen delay
    SplashScreen.testMode = true;
  });
  
  tearDownAll(() {
    // Reset test mode
    SplashScreen.testMode = false;
  });

  group('AppRouter Tests', () {
    late MockAuthService mockAuthService;
    late Instance mockInstance;
    late Account mockAccount;

    setUp(() {
      mockInstance = const Instance(domain: 'example.com', name: 'Example Instance');
      mockAccount = const Account(
        id: 'mock_account_id',
        username: 'mock_user',
        acct: 'mock_user@example.com',
        displayName: 'Mock User',
      );
      
      mockAuthService = MockAuthService();
      
      // Default: unauthenticated state
      when(mockAuthService.getAuthenticatedInstances())
          .thenAnswer((_) async => []);
      when(mockAuthService.getAccessToken(any))
          .thenAnswer((_) async => null);
      when(mockAuthService.isAuthenticated(any))
          .thenAnswer((_) async => false);
    });

    /// Helper to create a ProviderContainer with mocked auth service
    ProviderContainer createUnauthenticatedContainer() {
      return ProviderContainer(
        overrides: [
          authServiceProvider.overrideWithValue(mockAuthService),
        ],
      );
    }

    /// Helper to pump the router widget and return the router
    Future<GoRouter> pumpRouterApp(
      WidgetTester tester,
      ProviderContainer container, {
      required String startAt,
    }) async {
      // Initialize auth repository first to ensure state is ready
      await container.read(authRepositoryProvider.notifier).initialize();
      
      final router = container.read(appRouterProvider);
      
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      
      // Build the widget tree
      await tester.pump();
      
      // Navigate to the start location
      router.go(startAt);
      
      // Allow frame callbacks and navigation to settle
      await tester.pump();
      await tester.pump();
      await tester.pump();
      
      return router;
    }

    group('Router Configuration', () {
      testWidgets('should create GoRouter instance', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        final router = await pumpRouterApp(tester, container, startAt: '/auth/login');
        
        expect(router, isA<GoRouter>());
      });
    });

    group('Route Navigation - Unauthenticated', () {
      testWidgets('should navigate to login route', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        final router = await pumpRouterApp(tester, container, startAt: '/auth/login');

        expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
      });

      testWidgets('should navigate to onboarding route', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        final router = await pumpRouterApp(tester, container, startAt: '/onboarding');

        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect protected route to onboarding', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /settings when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/settings');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect /home to onboarding when not authenticated', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /home when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/home');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect /compose to onboarding when not authenticated', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /compose when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/compose');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect /explore to onboarding when not authenticated', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /explore when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/explore');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect /notifications to onboarding when not authenticated', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /notifications when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/notifications');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });

      testWidgets('should redirect /profile to onboarding when not authenticated', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        // Try to navigate to /profile when not authenticated
        final router = await pumpRouterApp(tester, container, startAt: '/profile');

        // Should be redirected to onboarding
        expect(router.routerDelegate.currentConfiguration.uri.path, '/onboarding');
      });
    });

    group('OAuth Callback Route', () {
      testWidgets('should navigate to OAuth callback route', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        final router = await pumpRouterApp(tester, container, startAt: '/oauth/callback');

        expect(router.routerDelegate.currentConfiguration.uri.path, '/oauth/callback');
      });
    });

    group('Error Handling', () {
      testWidgets('should handle invalid routes for unauthenticated user', (WidgetTester tester) async {
        final container = createUnauthenticatedContainer();
        addTearDown(container.dispose);
        
        final router = await pumpRouterApp(tester, container, startAt: '/invalid/route');

        // Unauthenticated users may get redirected or see error page
        expect(router.routerDelegate.currentConfiguration.uri.path, anyOf('/onboarding', '/invalid/route'));
      });
    });

    // Note: Tests for authenticated routes are currently skipped because they trigger
    // API calls (timeline, notifications, etc.) which create pending timers.
    // To test authenticated routes fully, the ApiService and timeline providers
    // would need to be mocked as well.
  });
}
