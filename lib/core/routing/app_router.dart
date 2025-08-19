import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/features/auth/screens/login_screen.dart';
import 'package:pixelodon/features/auth/screens/oauth_callback_screen.dart';
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
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          
          // Check query parameters first (for deep links)
          final queryParams = state.uri.queryParameters;
          final queryDomain = queryParams['domain'];
          final queryState = queryParams['state'];
          final queryCode = queryParams['code'];
          
          debugPrint('Auth callback route - Query parameters: $queryParams');
          debugPrint('Auth callback route - Extra parameters: $extra');
          
          // Check fragment for parameters if they're not in query string
          String? fragmentDomain;
          String? fragmentState;
          String? fragmentCode;
          
          if (state.uri.fragment.isNotEmpty) {
            debugPrint('Auth callback route - Checking fragment: ${state.uri.fragment}');
            final fragmentParams = Uri.splitQueryString(state.uri.fragment);
            fragmentDomain = fragmentParams['domain'];
            fragmentState = fragmentParams['state'];
            fragmentCode = fragmentParams['code'];
            
            debugPrint('Auth callback route - Fragment domain: $fragmentDomain');
            debugPrint('Auth callback route - Fragment state: $fragmentState');
            debugPrint('Auth callback route - Fragment code: $fragmentCode');
          }
          
          // If we have parameters from fragment, use them
          if (fragmentDomain != null && fragmentState != null) {
            return OAuthCallbackScreen(
              domain: fragmentDomain,
              state: fragmentState,
              code: fragmentCode,
            );
          }
          
          // If we have parameters from query string, use them
          if (queryDomain != null && queryState != null) {
            return OAuthCallbackScreen(
              domain: queryDomain,
              state: queryState,
              code: queryCode,
            );
          }
          
          // If we have the domain and state from the login screen, use them
          if (extra != null && extra.containsKey('domain') && extra.containsKey('state')) {
            return OAuthCallbackScreen(
              domain: extra['domain']!,
              state: extra['state']!,
              // No code here as this is the initial navigation to the callback screen
            );
          }
          
          // Otherwise, redirect to login
          return const LoginScreen();
        },
      ),
      
      // Handle callback with proper path format (for deep links)
      GoRoute(
        path: '/auth/callback',
        builder: (context, state) {
          debugPrint('Auth callback route - URI: ${state.uri}');
          
          // Get parameters from query string
          final queryParams = state.uri.queryParameters;
          final domain = queryParams['domain'];
          final oauthState = queryParams['state'];
          
          debugPrint('Auth callback route - Query parameters: $queryParams');
          
          // Check fragment for parameters if they're not in query string
          if ((domain == null || oauthState == null) && state.uri.fragment.isNotEmpty) {
            debugPrint('Auth callback route - Checking fragment: ${state.uri.fragment}');
            final fragmentParams = Uri.splitQueryString(state.uri.fragment);
            final fragmentDomain = fragmentParams['domain'];
            final fragmentState = fragmentParams['state'];
            
            if (fragmentDomain != null && fragmentState != null) {
              return OAuthCallbackScreen(
                domain: fragmentDomain,
                state: fragmentState,
              );
            }
          }
          
          if (domain != null && oauthState != null) {
            return OAuthCallbackScreen(
              domain: domain,
              state: oauthState,
            );
          }
          
          return const LoginScreen();
        },
      ),
      // Handle deep link callback from OAuth provider
      GoRoute(
        path: '/oauth/callback',
        builder: (context, state) {
          // Get the domain, state, and code from the query parameters
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
          
          if (domain != null && oauthState != null) {
            // Redirect to the auth callback route with the parameters
            // This ensures consistent handling of the callback
            return OAuthCallbackScreen(
              domain: domain,
              state: oauthState,
              code: code,
            );
          }
          
          // If we don't have the required parameters, redirect to login
          return const LoginScreen();
        },
      ),
      
      // Handle callback with proper path format (for deep links)
      GoRoute(
        path: '/oauth/callback',
        builder: (context, state) {
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
          
          if (domain != null && oauthState != null) {
            return OAuthCallbackScreen(
              domain: domain,
              state: oauthState,
              code: code,
            );
          }
          
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
            builder: (context, state) => const Center(
              child: Text('Home Screen - To be implemented'),
            ),
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
