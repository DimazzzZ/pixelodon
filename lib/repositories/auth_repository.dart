import 'package:flutter/foundation.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:pixelodon/core/config/tech_account_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pixelodon/providers/auth_provider.dart';

part 'auth_repository.g.dart';

/// State class for authentication
class AuthState {
  final List<Instance> instances;
  final String? activeInstanceDomain;
  final Map<String, Account> accounts;
  final bool isInitialized;

  const AuthState({
    this.instances = const [],
    this.activeInstanceDomain,
    this.accounts = const {},
    this.isInitialized = false,
  });

  AuthState copyWith({
    List<Instance>? instances,
    String? activeInstanceDomain,
    Map<String, Account>? accounts,
    bool? isInitialized,
  }) {
    return AuthState(
      instances: instances ?? this.instances,
      activeInstanceDomain: activeInstanceDomain ?? this.activeInstanceDomain,
      accounts: accounts ?? this.accounts,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }

  /// Get the currently active instance
  Instance? get activeInstance {
    if (activeInstanceDomain == null) return null;
    try {
      return instances.firstWhere(
        (instance) => instance.domain == activeInstanceDomain,
      );
    } catch (_) {
      return null;
    }
  }

  /// Get the currently active account
  Account? get activeAccount {
    if (activeInstanceDomain == null) return null;
    return accounts[activeInstanceDomain];
  }
}

/// Repository for managing authentication state with improved features
@Riverpod(keepAlive: true)
class AuthRepository extends _$AuthRepository {
  late final AuthService _authService;

  @override
  AuthState build() {
    _authService = ref.watch(authServiceProvider);
    
    // Initial load
    Future.microtask(() => initialize());
    
    return const AuthState();
  }
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Prevent multiple initializations if already initialized (though build handles recreation)
    if (state.isInitialized) {
      return;
    }

    try {
      // Load authenticated instances
      final domains = await _authService.getAuthenticatedInstances();

      if (domains.isNotEmpty) {
      final instances = <Instance>[];
      final accounts = <String, Account>{};
      String? activeInstanceDomain;

      // Load instance information for each domain
      for (final domain in domains) {
        try {
          final instance = await _authService.discoverInstance(domain);
          instances.add(instance);

          // Load account information
          final account = await _authService.getAccountInfo(domain);
          if (account != null) {
            accounts[domain] = account;
          }

          // Set the first instance as active if none is set
          activeInstanceDomain ??= domain;
        } catch (e) {
          debugPrint('Failed to load instance $domain: $e');
        }
      }

        state = state.copyWith(
          instances: instances,
          accounts: accounts,
          activeInstanceDomain: activeInstanceDomain,
          isInitialized: true,
        );
      } else {
        state = state.copyWith(isInitialized: true);
      }
    } catch (e) {
      // Mark as initialized even on error to prevent retry loops
      // The app will continue with empty state (logged out)
      state = state.copyWith(isInitialized: true);
    }
  }
  
  /// Set the active instance
  void setActiveInstance(String domain) {
    if (state.instances.any((instance) => instance.domain == domain)) {
      state = state.copyWith(activeInstanceDomain: domain);
    }
  }
  
  /// Discover an instance by domain
  Future<Instance> discoverInstance(String domain) async {
    return await _authService.discoverInstance(domain);
  }
  
  /// Start the OAuth flow for an instance
  ///
  /// Returns the URL to redirect the user to and the state to verify the callback
  /// If [forRegistration] is true, will attempt to show registration page
  Future<Map<String, String>> startOAuthFlow(String domain, {bool forRegistration = false}) async {
    return await _authService.getAuthorizationUrl(domain, forRegistration: forRegistration);
  }
  
  /// Complete the OAuth flow for an instance
  /// 
  /// Returns true if authentication was successful
  Future<bool> completeOAuthFlow(
    String domain, 
    String code,
    {String? state}
  ) async {
    try {
      // Exchange the authorization code for an access token
      await _authService.exchangeAuthorizationCode(domain, code, state: state);
      
      final currentInstances = List<Instance>.from(this.state.instances);
      final currentAccounts = Map<String, Account>.from(this.state.accounts);
      String? activeInstanceDomain = this.state.activeInstanceDomain;

      // Add the instance to the list if it's not already there
      if (!currentInstances.any((instance) => instance.domain == domain)) {
        final instance = await _authService.discoverInstance(domain);
        currentInstances.add(instance);
        
        // Set as active instance if none is set
        activeInstanceDomain ??= domain;
        
        // Get the account information
        final account = await _authService.getAccountInfo(domain);
        if (account != null) {
          currentAccounts[domain] = account;
        }
        
        this.state = this.state.copyWith(
          instances: currentInstances,
          accounts: currentAccounts,
          activeInstanceDomain: activeInstanceDomain,
        );
      } else {
        // If the instance is already in the list, make sure it's up to date
        final index = currentInstances.indexWhere((instance) => instance.domain == domain);
        if (index >= 0) {
          try {
            final updatedInstance = await _authService.discoverInstance(domain);
            currentInstances[index] = updatedInstance;
            
            // Update the account information
            final account = await _authService.getAccountInfo(domain);
            if (account != null) {
              currentAccounts[domain] = account;
            }
            
            this.state = this.state.copyWith(
              instances: currentInstances,
              accounts: currentAccounts,
            );
          } catch (e) {
            debugPrint('Failed to update instance info: $e');
            // Continue with the existing instance info
          }
        }
      }
      
      return true;
    } catch (e) {
      debugPrint('Failed to complete OAuth flow: $e');
      // Rethrow the exception to allow the UI to handle it
      rethrow;
    }
  }
  
  /// Refresh the access token for an instance
  /// 
  /// Returns true if the token was refreshed successfully
  Future<bool> refreshAccessToken(String domain) async {
    try {
      await _authService.refreshAccessToken(domain);
      return true;
    } catch (e) {
      debugPrint('Failed to refresh access token: $e');
      return false;
    }
  }
  
  /// Logout from an instance
  Future<void> logout(String domain) async {
    await _authService.logout(domain);
    
    final currentInstances = List<Instance>.from(state.instances);
    final currentAccounts = Map<String, Account>.from(state.accounts);
    
    currentInstances.removeWhere((instance) => instance.domain == domain);
    currentAccounts.remove(domain);
    
    // If the active instance was removed, set a new one
    String? activeInstanceDomain = state.activeInstanceDomain;
    if (activeInstanceDomain == domain) {
      activeInstanceDomain = currentInstances.isNotEmpty ? currentInstances.first.domain : null;
    }
    
    state = state.copyWith(
      instances: currentInstances,
      accounts: currentAccounts,
      activeInstanceDomain: activeInstanceDomain,
    );
  }
  
  /// Check if the user is authenticated with an instance
  Future<bool> isAuthenticated(String domain) async {
    return await _authService.isAuthenticated(domain);
  }
  
  /// Get the access token for an instance
  /// Falls back to technical account token for Mastodon domains when no user token exists
  Future<String?> getAccessToken(String domain) async {
    // First try to get user's access token
    final userToken = await _authService.getAccessToken(domain);
    
    // If user token exists, use it
    if (userToken != null) {
      return userToken;
    }
    
    // Check if this is a Mastodon domain and technical account is configured
    if (_isMastodonDomain(domain) && TechAccountConfig.isConfigured) {
      // Use technical account token for any Mastodon domain when user has no credentials
      // This allows cross-instance profile fetching using the technical account
      return TechAccountConfig.accessToken;
    }
    
    return null;
  }
  
  /// Check if the domain is a Mastodon instance
  bool _isMastodonDomain(String domain) {
    // For now, we assume domains are Mastodon unless explicitly marked as Pixelfed
    // This could be enhanced with instance detection logic in the future
    return true;
  }
  
  /// Validate an access token
  Future<bool> validateAccessToken(String domain) async {
    final accessToken = await _authService.getAccessToken(domain);
    if (accessToken == null) return false;
    
    return await _authService.validateAccessToken(domain, accessToken);
  }
  
  /// Update the account information for an instance
  Future<void> updateAccountInfo(String domain) async {
    try {
      final account = await _authService.getAccountInfo(domain);
      if (account != null) {
        final currentAccounts = Map<String, Account>.from(state.accounts);
        currentAccounts[domain] = account;
        state = state.copyWith(accounts: currentAccounts);
      }
    } catch (e) {
      debugPrint('Failed to update account information: $e');
    }
  }
  
  /// Get the account information for a domain
  Account? getAccount(String domain) {
    return state.accounts[domain];
  }
  
  // Getters for compatibility with old AuthRepository
  List<Instance> get instances => state.instances;
  Instance? get activeInstance => state.activeInstance;
  Account? get activeAccount => state.activeAccount;
}
