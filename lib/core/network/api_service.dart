import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pixelodon/core/config/app_config.dart';
import 'package:pixelodon/repositories/new_auth_repository.dart';

/// Base API service for Mastodon and Pixelfed
class ApiService {
  final Dio _dio;
  final NewAuthRepository _authRepository;
  
  /// Constructor
  ApiService({
    required NewAuthRepository authRepository,
    Dio? dio,
  }) : _authRepository = authRepository,
       _dio = dio ?? Dio() {
    _initializeDio();
  }
  
  /// Initialize Dio with interceptors and default options
  void _initializeDio() {
    _dio.options.connectTimeout = const Duration(milliseconds: AppConfig.apiTimeoutMs);
    _dio.options.receiveTimeout = const Duration(milliseconds: AppConfig.apiTimeoutMs);
    
    // Add logging interceptor in debug mode
    if (AppConfig.enableApiLogging) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
      ));
    }
    
    // Add auth interceptor
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Get the domain from the URL
        final uri = Uri.parse(options.uri.toString());
        final domain = uri.host;
        
        // Get the access token for the domain
        final accessToken = await _authRepository.getAccessToken(domain);
        
        // Add the access token to the request if available
        if (accessToken != null) {
          options.headers['Authorization'] = 'Bearer $accessToken';
        }
        
        return handler.next(options);
      },
      onError: (DioException error, handler) async {
        // Handle 401 Unauthorized errors
        if (error.response?.statusCode == 401) {
          // TODO: Implement token refresh if needed
          // For now, just pass the error through
        }
        
        return handler.next(error);
      },
    ));
  }
  
  /// Make a GET request
  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Make a POST request
  Future<Response> post(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Make a PUT request
  Future<Response> put(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Make a DELETE request
  Future<Response> delete(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Make a PATCH request
  Future<Response> patch(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Upload a file
  Future<Response> uploadFile(
    String url, {
    required File file,
    required String fieldName,
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        ...?data,
        fieldName: await MultipartFile.fromFile(
          file.path,
          filename: fileName,
        ),
      });
      
      final response = await _dio.post(
        url,
        data: formData,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      return _handleError(e);
    }
  }
  
  /// Handle errors
  Future<Response> _handleError(dynamic error) async {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        throw TimeoutException('Connection timed out');
      }
      
      if (error.type == DioExceptionType.connectionError) {
        throw NetworkException('No internet connection');
      }
      
      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;
        
        if (statusCode == 401) {
          throw UnauthorizedException('Unauthorized');
        }
        
        if (statusCode == 403) {
          throw ForbiddenException('Forbidden');
        }
        
        if (statusCode == 404) {
          throw NotFoundException('Not found');
        }
        
        if (statusCode == 429) {
          throw RateLimitException('Rate limit exceeded');
        }
        
        if (statusCode! >= 500) {
          throw ServerException('Server error');
        }
        
        throw ApiException(
          'API error: $statusCode',
          statusCode: statusCode,
          data: data,
        );
      }
    }
    
    throw UnknownException('Unknown error: $error');
  }
}

/// Base exception for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  
  ApiException(this.message, {this.statusCode, this.data});
  
  @override
  String toString() => message;
}

/// Exception for timeout errors
class TimeoutException extends ApiException {
  TimeoutException(super.message);
}

/// Exception for network errors
class NetworkException extends ApiException {
  NetworkException(super.message);
}

/// Exception for unauthorized errors
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message) : super(statusCode: 401);
}

/// Exception for forbidden errors
class ForbiddenException extends ApiException {
  ForbiddenException(super.message) : super(statusCode: 403);
}

/// Exception for not found errors
class NotFoundException extends ApiException {
  NotFoundException(super.message) : super(statusCode: 404);
}

/// Exception for rate limit errors
class RateLimitException extends ApiException {
  RateLimitException(super.message) : super(statusCode: 429);
}

/// Exception for server errors
class ServerException extends ApiException {
  ServerException(super.message) : super(statusCode: 500);
}

/// Exception for unknown errors
class UnknownException extends ApiException {
  UnknownException(super.message);
}
