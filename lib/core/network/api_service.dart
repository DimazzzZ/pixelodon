import 'dart:io';

import 'package:dio/dio.dart';
import 'package:pixelodon/core/config/app_config.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/utils/logger.dart';

/// Base exception for API errors
sealed class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException(this.message, {this.statusCode, this.data});

  @override
  String toString() => message;
}

/// Exception for general API errors
class GeneralApiException extends ApiException {
  const GeneralApiException(super.message, {super.statusCode, super.data});
}

/// Exception for timeout errors
class TimeoutException extends ApiException {
  const TimeoutException(super.message) : super(statusCode: 408);
}

/// Exception for network errors
class NetworkException extends ApiException {
  const NetworkException(super.message) : super(statusCode: 503);
}

/// Exception for unauthorized errors
class UnauthorizedException extends ApiException {
  const UnauthorizedException(super.message) : super(statusCode: 401);
}

/// Exception for forbidden errors
class ForbiddenException extends ApiException {
  const ForbiddenException(super.message) : super(statusCode: 403);
}

/// Exception for not found errors
class NotFoundException extends ApiException {
  const NotFoundException(super.message) : super(statusCode: 404);
}

/// Exception for rate limit errors
class RateLimitException extends ApiException {
  const RateLimitException(super.message) : super(statusCode: 429);
}

/// Exception for server errors
class ServerException extends ApiException {
  const ServerException(super.message) : super(statusCode: 500);
}

/// Exception for cancelled requests
class CancellationException extends ApiException {
  const CancellationException(super.message) : super(statusCode: 499);
}

/// Exception for unknown errors
class UnknownException extends ApiException {
  const UnknownException(super.message, {super.data});
}

/// Exceptions for Auth operations
class AuthDiscoveryException extends ApiException {
  const AuthDiscoveryException(super.message, {super.statusCode, super.data});
}

class AuthRegistrationException extends ApiException {
  const AuthRegistrationException(super.message, {super.statusCode, super.data});
}

class AuthTokenException extends ApiException {
  const AuthTokenException(super.message, {super.statusCode, super.data});
}

class AuthStorageException extends ApiException {
  const AuthStorageException(super.message, {super.statusCode, super.data});
}

class AuthLogoutException extends ApiException {
  const AuthLogoutException(super.message, {super.statusCode, super.data});
}

/// Base API service for Mastodon and Pixelfed
class ApiService {
  final Dio _dio;
  final AuthRepository _authRepository;
  
  /// Constructor
  ApiService({
    required AuthRepository authRepository,
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
        logger.e('API Error: ${error.message}', error: error, stackTrace: error.stackTrace);
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
  Future<Response<T>> get<T>(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.get<T>(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Make a POST request
  Future<Response<T>> post<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.post<T>(
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
      _handleError(e);
      rethrow;
    }
  }
  
  /// Make a PUT request
  Future<Response<T>> put<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.put<T>(
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
      _handleError(e);
      rethrow;
    }
  }
  
  /// Make a DELETE request
  Future<Response<T>> delete<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final response = await _dio.delete<T>(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response;
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }
  
  /// Make a PATCH request
  Future<Response<T>> patch<T>(
    String url, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await _dio.patch<T>(
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
      _handleError(e);
      rethrow;
    }
  }
  
  /// Upload a file
  Future<Response<T>> uploadFile<T>(
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
      
      final response = await _dio.post<T>(
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
      _handleError(e);
      rethrow;
    }
  }
  
  /// Handle errors
  void _handleError(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.cancel:
          throw const CancellationException('Request was cancelled');
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.receiveTimeout:
        case DioExceptionType.sendTimeout:
          throw const TimeoutException('Connection timed out');
        case DioExceptionType.connectionError:
          throw const NetworkException('No internet connection');
        case DioExceptionType.badResponse:
          final statusCode = error.response!.statusCode;
          final data = error.response!.data;

          throw switch (statusCode) {
            401 => const UnauthorizedException('Unauthorized'),
            403 => () {
                dynamic raw = data;
                String message = 'Forbidden';
                if (raw is Map) {
                  message = (raw['error'] ?? raw['message'] ?? raw['error_description'] ?? 'Forbidden').toString();
                } else if (raw is String && raw.trim().isNotEmpty) {
                  message = raw.trim();
                }
                return ForbiddenException(message);
              }(),
            404 => const NotFoundException('Not found'),
            429 => const RateLimitException('Rate limit exceeded'),
            final code when code != null && code >= 500 => const ServerException('Server error'),
            _ => GeneralApiException(
                'API error: $statusCode',
                statusCode: statusCode,
                data: data,
              ),
          };
        default:
          throw UnknownException('API error: ${error.type}', data: error.message);
      }
    }

    throw UnknownException('Unknown error: $error');
  }
}
