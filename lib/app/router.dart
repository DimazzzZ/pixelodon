import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/login_page.dart';
import '../features/timeline/presentation/timeline_page.dart';
import '../features/accounts/presentation/account_switcher_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const TimelinePage(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountSwitcherPage(),
      ),
    ],
  );
});

