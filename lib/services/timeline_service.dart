import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/status.dart';

/// Service for handling timeline-related API calls
class TimelineService {
  final ApiService _apiService;
  
  /// Constructor
  TimelineService({
    required ApiService apiService,
  }) : _apiService = apiService;
  
  /// Fetch the home timeline
  Future<List<Status>> getHomeTimeline(
    String domain, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    bool? local,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/timelines/home',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
          if (minId != null) 'min_id': minId,
          if (local != null) 'local': local,
        },
      );
      
      return (response.data as List)
          .map((json) => Status.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch the public timeline
  Future<List<Status>> getPublicTimeline(
    String domain, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    bool? local,
    bool? remote,
    bool? onlyMedia,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/timelines/public',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
          if (minId != null) 'min_id': minId,
          if (local != null) 'local': local,
          if (remote != null) 'remote': remote,
          if (onlyMedia != null) 'only_media': onlyMedia,
        },
      );
      
      return (response.data as List)
          .map((json) => Status.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch a tag timeline
  Future<List<Status>> getTagTimeline(
    String domain,
    String tag, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    bool? local,
    bool? onlyMedia,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/timelines/tag/$tag',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
          if (minId != null) 'min_id': minId,
          if (local != null) 'local': local,
          if (onlyMedia != null) 'only_media': onlyMedia,
        },
      );
      
      return (response.data as List)
          .map((json) => Status.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch a list timeline
  Future<List<Status>> getListTimeline(
    String domain,
    String listId, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/timelines/list/$listId',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
          if (minId != null) 'min_id': minId,
        },
      );
      
      return (response.data as List)
          .map((json) => Status.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch an account's statuses
  Future<List<Status>> getAccountStatuses(
    String domain,
    String accountId, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/accounts/$accountId/statuses',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
          if (minId != null) 'min_id': minId,
          if (onlyMedia != null) 'only_media': onlyMedia,
          if (excludeReplies != null) 'exclude_replies': excludeReplies,
          if (excludeReblogs != null) 'exclude_reblogs': excludeReblogs,
          if (pinned != null) 'pinned': pinned,
        },
      );
      
      return (response.data as List)
          .map((json) => Status.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch a status by ID
  Future<Status> getStatus(String domain, String id) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/statuses/$id',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Fetch a status context (ancestors and descendants)
  Future<Map<String, List<Status>>> getStatusContext(String domain, String id) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/statuses/$id/context',
      );
      
      final ancestors = (response.data['ancestors'] as List)
          .map((json) => Status.fromJson(json))
          .toList();
      
      final descendants = (response.data['descendants'] as List)
          .map((json) => Status.fromJson(json))
          .toList();
      
      return {
        'ancestors': ancestors,
        'descendants': descendants,
      };
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Create a new status
  Future<Status> createStatus(
    String domain, {
    required String status,
    String? inReplyToId,
    List<String>? mediaIds,
    bool? sensitive,
    String? spoilerText,
    Visibility? visibility,
    String? scheduledAt,
    String? language,
    Map<String, dynamic>? poll,
  }) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses',
        data: {
          'status': status,
          if (inReplyToId != null) 'in_reply_to_id': inReplyToId,
          if (mediaIds != null && mediaIds.isNotEmpty) 'media_ids': mediaIds,
          if (sensitive != null) 'sensitive': sensitive,
          if (spoilerText != null) 'spoiler_text': spoilerText,
          if (visibility != null) 'visibility': _visibilityToString(visibility),
          if (scheduledAt != null) 'scheduled_at': scheduledAt,
          if (language != null) 'language': language,
          if (poll != null) 'poll': poll,
        },
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Delete a status
  Future<void> deleteStatus(String domain, String id) async {
    try {
      await _apiService.delete(
        'https://$domain/api/v1/statuses/$id',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Reblog/boost a status
  Future<Status> reblogStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/reblog',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Undo a reblog/boost
  Future<Status> unreblogStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/unreblog',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Favourite/like a status
  Future<Status> favouriteStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/favourite',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Undo a favourite/like
  Future<Status> unfavouriteStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/unfavourite',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Bookmark a status
  Future<Status> bookmarkStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/bookmark',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Undo a bookmark
  Future<Status> unbookmarkStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/unbookmark',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Pin a status to profile
  Future<Status> pinStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/pin',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Unpin a status from profile
  Future<Status> unpinStatus(String domain, String id) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/statuses/$id/unpin',
      );
      
      return Status.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Convert Visibility enum to string
  String _visibilityToString(Visibility visibility) {
    switch (visibility) {
      case Visibility.public:
        return 'public';
      case Visibility.unlisted:
        return 'unlisted';
      case Visibility.private:
        return 'private';
      case Visibility.direct:
        return 'direct';
    }
  }
  
  /// Handle errors
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    return Exception('Failed to perform timeline operation: $error');
  }
}
