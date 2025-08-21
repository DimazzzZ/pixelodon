import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/features/compose/screens/compose_screen.dart';
import 'package:pixelodon/features/explore/screens/explore_screen.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';
import 'package:pixelodon/features/notifications/screens/notifications_screen.dart';
import 'package:pixelodon/features/profile/screens/profile_screen.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/features/splash/screens/splash_screen.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/features/status/screens/status_detail_screen.dart';
import 'package:pixelodon/features/tags/screens/tag_timeline_screen.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    
    // Global redirect function to handle authentication
    redirect: (context, state) {
      // Check if the user is authenticated using ref.read to avoid circular dependency
      final authRepository = ref.read(authRepositoryProvider);
      final isLoggedIn = authRepository.instances.isNotEmpty;
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isOAuthCallback = state.matchedLocation == '/oauth/callback';
      final isSplash = state.matchedLocation == '/splash';
      
      // Always allow splash screen
      if (isSplash) {
        return null;
      }
      
      // If on root path, redirect to splash
      if (state.matchedLocation == '/') {
        return '/splash';
      }
      
      // If the user is not logged in and not on the login screen or OAuth callback, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isOAuthCallback) {
        return '/auth/login';
      }
      
      // If the user is logged in and on the login screen, allow it (for adding accounts)
      // But don't redirect if on the callback screen
      if (isLoggedIn && isLoggingIn && state.matchedLocation != '/auth/callback' && state.matchedLocation != '/auth/login') {
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
      
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // OAuth callback route
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) => _buildOAuthCallbackScreen(state),
      ),
      
      // Handle deep link callback from OAuth provider
      GoRoute(
        path: '/oauth/callback',
        builder: (context, state) => _buildOAuthCallbackScreen(state),
      ),
      
      // Main app shell route
      ShellRoute(
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
              final container = ProviderScope.containerOf(context);
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
              return MaterialPage(
                key: UniqueKey(),
                child: ProfileScreen(accountId: accountId),
              );
            },
          ),
        ],
      ),
      
      // Routes outside the shell
      GoRoute(
        path: '/compose',
        builder: (context, state) => const ComposeScreen(),
      ),
      
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      
      // Status detail route
      GoRoute(
        path: '/status/:statusId',
        pageBuilder: (context, state) {
          final statusId = state.pathParameters['statusId']!;
          return MaterialPage(
            key: UniqueKey(),
            child: StatusDetailScreen(statusId: statusId),
          );
        },
      ),

      // Tag timeline route
      GoRoute(
        path: '/tag/:tag',
        pageBuilder: (context, state) {
          final tag = state.pathParameters['tag']!;
          return MaterialPage(
            key: UniqueKey(),
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
});

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
