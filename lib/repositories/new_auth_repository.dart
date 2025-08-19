import 'package:flutter/foundation.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/services/new_auth_service.dart';

/// Repository for managing authentication state with improved features
class NewAuthRepository extends ChangeNotifier {
  final NewAuthService _authService;
  
  /// Currently authenticated instances
  final List<Instance> _instances = [];
  
  /// Currently active instance domain
  String? _activeInstanceDomain;
  
  /// Currently authenticated accounts
  final Map<String, Account> _accounts = {};
  
  /// Constructor
  NewAuthRepository({
    NewAuthService? authService,
  }) : _authService = authService ?? NewAuthService();
  
  /// Initialize the repository
  Future<void> initialize() async {
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
  Future<Map<String, String>> startOAuthFlow(String domain) async {
    return await _authService.getAuthorizationUrl(domain);
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
  Future<String?> getAccessToken(String domain) async {
    return await _authService.getAccessToken(domain);
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
