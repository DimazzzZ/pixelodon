import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

@GenerateMocks([Dio, FlutterSecureStorage])
void main() {
  group('AuthService', () {
    late MockDio mockDio;
    late MockFlutterSecureStorage mockSecureStorage;
    late AuthService authService;

    setUp(() {
      mockDio = MockDio();
      mockSecureStorage = MockFlutterSecureStorage();
      authService = AuthService(
        dio: mockDio,
        secureStorage: mockSecureStorage,
      );
      
      // Mock client credentials for all tests
      when(mockSecureStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => '{"pixelfed.de":{"client_id":"test_client_id","client_secret":"test_client_secret"}}');
      
      // Mock storage write for all tests
      when(mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      )).thenAnswer((_) async => null);
      
      // Mock delete for all tests
      when(mockSecureStorage.delete(
        key: any(named: 'key'),
      )).thenAnswer((_) async => null);
    });
    
    // Helper function to verify HTTP Basic Auth is used
    void verifyBasicAuth() {
      verify(mockDio.post(
        any,
        options: argThat(
          predicate<Options>((options) {
            final headers = options.headers;
            return headers != null &&
                headers.containsKey('Authorization') &&
                (headers['Authorization'] as String).startsWith('Basic ');
          }),
        ),
        data: anyNamed('data'),
      )).called(1);
    }
    
    // Helper function to verify client credentials are not in request body
    void verifyNoClientCredentialsInBody(Map<String, dynamic> expectedFields) {
      verify(mockDio.post(
        any,
        options: anyNamed('options'),
        data: argThat(
          predicate<Map<String, dynamic>>((data) {
            // Verify that client_id and client_secret are NOT in the request body
            bool hasExpectedFields = true;
            for (var field in expectedFields.keys) {
              hasExpectedFields = hasExpectedFields && data.containsKey(field);
            }
            return hasExpectedFields &&
                !data.containsKey('client_id') &&
                !data.containsKey('client_secret');
          }),
        ),
      )).called(1);
    }

    test('exchangeAuthorizationCode should not include client credentials in request body', () async {
      // Mock token response
      when(mockDio.post(
        any,
        options: anyNamed('options'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {
              'access_token': 'test_access_token',
              'token_type': 'Bearer',
              'scope': 'read write follow push',
              'created_at': 1597944255,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      // Call the method
      await authService.exchangeAuthorizationCode('pixelfed.de', 'test_code', state: 'test_state');

      // Verify that the request was made with the correct data
      verifyNoClientCredentialsInBody({
        'redirect_uri': true,
        'grant_type': true,
        'code': true,
        'scope': true,
      });

      // Verify that the Authorization header was set with Basic auth
      verifyBasicAuth();
    });
    
    test('_refreshAccessToken should not include client credentials in request body', () async {
      // Mock token response
      when(mockDio.post(
        any,
        options: anyNamed('options'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {
              'access_token': 'new_test_access_token',
              'refresh_token': 'new_test_refresh_token',
              'token_type': 'Bearer',
              'scope': 'read write follow push',
              'created_at': 1597944255,
            },
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      // We need to access the private method using reflection
      // For testing purposes, we'll use the public method that calls it
      when(mockSecureStorage.read(key: '_access_tokens'))
          .thenAnswer((_) async => jsonEncode({
                'pixelfed.de': {
                  'access_token': 'old_access_token',
                  'refresh_token': 'test_refresh_token',
                  'expires_at': DateTime.now().subtract(Duration(hours: 1)).millisecondsSinceEpoch,
                  'token_type': 'Bearer',
                  'created_at': 1597944255,
                }
              }));

      // Call getAccessToken which will trigger _refreshAccessToken since the token is expired
      await authService.getAccessToken('pixelfed.de');

      // Verify that the request was made with the correct data
      verifyNoClientCredentialsInBody({
        'grant_type': true,
        'refresh_token': true,
        'scope': true,
      });

      // Verify that the Authorization header was set with Basic auth
      verifyBasicAuth();
    });
    
    test('revokeAccessToken should not include client credentials in request body', () async {
      // Mock token response
      when(mockDio.post(
        any,
        options: anyNamed('options'),
        data: anyNamed('data'),
      )).thenAnswer((_) async => Response(
            data: {},
            statusCode: 200,
            requestOptions: RequestOptions(path: ''),
          ));

      // Call the method
      await authService.revokeAccessToken('pixelfed.de', 'test_token');

      // Verify that the request was made with the correct data
      verifyNoClientCredentialsInBody({
        'token': true,
      });

      // Verify that the Authorization header was set with Basic auth
      verifyBasicAuth();
    });
  });
}
