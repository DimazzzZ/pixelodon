import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/services/timeline_service.dart';

import 'timeline_service_test.mocks.dart';

@GenerateMocks([ApiService])
void main() {
  group('TimelineService Tests', () {
    late TimelineService timelineService;
    late MockApiService mockApiService;

    setUp(() {
      mockApiService = MockApiService();
      timelineService = TimelineService(apiService: mockApiService);
    });

    group('Constructor', () {
      test('should create TimelineService with required dependencies', () {
        expect(timelineService, isA<TimelineService>());
      });
    });

    group('getHomeTimeline', () {
      test('should return list of statuses when API call succeeds', () async {
        const domain = 'mastodon.social';
        final mockResponse = Response(
          data: [
            {
              'id': '123',
              'content': 'Test status 1',
              'created_at': '2023-01-01T00:00:00.000Z',
              'account': {
                'id': '456',
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
              'media_attachments': [],
              'mentions': [],
              'tags': [],
              'emojis': [],
              'reblogs_count': 0,
              'favourites_count': 0,
              'replies_count': 0,
              'url': 'https://mastodon.social/@testuser/123',
              'in_reply_to_id': null,
              'in_reply_to_account_id': null,
              'reblog': null,
              'poll': null,
              'card': null,
              'language': 'en',
              'text': 'Test status 1',
              'favourited': false,
              'reblogged': false,
              'muted': false,
              'bookmarked': false,
              'pinned': false,
              'sensitive': false,
              'spoiler_text': '',
              'visibility': 'public',
              'application': null,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {},
        )).thenAnswer((_) async => mockResponse);

        final result = await timelineService.getHomeTimeline(domain);

        expect(result, isA<List<Status>>());
        expect(result.length, equals(1));
        expect(result[0].id, equals('123'));
        expect(result[0].content, equals('Test status 1'));
        verify(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {},
        )).called(1);
      });

      test('should include query parameters when provided', () async {
        const domain = 'mastodon.social';
        const limit = 20;
        const maxId = '100';
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {
            'limit': limit,
            'max_id': maxId,
          },
        )).thenAnswer((_) async => mockResponse);

        await timelineService.getHomeTimeline(
          domain,
          limit: limit,
          maxId: maxId,
        );

        verify(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {
            'limit': limit,
            'max_id': maxId,
          },
        )).called(1);
      });

      test('should throw exception when API call fails', () async {
        const domain = 'mastodon.social';
        
        when(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {},
        )).thenThrow(DioException(
          requestOptions: RequestOptions(path: ''),
          response: Response(
            statusCode: 401,
            requestOptions: RequestOptions(path: ''),
          ),
        ));

        expect(
          () => timelineService.getHomeTimeline(domain),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('getPublicTimeline', () {
      test('should return list of statuses when API call succeeds', () async {
        const domain = 'mastodon.social';
        final mockResponse = Response(
          data: [
            {
              'id': '789',
              'content': 'Public status',
              'created_at': '2023-01-01T00:00:00.000Z',
              'account': {
                'id': '456',
                'username': 'publicuser',
                'display_name': 'Public User',
                'acct': 'publicuser',
                'url': 'https://mastodon.social/@publicuser',
                'avatar': 'https://example.com/avatar.jpg',
                'header': 'https://example.com/header.jpg',
                'note': 'Public bio',
                'followers_count': 200,
                'following_count': 100,
                'statuses_count': 50,
                'created_at': '2023-01-01T00:00:00.000Z',
              },
              'media_attachments': [],
              'mentions': [],
              'tags': [],
              'emojis': [],
              'reblogs_count': 5,
              'favourites_count': 10,
              'replies_count': 2,
              'url': 'https://mastodon.social/@publicuser/789',
              'in_reply_to_id': null,
              'in_reply_to_account_id': null,
              'reblog': null,
              'poll': null,
              'card': null,
              'language': 'en',
              'text': 'Public status',
              'favourited': false,
              'reblogged': false,
              'muted': false,
              'bookmarked': false,
              'pinned': false,
              'sensitive': false,
              'spoiler_text': '',
              'visibility': 'public',
              'application': null,
            },
          ],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/public',
          queryParameters: {},
        )).thenAnswer((_) async => mockResponse);

        final result = await timelineService.getPublicTimeline(domain);

        expect(result, isA<List<Status>>());
        expect(result.length, equals(1));
        expect(result[0].id, equals('789'));
        expect(result[0].content, equals('Public status'));
      });

      test('should handle local timeline parameter', () async {
        const domain = 'mastodon.social';
        const local = true;
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/public',
          queryParameters: {'local': local},
        )).thenAnswer((_) async => mockResponse);

        await timelineService.getPublicTimeline(domain, local: local);

        verify(mockApiService.get(
          'https://$domain/api/v1/timelines/public',
          queryParameters: {'local': local},
        )).called(1);
      });
    });

    group('Error Handling', () {
      test('should handle network errors gracefully', () async {
        const domain = 'mastodon.social';
        
        when(mockApiService.get(any, queryParameters: anyNamed('queryParameters')))
            .thenThrow(DioException(
              requestOptions: RequestOptions(path: ''),
              type: DioExceptionType.connectionTimeout,
            ));

        expect(
          () => timelineService.getHomeTimeline(domain),
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

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {},
        )).thenAnswer((_) async => mockResponse);

        expect(
          () => timelineService.getHomeTimeline(domain),
          throwsA(isA<Exception>()),
        );
      });

      test('should handle empty response', () async {
        const domain = 'mastodon.social';
        final mockResponse = Response(
          data: [],
          statusCode: 200,
          requestOptions: RequestOptions(path: ''),
        );

        when(mockApiService.get(
          'https://$domain/api/v1/timelines/home',
          queryParameters: {},
        )).thenAnswer((_) async => mockResponse);

        final result = await timelineService.getHomeTimeline(domain);

        expect(result, isA<List<Status>>());
        expect(result.isEmpty, isTrue);
      });
    });
  });
}
