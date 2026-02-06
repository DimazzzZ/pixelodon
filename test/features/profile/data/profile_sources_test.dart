import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:pixelodon/features/profile/data/profile_sources.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/models/account.dart';

import 'profile_sources_test.mocks.dart';

@GenerateMocks([AccountService, TimelineService])
void main() {
  group('RealProfileRemoteDataSource', () {
    late RealProfileRemoteDataSource dataSource;
    late MockAccountService mockAccountService;
    late MockTimelineService mockTimelineService;
    
    const testDomain = 'mastodon.example.com';
    const testUserId = '123';
    const testCurrentUserId = '456';

    setUp(() {
      mockAccountService = MockAccountService();
      mockTimelineService = MockTimelineService();
      
      dataSource = RealProfileRemoteDataSource(
        accountService: mockAccountService,
        timelineService: mockTimelineService,
        domain: testDomain,
        currentUserId: testCurrentUserId,
      );
    });

    group('getComments', () {
      test('should call getAccountStatuses with excludeReplies: false', () async {
        // Arrange
        const cursor = 'test_cursor';
        final mockStatuses = <Status>[
          Status(
            id: '1',
            content: 'This is a reply',
            inReplyToId: '100', // This makes it a reply
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime.now(),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '2',
            content: 'This is not a reply',
            inReplyToId: null, // This is not a reply
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime.now(),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
        ];
        
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReblogs: anyNamed('excludeReblogs'),
          excludeReplies: anyNamed('excludeReplies'),
        )).thenAnswer((_) async => mockStatuses);

        // Act
        await dataSource.getComments(testUserId, cursor: cursor);

        // Assert
        verify(mockTimelineService.getAccountStatuses(
          testDomain,
          testUserId,
          maxId: cursor,
          limit: 20,
          excludeReblogs: true,
          excludeReplies: false, // This is the key fix
        )).called(1);
      });

      test('should filter and return only replies as CommentItems', () async {
        // Arrange
        final mockStatuses = <Status>[
          Status(
            id: '1',
            content: 'This is a reply',
            inReplyToId: '100', // This makes it a reply
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 50),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '2',
            content: 'This is not a reply',
            inReplyToId: null, // This is not a reply
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 50),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '3',
            content: 'Another reply',
            inReplyToId: '200', // This makes it a reply
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 45),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
        ];
        
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReblogs: anyNamed('excludeReblogs'),
          excludeReplies: anyNamed('excludeReplies'),
        )).thenAnswer((_) async => mockStatuses);

        // Act
        final result = await dataSource.getComments(testUserId);

        // Assert
        expect(result.items, hasLength(2)); // Only the 2 replies should be returned
        expect(result.items[0].id, '1');
        expect(result.items[0].inReplyToId, '100');
        expect(result.items[0].text, 'This is a reply');
        expect(result.items[1].id, '3');
        expect(result.items[1].inReplyToId, '200');
        expect(result.items[1].text, 'Another reply');
        expect(result.hasMore, false); // Less than 20 items, so no more pages
        expect(result.nextCursor, '3'); // Last status ID
      });

      test('should handle empty response correctly', () async {
        // Arrange
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReblogs: anyNamed('excludeReblogs'),
          excludeReplies: anyNamed('excludeReplies'),
        )).thenAnswer((_) async => <Status>[]);

        // Act
        final result = await dataSource.getComments(testUserId);

        // Assert
        expect(result.items, isEmpty);
        expect(result.hasMore, false);
        expect(result.nextCursor, isNull);
      });

      test('should handle exception and rethrow with context', () async {
        // Arrange
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReblogs: anyNamed('excludeReblogs'),
          excludeReplies: anyNamed('excludeReplies'),
        )).thenThrow(Exception('API Error'));

        // Act & Assert
        expect(
          () => dataSource.getComments(testUserId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch comments'),
          )),
        );
      });
    });

    group('getBoosts', () {
      test('should call getAccountStatuses with excludeReblogs: false', () async {
        // Arrange
        const cursor = 'test_cursor';
        final mockStatuses = <Status>[
          Status(
            id: '1',
            content: 'Original post content',
            rebloggedStatus: Status(
              id: '100',
              content: 'This is the original post that was boosted',
              account: const Account(
                id: '999',
                username: 'originaluser',
                displayName: 'Original User',
                avatar: 'https://example.com/orig_avatar.jpg',
                acct: 'originaluser@example.com',
              ),
              createdAt: DateTime.now(),
              mediaAttachments: [],
              emojis: [],
              tags: [],
              mentions: [],
              favouritesCount: 5,
              reblogsCount: 2,
              repliesCount: 1,
            ),
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime.now(),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '2',
            content: 'Regular post, not a boost',
            rebloggedStatus: null, // This is not a boost
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime.now(),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
        ];
        
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReplies: anyNamed('excludeReplies'),
          excludeReblogs: anyNamed('excludeReblogs'),
        )).thenAnswer((_) async => mockStatuses);

        // Act
        await dataSource.getBoosts(testUserId, cursor: cursor);

        // Assert
        verify(mockTimelineService.getAccountStatuses(
          testDomain,
          testUserId,
          maxId: cursor,
          limit: 20,
          excludeReplies: true,
          excludeReblogs: false, // This is the key fix for boosts
        )).called(1);
      });

      test('should filter and return only boosts as BoostItems', () async {
        // Arrange
        final mockStatuses = <Status>[
          Status(
            id: '1',
            content: 'Boost wrapper content',
            rebloggedStatus: Status(
              id: '100',
              content: 'This is the original post that was boosted',
              account: const Account(
                id: '999',
                username: 'originaluser',
                displayName: 'Original User',
                avatar: 'https://example.com/orig_avatar.jpg',
                acct: 'originaluser@example.com',
              ),
              createdAt: DateTime(2024, 8, 30, 17, 45),
              mediaAttachments: [],
              emojis: [],
              tags: [],
              mentions: [],
              favouritesCount: 5,
              reblogsCount: 2,
              repliesCount: 1,
            ),
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 50),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '2',
            content: 'Regular post, not a boost',
            rebloggedStatus: null, // This is not a boost
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 40),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
          Status(
            id: '3',
            content: 'Another boost',
            rebloggedStatus: Status(
              id: '200',
              content: 'Another original post',
              account: const Account(
                id: '888',
                username: 'anotheruser',
                displayName: 'Another User',
                avatar: 'https://example.com/another_avatar.jpg',
                acct: 'anotheruser@example.com',
              ),
              createdAt: DateTime(2024, 8, 30, 17, 30),
              mediaAttachments: [],
              emojis: [],
              tags: [],
              mentions: [],
              favouritesCount: 3,
              reblogsCount: 1,
              repliesCount: 0,
            ),
            account: const Account(
              id: testUserId,
              username: 'testuser',
              displayName: 'Test User',
              avatar: 'https://example.com/avatar.jpg',
              acct: 'testuser@example.com',
            ),
            createdAt: DateTime(2024, 8, 30, 17, 35),
            mediaAttachments: [],
            emojis: [],
            tags: [],
            mentions: [],
            favouritesCount: 0,
            reblogsCount: 0,
            repliesCount: 0,
          ),
        ];
        
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReplies: anyNamed('excludeReplies'),
          excludeReblogs: anyNamed('excludeReblogs'),
        )).thenAnswer((_) async => mockStatuses);

        // Act
        final result = await dataSource.getBoosts(testUserId);

        // Assert
        expect(result.items, hasLength(2)); // Only the 2 boosts should be returned
        expect(result.items[0].id, '1');
        expect(result.items[0].originalAuthor, 'originaluser');
        expect(result.items[0].boosterUsername, 'testuser');
        expect(result.items[0].text, 'This is the original post that was boosted');
        expect(result.items[1].id, '3');
        expect(result.items[1].originalAuthor, 'anotheruser');
        expect(result.items[1].boosterUsername, 'testuser');
        expect(result.items[1].text, 'Another original post');
        expect(result.hasMore, false); // Less than 20 items, so no more pages
        expect(result.nextCursor, '3'); // Last status ID
      });

      test('should handle empty response correctly', () async {
        // Arrange
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReplies: anyNamed('excludeReplies'),
          excludeReblogs: anyNamed('excludeReblogs'),
        )).thenAnswer((_) async => <Status>[]);

        // Act
        final result = await dataSource.getBoosts(testUserId);

        // Assert
        expect(result.items, isEmpty);
        expect(result.hasMore, false);
        expect(result.nextCursor, isNull);
      });

      test('should handle exception and rethrow with context', () async {
        // Arrange
        when(mockTimelineService.getAccountStatuses(
          any,
          any,
          maxId: anyNamed('maxId'),
          limit: anyNamed('limit'),
          excludeReplies: anyNamed('excludeReplies'),
          excludeReblogs: anyNamed('excludeReblogs'),
        )).thenThrow(Exception('API Error'));

        // Act & Assert
        expect(
          () => dataSource.getBoosts(testUserId),
          throwsA(isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Failed to fetch boosts'),
          )),
        );
      });
    });
  });
}
