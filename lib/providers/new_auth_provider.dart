import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/repositories/new_auth_repository.dart';
import 'package:pixelodon/services/new_auth_service.dart';

/// Provider for the new AuthService
final newAuthServiceProvider = Provider<NewAuthService>((ref) {
  return NewAuthService();
});

/// Provider for the new AuthRepository
final newAuthRepositoryProvider = ChangeNotifierProvider<NewAuthRepository>((ref) {
  final authService = ref.watch(newAuthServiceProvider);
  return NewAuthRepository(authService: authService);
});

/// Provider for the list of authenticated instances
final newInstancesProvider = Provider<List<Instance>>((ref) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return authRepository.instances;
});

/// Provider for the currently active instance
final newActiveInstanceProvider = Provider<Instance?>((ref) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return authRepository.activeInstance;
});

/// Provider for the currently active account
final newActiveAccountProvider = Provider<Account?>((ref) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return authRepository.activeAccount;
});

/// Provider for checking if a user is authenticated with a specific instance
final newIsAuthenticatedProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.isAuthenticated(domain);
});

/// Provider for getting the access token for a specific instance
final newAccessTokenProvider = FutureProvider.family<String?, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.getAccessToken(domain);
});

/// Provider for validating an access token for a specific instance
final newValidateAccessTokenProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.validateAccessToken(domain);
});

/// Provider for discovering an instance by domain
final newInstanceDiscoveryProvider = FutureProvider.family<Instance, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.discoverInstance(domain);
});

/// Provider for starting the OAuth flow
final newOAuthFlowProvider = FutureProvider.family<Map<String, String>, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.startOAuthFlow(domain);
});

/// Provider for completing the OAuth flow
final newCompleteOAuthFlowProvider = FutureProvider.family<bool, ({String domain, String code, String? state})>((ref, params) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.completeOAuthFlow(params.domain, params.code, state: params.state);
});

/// Provider for refreshing an access token
final newRefreshAccessTokenProvider = FutureProvider.family<bool, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return await authRepository.refreshAccessToken(domain);
});

/// Provider for getting account information for a domain
final newAccountInfoProvider = Provider.family<Account?, String>((ref, domain) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return authRepository.getAccount(domain);
});

/// Provider for updating account information for a domain
final newUpdateAccountInfoProvider = FutureProvider.family<void, String>((ref, domain) async {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  await authRepository.updateAccountInfo(domain);
});
