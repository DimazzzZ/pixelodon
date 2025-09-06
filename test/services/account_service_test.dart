import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/services/account_service.dart';

import 'account_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('AccountService Tests', () {
    late AccountService accountService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      accountService = AccountService(apiService: mockApiService);
    });

    group('Constructor', () {
      test('should create AccountService with required dependencies', () {
        expect(accountService, isA<AccountService>());
      });
    });

    group('getVerifyCredentials', () {
      test('should return account when API call succeeds', () async {
        const domain = 'mastodon.social';
        final mockResponse = Response(
          data: {
            'id': '123',
            'username': 'testuser',
            'display_name': 'Test User',
            'acct': 'testuser',
            'url': 'https://mastodon.social/@testuser',
            'avatar': 'https://example.com/avatar.jpg',
            'header': 'https://example.com/header.jpg',
            'note': 'Test bio',
            'followers_count': 100,
            'following_count': 50,
            'statuses_count': 25,
            'created_at': '2023-01-01T00:00:00.000Z',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get('https://$domain/api/v1/accounts/verify_credentials'))
            .thenAnswer((_) async => mockResponse);

        final result = await accountService.getVerifyCredentials(domain);

        expect(result, isA<Account>());
        expect(result.id, equals('123'));
        expect(result.username, equals('testuser'));
        verify(mockApiService.get('https://$domain/api/v1/accounts/verify_credentials')).called(1);
      });

      test('should throw exception when API call fails', () async {
        const domain = 'mastodon.social';
        
        when(mockApiService.get('https://$domain/api/v1/accounts/verify_credentials'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 401,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        expect(
          () => accountService.getVerifyCredentials(domain),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getAccount', () {
      test('should return account when API call succeeds', () async {
        const domain = 'mastodon.social';
        const accountId = '123';
        final mockResponse = Response(
          data: {
            'id': accountId,
            'username': 'testuser',
            'display_name': 'Test User',
            'acct': 'testuser',
            'url': 'https://mastodon.social/@testuser',
            'avatar': 'https://example.com/avatar.jpg',
            'header': 'https://example.com/header.jpg',
            'note': 'Test bio',
            'followers_count': 100,
            'following_count': 50,
            'statuses_count': 25,
            'created_at': '2023-01-01T00:00:00.000Z',
          },
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get('https://$domain/api/v1/accounts/$accountId'))
            .thenAnswer((_) async => mockResponse);

        final result = await accountService.getAccount(domain, accountId);

        expect(result, isA<Account>());
        expect(result.id, equals(accountId));
        verify(mockApiService.get('https://$domain/api/v1/accounts/$accountId')).called(1);
      });

      test('should throw exception when account not found', () async {
        const domain = 'mastodon.social';
        const accountId = 'nonexistent';
        
        when(mockApiService.get('https://$domain/api/v1/accounts/$accountId'))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              response: Response(
                statusCode: 404,
                requestOptions: RequestOptions(path: ''),
              ),
            ));

        expect(
          () => accountService.getAccount(domain, accountId),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('searchAccounts', () {
      test('should return list of accounts when search succeeds', () async {
        const domain = 'mastodon.social';
        const query = 'test';
        final mockResponse = Response(
          data: [
            {
              'id': '123',
              'username': 'testuser1',
              'display_name': 'Test User 1',
              'acct': 'testuser1',
              'url': 'https://mastodon.social/@testuser1',
              'avatar': 'https://example.com/avatar1.jpg',
              'header': 'https://example.com/header1.jpg',
              'note': 'Test bio 1',
              'followers_count': 100,
              'following_count': 50,
              'statuses_count': 25,
              'created_at': '2023-01-01T00:00:00.000Z',
            },
            {
              'id': '456',
              'username': 'testuser2',
              'display_name': 'Test User 2',
              'acct': 'testuser2',
              'url': 'https://mastodon.social/@testuser2',
              'avatar': 'https://example.com/avatar2.jpg',
              'header': 'https://example.com/header2.jpg',
              'note': 'Test bio 2',
              'followers_count': 200,
              'following_count': 75,
              'statuses_count': 50,
              'created_at': '2023-01-01T00:00:00.000Z',
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/accounts/search',
          queryParameters: {'q': query},
        )).thenAnswer((_) async => mockResponse);

        final result = await accountService.searchAccounts(domain, query: query);

        expect(result, isA<List<Account>>());
        expect(result.length, equals(2));
        expect(result[0].username, equals('testuser1'));
        expect(result[1].username, equals('testuser2'));
      });

      test('should return empty list when no accounts found', () async {
        const domain = 'mastodon.social';
        const query = 'nonexistent';
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/accounts/search',
          queryParameters: {'q': query},
        )).thenAnswer((_) async => mockResponse);

        final result = await accountService.searchAccounts(domain, query: query);

        expect(result, isA<List<Account>>());
        expect(result.isEmpty, isTrue);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        const domain = 'mastodon.social';
        
        when(mockApiService.get(any))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        expect(
          () => accountService.getVerifyCredentials(domain),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle malformed response data', () async {
        const domain = 'mastodon.social';
        final mockResponse = Response(
          data: 'invalid json',
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get('https://$domain/api/v1/accounts/verify_credentials'))
            .thenAnswer((_) async => mockResponse);

        expect(
          () => accountService.getVerifyCredentials(domain),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
