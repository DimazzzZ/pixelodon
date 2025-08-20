import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/services/auth_service.dart';

/// Provider for the AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for the AuthRepository
final authRepositoryProvider = ChangeNotifierProvider<AuthRepository>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthRepository(authService: authService);
});

/// Provider for the list of authenticated instances
final instancesProvider = Provider<List<Instance>>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.instances;
});

/// Provider for the currently active instance
final activeInstanceProvider = Provider<Instance?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.activeInstance;
});

/// Provider for the currently active account
final activeAccountProvider = Provider<Account?>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.activeAccount;
});

/// Provider for checking if a user is authenticated with a specific instance
final isAuthenticatedProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.isAuthenticated(domain);
});

/// Provider for getting the access token for a specific instance
final accessTokenProvider = FutureProvider.family<String?, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.getAccessToken(domain);
});

/// Provider for validating an access token for a specific instance
final validateAccessTokenProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.validateAccessToken(domain);
});

/// Provider for discovering an instance by domain
final instanceDiscoveryProvider = FutureProvider.family<Instance, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.discoverInstance(domain);
});

/// Provider for starting the OAuth flow
final oauthFlowProvider = FutureProvider.family<Map<String, String>, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.startOAuthFlow(domain);
});

/// Provider for completing the OAuth flow
final completeOAuthFlowProvider = FutureProvider.family<bool, ({String domain, String code, String? state})>((ref, params) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.completeOAuthFlow(params.domain, params.code, state: params.state);
});

/// Provider for refreshing an access token
final refreshAccessTokenProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  return await authRepository.refreshAccessToken(domain);
});

/// Provider for getting account information for a domain
final accountInfoProvider = Provider.family<Account?, String>((ref, domain) {
  final authRepository = ref.watch(authRepositoryProvider);
  return authRepository.getAccount(domain);
});

/// Provider for updating account information for a domain
final updateAccountInfoProvider = FutureProvider.family<void, String>((ref, domain) async {
  final authRepository = ref.watch(authRepositoryProvider);
  await authRepository.updateAccountInfo(domain);
});
