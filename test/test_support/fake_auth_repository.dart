import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

/// A fake AuthRepository for testing that doesn't require mocking Riverpod internals.
/// 
/// This implementation allows tests to configure the auth state without
/// triggering Mockito's issues with Riverpod Notifier internal methods.
class FakeAuthRepository extends AuthRepository {
  AuthState _state;
  
  /// Create a fake repository with optional initial state
  FakeAuthRepository({
    List<Instance> instances = const [],
    String? activeInstanceDomain,
    Map<String, Account> accounts = const {},
    bool isInitialized = true,
  }) : _state = AuthState(
    instances: instances,
    activeInstanceDomain: activeInstanceDomain,
    accounts: accounts,
    isInitialized: isInitialized,
  );
  
  @override
  AuthState build() {
    // Return the configured state immediately, no async initialization
    return _state;
  }
  
  /// Update the internal state (for testing)
  void setState(AuthState newState) {
    _state = newState;
    // Note: In a real Riverpod notifier, we would call `state = newState`
    // but since we're not properly initialized in the Riverpod lifecycle,
    // we just update our internal state
  }
  
  @override
  Future<void> initialize() async {
    // No-op for fake - state is already configured
  }
  
  @override
  void setActiveInstance(String domain) {
    if (_state.instances.any((instance) => instance.domain == domain)) {
      _state = _state.copyWith(activeInstanceDomain: domain);
    }
  }
  
  @override
  Future<Instance> discoverInstance(String domain) async {
    // Return a mock instance
    return Instance(domain: domain, name: 'Test Instance - $domain');
  }
  
  @override
  Future<Map<String, String>> startOAuthFlow(String domain, {bool forRegistration = false}) async {
    return {
      'url': 'https://$domain/oauth/authorize?test=true',
      'state': 'test_state_${DateTime.now().millisecondsSinceEpoch}',
    };
  }
  
  @override
  Future<bool> completeOAuthFlow(String domain, String code, {String? state}) async {
    // Simulate successful OAuth completion
    final newInstance = Instance(domain: domain, name: 'Authenticated Instance');
    final newAccount = Account(
      id: 'test_account_$domain',
      username: 'testuser',
      acct: 'testuser@$domain',
      displayName: 'Test User',
    );
    
    final updatedInstances = [..._state.instances, newInstance];
    final updatedAccounts = Map<String, Account>.from(_state.accounts);
    updatedAccounts[domain] = newAccount;
    
    _state = _state.copyWith(
      instances: updatedInstances,
      accounts: updatedAccounts,
      activeInstanceDomain: _state.activeInstanceDomain ?? domain,
    );
    
    return true;
  }
  
  @override
  Future<bool> refreshAccessToken(String domain) async {
    return true;
  }
  
  @override
  Future<void> logout(String domain) async {
    final updatedInstances = _state.instances
        .where((instance) => instance.domain != domain)
        .toList();
    final updatedAccounts = Map<String, Account>.from(_state.accounts);
    updatedAccounts.remove(domain);
    
    String? activeInstanceDomain = _state.activeInstanceDomain;
    if (activeInstanceDomain == domain) {
      activeInstanceDomain = updatedInstances.isNotEmpty 
          ? updatedInstances.first.domain 
          : null;
    }
    
    _state = _state.copyWith(
      instances: updatedInstances,
      accounts: updatedAccounts,
      activeInstanceDomain: activeInstanceDomain,
    );
  }
  
  @override
  Future<bool> isAuthenticated(String domain) async {
    return _state.instances.any((instance) => instance.domain == domain);
  }
  
  @override
  Future<String?> getAccessToken(String domain) async {
    if (_state.instances.any((instance) => instance.domain == domain)) {
      return 'fake_access_token_$domain';
    }
    return null;
  }
  
  @override
  Future<bool> validateAccessToken(String domain) async {
    return _state.instances.any((instance) => instance.domain == domain);
  }
  
  @override
  Future<void> updateAccountInfo(String domain) async {
    // No-op for fake
  }
  
  @override
  Account? getAccount(String domain) {
    return _state.accounts[domain];
  }
  
  // Getters for compatibility
  @override
  List<Instance> get instances => _state.instances;
  
  @override
  Instance? get activeInstance => _state.activeInstance;
  
  @override
  Account? get activeAccount => _state.activeAccount;
}

/// Factory for creating fake auth repository with common configurations
class FakeAuthRepositoryFactory {
  /// Create an unauthenticated (logged out) state
  static FakeAuthRepository unauthenticated() {
    return FakeAuthRepository(
      instances: [],
      activeInstanceDomain: null,
      accounts: {},
      isInitialized: true,
    );
  }
  
  /// Create an authenticated state with a single instance
  static FakeAuthRepository authenticated({
    String domain = 'example.com',
    String instanceName = 'Example Instance',
    Account? account,
  }) {
    final instance = Instance(domain: domain, name: instanceName);
    final defaultAccount = account ?? Account(
      id: 'test_account_id',
      username: 'testuser',
      acct: 'testuser@$domain',
      displayName: 'Test User',
    );
    
    return FakeAuthRepository(
      instances: [instance],
      activeInstanceDomain: domain,
      accounts: {domain: defaultAccount},
      isInitialized: true,
    );
  }
  
  /// Create an authenticated state with multiple instances
  static FakeAuthRepository multiInstance({
    required List<String> domains,
    String? activeDomain,
  }) {
    final instances = domains.map((d) => Instance(domain: d, name: 'Instance $d')).toList();
    final accounts = <String, Account>{};
    for (final domain in domains) {
      accounts[domain] = Account(
        id: 'account_$domain',
        username: 'user_$domain',
        acct: 'user@$domain',
        displayName: 'User on $domain',
      );
    }
    
    return FakeAuthRepository(
      instances: instances,
      activeInstanceDomain: activeDomain ?? domains.first,
      accounts: accounts,
      isInitialized: true,
    );
  }
}
