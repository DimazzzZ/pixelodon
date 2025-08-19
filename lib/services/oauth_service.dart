import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class OAuthService {
  final Dio _dio;
  final FlutterSecureStorage _storage;
  static const String _codeVerifierKey = 'oauth_code_verifier';
  static const String _tokenKey = 'oauth_token';
  static const String _refreshTokenKey = 'oauth_refresh_token';
  static const String _tokenExpiryKey = 'oauth_token_expiry';

  OAuthService({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : _dio = dio ?? Dio(),
        _storage = storage ?? const FlutterSecureStorage();

  Future<String> generateCodeVerifier() async {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    final random = Random.secure();
    final verifier = List.generate(128, (_) => charset[random.nextInt(charset.length)]).join();
    await _storage.write(key: _codeVerifierKey, value: verifier);
    return verifier;
  }

  String generateCodeChallenge(String verifier) {
    final bytes = utf8.encode(verifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<Map<String, dynamic>> exchangeCodeForToken({
    required String code,
    required String redirectUri,
    required String clientId,
    required String tokenEndpoint,
  }) async {
    try {
      final codeVerifier = await _storage.read(key: _codeVerifierKey);
      if (codeVerifier == null) {
        throw Exception('Code verifier not found');
      }

      final response = await _dio.post(
        tokenEndpoint,
        data: {
          'client_id': clientId,
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'code_verifier': codeVerifier,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        await _storeTokens(tokenData);
        return tokenData;
      } else {
        throw DioException(
          requestOptions: response.requestOptions,
          response: response,
          error: 'Failed to exchange code for token',
        );
      }
    } catch (e) {
      if (e is DioException) {
        final errorMessage = e.response?.data?['error_description'] ?? 
                           e.response?.data?['error'] ?? 
                           'Network error occurred';
        throw Exception(errorMessage);
      }
      rethrow;
    }
  }

  Future<void> _storeTokens(Map<String, dynamic> tokenData) async {
    final expiresIn = tokenData['expires_in'] as int?;
    if (expiresIn != null) {
      final expiryDate = DateTime.now().add(Duration(seconds: expiresIn));
      await _storage.write(key: _tokenExpiryKey, value: expiryDate.toIso8601String());
    }
    
    await _storage.write(key: _tokenKey, value: tokenData['access_token']);
    if (tokenData['refresh_token'] != null) {
      await _storage.write(key: _refreshTokenKey, value: tokenData['refresh_token']);
    }
  }

  Future<bool> isTokenValid() async {
    final expiryStr = await _storage.read(key: _tokenExpiryKey);
    if (expiryStr == null) return false;
    
    final expiry = DateTime.parse(expiryStr);
    return DateTime.now().isBefore(expiry);
  }

  Future<Map<String, dynamic>?> refreshToken({
    required String clientId,
    required String tokenEndpoint,
  }) async {
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    if (refreshToken == null) return null;

    try {
      final response = await _dio.post(
        tokenEndpoint,
        data: {
          'client_id': clientId,
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
        ),
      );

      if (response.statusCode == 200) {
        final tokenData = response.data;
        await _storeTokens(tokenData);
        return tokenData;
      }
    } catch (e) {
      // If refresh fails, clear stored tokens
      await clearTokens();
      rethrow;
    }
    return null;
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenExpiryKey);
    await _storage.delete(key: _codeVerifierKey);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _tokenKey);
  }
}
