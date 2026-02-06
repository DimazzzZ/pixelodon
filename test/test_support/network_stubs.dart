import 'package:dio/dio.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/services/timeline_service.dart';

import 'network_stubs.mocks.dart';

export 'network_stubs.mocks.dart';

@GenerateMocks([TimelineService])
void main() {}

/// Network stubs and fixtures for testing
class NetworkStubs {
  /// Create a mock timeline service with configurable behavior
  static MockTimelineService createMockTimelineService() {
    return MockTimelineService();
  }

  /// Configure mock timeline service for successful responses
  static void configureSuccessfulTimeline(
    MockTimelineService mockService, {
    List<Status>? statuses,
    int limit = 20,
    bool hasMore = true,
  }) {
    final mockStatuses = statuses ?? createMockStatuses(limit);
    
    when(mockService.getHomeTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
    )).thenAnswer((_) async => mockStatuses);
    
    when(mockService.getPublicTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
      local: anyNamed('local'),
      remote: anyNamed('remote'),
    )).thenAnswer((_) async => mockStatuses);
  }

  /// Configure mock timeline service for empty responses
  static void configureEmptyTimeline(MockTimelineService mockService) {
    when(mockService.getHomeTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
    )).thenAnswer((_) async => <Status>[]);
    
    when(mockService.getPublicTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
      local: anyNamed('local'),
      remote: anyNamed('remote'),
    )).thenAnswer((_) async => <Status>[]);
  }

  /// Configure mock timeline service for error responses
  static void configureErrorTimeline(
    MockTimelineService mockService, {
    String errorMessage = 'Network error',
  }) {
    when(mockService.getHomeTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
    )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      message: errorMessage,
    ));
    
    when(mockService.getPublicTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
      local: anyNamed('local'),
      remote: anyNamed('remote'),
    )).thenThrow(DioException(
      requestOptions: RequestOptions(path: '/api/v1/timelines/public'),
      message: errorMessage,
    ));
  }

  /// Configure mock timeline service for paginated responses
  static void configurePaginatedTimeline(
    MockTimelineService mockService, {
    int pageSize = 20,
    int totalPages = 3,
  }) {
    var currentPage = 0;
    
    when(mockService.getHomeTimeline(
      any,
      limit: anyNamed('limit'),
      maxId: anyNamed('maxId'),
    )).thenAnswer((invocation) async {
      final maxId = invocation.namedArguments[#maxId] as String?;
      
      if (maxId == null) {
        // First page
        currentPage = 0;
      } else {
        currentPage++;
      }
      
      if (currentPage >= totalPages) {
        return <Status>[]; // No more pages
      }
      
      return createMockStatuses(
        pageSize,
        startIndex: currentPage * pageSize,
      );
    });
  }

  /// Create mock status objects for testing
  static List<Status> createMockStatuses(
    int count, {
    int startIndex = 0,
    bool withMedia = false,
  }) {
    return List.generate(count, (index) {
      final id = '${startIndex + index + 1}';
      return Status(
        id: id,
        createdAt: DateTime.now().subtract(Duration(minutes: index)),
        account: createMockAccount(id),
        content: 'This is test status #${startIndex + index + 1} content',
        visibility: Visibility.public,
        sensitive: false,
        spoilerText: '',
        mediaAttachments: withMedia ? [createMockMediaAttachment()] : [],
        application: createMockApplication(),
        mentions: [],
        tags: [],
        emojis: [],
        reblogsCount: index,
        favouritesCount: index * 2,
        repliesCount: index,
        url: 'https://test.example.com/statuses/$id',
        inReplyToId: null,
        inReplyToAccountId: null,
        rebloggedStatus: null,
        poll: null,
        card: null,
        language: 'en',
        text: 'This is test status #${startIndex + index + 1} content',
        favourited: false,
        reblogged: false,
        muted: false,
        bookmarked: false,
        pinned: false,
      );
    });
  }

  /// Create a mock account for testing
  static Account createMockAccount(String id) {
    return Account(
      id: id,
      username: 'testuser$id',
      acct: 'testuser$id@test.example.com',
      displayName: 'Test User $id',
      locked: false,
      bot: false,
      discoverable: true,
      group: false,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      note: 'Test account bio',
      url: 'https://test.example.com/@testuser$id',
      avatar: null, // Use null to avoid network image loading in tests
      avatarStatic: null, // Use null to avoid network image loading in tests
      header: null, // Use null to avoid network image loading in tests
      headerStatic: null, // Use null to avoid network image loading in tests
      followersCount: 100,
      followingCount: 50,
      statusesCount: 200,
      lastStatusAt: DateTime.now(),
      fields: [],
    );
  }

  /// Create a mock media attachment for testing
  static MediaAttachment createMockMediaAttachment() {
    return const MediaAttachment(
      id: 'media_1',
      type: AttachmentType.image,
      url: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', // 1x1 transparent PNG
      previewUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==', // 1x1 transparent PNG
      remoteUrl: null,
      meta: {},
      description: 'Test image description',
      blurhash: null,
    );
  }

  /// Create a mock application for testing
  static Application createMockApplication() {
    return const Application(
      name: 'Pixelodon Test',
      website: 'https://pixelodon.app',
    );
  }
}

/// HTTP response fixtures for different scenarios
class ResponseFixtures {
  /// Successful timeline response with statuses
  static Map<String, dynamic> timelineSuccess({
    int count = 20,
    int startIndex = 0,
  }) {
    final statuses = NetworkStubs.createMockStatuses(count, startIndex: startIndex);
    return {
      'data': statuses.map((s) => s.toJson()).toList(),
      'status': 'success',
    };
  }

  /// Empty timeline response
  static Map<String, dynamic> timelineEmpty() {
    return {
      'data': [],
      'status': 'success',
    };
  }

  /// Error response
  static Map<String, dynamic> errorResponse({
    String message = 'Internal server error',
    int code = 500,
  }) {
    return {
      'error': message,
      'code': code,
      'status': 'error',
    };
  }

  /// Network timeout response
  static DioException networkTimeout() {
    return DioException(
      requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      type: DioExceptionType.connectionTimeout,
      message: 'Connection timeout',
    );
  }

  /// Rate limit response
  static DioException rateLimitExceeded() {
    return DioException(
      requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      response: Response(
        statusCode: 429,
        statusMessage: 'Too Many Requests',
        requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      ),
      type: DioExceptionType.badResponse,
      message: 'Rate limit exceeded',
    );
  }

  /// Unauthorized response
  static DioException unauthorizedResponse() {
    return DioException(
      requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      response: Response(
        statusCode: 401,
        statusMessage: 'Unauthorized',
        requestOptions: RequestOptions(path: '/api/v1/timelines/home'),
      ),
      type: DioExceptionType.badResponse,
      message: 'Unauthorized',
    );
  }
}

/// Test data generators for specific scenarios
class TestDataGenerators {
  /// Generate test data for pagination testing
  static List<List<Status>> paginatedStatusData({
    int pages = 3,
    int itemsPerPage = 20,
  }) {
    return List.generate(pages, (pageIndex) {
      return NetworkStubs.createMockStatuses(
        itemsPerPage,
        startIndex: pageIndex * itemsPerPage,
      );
    });
  }

  /// Generate mixed content types (text, images, videos)
  static List<Status> mixedContentStatuses(int count) {
    return List.generate(count, (index) {
      final hasMedia = index % 3 == 0; // Every 3rd status has media
      return NetworkStubs.createMockStatuses(1, 
        startIndex: index, 
        withMedia: hasMedia
      ).first;
    });
  }

  /// Generate statuses for search/filter testing
  static List<Status> searchableStatuses() {
    final keywords = ['flutter', 'dart', 'mobile', 'development', 'testing'];
    
    return keywords.asMap().entries.map((entry) {
      final index = entry.key;
      final keyword = entry.value;
      
      final status = NetworkStubs.createMockStatuses(1, startIndex: index).first;
      return status.copyWith(
        content: 'This is a post about $keyword development. #$keyword',
        tags: [keyword],
      );
    }).toList();
  }
}
