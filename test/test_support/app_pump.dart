import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/core/routing/app_router.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/services/timeline_service.dart';

/// Test utilities for pumping the app with various configurations
class AppPump {
  /// Pump app with basic MaterialApp wrapper and ProviderScope
  static Future<void> pumpApp(
    WidgetTester tester,
    Widget child, {
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeMode,
          home: child,
        ),
      ),
    );
  }

  /// Pump app with router for navigation testing
  static Future<void> pumpAppWithRouter(
    WidgetTester tester, {
    String initialLocation = '/',
    List<Override> overrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appRouterProvider.overrideWith((ref) => GoRouter(
            initialLocation: initialLocation,
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Scaffold(
                  body: Center(child: Text('Test Home')),
                ),
              ),
            ],
          )),
          ...overrides,
        ],
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              themeMode: themeMode,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }

  /// Pump app with authenticated state and active instance
  static Future<void> pumpAuthenticatedApp(
    WidgetTester tester,
    Widget child, {
    Instance? instance,
    List<Override> additionalOverrides = const [],
    ThemeMode themeMode = ThemeMode.light,
  }) async {
    final testInstance = instance ??
        const Instance(
          domain: 'test.example.com',
          name: 'Test Instance',
          isPixelfed: false,
        );

    final overrides = [
      activeInstanceProvider.overrideWith((ref) => testInstance),
      ...additionalOverrides,
    ];

    await pumpApp(tester, child, overrides: overrides, themeMode: themeMode);
  }

  /// Pump app with mocked timeline service
  static Future<void> pumpWithMockedTimeline(
    WidgetTester tester,
    Widget child, {
    TimelineService? mockTimelineService,
    Instance? instance,
    List<Override> additionalOverrides = const [],
  }) async {
    final testInstance = instance ??
        const Instance(
          domain: 'test.example.com',
          name: 'Test Instance',
          isPixelfed: false,
        );

    final overrides = [
      activeInstanceProvider.overrideWith((ref) => testInstance),
      if (mockTimelineService != null)
        timelineServiceProvider.overrideWithValue(mockTimelineService),
      appRouterProvider.overrideWith((ref) => GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => child,
          ),
          GoRoute(
            path: '/status/:id',
            builder: (context, state) => Scaffold(
              appBar: AppBar(title: const Text('Status Detail')),
              body: Center(child: Text('Status ${state.pathParameters['id']}')),
            ),
          ),
        ],
      )),
      ...additionalOverrides,
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: Consumer(
          builder: (context, ref, child) {
            final router = ref.watch(appRouterProvider);
            return MaterialApp.router(
              theme: ThemeData.light(),
              darkTheme: ThemeData.dark(),
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}

/// Extension methods for common pump operations
extension WidgetTesterExtensions on WidgetTester {
  /// Bounded pumpAndSettle to avoid infinite loops
  Future<void> pumpAndSettleSafely({
    Duration timeout = const Duration(seconds: 10),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (binding.hasScheduledFrame && stopwatch.elapsed < timeout) {
      await pump(interval);
    }
    
    stopwatch.stop();
  }

  /// Pump until a widget is found or timeout
  Future<bool> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout) {
      await pump(interval);
      
      if (finder.evaluate().isNotEmpty) {
        stopwatch.stop();
        return true;
      }
    }
    
    stopwatch.stop();
    return false;
  }

  /// Pump while a widget is visible
  Future<void> pumpWhileVisible(
    Finder finder, {
    Duration timeout = const Duration(seconds: 5),
    Duration interval = const Duration(milliseconds: 100),
  }) async {
    final stopwatch = Stopwatch()..start();
    
    while (stopwatch.elapsed < timeout && finder.evaluate().isNotEmpty) {
      await pump(interval);
    }
    
    stopwatch.stop();
  }

  /// Wait for animations to complete
  Future<void> waitForAnimations({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await pumpAndSettle(timeout);
  }
}
