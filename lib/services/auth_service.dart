import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixelodon/models/instance.dart';

/// Service for handling authentication with Mastodon and Pixelfed instances
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;
  
  /// Constructor
  AuthService({
    Dio? dio,
    FlutterSecureStorage? secureStorage,
  }) : _dio = dio ?? Dio(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();
       
  /// Testing method to expose _isRedirectUriSafe for unit tests
  /// This should only be used in tests
  bool isRedirectUriSafeForTesting(String uri) {
    return _isRedirectUriSafe(uri);
  }
  
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
  static const String _clientCredentialsKey = 'client_credentials';
  
  /// Key for storing access tokens in secure storage
  static const String _accessTokensKey = 'access_tokens';
  
  /// Key for storing PKCE code verifiers in secure storage
  static const String _pkceVerifiersKey = 'pkce_verifiers';
  
  /// Discovers an instance by its domain
  /// 
  /// Returns an [Instance] object with information about the instance
  Future<Instance> discoverInstance(String domain) async {
    try {
      // Normalize domain
      domain = domain.toLowerCase().trim();
      if (domain.startsWith('http://') || domain.startsWith('https://')) {
        final uri = Uri.parse(domain);
        domain = uri.host;
      }
      
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
      // Note: Uri.parse() already separates the scheme from '://'
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
  
  /// Validates an authorization URL to ensure it's properly formed
  /// 
  /// Returns true if the URL is valid, false otherwise
  bool _isAuthorizationUrlValid(String url) {
    try {
      debugPrint('Validating authorization URL: $url');
      final uri = Uri.parse(url);
      
      // Check for required parameters
      final requiredParams = ['client_id', 'redirect_uri', 'response_type', 'scope', 'state'];
      for (final param in requiredParams) {
        if (!uri.queryParameters.containsKey(param)) {
          debugPrint('Missing required parameter: $param');
          return false;
        }
      }
      
      // Check that response_type is 'code'
      if (uri.queryParameters['response_type'] != 'code') {
        debugPrint('response_type is not "code"');
        return false;
      }
      
      // Check that the redirect URI is safe
      final redirectUri = uri.queryParameters['redirect_uri'];
      if (redirectUri != null && !_isRedirectUriSafe(redirectUri)) {
        debugPrint('Redirect URI is not safe: $redirectUri');
        return false;
      }
      
      // Make sure domain parameter is included
      if (!uri.queryParameters.containsKey('domain')) {
        debugPrint('Warning: domain parameter is missing');
      }
      
      debugPrint('Authorization URL is valid');
      return true;
    } catch (e) {
      debugPrint('Error validating authorization URL: $e');
      return false;
    }
  }
  
  /// Gets the authorization URL for an instance
  /// 
  /// Returns the URL to redirect the user to and the state to verify the callback
  Future<Map<String, String>> getAuthorizationUrl(String domain) async {
    debugPrint('Getting authorization URL for domain: $domain');
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
    
    // Validate the URL
    if (!_isAuthorizationUrlValid(url)) {
      debugPrint('Authorization URL is invalid');
      throw Exception('Invalid authorization URL');
    }
    
    return {
      'url': url,
      'state': state,
    };
  }
  
  /// Exchanges an authorization code for an access token
  /// 
  /// Returns an access token
  Future<String> exchangeAuthorizationCode(
    String domain, 
    String code,
    {String? state}
  ) async {
    try {
      debugPrint('Exchanging authorization code for domain: $domain, code: $code, state: $state');
      final credentials = await getClientCredentials(domain);
      debugPrint('Got client credentials: client_id=${credentials['client_id']}');
      
      // Use HTTP Basic Auth for client authentication
      final clientId = credentials['client_id']!;
      final clientSecret = credentials['client_secret']!;
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
      
      // Prepare request data
      final Map<String, dynamic> requestData = {
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'scope': _scopes,
      };
      debugPrint('Request data: $requestData');
      
      // Add code_verifier if we have a state parameter (PKCE flow)
      if (state != null && state.isNotEmpty) {
        final codeVerifier = await _getAndRemoveCodeVerifier(domain, state);
        debugPrint('Code verifier for state $state: ${codeVerifier != null ? 'found' : 'not found'}');
        if (codeVerifier != null) {
          requestData['code_verifier'] = codeVerifier;
        } else {
          debugPrint('Warning: No code verifier found for state $state. PKCE validation may fail.');
        }
      }
      
      debugPrint('Sending token request to https://$domain/oauth/token');
      final response = await _dio.post(
        'https://$domain/oauth/token',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
        data: requestData,
      );
      
      // Check for error responses
      if (response.statusCode != 200) {
        final errorData = response.data;
        final errorMessage = errorData['error_description'] ?? errorData['error'] ?? 'Unknown error';
        debugPrint('Token request failed with status ${response.statusCode}: $errorMessage');
        throw Exception('Failed to obtain access token: $errorMessage');
      }
      
      final accessToken = response.data['access_token'];
      final refreshToken = response.data['refresh_token'];
      final expiresIn = response.data['expires_in'];
      final tokenType = response.data['token_type'];
      
      // Calculate token expiration time
      final expirationTime = expiresIn != null 
          ? DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch 
          : null;
      
      // Save the tokens and related information
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) 
          : {};
      
      tokens[domain] = {
        'access_token': accessToken,
        'refresh_token': refreshToken,
        'expires_at': expirationTime,
        'token_type': tokenType,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _secureStorage.write(
        key: _accessTokensKey,
        value: jsonEncode(tokens),
      );
      
      debugPrint('Successfully obtained access token');
      return accessToken;
    } catch (e) {
      debugPrint('Error exchanging authorization code: $e');
      if (e is DioException) {
        debugPrint('DioError type: ${e.type}');
        debugPrint('DioError message: ${e.message}');
        
        if (e.response != null) {
          debugPrint('DioError status code: ${e.response?.statusCode}');
          debugPrint('DioError response: ${e.response?.data}');
          
          // Handle specific error cases
          if (e.response?.statusCode == 400) {
            final errorData = e.response?.data;
            if (errorData is Map) {
              final errorType = errorData['error'];
              if (errorType == 'invalid_grant') {
                throw Exception('Authorization code is invalid or expired. Please try logging in again.');
              } else if (errorType == 'invalid_client') {
                throw Exception('Client authentication failed. Please try again.');
              }
            }
          }
        }
      }
      throw Exception('Failed to exchange authorization code. Please try again.');
    }
  }
  
  /// Gets the access token for an instance
  /// 
  /// Returns the access token or null if not authenticated
  /// Automatically refreshes the token if it's expired
  Future<String?> getAccessToken(String domain) async {
    final tokensJson = await _secureStorage.read(key: _accessTokensKey);
    
    if (tokensJson != null) {
      final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
      
      if (tokens.containsKey(domain)) {
        final tokenData = tokens[domain];
        
        // Handle both old format (string) and new format (map)
        if (tokenData is String) {
          return tokenData;
        } else if (tokenData is Map) {
          final accessToken = tokenData['access_token'];
          final refreshToken = tokenData['refresh_token'];
          final expiresAt = tokenData['expires_at'];
          
          // Check if token is expired
          if (expiresAt != null) {
            final now = DateTime.now().millisecondsSinceEpoch;
            final isExpired = now > expiresAt;
            
            // If token is expired and we have a refresh token, try to refresh
            if (isExpired && refreshToken != null) {
              debugPrint('Access token for $domain is expired, attempting to refresh');
              try {
                final newAccessToken = await _refreshAccessToken(domain, refreshToken);
                return newAccessToken;
              } catch (e) {
                debugPrint('Failed to refresh token: $e');
                // If refresh fails, return the existing token and let the API call fail
                // This way the user will be prompted to re-authenticate
              }
            }
          }
          
          return accessToken;
        }
      }
    }
    
    return null;
  }
  
  /// Refreshes an access token using a refresh token
  /// 
  /// Returns a new access token
  Future<String> _refreshAccessToken(String domain, String refreshToken) async {
    try {
      debugPrint('Refreshing access token for domain: $domain');
      final credentials = await getClientCredentials(domain);
      
      final clientId = credentials['client_id']!;
      final clientSecret = credentials['client_secret']!;
      
      // Use HTTP Basic Auth for client authentication
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
      
      final response = await _dio.post(
        'https://$domain/oauth/token',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
        data: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'scope': _scopes,
        },
      );
      
      final newAccessToken = response.data['access_token'];
      final newRefreshToken = response.data['refresh_token'] ?? refreshToken;
      final expiresIn = response.data['expires_in'];
      final tokenType = response.data['token_type'];
      
      // Calculate token expiration time
      final expirationTime = expiresIn != null 
          ? DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch 
          : null;
      
      // Update the stored tokens
      final tokensJson = await _secureStorage.read(key: _accessTokensKey);
      final Map<String, dynamic> tokens = tokensJson != null 
          ? jsonDecode(tokensJson) 
          : {};
      
      tokens[domain] = {
        'access_token': newAccessToken,
        'refresh_token': newRefreshToken,
        'expires_at': expirationTime,
        'token_type': tokenType,
        'created_at': DateTime.now().millisecondsSinceEpoch,
      };
      
      await _secureStorage.write(
        key: _accessTokensKey,
        value: jsonEncode(tokens),
      );
      
      debugPrint('Successfully refreshed access token');
      return newAccessToken;
    } catch (e) {
      debugPrint('Error refreshing access token: $e');
      throw Exception('Failed to refresh access token: $e');
    }
  }
  
  /// Checks if the user is authenticated with an instance
  /// 
  /// Returns true if authenticated
  Future<bool> isAuthenticated(String domain) async {
    final accessToken = await getAccessToken(domain);
    return accessToken != null;
  }
  
  /// Revokes an access token with the server
  /// 
  /// Returns true if successful
  Future<bool> revokeAccessToken(String domain, String token) async {
    try {
      final credentials = await getClientCredentials(domain);
      
      // Use HTTP Basic Auth for client authentication
      final clientId = credentials['client_id']!;
      final clientSecret = credentials['client_secret']!;
      final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
      
      await _dio.post(
        'https://$domain/oauth/revoke',
        options: Options(
          headers: {
            'Authorization': basicAuth,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
        data: {
          'token': token,
        },
      );
      
      return true;
    } catch (e) {
      debugPrint('Failed to revoke token: $e');
      return false;
    }
  }
  
  /// Logs out from an instance
  /// 
  /// Removes the access token and attempts to revoke it
  Future<void> logout(String domain) async {
    final tokensJson = await _secureStorage.read(key: _accessTokensKey);
    
    if (tokensJson != null) {
      final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
      
      if (tokens.containsKey(domain)) {
        final tokenData = tokens[domain];
        String? accessToken;
        String? refreshToken;
        
        // Handle both old format (string) and new format (map)
        if (tokenData is String) {
          accessToken = tokenData;
        } else if (tokenData is Map) {
          accessToken = tokenData['access_token'];
          refreshToken = tokenData['refresh_token'];
        }
        
        if (accessToken != null) {
          // Try to revoke the access token with the server
          try {
            await revokeAccessToken(domain, accessToken);
          } catch (e) {
            debugPrint('Error revoking access token: $e');
            // Continue with logout even if revocation fails
          }
          
          // Try to revoke the refresh token if available
          if (refreshToken != null) {
            try {
              await revokeAccessToken(domain, refreshToken);
            } catch (e) {
              debugPrint('Error revoking refresh token: $e');
              // Continue with logout even if revocation fails
            }
          }
        }
        
        // Remove the token from local storage
        tokens.remove(domain);
        
        await _secureStorage.write(
          key: _accessTokensKey,
          value: jsonEncode(tokens),
        );
        
        debugPrint('Successfully logged out from $domain');
      }
    }
  }
  
  /// Gets all authenticated instances
  /// 
  /// Returns a list of domains
  Future<List<String>> getAuthenticatedInstances() async {
    final tokensJson = await _secureStorage.read(key: _accessTokensKey);
    
    if (tokensJson != null) {
      final tokens = jsonDecode(tokensJson) as Map<String, dynamic>;
      return tokens.keys.toList();
    }
    
    return [];
  }
}
