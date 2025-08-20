import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/models/account.dart';

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
      domain = _normalizeDomain(domain);
      
      // Check if instance exists and get info
      final response = await _dio.get('https://$domain/api/v1/instance');
      
      final json = response.data;
      
      // Check if it's a Pixelfed instance
      bool isPixelfed = false;
      bool supportsStories = false;
      
      if (json['version'] != null) {
        isPixelfed = json['version'].toString().toLowerCase().contains('pixelfed');
      }
      
      // Check for stories support (Pixelfed specific)
      if (isPixelfed) {
        try {
          final nodeInfoResponse = await _dio.get('https://$domain/.well-known/nodeinfo');
          final nodeInfoLinks = nodeInfoResponse.data['links'] as List;
          if (nodeInfoLinks.isNotEmpty) {
            final nodeInfoUrl = nodeInfoLinks.first['href'];
            final nodeInfoDetailsResponse = await _dio.get(nodeInfoUrl);
            final software = nodeInfoDetailsResponse.data['software'];
            if (software != null && software['name'] == 'pixelfed') {
              // Check for stories support in features
              final features = nodeInfoDetailsResponse.data['metadata']['features'] as List?;
              if (features != null) {
                supportsStories = features.contains('stories');
              }
            }
          }
        } catch (e) {
          // Ignore errors in nodeinfo detection
          debugPrint('Error detecting nodeinfo: $e');
        }
      }
      
      return Instance(
        domain: domain,
        name: json['title'] ?? domain,
        description: json['description'],
        version: json['version'],
        thumbnail: json['thumbnail'],
        languages: json['languages'] != null 
            ? List<String>.from(json['languages']) 
            : null,
        maxCharsPerPost: json['configuration']?['statuses']?['max_characters'],
        maxMediaAttachments: json['configuration']?['statuses']?['max_media_attachments'],
        isPixelfed: isPixelfed,
        supportsStories: supportsStories,
        tosUrl: json['urls']?['terms'],
        privacyPolicyUrl: json['urls']?['privacy'],
        contactEmail: json['email'],
      );
    } catch (e) {
      throw Exception('Failed to discover instance: $e');
    }
  }
  
  /// Normalizes a domain by removing protocol and trailing slashes
  String _normalizeDomain(String domain) {
    domain = domain.toLowerCase().trim();
    if (domain.startsWith('http://') || domain.startsWith('https://')) {
      final uri = Uri.parse(domain);
      domain = uri.host;
    }
    return domain;
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
        throw Exception('Unsafe redirect URI');
      }
      
      final response = await _dio.post(
        'https://$domain/api/v1/apps',
        data: {
          'client_name': _clientName,
          'redirect_uris': _redirectUri,
          'scopes': _scopes,
          'website': _clientWebsite,
        },
      );
      
      return {
        'client_id': response.data['client_id'],
        'client_secret': response.data['client_secret'],
      };
    } catch (e) {
      throw Exception('Failed to register app: $e');
    }
  }
  
  /// Gets the client credentials for an instance
  /// 
  /// Returns a client ID and client secret
  Future<Map<String, String>> getClientCredentials(String domain) async {
    // Normalize domain
    domain = _normalizeDomain(domain);
    
    // Check if we already have credentials for this domain
    final credentialsJson = await _secureStorage.read(key: _clientCredentialsKey);
    
    if (credentialsJson != null) {
      final credentials = jsonDecode(credentialsJson) as Map<String, dynamic>;
      
      if (credentials.containsKey(domain)) {
        return Map<String, String>.from(credentials[domain]);
      }
    }
    
    // Register a new app
    final appCredentials = await _registerApp(domain);
    
    // Save the credentials
    final Map<String, dynamic> credentials = credentialsJson != null 
        ? jsonDecode(credentialsJson) 
        : {};
    
    credentials[domain] = appCredentials;
    
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
  Future<void> _storeCodeVerifier(String domain, String state, String verifier) async {
    debugPrint('Storing code verifier for domain: $domain, state: $state');
    
    try {
      // Use a simpler approach to store the verifier directly with a unique key
      final key = 'pkce_verifier_${domain}_$state';
      
      // Store the verifier directly
      await _secureStorage.write(
        key: key,
        value: verifier,
      );
      
      // Verify that the verifier was stored correctly
      final storedVerifier = await _secureStorage.read(key: key);
      if (storedVerifier == verifier) {
        debugPrint('Verified: code verifier was stored correctly');
      } else {
        debugPrint('Error: code verifier was not stored correctly');
      }
    } catch (e) {
      debugPrint('Error storing code verifier: $e');
      throw Exception('Failed to store code verifier: $e');
    }
  }
  
  /// Retrieves and removes a PKCE code verifier for a domain and state
  Future<String?> _getAndRemoveCodeVerifier(String domain, String? state) async {
    debugPrint('Getting code verifier for domain: $domain, state: $state');
    // If state is null or empty, we're not using PKCE
    if (state == null || state.isEmpty) {
      debugPrint('State is null or empty, not using PKCE');
      return null;
    }
    
    try {
      // Use the same key format as in _storeCodeVerifier
      final key = 'pkce_verifier_${domain}_$state';
      
      // Get the verifier
      final verifier = await _secureStorage.read(key: key);
      
      if (verifier != null) {
        debugPrint('Found code verifier for key: $key');
        
        // Remove the used verifier
        await _secureStorage.delete(key: key);
        debugPrint('Removed code verifier for key: $key');
        
        return verifier;
      } else {
        debugPrint('No code verifier found for key: $key');
      }
    } catch (e) {
      debugPrint('Error retrieving code verifier: $e');
    }
    
    return null;
  }
  
  /// Gets the authorization URL for an instance
  /// 
  /// Returns the URL to redirect the user to and the state to verify the callback
  Future<Map<String, String>> getAuthorizationUrl(String domain) async {
    debugPrint('Getting authorization URL for domain: $domain');
    
    // Normalize domain
    domain = _normalizeDomain(domain);
    
    final credentials = await getClientCredentials(domain);
    debugPrint('Got client credentials: client_id=${credentials['client_id']}');
    
    final state = _generateState();
    debugPrint('Generated state: $state');
    
    // Generate PKCE code verifier and challenge
    final codeVerifier = _generateCodeVerifier();
    debugPrint('Generated code verifier (first 10 chars): ${codeVerifier.substring(0, 10)}...');
    
    final codeChallenge = _generateCodeChallenge(codeVerifier);
    debugPrint('Generated code challenge: $codeChallenge');
    
    // Store the code verifier for later use
    await _storeCodeVerifier(domain, state, codeVerifier);
    
    final url = 'https://$domain/oauth/authorize?'
        'client_id=${Uri.encodeComponent(credentials['client_id']!)}&'
        'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
        'response_type=code&'
        'scope=${Uri.encodeComponent(_scopes)}&'
        'state=$state&'
        'code_challenge=$codeChallenge&'
        'code_challenge_method=S256&'
        'domain=$domain';
    
    debugPrint('Generated authorization URL: $url');
    
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
      debugPrint('Exchanging authorization code for domain: $domain, code: $code, state: $state');
      
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      final credentials = await getClientCredentials(domain);
      debugPrint('Got client credentials: client_id=${credentials['client_id']}');
      
      // Get the code verifier if we have a state
      final codeVerifier = await _getAndRemoveCodeVerifier(domain, state);
      debugPrint('Code verifier: ${codeVerifier != null ? '${codeVerifier.substring(0, 10)}...' : 'null'}');
      
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
      
      final response = await _dio.post(
        'https://$domain/oauth/token',
        data: requestData,
      );
      
      final accessToken = response.data['access_token'] as String;
      final refreshToken = response.data['refresh_token'] as String?;
      
      // Store the access token
      await _storeAccessToken(domain, accessToken);
      
      // Store the refresh token if we have one
      if (refreshToken != null) {
        await _storeRefreshToken(domain, refreshToken);
      }
      
      // Fetch and store the user's account information
      await _fetchAndStoreAccountInfo(domain, accessToken);
      
      return {
        'access_token': accessToken,
        'refresh_token': refreshToken ?? '',
      };
    } catch (e) {
      throw Exception('Failed to exchange authorization code: $e');
    }
  }
  
  /// Refreshes an access token using a refresh token
  /// 
  /// Returns a new access token and refresh token
  Future<Map<String, String>> refreshAccessToken(String domain) async {
    try {
      debugPrint('Refreshing access token for domain: $domain');
      
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      // Get the refresh token
      final refreshToken = await getRefreshToken(domain);
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }
      
      final credentials = await getClientCredentials(domain);
      
      final response = await _dio.post(
        'https://$domain/oauth/token',
        data: {
          'client_id': credentials['client_id'],
          'client_secret': credentials['client_secret'],
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': _scopes,
        },
      );
      
      final accessToken = response.data['access_token'] as String;
      final newRefreshToken = response.data['refresh_token'] as String?;
      
      // Store the new access token
      await _storeAccessToken(domain, accessToken);
      
      // Store the new refresh token if we have one
      if (newRefreshToken != null) {
        await _storeRefreshToken(domain, newRefreshToken);
      }
      
      return {
        'access_token': accessToken,
        'refresh_token': newRefreshToken ?? refreshToken,
      };
    } catch (e) {
      throw Exception('Failed to refresh access token: $e');
    }
  }
  
  /// Stores an access token for a domain
  Future<void> _storeAccessToken(String domain, String accessToken) async {
    try {
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) 
          : {};
      
      tokens[domain] = accessToken;
      
      await _secureStorage.write(
        key: _accessTokensKey,
        value: jsonEncode(tokens),
      );
    } catch (e) {
      throw Exception('Failed to store access token: $e');
    }
  }
  
  /// Stores a refresh token for a domain
  Future<void> _storeRefreshToken(String domain, String refreshToken) async {
    try {
      final tokensJson = await _secureStorage.read(key: _refreshTokensKey);
      
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) 
          : {};
      
      tokens[domain] = refreshToken;
      
      await _secureStorage.write(
        key: _refreshTokensKey,
        value: jsonEncode(tokens),
      );
    } catch (e) {
      throw Exception('Failed to store refresh token: $e');
    }
  }
  
  /// Gets the access token for a domain
  Future<String?> getAccessToken(String domain) async {
    try {
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      if (tokensJson != null) {
        final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        
        if (tokens.containsKey(domain)) {
          return tokens[domain] as String;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get access token: $e');
      return null;
    }
  }
  
  /// Gets the refresh token for a domain
  Future<String?> getRefreshToken(String domain) async {
    try {
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      final tokensJson = await _secureStorage.read(key: _refreshTokensKey);
      
      if (tokensJson != null) {
        final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        
        if (tokens.containsKey(domain)) {
          return tokens[domain] as String;
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get refresh token: $e');
      return null;
    }
  }
  
  /// Fetches and stores the user's account information
  Future<Account> _fetchAndStoreAccountInfo(String domain, String accessToken) async {
    try {
      final response = await _dio.get(
        'https://$domain/api/v1/accounts/verify_credentials',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      final accountData = response.data;
      
      final account = Account(
        id: accountData['id'],
        username: accountData['username'],
        acct: accountData['acct'],
        displayName: accountData['display_name'],
        note: accountData['note'],
        url: accountData['url'],
        avatar: accountData['avatar'],
        avatarStatic: accountData['avatar_static'],
        header: accountData['header'],
        headerStatic: accountData['header_static'],
        followersCount: accountData['followers_count'],
        followingCount: accountData['following_count'],
        statusesCount: accountData['statuses_count'],
        lastStatusAt: accountData['last_status_at'] != null
            ? DateTime.tryParse(accountData['last_status_at'].toString())
            : null,
        createdAt: accountData['created_at'] != null
            ? DateTime.tryParse(accountData['created_at'].toString())
            : null,
        bot: accountData['bot'] ?? false,
        locked: accountData['locked'] ?? false,
        fields: (accountData['fields'] as List?)
            ?.map((field) => Field(
                  name: field['name'] ?? '',
                  value: field['value'] ?? '',
                  verifiedAt: field['verified_at'] != null
                      ? DateTime.tryParse(field['verified_at'].toString())
                      : null,
                ))
            .toList(),
      );
      
      // Store the account information
      await _storeAccountInfo(domain, account);
      
      return account;
    } catch (e) {
      throw Exception('Failed to fetch account information: $e');
    }
  }
  
  /// Stores account information for a domain
  Future<void> _storeAccountInfo(String domain, Account account) async {
    try {
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      
      final Map<String, dynamic> accounts = accountsJson != null 
          ? jsonDecode(accountsJson) 
          : {};
      
      accounts[domain] = account.toJson();
      
      await _secureStorage.write(
        key: _accountsKey,
        value: jsonEncode(accounts),
      );
    } catch (e) {
      throw Exception('Failed to store account information: $e');
    }
  }
  
  /// Gets the account information for a domain
  Future<Account?> getAccountInfo(String domain) async {
    try {
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      
      if (accountsJson != null) {
        final accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        
        if (accounts.containsKey(domain)) {
          return Account.fromJson(accounts[domain]);
        }
      }
      
      return null;
    } catch (e) {
      debugPrint('Failed to get account information: $e');
      return null;
    }
  }
  
  /// Checks if the user is authenticated with an instance
  Future<bool> isAuthenticated(String domain) async {
    // Normalize domain
    domain = _normalizeDomain(domain);
    
    final accessToken = await getAccessToken(domain);
    return accessToken != null;
  }
  
  /// Gets a list of authenticated instances
  Future<List<String>> getAuthenticatedInstances() async {
    try {
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      if (tokensJson != null) {
        final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
        return tokens.keys.toList();
      }
      
      return [];
    } catch (e) {
      debugPrint('Failed to get authenticated instances: $e');
      return [];
    }
  }
  
  /// Logs out from an instance
  Future<void> logout(String domain) async {
    try {
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      // Remove the access token
      final accessTokensJson = await _secureStorage.read(key: _accessTokensKey);
      if (accessTokensJson != null) {
        final accessTokens = jsonDecode(accessTokensJson) as Map<String, dynamic>;
        accessTokens.remove(domain);
        await _secureStorage.write(
          key: _accessTokensKey,
          value: jsonEncode(accessTokens),
        );
      }
      
      // Remove the refresh token
      final refreshTokensJson = await _secureStorage.read(key: _refreshTokensKey);
      if (refreshTokensJson != null) {
        final refreshTokens = jsonDecode(refreshTokensJson) as Map<String, dynamic>;
        refreshTokens.remove(domain);
        await _secureStorage.write(
          key: _refreshTokensKey,
          value: jsonEncode(refreshTokens),
        );
      }
      
      // Remove the account information
      final accountsJson = await _secureStorage.read(key: _accountsKey);
      if (accountsJson != null) {
        final accounts = jsonDecode(accountsJson) as Map<String, dynamic>;
        accounts.remove(domain);
        await _secureStorage.write(
          key: _accountsKey,
          value: jsonEncode(accounts),
        );
      }
    } catch (e) {
      throw Exception('Failed to logout: $e');
    }
  }
  
  /// Validates an access token
  Future<bool> validateAccessToken(String domain, String accessToken) async {
    try {
      // Normalize domain
      domain = _normalizeDomain(domain);
      
      final response = await _dio.get(
        'https://$domain/api/v1/apps/verify_credentials',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Failed to validate access token: $e');
      return false;
    }
  }
}
