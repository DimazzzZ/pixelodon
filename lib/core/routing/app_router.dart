import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';
import 'package:pixelodon/providers/new_auth_provider.dart';

/// Provider for the app router
final appRouterProvider = Provider<GoRouter>((ref) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  
  return GoRouter(
    initialLocation: '/auth/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Check if the user is authenticated
      final isLoggedIn = authRepository.instances.isNotEmpty;
      final isLoggingIn = state.matchedLocation.startsWith('/auth');
      final isOAuthCallback = state.matchedLocation == '/oauth/callback';
      
      // If the user is not logged in and not on the login screen or OAuth callback, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isOAuthCallback) {
        return '/auth/login';
      }
      
      // If the user is logged in and on the login screen, redirect to home
      // But don't redirect if on the callback screen
      if (isLoggedIn && isLoggingIn && state.matchedLocation != '/auth/callback') {
        return '/home';
      }
      
      // No redirect needed
      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/login',
        builder: (context, state) => const LoginScreen(),
      ),
      // Handle OAuth callback - both for navigation from login screen and deep links
      GoRoute(
        path: '/oauth/callback',
        builder: (context, state) {
          debugPrint('OAuth callback route - URI: ${state.uri}');
          debugPrint('OAuth callback route - Full URI: ${state.uri}');
          
          // Get parameters from query string (from deep link)
          final queryParams = state.uri.queryParameters;
          final queryDomain = queryParams['domain'];
          final queryState = queryParams['state'];
          final queryCode = queryParams['code'];
          
          debugPrint('OAuth callback route - Query parameters: $queryParams');
          
          // Get parameters from extra data (from navigation)
          final extra = state.extra as Map<String, dynamic>?;
          debugPrint('OAuth callback route - Extra parameters: $extra');
          
          // Check fragment for parameters if they're not in query string
          String? fragmentDomain;
          String? fragmentState;
          String? fragmentCode;
          
          if (state.uri.fragment.isNotEmpty) {
            debugPrint('OAuth callback route - Checking fragment: ${state.uri.fragment}');
            final fragmentParams = Uri.splitQueryString(state.uri.fragment);
            fragmentDomain = fragmentParams['domain'];
            fragmentState = fragmentParams['state'];
            fragmentCode = fragmentParams['code'];
            
            debugPrint('OAuth callback route - Fragment domain: $fragmentDomain');
            debugPrint('OAuth callback route - Fragment state: $fragmentState');
            debugPrint('OAuth callback route - Fragment code: $fragmentCode');
          }
          
          // Priority: query params > fragment params > extra params
          final domain = queryDomain ?? fragmentDomain ?? extra?['domain'];
          final oauthState = queryState ?? fragmentState ?? extra?['state'];
          final code = queryCode ?? fragmentCode;
          
          debugPrint('OAuth callback route - Final domain: $domain');
          debugPrint('OAuth callback route - Final state: $oauthState');
          debugPrint('OAuth callback route - Final code: $code');
          
          if (domain != null && oauthState != null) {
            return OAuthCallbackScreen(
              domain: domain,
              state: oauthState,
              code: code,
            );
          }
          
          // If we don't have the required parameters, redirect to login
          debugPrint('OAuth callback route - Missing required parameters, redirecting to login');
          return const LoginScreen();
        },
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
        builder: (context, state) => Scaffold(
          appBar: AppBar(title: const Text('Settings')),
          body: const Center(
            child: Text('Settings Screen - To be implemented'),
          ),
        ),
      ),
      
      // Fallback route
      GoRoute(
        path: '/',
        redirect: (_, __) => '/home',
      ),
    ],
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
  );
});
