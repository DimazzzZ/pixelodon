import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/oauth_callback_screen.dart';
import '../providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final router = RouterNotifier(ref);

  return GoRouter(
    refreshListenable: router,
    redirect: router._redirectLogic,
    routes: router._routes,
  );
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(activeInstanceProvider, (_, __) => notifyListeners());
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final activeInstance = _ref.read(activeInstanceProvider);
    final isAuth = activeInstance != null;

    // If the user is not logged in and trying to access a protected route
    if (!isAuth && state.matchedLocation != '/login') {
      return '/login';
    }

    // If the user is logged in and trying to access auth routes
    if (isAuth && (state.matchedLocation == '/login')) {
      return '/';
    }

    return null;
  }

  List<RouteBase> get _routes => [
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: '/auth/callback',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return OAuthCallbackScreen(
              domain: extra?['domain'] ?? '',
              state: extra?['state'],
            );
          },
        ),
        GoRoute(
          path: '/',
          builder: (context, state) => const Scaffold(
            body: Center(child: Text('Home Screen')),
          ),
        ),
        // Add more routes here
      ];
}
