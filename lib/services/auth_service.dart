import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/core/config/tech_account_config.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/utils/logger.dart';

/// Enhanced service for handling authentication with Mastodon and Pixelfed instances
/// This is a new implementation with improved features and error handling
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  /// Constructor
  AuthService({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  }) : _dio = dio ?? Dio(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();
       
  /// Client name for OAuth registration
  static const String _clientName = 'Pixelodon';
  
  /// Client website for OAuth registration
  static const String _clientWebsite = 'https://pixelodon.app';
  
  /// Redirect URI for OAuth flow
  static const String _redirectUri = 'pixelodon://oauth/callback';
  
  /// Scopes to request during OAuth flow
  static const String _scopes = 'read write follow push';
  
  /// Available scopes for more granular control
  static const Map<String, String> availableScopes = {
    'read': 'Read data from your account',
    'write': 'Post, favorite, and follow on your behalf',
    'follow': 'Follow, unfollow, block, and unblock accounts',
    'push': 'Receive push notifications',
    'admin': 'Access administrative functions (admin accounts only)',
    'admin:read': 'Read administrative data (admin accounts only)',
    'admin:write': 'Modify administrative data (admin accounts only)',
  };
  
  /// Key for storing client credentials in secure storage
  static const String _clientCredentialsKey = 'new_client_credentials';
  
  /// Key for storing access tokens in secure storage
  static const String _accessTokensKey = 'new_access_tokens';
  
  /// Key for storing refresh tokens in secure storage
  static const String _refreshTokensKey = 'new_refresh_tokens';
  
  /// Key for storing account information in secure storage
  static const String _accountsKey = 'new_accounts';
  
  /// Discovers an instance by its domain
  /// 
  /// Returns an [Instance] object with information about the instance
  Future<Instance> discoverInstance(String domain) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      // Check if instance exists and get info
      final response = await _dio.get<Map<String, dynamic>>('https://$normalizedDomain/api/v1/instance');
      
      final Map<String, dynamic> json = response.data!;
      
      // Check if it's a Pixelfed instance
      bool isPixelfed = false;
      bool supportsStories = false;
      
      if (json['version'] != null) {
        isPixelfed = json['version'].toString().toLowerCase().contains('pixelfed');
      }
      
      // Check for stories support (Pixelfed specific)
      if (isPixelfed) {
        try {
          final nodeInfoResponse = await _dio.get<Map<String, dynamic>>('https://$normalizedDomain/.well-known/nodeinfo');
          final nodeInfoLinks = nodeInfoResponse.data!['links'] as List;
          if (nodeInfoLinks.isNotEmpty) {
            final nodeInfoUrl = nodeInfoLinks.first['href'] as String;
            final nodeInfoDetailsResponse = await _dio.get<Map<String, dynamic>>(nodeInfoUrl);
            final software = nodeInfoDetailsResponse.data!['software'] as Map<String, dynamic>?;
            if (software != null && software['name'] == 'pixelfed') {
              // Check for stories support in features
              final features = nodeInfoDetailsResponse.data!['metadata']['features'] as List?;
              if (features != null) {
                supportsStories = features.contains('stories');
              }
            }
          }
        } catch (e) {
          // Ignore errors in nodeinfo detection
          logger.w('Error detecting nodeinfo for $normalizedDomain: $e');
        }
      }
      
      return Instance(
        domain: normalizedDomain,
        name: (json['title'] ?? normalizedDomain) as String,
        description: json['description'] as String?,
        version: json['version'] as String?,
        thumbnail: json['thumbnail'] as String?,
        languages: json['languages'] != null 
            ? List<String>.from(json['languages'] as Iterable) 
            : null,
        maxCharsPerPost: json['configuration']?['statuses']?['max_characters'] as int?,
        maxMediaAttachments: json['configuration']?['statuses']?['max_media_attachments'] as int?,
        isPixelfed: isPixelfed,
        supportsStories: supportsStories,
        tosUrl: json['urls']?['terms'] as String?,
        privacyPolicyUrl: json['urls']?['privacy'] as String?,
        contactEmail: json['email'] as String?,
      );
    } catch (e) {
      logger.e('Failed to discover instance $domain', error: e);
      throw AuthDiscoveryException('Failed to discover instance: $e', data: e);
    }
  }
  
  /// Normalizes a domain by removing protocol and trailing slashes
  String _normalizeDomain(String domain) {
    var normalized = domain.toLowerCase().trim();
    if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
      final uri = Uri.parse(normalized);
      normalized = uri.host;
    }
    return normalized;
  }
  
  /// Validates a redirect URI to ensure it's safe
  /// 
  /// Returns true if the URI is safe, false otherwise
  bool _isRedirectUriSafe(String uri) {
    try {
      final parsedUri = Uri.parse(uri);
      
      // Check for potentially dangerous schemes
      final dangerousSchemes = ['javascript', 'data', 'vbscript', 'file'];
      if (dangerousSchemes.contains(parsedUri.scheme.toLowerCase())) {
        return false;
      }
      
      // Only allow custom schemes (like pixelodon://) or https
      if (parsedUri.scheme != 'https' && parsedUri.scheme != 'pixelodon') {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Registers a client application with the instance
  /// 
  /// Returns a client ID and client secret
  Future<Map<String, String>> _registerApp(String domain) async {
    try {
      // Validate redirect URI
      if (!_isRedirectUriSafe(_redirectUri)) {
        throw const AuthRegistrationException('Unsafe redirect URI');
      }
      
      final response = await _dio.post<Map<String, dynamic>>(
        'https://$domain/api/v1/apps',
        data: {
          'client_name': _clientName,
          'redirect_uris': _redirectUri,
          'scopes': _scopes,
          'website': _clientWebsite,
        },
      );
      
      final data = response.data!;
      return {
        'client_id': data['client_id'] as String,
        'client_secret': data['client_secret'] as String,
      };
    } catch (e) {
      logger.e('Failed to register app on $domain', error: e);
      throw AuthRegistrationException('Failed to register app: $e', data: e);
    }
  }
  
  /// Gets the client credentials for an instance
  /// 
  /// Returns a client ID and client secret
  Future<Map<String, String>> getClientCredentials(String domain) async {
    // Normalize domain
    final normalizedDomain = _normalizeDomain(domain);
    
    // Check if we already have credentials for this domain
    final credentialsJson = await _secureStorage.read(key: _clientCredentialsKey);
    
    if (credentialsJson != null) {
      final Map<String, dynamic> credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      
      if (credentials.containsKey(normalizedDomain)) {
        final domainCreds = credentials[normalizedDomain] as Map<String, dynamic>;
        return domainCreds.map((key, value) => MapEntry(key, value as String));
      }
    }
    
    // Register a new app
    final appCredentials = await _registerApp(normalizedDomain);
    
    // Save the credentials
    final Map<String, dynamic> credentials = credentialsJson != null 
        ? jsonDecode(credentialsJson) as Map<String, dynamic>
        : {};
    
    credentials[normalizedDomain] = appCredentials;
    
    await _secureStorage.write(
      key: _clientCredentialsKey,
      value: jsonEncode(credentials),
    );
    
    return appCredentials;
  }
  
  /// Generates a random state string for OAuth
  String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Generates a random code verifier for PKCE
  String _generateCodeVerifier() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    // The code verifier should be between 43 and 128 characters
    return List.generate(96, (_) => chars[random.nextInt(chars.length)]).join();
  }
  
  /// Generates a code challenge from a code verifier using SHA-256
  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes)
      .replaceAll('=', '') // Remove padding
      .replaceAll('+', '-') // Replace + with -
      .replaceAll('/', '_'); // Replace / with _
  }
  
  /// Stores a PKCE code verifier for a domain and state
  @visibleForTesting
  Future<void> storeCodeVerifier(String domain, String state, String verifier) async {
    logger.d('Storing code verifier for domain: $domain, state: $state');
    
    try {
      // Use a simpler approach to store the verifier directly with a unique key
      final key = 'pkce_verifier_${domain}_$state';
      
      // Store the verifier directly
      await _secureStorage.write(
        key: key,
        value: verifier,
      );

      // Also store the domain-state mapping for deep link handling
      await _secureStorage.write(key: 'oauth_domain_$state', value: domain);
    } catch (e) {
      logger.e('Error storing code verifier for $domain', error: e);
      throw AuthStorageException('Failed to store code verifier: $e', data: e);
    }
  }
  
  /// Retrieves the domain associated with an OAuth state
  Future<String?> getDomainFromState(String state) async {
    try {
      final domain = await _secureStorage.read(key: 'oauth_domain_$state');
      logger.d('Retrieved domain for state $state: $domain');
      return domain;
    } catch (e) {
      logger.e('Error retrieving domain for state $state', error: e);
      return null;
    }
  }

  /// Retrieves and removes a PKCE code verifier for a domain and state
  @visibleForTesting
  Future<String?> getAndRemoveCodeVerifier(String domain, String? state) async {
    logger.d('Getting code verifier for domain: $domain, state: $state');
    // If state is null or empty, we're not using PKCE
    if (state == null || state.isEmpty) {
      logger.d('State is null or empty, not using PKCE');
      return null;
    }
    
    try {
      // Use the same key format as in _storeCodeVerifier
      final key = 'pkce_verifier_${domain}_$state';
      
      // Get the verifier
      final verifier = await _secureStorage.read(key: key);
      
      if (verifier != null) {
        logger.d('Found code verifier for key: $key');
        
        // Remove the used verifier
        await _secureStorage.delete(key: key);
        logger.d('Removed code verifier for key: $key');

        // Also remove the domain-state mapping
        await _secureStorage.delete(key: 'oauth_domain_$state');
        logger.d('Removed domain mapping for state: $state');
        
        return verifier;
      } else {
        logger.d('No code verifier found for key: $key');
      }
    } catch (e) {
      logger.e('Error retrieving code verifier for $domain', error: e);
    }
    
    return null;
  }
  
  /// Gets the authorization URL for an instance
  ///
  /// Returns the URL to redirect the user to and the state to verify the callback
  /// If [forRegistration] is true, will attempt to show registration page
  Future<Map<String, String>> getAuthorizationUrl(String domain, {bool forRegistration = false}) async {
    logger.d('Getting authorization URL for domain: $domain');
    
    // Normalize domain
    final normalizedDomain = _normalizeDomain(domain);
    
    final credentials = await getClientCredentials(normalizedDomain);
    
    final state = _generateState();
    
    // Generate PKCE code verifier and challenge
    final codeVerifier = _generateCodeVerifier();
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    
    // Store the code verifier for later use
    await storeCodeVerifier(normalizedDomain, state, codeVerifier);
    
    // Build the URL - use sign-up page for registration, OAuth for login
    String url;
    if (forRegistration) {
      // For registration, go directly to the sign-up page with OAuth parameters
      url = 'https://$normalizedDomain/auth/sign_up?'
          'client_id=${Uri.encodeComponent(credentials['client_id']!)}&'
          'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
          'response_type=code&'
          'scope=${Uri.encodeComponent(_scopes)}&'
          'state=$state&'
          'code_challenge=$codeChallenge&'
          'code_challenge_method=S256&'
          'domain=$normalizedDomain';
    } else {
      // For login, use the standard OAuth authorize endpoint
      url = 'https://$normalizedDomain/oauth/authorize?'
          'client_id=${Uri.encodeComponent(credentials['client_id']!)}&'
          'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
          'response_type=code&'
          'scope=${Uri.encodeComponent(_scopes)}&'
          'state=$state&'
          'code_challenge=$codeChallenge&'
          'code_challenge_method=S256&'
          'domain=$normalizedDomain';
    }
    
    logger.d('Generated authorization URL: $url');
    
    return {
      'url': url,
      'state': state,
    };
  }
  
  /// Exchanges an authorization code for an access token
  /// 
  /// Returns an access token and refresh token
  Future<Map<String, String>> exchangeAuthorizationCode(
    String domain, 
    String code,
    {String? state}
  ) async {
    try {
      logger.d('Exchanging authorization code for domain: $domain, code: $code, state: $state');
      
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      final credentials = await getClientCredentials(normalizedDomain);
      
      // Get the code verifier if we have a state
      final codeVerifier = await getAndRemoveCodeVerifier(normalizedDomain, state);
      
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'client_id': credentials['client_id'],
        'client_secret': credentials['client_secret'],
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'scope': _scopes,
      };
      
      // Add code verifier if we have one
      if (codeVerifier != null) {
        requestData['code_verifier'] = codeVerifier;
      }
      
      final response = await _dio.post<Map<String, dynamic>>(
        'https://$normalizedDomain/oauth/token',
        data: requestData,
      );
      
      final data = response.data!;
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String?;
      
      // Store the access token
      await _storeAccessToken(normalizedDomain, accessToken);
      
      // Store the refresh token if we have one
      if (refreshToken != null) {
        await _storeRefreshToken(normalizedDomain, refreshToken);
      }
      
      // Fetch and store the user's account information
      await _fetchAndStoreAccountInfo(normalizedDomain, accessToken);
      
      return {
        'access_token': accessToken,
        'refresh_token': refreshToken ?? '',
      };
    } catch (e) {
      logger.e('Failed to exchange authorization code for $domain', error: e);
      throw AuthTokenException('Failed to exchange authorization code: $e', data: e);
    }
  }
  
  /// Refreshes an access token using a refresh token
  /// 
  /// Returns a new access token and refresh token
  Future<Map<String, String>> refreshAccessToken(String domain) async {
    try {
      logger.d('Refreshing access token for domain: $domain');
      
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      // Get the refresh token
      final refreshToken = await getRefreshToken(normalizedDomain);
      if (refreshToken == null) {
        throw const AuthTokenException('No refresh token available');
      }
      
      final credentials = await getClientCredentials(normalizedDomain);
      
      final response = await _dio.post<Map<String, dynamic>>(
        'https://$normalizedDomain/oauth/token',
        data: {
          'client_id': credentials['client_id'],
          'client_secret': credentials['client_secret'],
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': _scopes,
        },
      );
      
      final data = response.data!;
      final accessToken = data['access_token'] as String;
      final newRefreshToken = data['refresh_token'] as String?;
      
      // Store the new access token
      await _storeAccessToken(normalizedDomain, accessToken);
      
      // Store the new refresh token if we have one
      if (newRefreshToken != null) {
        await _storeRefreshToken(normalizedDomain, newRefreshToken);
      }
      
      return {
        'access_token': accessToken,
        'refresh_token': newRefreshToken ?? refreshToken,
      };
    } catch (e) {
      logger.e('Failed to refresh access token for $domain', error: e);
      throw AuthTokenException('Failed to refresh access token: $e', data: e);
    }
  }
  
  /// Stores an access token for a domain
  Future<void> _storeAccessToken(String domain, String accessToken) async {
    try {
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) as Map<String, dynamic>
          : {};
      
      tokens[domain] = accessToken;
      
      await _secureStorage.write(
        key: _accessTokensKey,
        value: jsonEncode(tokens),
      );
    } catch (e) {
      logger.e('Failed to store access token for $domain', error: e);
      throw AuthStorageException('Failed to store access token: $e', data: e);
    }
  }
  
  /// Stores a refresh token for a domain
  Future<void> _storeRefreshToken(String domain, String refreshToken) async {
    try {
      final tokensJson = await _secureStorage.read(key: _refreshTokensKey);
      
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) as Map<String, dynamic>
          : {};
      
      tokens[domain] = refreshToken;
      
      await _secureStorage.write(
        key: _refreshTokensKey,
        value: jsonEncode(tokens),
      );
    } catch (e) {
      logger.e('Failed to store refresh token for $domain', error: e);
      throw AuthStorageException('Failed to store refresh token: $e', data: e);
    }
  }
  
  /// Gets the access token for a domain
  Future<String?> getAccessToken(String domain) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      if (tokensJson != null) {
        final Map<String, dynamic> tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        
        if (tokens.containsKey(normalizedDomain)) {
          return tokens[normalizedDomain] as String;
        }
      }

      return await _getTechTokenFallback(normalizedDomain);
    } catch (e) {
      logger.w('Failed to get access token for $domain', error: e);
      return await _getTechTokenFallback(domain);
    }
  }

  Future<String?> _getTechTokenFallback(String domain) async {
    try {
      return (TechAccountConfig.domain == domain) ? TechAccountConfig.accessToken : null;
    } catch (_) {
      return null;
    }
  }
  
  /// Gets the refresh token for a domain
  Future<String?> getRefreshToken(String domain) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      final tokensJson = await _secureStorage.read(key: _refreshTokensKey);
      
      if (tokensJson != null) {
        final Map<String, dynamic> tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        
        if (tokens.containsKey(normalizedDomain)) {
          return tokens[normalizedDomain] as String;
        }
      }
      
      return null;
    } catch (e) {
      logger.w('Failed to get refresh token for $domain', error: e);
      return null;
    }
  }
  
  /// Fetches and stores the user's account information
  Future<Account> _fetchAndStoreAccountInfo(String domain, String accessToken) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://$domain/api/v1/accounts/verify_credentials',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      final Map<String, dynamic> accountData = response.data!;
      
      final account = Account(
        id: accountData['id'] as String,
        username: accountData['username'] as String,
        acct: accountData['acct'] as String,
        displayName: accountData['display_name'] as String,
        note: accountData['note'] as String,
        url: accountData['url'] as String,
        avatar: accountData['avatar'] as String,
        avatarStatic: accountData['avatar_static'] as String,
        header: accountData['header'] as String,
        headerStatic: accountData['header_static'] as String,
        followersCount: accountData['followers_count'] as int,
        followingCount: accountData['following_count'] as int,
        statusesCount: accountData['statuses_count'] as int,
        lastStatusAt: accountData['last_status_at'] != null
            ? DateTime.tryParse(accountData['last_status_at'].toString())
            : null,
        createdAt: accountData['created_at'] != null
            ? DateTime.tryParse(accountData['created_at'].toString())
            : null,
        bot: (accountData['bot'] as bool?) ?? false,
        locked: (accountData['locked'] as bool?) ?? false,
        fields: (accountData['fields'] as List?)
            ?.map((field) {
              final f = field as Map<String, dynamic>;
              return Field(
                  name: (f['name'] ?? '') as String,
                  value: (f['value'] ?? '') as String,
                  verifiedAt: f['verified_at'] != null
                      ? DateTime.tryParse(f['verified_at'].toString())
                      : null,
                );
            })
            .toList(),
      );
      
      // Store the account information
      await _storeAccountInfo(domain, account);
      
      return account;
    } catch (e) {
      logger.e('Failed to fetch account info for $domain', error: e);
      throw AuthTokenException('Failed to fetch account information: $e', data: e);
    }
  }
  
  /// Stores account information for a domain
  Future<void> _storeAccountInfo(String domain, Account account) async {
    try {
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      
      final Map<String, dynamic> accounts = accountsJson != null 
          ? jsonDecode(accountsJson) as Map<String, dynamic>
          : {};
      
      accounts[domain] = account.toJson();
      
      await _secureStorage.write(
        key: _accountsKey,
        value: jsonEncode(accounts),
      );
    } catch (e) {
      logger.e('Failed to store account info for $domain', error: e);
      throw AuthStorageException('Failed to store account information: $e', data: e);
    }
  }
  
  /// Gets the account information for a domain
  Future<Account?> getAccountInfo(String domain) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      
      if (accountsJson != null) {
        final Map<String, dynamic> accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        
        if (accounts.containsKey(normalizedDomain)) {
          return Account.fromJson(accounts[normalizedDomain] as Map<String, dynamic>);
        }
      }
      
      return null;
    } catch (e) {
      logger.w('Failed to get account info for $domain', error: e);
      return null;
    }
  }
  
  /// Checks if the user is authenticated with an instance
  Future<bool> isAuthenticated(String domain) async {
    // Normalize domain
    final normalizedDomain = _normalizeDomain(domain);
    
    final accessToken = await getAccessToken(normalizedDomain);
    return accessToken != null;
  }
  
  /// Gets a list of authenticated instances
  Future<List<String>> getAuthenticatedInstances() async {
    try {
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      if (tokensJson != null) {
        final Map<String, dynamic> tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        return tokens.keys.toList();
      }
      
      return [];
    } catch (e) {
      logger.w('Failed to get authenticated instances', error: e);
      return [];
    }
  }
  
  /// Logs out from an instance
  Future<void> logout(String domain) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      // Remove the access token
      final accessTokensJson = await _secureStorage.read(key: _accessTokensKey);
      if (accessTokensJson != null) {
        final Map<String, dynamic> accessTokens = jsonDecode(accessTokensJson) as Map<String, dynamic>;
        accessTokens.remove(normalizedDomain);
        await _secureStorage.write(
          key: _accessTokensKey,
          value: jsonEncode(accessTokens),
        );
      }
      
      // Remove the refresh token
      final refreshTokensJson = await _secureStorage.read(key: _refreshTokensKey);
      if (refreshTokensJson != null) {
        final Map<String, dynamic> refreshTokens = jsonDecode(refreshTokensJson) as Map<String, dynamic>;
        refreshTokens.remove(normalizedDomain);
        await _secureStorage.write(
          key: _refreshTokensKey,
          value: jsonEncode(refreshTokens),
        );
      }
      
      // Remove the account information
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      if (accountsJson != null) {
        final Map<String, dynamic> accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        accounts.remove(normalizedDomain);
        await _secureStorage.write(
          key: _accountsKey,
          value: jsonEncode(accounts),
        );
      }
    } catch (e) {
      logger.e('Failed to logout from $domain', error: e);
      throw AuthLogoutException('Failed to logout: $e', data: e);
    }
  }
  
  /// Validates an access token
  Future<bool> validateAccessToken(String domain, String accessToken) async {
    try {
      // Normalize domain
      final normalizedDomain = _normalizeDomain(domain);
      
      final response = await _dio.get<Map<String, dynamic>>(
        'https://$normalizedDomain/api/v1/apps/verify_credentials',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      logger.w('Failed to validate access token for $domain', error: e);
      return false;
    }
  }
}
