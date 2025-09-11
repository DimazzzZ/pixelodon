import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app_links/app_links.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/features/compose/screens/compose_screen.dart';
import 'package:pixelodon/features/explore/screens/explore_screen.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';
import 'package:pixelodon/features/notifications/screens/notifications_screen.dart';
import 'package:pixelodon/features/profile/presentation/screens/profile_screen.dart';
import 'package:pixelodon/features/profile/domain/profile_usecases.dart';
import 'package:pixelodon/features/profile/screens/follow_list_screen.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/features/splash/screens/splash_screen.dart';
import 'package:pixelodon/providers/auth_provider.dart';

import 'package:pixelodon/features/status/screens/status_detail_screen.dart';
import 'package:pixelodon/features/tags/screens/tag_timeline_screen.dart';
import 'package:pixelodon/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pixelodon/features/guest/screens/guest_screen.dart';
import 'package:pixelodon/features/guest/screens/guest_status_detail_screen.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
final _shellNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'shell');

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    navigatorKey: rootNavigatorKey,
    
    // Global redirect function to handle authentication and onboarding
    redirect: (context, state) {
      // Check if the user is authenticated using ref.read to avoid circular dependency
      final authRepository = ref.read(authRepositoryProvider);
      final isLoggedIn = authRepository.instances.isNotEmpty;
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isOAuthCallback = state.matchedLocation == '/oauth/callback';
      final isSplash = state.matchedLocation == '/splash';
      final isOnboarding = state.matchedLocation == '/onboarding';

      // Note: onboarding completion is checked in individual route logic
      
      // Always allow splash screen and onboarding
      if (isSplash || isOnboarding) {
        return null;
      }
      
      // If on root path, redirect based on auth state
      if (state.matchedLocation == '/') {
        if (isLoggedIn) {
          return '/home';
        } else {
          // Always show onboarding for non-authenticated users
          return '/onboarding';
        }
      }

      // If the user is not logged in and not on auth/onboarding/guest screens, redirect to onboarding
      if (!isLoggedIn && !isLoggingIn && !isOAuthCallback &&
          !state.matchedLocation.startsWith('/guest') &&
          !state.matchedLocation.startsWith('/status/')) {
        // Allow direct access to login, guest mode, and status pages (which will redirect to guest)
        if (state.matchedLocation == '/auth/login' || state.matchedLocation == '/guest') {
          return null;
        }
        return '/onboarding';
      }
      
      // If the user is logged in and on the login/onboarding screen, allow it (for adding accounts)
      // But don't redirect if on the callback screen
      if (isLoggedIn && (isLoggingIn || isOnboarding) && 
          state.matchedLocation != '/auth/callback' && 
          state.matchedLocation != '/auth/login') {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
    
    // Error handler for the router
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(
        title: const Text('Page Not Found'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Page not found: ${state.matchedLocation}',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    ),
    
    // Define all routes
    routes: [
      // Splash screen route
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // Onboarding route for new users
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      
      // Auth routes
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Guest mode route
      GoRoute(
        path: '/guest',
        builder: (context, state) {
          final instance = state.uri.queryParameters['instance'];
          return GuestScreen(instance: instance);
        },
      ),

      // Guest status detail route
      GoRoute(
        path: '/guest/status/:statusId',
        pageBuilder: (context, state) {
          final statusId = state.pathParameters['statusId']!;
          return MaterialPage(
            child: GuestStatusDetailScreen(statusId: statusId),
          );
        },
      ),
      
      // OAuth callback route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/auth/callback',
        builder: (context, state) => _buildOAuthCallbackScreen(state),
      ),
      
      // Handle deep link callback from OAuth provider
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/oauth/callback',
        builder: (context, state) => _buildOAuthCallbackScreen(state),
      ),
      
      // Main app shell route
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          // Home route
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          
          // Explore route
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          
          // Notifications route
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const NotificationsScreen(),
          ),
          
          // Profile route - current user
          GoRoute(
            path: '/profile',
            redirect: (context, state) {
              // Get current user's account ID from provider
              final container = ProviderScope.containerOf(context, listen: false);
              final activeAccount = container.read(activeAccountProvider);
              if (activeAccount != null) {
                return '/profile/${activeAccount.id}';
              }
              // If no active account, redirect to home
              return '/home';
            },
          ),
          
          // Profile route - specific user
          GoRoute(
            path: '/profile/:accountId',
            pageBuilder: (context, state) {
              final accountId = state.pathParameters['accountId']!;
              final username = state.uri.queryParameters['username'];
              final domain = state.uri.queryParameters['domain'];
              return MaterialPage(
                child: ProfileScreen(
                  args: ProfileRouteArgs(
                    userId: accountId,
                    username: username,
                    domain: domain,
                  ),
                ),
              );
            },
          ),

          // Following list
          GoRoute(
            path: '/profile/:accountId/following',
            pageBuilder: (context, state) {
              final accountId = state.pathParameters['accountId']!;
              final domain = state.uri.queryParameters['domain'];
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: FollowListScreen(accountId: accountId, type: FollowListType.following, domainOverride: domain),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                        CurveTween(curve: Curves.easeInOut),
                      ),
                    ),
                    child: child,
                  );
                },
              );
            },
          ),

          // Followers list
          GoRoute(
            path: '/profile/:accountId/followers',
            pageBuilder: (context, state) {
              final accountId = state.pathParameters['accountId']!;
              final domain = state.uri.queryParameters['domain'];
              return CustomTransitionPage<void>(
                key: state.pageKey,
                child: FollowListScreen(accountId: accountId, type: FollowListType.followers, domainOverride: domain),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return SlideTransition(
                    position: animation.drive(
                      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero).chain(
                        CurveTween(curve: Curves.easeInOut),
                      ),
                    ),
                    child: child,
                  );
                },
              );
            },
          ),

        ],
      ),
      
      // Routes outside the shell
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/compose',
        builder: (context, state) => const ComposeScreen(),
      ),
      
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Status detail route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/status/:statusId',
        pageBuilder: (context, state) {
          final statusId = state.pathParameters['statusId']!;
          return MaterialPage(
            child: StatusDetailScreen(statusId: statusId),
          );
        },
        redirect: (context, state) {
          // Check if user is not authenticated and redirect to guest mode
          final authRepository = ref.read(authRepositoryProvider);
          final isLoggedIn = authRepository.instances.isNotEmpty;

          if (!isLoggedIn) {
            final statusId = state.pathParameters['statusId']!;
            return '/guest/status/$statusId';
          }

          return null; // No redirect needed
        },
      ),

      // Tag timeline route
      GoRoute(
        parentNavigatorKey: rootNavigatorKey,
        path: '/tag/:tag',
        pageBuilder: (context, state) {
          final tag = state.pathParameters['tag']!;
          return MaterialPage(
            child: TagTimelineScreen(tag: tag),
          );
        },
      ),
      
      // Fallback route
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
    ],
  );

  // Set up deep link handling for OAuth callbacks (only in non-test environments)
  if (!kIsWeb && !const bool.fromEnvironment('flutter.test')) {
    _setupDeepLinkHandling(router);
  }

  // Ensure initial configuration is set for tests and non-widget contexts
  // This makes router.routerDelegate.currentConfiguration available immediately
  // without needing a MaterialApp.router to mount the router.
  // Do not force navigation here; let initialLocation and SplashScreen control the flow.
  return router;
});

/// Set up deep link handling for OAuth callbacks
void _setupDeepLinkHandling(GoRouter router) {
  final appLinks = AppLinks();

  // Handle initial link if app was launched from a deep link
  appLinks.getInitialAppLink().then((uri) {
    if (uri != null) {
      _handleDeepLink(router, uri);
    }
  });

  // Listen for deep links while app is running
  appLinks.uriLinkStream.listen((uri) {
    _handleDeepLink(router, uri);
  });
}

/// Handle incoming deep links
void _handleDeepLink(GoRouter router, Uri uri) async {
  debugPrint('Received deep link: $uri');

  // Check if this is an OAuth callback
  if (uri.scheme == 'pixelodon' && uri.host == 'oauth' && uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'callback') {
    debugPrint('Processing OAuth callback deep link');

    // Extract parameters from the deep link
    final code = uri.queryParameters['code'];
    final state = uri.queryParameters['state'];
    final error = uri.queryParameters['error'];

    debugPrint('Deep link parameters - code: $code, state: $state, error: $error');

    // Navigate to OAuth callback route with parameters
    if (code != null && state != null) {
      // Retrieve the domain from the stored state
      final authService = AuthService();
      final domain = await authService.getDomainFromState(state);

      if (domain != null) {
        debugPrint('Retrieved domain from state: $domain');
        router.go('/oauth/callback', extra: {
          'code': code,
          'state': state,
          'domain': domain,
        });
      } else {
        debugPrint('Could not retrieve domain for state: $state');
        router.go('/auth/login');
      }
    } else if (error != null) {
      // Handle OAuth error
      debugPrint('OAuth error from deep link: $error');
      router.go('/auth/login');
    } else {
      debugPrint('Invalid OAuth callback deep link - missing required parameters');
      router.go('/auth/login');
    }
  }
}

/// Helper function to build the OAuth callback screen
Widget _buildOAuthCallbackScreen(GoRouterState state) {
  debugPrint('OAuth callback route - URI: ${state.uri}');
  
  // Get parameters from query string
  final queryParams = state.uri.queryParameters;
  final domain = queryParams['domain'];
  final oauthState = queryParams['state'];
  final code = queryParams['code'];
  
  debugPrint('OAuth callback route - Query parameters: $queryParams');
  
  // Check fragment for parameters if they're not in query string
  if ((domain == null || oauthState == null || code == null) && state.uri.fragment.isNotEmpty) {
    debugPrint('OAuth callback route - Checking fragment: ${state.uri.fragment}');
    final fragmentParams = Uri.splitQueryString(state.uri.fragment);
    final fragmentDomain = fragmentParams['domain'];
    final fragmentState = fragmentParams['state'];
    final fragmentCode = fragmentParams['code'];
    
    if (fragmentDomain != null && fragmentState != null) {
      return OAuthCallbackScreen(
        domain: fragmentDomain,
        state: fragmentState,
        code: fragmentCode,
      );
    }
  }
  
  // Check extra parameters from navigation
  final extra = state.extra as Map<String, dynamic>?;
  if (extra != null && extra.containsKey('domain') && extra.containsKey('state')) {
    return OAuthCallbackScreen(
      domain: extra['domain']!,
      state: extra['state']!,
      code: extra['code'],
    );
  }
  
  // If we have parameters from query string, use them
  if (domain != null && oauthState != null) {
    return OAuthCallbackScreen(
      domain: domain,
      state: oauthState,
      code: code,
    );
  }
  
  // If we don't have the required parameters, redirect to login
  return const LoginScreen();
}
