import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/models/status.dart';

/// Service for handling media-related API calls
class MediaService {
  final ApiService _apiService;
  
  /// Constructor
  MediaService({
    required ApiService apiService,
  }) : _apiService = apiService;
  
  /// Upload a media attachment
  Future<MediaAttachment> uploadMedia(
    String domain, {
    required File file,
    String? description,
    bool? focus,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        if (description != null) 'description': description,
        if (focus != null) 'focus': focus,
      });
      
      final response = await _apiService.post(
        'https://$domain/api/v1/media',
        data: formData,
      );
      
      return MediaAttachment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get a media attachment by ID
  Future<MediaAttachment> getMedia(String domain, String id) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/media/$id',
      );
      
      return MediaAttachment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Update a media attachment
  Future<MediaAttachment> updateMedia(
    String domain,
    String id, {
    String? description,
    bool? focus,
  }) async {
    try {
      final response = await _apiService.put(
        'https://$domain/api/v1/media/$id',
        data: {
          if (description != null) 'description': description,
          if (focus != null) 'focus': focus,
        },
      );
      
      return MediaAttachment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Upload a media attachment for a story (Pixelfed-specific)
  Future<MediaAttachment> uploadStoryMedia(
    String domain, {
    required File file,
    String? description,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
        if (description != null) 'description': description,
        'story': true,
      });
      
      final response = await _apiService.post(
        'https://$domain/api/v1/media',
        data: formData,
      );
      
      return MediaAttachment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get EXIF data for a media attachment (Pixelfed-specific)
  Future<Map<String, dynamic>> getMediaExif(String domain, String id) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/media/$id/exif',
      );
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Process an image (crop, rotate, etc.)
  Future<MediaAttachment> processImage(
    String domain,
    String id, {
    int? x,
    int? y,
    int? width,
    int? height,
    int? rotate,
    double? brightness,
    double? contrast,
    double? saturation,
    String? filter,
  }) async {
    try {
      final response = await _apiService.post(
        'https://$domain/api/v1/media/$id/process',
        data: {
          if (x != null) 'x': x,
          if (y != null) 'y': y,
          if (width != null) 'width': width,
          if (height != null) 'height': height,
          if (rotate != null) 'rotate': rotate,
          if (brightness != null) 'brightness': brightness,
          if (contrast != null) 'contrast': contrast,
          if (saturation != null) 'saturation': saturation,
          if (filter != null) 'filter': filter,
        },
      );
      
      return MediaAttachment.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get trending media (Pixelfed-specific)
  Future<List<MediaAttachment>> getTrendingMedia(
    String domain, {
    int? limit,
    String? maxId,
    String? sinceId,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/trends/media',
        queryParameters: {
          if (limit != null) 'limit': limit,
          if (maxId != null) 'max_id': maxId,
          if (sinceId != null) 'since_id': sinceId,
        },
      );
      
      return (response.data as List)
          .map((json) => MediaAttachment.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  /// Get media timeline (Pixelfed-specific)
  Future<List<Status>> getMediaTimeline(
    String domain, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
  }) async {
    try {
      final response = await _apiService.get(
        'https://$domain/api/v1/timelines/media',
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
  
  /// Handle errors
  Exception _handleError(dynamic error) {
    if (error is ApiException) {
      return error;
    }
    
    return Exception('Failed to perform media operation: $error');
  }
}
