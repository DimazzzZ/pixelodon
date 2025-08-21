import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/notification.dart' as model;

/// Service for handling notification-related API calls
class NotificationService {
  final ApiService _apiService;
  
  /// Constructor
  NotificationService({
    required ApiService apiService,
  }) : _apiService = apiService;
  
  /// Fetch notifications from the API
  Future<List<model.Notification>> getNotifications(
    String domain, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    List<model.NotificationType>? excludeTypes,
    bool? accountId,
  }) async {
    try {
      final Map<String, dynamic> queryParameters = {};
      
      if (limit != null) queryParameters['limit'] = limit;
      if (maxId != null) queryParameters['max_id'] = maxId;
      if (sinceId != null) queryParameters['since_id'] = sinceId;
      if (minId != null) queryParameters['min_id'] = minId;
      if (accountId != null) queryParameters['account_id'] = accountId;
      
      // Add exclude types if provided
      if (excludeTypes != null && excludeTypes.isNotEmpty) {
        for (final type in excludeTypes) {
          queryParameters['exclude_types[]'] = _getNotificationTypeString(type);
        }
      }
      
      final response = await _apiService.get(
        'https://$domain/api/v1/notifications',
        queryParameters: queryParameters,
      );
      
      return (response.data as List)
          .map((json) => model.Notification.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get a single notification by ID
  Future<model.Notification> getNotification(
    String domain,
    String notificationId,
  ) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/notifications/$notificationId',
      );
      
      return model.Notification.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Mark all notifications as read
  Future<void> markNotificationsAsRead(String domain) async {
    // Try a sequence of known endpoints from Mastodon and Pixelfed.
    // We return on the first success (any 2xx). If all fail, rethrow the last error.
    final candidates = <String>[
      // Mastodon standard
      'https://$domain/api/v1/notifications/clear',
      // Pixelfed commonly referenced variants
      'https://$domain/api/pixelfed/v1/notifications/mark-as-read',
      'https://$domain/api/pixelfed/v1/notifications/mark_read',
      'https://$domain/api/pixelfed/v1/notifications/mark-read',
      'https://$domain/api/pixelfed/v1/notifications/clear',
    ];

    Exception? lastError;
    for (final url in candidates) {
      try {
        await _apiService.post(url);
        return; // success
      } catch (e) {
        // Keep the last processed error to surface if everything fails
        if (e is Exception) {
          lastError = e;
        } else {
          lastError = Exception('Unexpected error: $e');
        }
        // Continue with next candidate
        continue;
      }
    }

    // If none succeeded, throw the last error encountered
    if (lastError != null) {
      throw lastError;
    }

    // Fallback generic error (shouldn't normally reach here)
    throw Exception('Failed to mark notifications as read: no supported endpoint succeeded.');
  }
  
  /// Dismiss a notification
  Future<void> dismissNotification(
    String domain,
    String notificationId,
  ) async {
    try {
      await _apiService.post(
        'https://$domain/api/v1/notifications/$notificationId/dismiss',
      );
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Convert NotificationType enum to API string
  String _getNotificationTypeString(model.NotificationType type) {
    switch (type) {
      case model.NotificationType.follow:
        return 'follow';
      case model.NotificationType.followRequest:
        return 'follow_request';
      case model.NotificationType.mention:
        return 'mention';
      case model.NotificationType.reblog:
        return 'reblog';
      case model.NotificationType.favourite:
        return 'favourite';
      case model.NotificationType.poll:
        return 'poll';
      case model.NotificationType.status:
        return 'status';
      case model.NotificationType.update:
        return 'update';
      case model.NotificationType.adminSignUp:
        return 'admin.sign_up';
      case model.NotificationType.adminReport:
        return 'admin.report';
      case model.NotificationType.comment:
        return 'comment';
      case model.NotificationType.like:
        return 'like';
      case model.NotificationType.share:
        return 'share';
      case model.NotificationType.storyReaction:
        return 'story.reaction';
      case model.NotificationType.storyMention:
        return 'story.mention';
      case model.NotificationType.direct:
        return 'direct';
      case model.NotificationType.unknown:
        return 'unknown';
    }
  }
  
  /// Handle API errors
  Exception _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return Exception('Connection timeout. Please check your network connection.');
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          final message = error.response?.data?['error'] ?? 'Unknown server error';
          return Exception('Server error ($statusCode): $message');
        case DioExceptionType.cancel:
          return Exception('Request was cancelled');
        case DioExceptionType.unknown:
          if (error.error is SocketException) {
            return Exception('No internet connection');
          }
          return Exception('Network error: ${error.message}');
        default:
          return Exception('Unknown error occurred');
      }
    }
    return Exception('Unexpected error: $error');
  }
}
