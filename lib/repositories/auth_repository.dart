import 'package:flutter/foundation.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:pixelodon/core/config/tech_account_config.dart';

/// Repository for managing authentication state with improved features
class AuthRepository extends ChangeNotifier {
  final AuthService _authService;
  
  /// Currently authenticated instances
  final List<Instance> _instances = [];
  
  /// Currently active instance domain
  String? _activeInstanceDomain;
  
  /// Currently authenticated accounts
  final Map<String, Account> _accounts = {};

  /// Flag to track if initialization has been completed
  bool _isInitialized = false;

  /// Constructor
  AuthRepository({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();
  
  /// Initialize the repository
  Future<void> initialize() async {
    // Prevent multiple initializations
    if (_isInitialized) {
      return;
    }

    // Load authenticated instances
    final domains = await _authService.getAuthenticatedInstances();

    if (domains.isNotEmpty) {
      // Load instance information for each domain
      for (final domain in domains) {
        try {
          final instance = await _authService.discoverInstance(domain);
          _instances.add(instance);

          // Load account information
          final account = await _authService.getAccountInfo(domain);
          if (account != null) {
            _accounts[domain] = account;
          }

          // Set the first instance as active if none is set
          _activeInstanceDomain ??= domain;
        } catch (e) {
          debugPrint('Failed to load instance $domain: $e');
        }
      }

      notifyListeners();
    }

    _isInitialized = true;
  }
  
  /// Get the list of authenticated instances
  List<Instance> get instances => _instances;
  
  /// Get the currently active instance
  Instance? get activeInstance {
    if (_activeInstanceDomain == null) return null;
    try {
      return _instances.firstWhere(
        (instance) => instance.domain == _activeInstanceDomain,
      );
    } catch (_) {
      return null;
    }
  }
  
  /// Get the currently active account
  Account? get activeAccount {
    if (_activeInstanceDomain == null) return null;
    return _accounts[_activeInstanceDomain];
  }
  
  /// Set the active instance
  void setActiveInstance(String domain) {
    if (_instances.any((instance) => instance.domain == domain)) {
      _activeInstanceDomain = domain;
      notifyListeners();
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
      
      // Add the instance to the list if it's not already there
      if (!_instances.any((instance) => instance.domain == domain)) {
        final instance = await _authService.discoverInstance(domain);
        _instances.add(instance);
        
        // Set as active instance if none is set
        _activeInstanceDomain ??= domain;
        
        // Get the account information
        final account = await _authService.getAccountInfo(domain);
        if (account != null) {
          _accounts[domain] = account;
        }
        
        notifyListeners();
      } else {
        // If the instance is already in the list, make sure it's up to date
        final index = _instances.indexWhere((instance) => instance.domain == domain);
        if (index >= 0) {
          try {
            final updatedInstance = await _authService.discoverInstance(domain);
            _instances[index] = updatedInstance;
            
            // Update the account information
            final account = await _authService.getAccountInfo(domain);
            if (account != null) {
              _accounts[domain] = account;
            }
            
            notifyListeners();
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
    
    _instances.removeWhere((instance) => instance.domain == domain);
    _accounts.remove(domain);
    
    // If the active instance was removed, set a new one
    if (_activeInstanceDomain == domain) {
      _activeInstanceDomain = _instances.isNotEmpty ? _instances.first.domain : null;
    }
    
    notifyListeners();
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
        _accounts[domain] = account;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to update account information: $e');
    }
  }
  
  /// Get the account information for a domain
  Account? getAccount(String domain) {
    return _accounts[domain];
  }
}
