import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/services/auth_service.dart';

class TestDio implements Dio {
  Options? lastOptions;
  dynamic lastData;
  String? lastPath;

  Response Function(String path, {dynamic data, Options? options})? onPost;

  @override
  Future<Response<T>> post<T>(String path, {data, Options? options, CancelToken? cancelToken, ProgressCallback? onSendProgress, ProgressCallback? onReceiveProgress, Map<String, dynamic>? queryParameters}) async {
    lastPath = path;
    lastOptions = options;
    lastData = data;
    final resp = onPost?.call(path, data: data, options: options) ?? Response(requestOptions: RequestOptions(path: path), data: {}, statusCode: 200);
    return resp as Response<T>;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestSecureStorage extends FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<String?> read({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    return _store[key];
  }

  @override
  Future<void> write({required String key, required String? value, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({required String key, AppleOptions? iOptions, AndroidOptions? aOptions, LinuxOptions? lOptions, WebOptions? webOptions, AppleOptions? mOptions, WindowsOptions? wOptions}) async {
    _store.remove(key);
  }
}

void main() {
  group('AuthService', () {
    late TestDio testDio;
    late TestSecureStorage testStorage;
    late AuthService authService;

    setUp(() {
      testDio = TestDio();
      testStorage = TestSecureStorage();
      authService = AuthService(dio: testDio, secureStorage: testStorage);

      // Seed client credentials
      testStorage.write(key: '_client_credentials', value: '{"pixelfed.de":{"client_id":"test_client_id","client_secret":"test_client_secret"}}');
    });

    test('exchangeAuthorizationCode should not include client credentials in request body', () async {
      testDio.onPost = (path, {data, options}) {
        // Return token response
        return Response(
          data: {
            'access_token': 'test_access_token',
            'token_type': 'Bearer',
            'scope': 'read write follow push',
            'created_at': 1597944255,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      };

      await authService.exchangeAuthorizationCode('pixelfed.de', 'test_code', state: 'test_state');

      // Validate headers
      final headers = testDio.lastOptions?.headers ?? {};
      expect(headers['Authorization'], isNotNull);
      expect((headers['Authorization'] as String).startsWith('Basic '), isTrue);

      // Validate body
      final body = testDio.lastData as Map<String, dynamic>;
      expect(body.containsKey('client_id'), isFalse);
      expect(body.containsKey('client_secret'), isFalse);
      expect(body.containsKey('redirect_uri'), isTrue);
      expect(body.containsKey('grant_type'), isTrue);
      expect(body.containsKey('code'), isTrue);
      expect(body.containsKey('scope'), isTrue);
    });

    test('refreshAccessToken should not include client credentials in request body', () async {
      // Seed expired token so getAccessToken triggers refresh
      await testStorage.write(key: '_access_tokens', value: jsonEncode({
        'pixelfed.de': {
          'access_token': 'old_access_token',
          'refresh_token': 'test_refresh_token',
          'expires_at': DateTime.now().subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
          'token_type': 'Bearer',
        }
      }));

      testDio.onPost = (path, {data, options}) {
        return Response(
          data: {
            'access_token': 'new_test_access_token',
            'refresh_token': 'new_test_refresh_token',
            'token_type': 'Bearer',
            'scope': 'read write follow push',
            'created_at': 1597944255,
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      };

      await authService.getAccessToken('pixelfed.de');

      final headers = testDio.lastOptions?.headers ?? {};
      expect(headers['Authorization'], isNotNull);
      expect((headers['Authorization'] as String).startsWith('Basic '), isTrue);

      final body = testDio.lastData as Map<String, dynamic>;
      expect(body.containsKey('client_id'), isFalse);
      expect(body.containsKey('client_secret'), isFalse);
      expect(body['grant_type'], 'refresh_token');
      expect(body['refresh_token'], 'test_refresh_token');
      expect(body.containsKey('scope'), isTrue);
    });

    test('revokeAccessToken should not include client credentials in request body', () async {
      testDio.onPost = (path, {data, options}) {
        return Response(
          data: {},
          statusCode: 200,
          requestOptions: RequestOptions(path: path),
        );
      };

      await authService.revokeAccessToken('pixelfed.de', 'test_token');

      final headers = testDio.lastOptions?.headers ?? {};
      expect(headers['Authorization'], isNotNull);
      expect((headers['Authorization'] as String).startsWith('Basic '), isTrue);

      final body = testDio.lastData as Map<String, dynamic>;
      expect(body.containsKey('client_id'), isFalse);
      expect(body.containsKey('client_secret'), isFalse);
      expect(body['token'], 'test_token');
    });
  });
}
