import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user.dart';
import 'auth_state.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(AuthService());
});

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(const AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = const AuthState.loading();
    final isAuth = await _authService.isAuthenticatedLegacy();
    if (!isAuth) {
      state = const AuthState.unauthenticated();
      return;
    }
    // TODO: Fetch user data from API
    // For now, just set to unauthenticated
    state = const AuthState.unauthenticated();
  }

  Future<void> signIn(String username, String password) async {
    try {
      state = const AuthState.loading();
      // TODO: Implement actual API call
      // For demonstration, using mock data
      final user = User(
        id: '1',
        username: username,
        email: '$username@example.com',
      );
      await _authService.saveAuthToken('mock_token');
      await _authService.saveUserId(user.id);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<void> signOut() async {
    await _authService.clearAuth();
    state = const AuthState.unauthenticated();
  }
}
