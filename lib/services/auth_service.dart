import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixelodon/models/instance.dart';

/// A complete AuthService supporting per-instance OAuth2 (code/implicit),
/// multiple accounts (Mastodon + Pixelfed), and per-account settings.
class AuthService {
  final Dio _dio;
  final FlutterSecureStorage _secureStorage;

  AuthService({Dio? dio, FlutterSecureStorage? secureStorage})
      : _dio = dio ?? Dio(),
        _secureStorage = secureStorage ?? const FlutterSecureStorage();

  // OAuth configuration
  static const String _clientName = 'Pixelodon';
  static const String _clientWebsite = 'https://pixelodon.app';
  static const String _redirectUri = 'pixelodon://oauth/callback';
  static const String _scopes = 'read write follow push';

  // Storage keys (kept compatible with tests where applicable)
  static const String _clientCredentialsKey = '_client_credentials';
  static const String _accessTokensKey = '_access_tokens';
  static const String _pkceVerifiersKey = '_pkce_verifiers';
  static const String _accountSettingsKey = '_account_settings';

  // Backward-compat simple keys (for legacy callers like AuthNotifier)
  static const String _legacyTokenKey = 'auth_token';
  static const String _legacyUserIdKey = 'user_id';

  // ------------------------
  // Instance discovery
  // ------------------------
  Future<Instance> discoverInstance(String domain) async {
    final normalized = _normalizeDomain(domain);
    final resp = await _dio.get('https://$normalized/api/v1/instance');
    final data = resp.data as Map<String, dynamic>;

    final version = data['version']?.toString();
    final isPixelfed = (version ?? '').toLowerCase().contains('pixelfed');

    return Instance(
      domain: normalized,
      name: data['title'] ?? normalized,
      description: data['description'],
      version: version,
      thumbnail: data['thumbnail'],
      languages: data['languages'] != null ? List<String>.from(data['languages']) : null,
      maxCharsPerPost: data['configuration']?['statuses']?['max_characters'],
      maxMediaAttachments: data['configuration']?['statuses']?['max_media_attachments'],
      isPixelfed: isPixelfed,
      supportsStories: false,
      tosUrl: data['urls']?['terms'],
      privacyPolicyUrl: data['urls']?['privacy'],
      contactEmail: data['email'],
    );
  }

  // ------------------------
  // OAuth client registration and credentials
  // ------------------------
  Future<Map<String, String>> _registerApp(String domain) async {
    final normalized = _normalizeDomain(domain);
    if (!isRedirectUriSafeForTesting(_redirectUri)) {
      throw Exception('Unsafe redirect URI');
    }
    final resp = await _dio.post(
      'https://$normalized/api/v1/apps',
      data: {
        'client_name': _clientName,
        'redirect_uris': _redirectUri,
        'scopes': _scopes,
        'website': _clientWebsite,
      },
    );
    return {
      'client_id': resp.data['client_id'] as String,
      'client_secret': resp.data['client_secret'] as String,
    };
  }

  Future<Map<String, String>> getClientCredentials(String domain) async {
    final normalized = _normalizeDomain(domain);
    final jsonStr = await _secureStorage.read(key: _clientCredentialsKey);
    Map<String, dynamic> all = {};
    if (jsonStr != null) {
      try { all = jsonDecode(jsonStr) as Map<String, dynamic>; } catch (_) {}
    }
    if (all.containsKey(normalized)) {
      return Map<String, String>.from(all[normalized] as Map);
    }
    final creds = await _registerApp(normalized);
    all[normalized] = creds;
    await _secureStorage.write(key: _clientCredentialsKey, value: jsonEncode(all));
    return creds;
  }

  // ------------------------
  // Authorization URL (OAuth2 Code flow with PKCE)
  // ------------------------
  Future<Map<String, String>> getAuthorizationUrl(String domain) async {
    final normalized = _normalizeDomain(domain);
    final creds = await getClientCredentials(normalized);
    final state = _generateState();

    // PKCE
    final verifier = _generateCodeVerifier();
    final challenge = _generateCodeChallenge(verifier);
    await _storeCodeVerifier(normalized, state, verifier);

    final url = 'https://$normalized/oauth/authorize?'
        'client_id=${Uri.encodeComponent(creds['client_id']!)}&'
        'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
        'response_type=code&'
        'scope=${Uri.encodeComponent(_scopes)}&'
        'state=$state&'
        'code_challenge=$challenge&'
        'code_challenge_method=S256';

    return {'url': url, 'state': state};
  }

  // ------------------------
  // Authorization URL (OAuth2 Implicit flow)
  // ------------------------
  Future<Map<String, String>> getImplicitAuthorizationUrl(String domain) async {
    final normalized = _normalizeDomain(domain);
    final creds = await getClientCredentials(normalized);
    final state = _generateState();

    final url = 'https://$normalized/oauth/authorize?'
        'client_id=${Uri.encodeComponent(creds['client_id']!)}&'
        'redirect_uri=${Uri.encodeComponent(_redirectUri)}&'
        'response_type=token&'
        'scope=${Uri.encodeComponent(_scopes)}&'
        'state=$state';

    return {'url': url, 'state': state};
  }

  /// Handle implicit callback: parse fragment for access_token etc. and store
  Future<void> handleImplicitCallback(String domain, Uri callbackUri, {String? expectedState}) async {
    final normalized = _normalizeDomain(domain);
    // The implicit flow returns params in fragment
    final fragment = callbackUri.fragment;
    if (fragment.isEmpty) {
      throw Exception('Missing fragment in callback');
    }
    final map = <String, String>{};
    for (final part in fragment.split('&')) {
      final idx = part.indexOf('=');
      if (idx > 0) {
        final k = Uri.decodeComponent(part.substring(0, idx));
        final v = Uri.decodeComponent(part.substring(idx + 1));
        map[k] = v;
      }
    }
    if (expectedState != null && map['state'] != expectedState) {
      throw Exception('State mismatch');
    }
    final accessToken = map['access_token'];
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('No access token in callback');
    }
    final expiresIn = int.tryParse(map['expires_in'] ?? '0');
    await _storeToken(normalized, accessToken, expiresIn: expiresIn);
  }

  // ------------------------
  // Token exchange/refresh using Basic auth header (no creds in body)
  // ------------------------
  Future<Map<String, String>> exchangeAuthorizationCode(
    String domain,
    String code, {
    String? state,
  }) async {
    final normalized = _normalizeDomain(domain);
    final creds = await getClientCredentials(normalized);

    final verifier = await _getAndRemoveCodeVerifier(normalized, state);

    final basic = _basicHeader(creds['client_id']!, creds['client_secret']!);
    final response = await _dio.post(
      'https://$normalized/oauth/token',
      data: {
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
        'code': code,
        'scope': _scopes,
        if (verifier != null) 'code_verifier': verifier,
      },
      options: Options(headers: {'Authorization': 'Basic $basic'}),
    );

    final accessToken = response.data['access_token'] as String;
    final refreshToken = response.data['refresh_token'] as String?;
    final expiresIn = (response.data['expires_in'] ?? 0) as int;

    await _storeToken(normalized, accessToken, refreshToken: refreshToken, expiresIn: expiresIn);

    // Optionally, could fetch account info here

    return {
      'access_token': accessToken,
      'refresh_token': refreshToken ?? '',
    };
  }

  Future<Map<String, String>> refreshAccessToken(String domain) async {
    final normalized = _normalizeDomain(domain);
    final tokensMap = await _readTokens();
    final entry = tokensMap[normalized] as Map<String, dynamic>?;
    if (entry == null || entry['refresh_token'] == null) {
      throw Exception('No refresh token available');
    }

    final creds = await getClientCredentials(normalized);
    final basic = _basicHeader(creds['client_id']!, creds['client_secret']!);

    final response = await _dio.post(
      'https://$normalized/oauth/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': entry['refresh_token'],
        'scope': _scopes,
      },
      options: Options(headers: {'Authorization': 'Basic $basic'}),
    );

    final newAccess = response.data['access_token'] as String;
    final newRefresh = response.data['refresh_token'] as String? ?? entry['refresh_token'] as String;
    final expiresIn = (response.data['expires_in'] ?? 0) as int;

    await _storeToken(normalized, newAccess, refreshToken: newRefresh, expiresIn: expiresIn);

    return {
      'access_token': newAccess,
      'refresh_token': newRefresh,
    };
  }

  Future<void> revokeAccessToken(String domain, String token) async {
    final normalized = _normalizeDomain(domain);
    final creds = await getClientCredentials(normalized);
    final basic = _basicHeader(creds['client_id']!, creds['client_secret']!);

    await _dio.post(
      'https://$normalized/oauth/revoke',
      data: {
        'token': token,
      },
      options: Options(headers: {'Authorization': 'Basic $basic'}),
    );
  }

  // ------------------------
  // Access helpers
  // ------------------------
  Future<bool> isAuthenticated(String domain) async {
    final token = await getAccessToken(domain);
    return token != null;
  }

  Future<String?> getAccessToken(String domain) async {
    final normalized = _normalizeDomain(domain);
    final tokens = await _readTokens();
    final entry = tokens[normalized] as Map<String, dynamic>?;
    if (entry == null) return null;

    final expiresAt = entry['expires_at'] as int?;
    if (expiresAt != null && DateTime.now().millisecondsSinceEpoch >= expiresAt) {
      // Attempt refresh
      try {
        await refreshAccessToken(normalized);
        final updated = await _readTokens();
        return (updated[normalized] as Map<String, dynamic>?)?['access_token'] as String?;
      } catch (e) {
        debugPrint('Token refresh failed: $e');
        return entry['access_token'] as String?; // fall back if any
      }
    }
    return entry['access_token'] as String?;
  }

  Future<List<String>> getAuthenticatedInstances() async {
    final tokens = await _readTokens();
    return tokens.keys.map((e) => e.toString()).toList();
  }

  Future<void> logout(String domain) async {
    final normalized = _normalizeDomain(domain);
    final tokens = await _readTokens();
    tokens.remove(normalized);
    await _secureStorage.write(key: _accessTokensKey, value: jsonEncode(tokens));
  }

  // ------------------------
  // Per-account settings
  // ------------------------
  Future<Map<String, dynamic>?> getAccountSettings(String domain) async {
    final normalized = _normalizeDomain(domain);
    final jsonStr = await _secureStorage.read(key: _accountSettingsKey);
    if (jsonStr == null) return null;
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return map[normalized] as Map<String, dynamic>?;
    } catch (_) {
      return null;
    }
  }

  Future<void> setAccountSettings(String domain, Map<String, dynamic> settings) async {
    final normalized = _normalizeDomain(domain);
    final jsonStr = await _secureStorage.read(key: _accountSettingsKey);
    Map<String, dynamic> all = {};
    if (jsonStr != null) {
      try { all = jsonDecode(jsonStr) as Map<String, dynamic>; } catch (_) {}
    }
    all[normalized] = settings;
    await _secureStorage.write(key: _accountSettingsKey, value: jsonEncode(all));
  }

  // ------------------------
  // Utilities & storage helpers
  // ------------------------
  String _normalizeDomain(String domain) {
    var d = domain.trim().toLowerCase();
    if (d.startsWith('http://') || d.startsWith('https://')) {
      d = Uri.parse(d).host;
    }
    return d;
  }

  String _generateState() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rnd = Random.secure();
    return List.generate(32, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  String _generateCodeVerifier() {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final rnd = Random.secure();
    return List.generate(128, (_) => charset[rnd.nextInt(charset.length)]).join();
  }

  String _base64UrlNoPadding(Uint8List data) {
    return base64Url.encode(data).replaceAll('=', '');
  }

  String _generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return _base64UrlNoPadding(Uint8List.fromList(digest.bytes));
  }

  Future<void> _storeCodeVerifier(String domain, String state, String verifier) async {
    final jsonStr = await _secureStorage.read(key: _pkceVerifiersKey);
    Map<String, dynamic> all = {};
    if (jsonStr != null) {
      try { all = jsonDecode(jsonStr) as Map<String, dynamic>; } catch (_) {}
    }
    final key = '$domain|$state';
    all[key] = verifier;
    await _secureStorage.write(key: _pkceVerifiersKey, value: jsonEncode(all));
  }

  Future<String?> _getAndRemoveCodeVerifier(String domain, String? state) async {
    if (state == null) return null;
    final jsonStr = await _secureStorage.read(key: _pkceVerifiersKey);
    if (jsonStr == null) return null;
    Map<String, dynamic> all;
    try {
      all = jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
    final key = '$domain|$state';
    final verifier = all[key] as String?;
    if (verifier != null) {
      all.remove(key);
      await _secureStorage.write(key: _pkceVerifiersKey, value: jsonEncode(all));
    }
    return verifier;
  }

  String _basicHeader(String clientId, String clientSecret) {
    final raw = utf8.encode('$clientId:$clientSecret');
    return base64Encode(raw);
  }

  Future<Map<String, dynamic>> _readTokens() async {
    final jsonStr = await _secureStorage.read(key: _accessTokensKey);
    if (jsonStr == null) return {};
    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }

  Future<void> _storeToken(String domain, String accessToken, {String? refreshToken, int? expiresIn}) async {
    final all = await _readTokens();
    final expiresAt = expiresIn != null && expiresIn > 0
        ? DateTime.now().add(Duration(seconds: expiresIn)).millisecondsSinceEpoch
        : null;
    all[domain] = {
      'access_token': accessToken,
      if (refreshToken != null) 'refresh_token': refreshToken,
      if (expiresAt != null) 'expires_at': expiresAt,
      'token_type': 'Bearer',
    };
    await _secureStorage.write(key: _accessTokensKey, value: jsonEncode(all));
  }

  // ------------------------
  // Legacy compatibility methods (no-ops for old simple provider)
  // ------------------------
  Future<void> saveAuthToken(String token) async {
    await _secureStorage.write(key: _legacyTokenKey, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _secureStorage.read(key: _legacyTokenKey);
  }

  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _legacyUserIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _secureStorage.read(key: _legacyUserIdKey);
  }

  Future<void> clearAuth() async {
    await _secureStorage.delete(key: _legacyTokenKey);
    await _secureStorage.delete(key: _legacyUserIdKey);
  }

  Future<bool> isAuthenticatedLegacy() async {
    final token = await getAuthToken();
    return token != null;
  }


  // ------------------------
  // Testing helper (exposes redirect URI validation rule)
  // ------------------------
  bool isRedirectUriSafeForTesting(String uri) {
    try {
      final parsed = Uri.parse(uri);
      const dangerous = ['javascript', 'data', 'vbscript', 'file'];
      if (dangerous.contains(parsed.scheme.toLowerCase())) return false;
      if (parsed.scheme != 'https' && parsed.scheme != 'pixelodon') return false;
      return true;
    } catch (_) {
      return false;
    }
  }
}
