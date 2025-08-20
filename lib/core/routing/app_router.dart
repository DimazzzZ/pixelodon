import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';
import 'package:pixelodon/features/settings/screens/settings_screen.dart';
import 'package:pixelodon/providers/auth_provider.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    
    // Global redirect function to handle authentication
    redirect: (context, state) {
      // Check if the user is authenticated
      final isLoggedIn = authRepository.instances.isNotEmpty;
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isOAuthCallback = state.matchedLocation == '/oauth/callback';
      
      // If on root path, redirect based on authentication status
      if (state.matchedLocation == '/') {
        return isLoggedIn ? '/home' : '/auth/login';
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
            builder: (context, state) => const Center(
              child: Text('Explore Screen - To be implemented'),
            ),
          ),
          
          // Notifications route
          GoRoute(
            path: '/notifications',
            builder: (context, state) => const Center(
              child: Text('Notifications Screen - To be implemented'),
            ),
          ),
          
          // Profile route
          GoRoute(
            path: '/profile',
            builder: (context, state) => const Center(
              child: Text('Profile Screen - To be implemented'),
            ),
          ),
        ],
      ),
      
      // Routes outside the shell
      GoRoute(
        path: '/compose',
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('New Post')),
          body: const Center(
            child: Text('Compose Screen - To be implemented'),
          ),
        ),
      ),

      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
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
