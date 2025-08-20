import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/core/config/app_config.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/repositories/new_auth_repository.dart';

import 'api_service_test.mocks.dart';

@GenerateMocks([Dio, NewAuthRepository])
void main() {
  group('ApiService Tests', () {
    late MockDio mockDio;
    late MockNewAuthRepository mockAuthRepository;
    late ApiService apiService;

    setUp(() {
      mockDio = MockDio();
      mockAuthRepository = MockNewAuthRepository();
      
      // Mock BaseOptions
      when(mockDio.options).thenReturn(BaseOptions());
      when(mockDio.interceptors).thenReturn(Interceptors());

      apiService = ApiService(
        authRepository: mockAuthRepository,
        dio: mockDio,
      );
    });

    group('Constructor and Initialization', () {
      test('should initialize with default Dio when none provided', () {
        final service = ApiService(authRepository: mockAuthRepository);
        expect(service, isNotNull);
      });

      test('should use provided Dio instance', () {
        final service = ApiService(
          authRepository: mockAuthRepository,
          dio: mockDio,
        );
        expect(service, isNotNull);
      });
    });

    group('HTTP GET Requests', () {
      test('should make successful GET request', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        final mockResponse = Response(
          data: {'success': true},
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.get(
          url,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.get(url);

        // Assert
        expect(result, mockResponse);
        expect(result.statusCode, 200);
        expect(result.data['success'], true);
      });

      test('should handle GET request with query parameters', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        const queryParams = {'page': '1', 'limit': '10'};
        final mockResponse = Response(
          data: {'results': []},
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.get(
          url,
          queryParameters: queryParams,
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.get(url, queryParameters: queryParams);

        // Assert
        expect(result, mockResponse);
        verify(mockDio.get(
          url,
          queryParameters: queryParams,
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).called(1);
      });
    });

    group('HTTP POST Requests', () {
      test('should make successful POST request', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        const data = {'name': 'test'};
        final mockResponse = Response(
          data: {'id': 1, 'name': 'test'},
          statusCode: 201,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.post(
          url,
          data: data,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.post(url, data: data);

        // Assert
        expect(result, mockResponse);
        expect(result.statusCode, 201);
        expect(result.data['name'], 'test');
      });
    });

    group('HTTP PUT Requests', () {
      test('should make successful PUT request', () async {
        // Arrange
        const url = 'https://example.com/api/test/1';
        const data = {'name': 'updated'};
        final mockResponse = Response(
          data: {'id': 1, 'name': 'updated'},
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.put(
          url,
          data: data,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.put(url, data: data);

        // Assert
        expect(result, mockResponse);
        expect(result.statusCode, 200);
        expect(result.data['name'], 'updated');
      });
    });

    group('HTTP DELETE Requests', () {
      test('should make successful DELETE request', () async {
        // Arrange
        const url = 'https://example.com/api/test/1';
        final mockResponse = Response(
          data: {},
          statusCode: 204,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.delete(
          url,
          data: anyNamed('data'),
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.delete(url);

        // Assert
        expect(result, mockResponse);
        expect(result.statusCode, 204);
      });
    });

    group('HTTP PATCH Requests', () {
      test('should make successful PATCH request', () async {
        // Arrange
        const url = 'https://example.com/api/test/1';
        const data = {'status': 'active'};
        final mockResponse = Response(
          data: {'id': 1, 'status': 'active'},
          statusCode: 200,
          requestOptions: RequestOptions(path: url),
        );
        
        when(mockDio.patch(
          url,
          data: data,
          queryParameters: anyNamed('queryParameters'),
          options: anyNamed('options'),
          cancelToken: anyNamed('cancelToken'),
          onSendProgress: anyNamed('onSendProgress'),
          onReceiveProgress: anyNamed('onReceiveProgress'),
        )).thenAnswer((_) async => mockResponse);

        // Act
        final result = await apiService.patch(url, data: data);

        // Assert
        expect(result, mockResponse);
        expect(result.statusCode, 200);
        expect(result.data['status'], 'active');
      });
    });

    group('Error Handling', () {
      test('should handle timeout exception', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.connectionTimeout,
            requestOptions: RequestOptions(path: url),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<TimeoutException>()),
        );
      });

      test('should handle connection error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.connectionError,
            requestOptions: RequestOptions(path: url),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<NetworkException>()),
        );
      });

      test('should handle 401 unauthorized error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: url),
            response: Response(
              statusCode: 401,
              data: {'error': 'Unauthorized'},
              requestOptions: RequestOptions(path: url),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<UnauthorizedException>()),
        );
      });

      test('should handle 403 forbidden error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: url),
            response: Response(
              statusCode: 403,
              data: {'error': 'Forbidden'},
              requestOptions: RequestOptions(path: url),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<ForbiddenException>()),
        );
      });

      test('should handle 404 not found error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: url),
            response: Response(
              statusCode: 404,
              data: {'error': 'Not found'},
              requestOptions: RequestOptions(path: url),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<NotFoundException>()),
        );
      });

      test('should handle 429 rate limit error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: url),
            response: Response(
              statusCode: 429,
              data: {'error': 'Rate limit exceeded'},
              requestOptions: RequestOptions(path: url),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<RateLimitException>()),
        );
      });

      test('should handle 500 server error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(
          DioException(
            type: DioExceptionType.badResponse,
            requestOptions: RequestOptions(path: url),
            response: Response(
              statusCode: 500,
              data: {'error': 'Internal server error'},
              requestOptions: RequestOptions(path: url),
            ),
          ),
        );

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<ServerException>()),
        );
      });

      test('should handle unknown error', () async {
        // Arrange
        const url = 'https://example.com/api/test';
        when(mockDio.get(any)).thenThrow(Exception('Unknown error'));

        // Act & Assert
        expect(
          () => apiService.get(url),
          throwsA(isA<UnknownException>()),
        );
      });
    });

    group('Exception Classes', () {
      test('ApiException should have correct properties', () {
        const message = 'Test error';
        const statusCode = 400;
        const data = {'error': 'Bad request'};
        
        final exception = ApiException(message, statusCode: statusCode, data: data);
        
        expect(exception.message, message);
        expect(exception.statusCode, statusCode);
        expect(exception.data, data);
        expect(exception.toString(), message);
      });

      test('UnauthorizedException should have status code 401', () {
        final exception = UnauthorizedException('Unauthorized');
        expect(exception.statusCode, 401);
      });

      test('ForbiddenException should have status code 403', () {
        final exception = ForbiddenException('Forbidden');
        expect(exception.statusCode, 403);
      });

      test('NotFoundException should have status code 404', () {
        final exception = NotFoundException('Not found');
        expect(exception.statusCode, 404);
      });

      test('RateLimitException should have status code 429', () {
        final exception = RateLimitException('Rate limit exceeded');
        expect(exception.statusCode, 429);
      });

      test('ServerException should have status code 500', () {
        final exception = ServerException('Server error');
        expect(exception.statusCode, 500);
      });

      test('TimeoutException should extend ApiException', () {
        final exception = TimeoutException('Timeout');
        expect(exception, isA<ApiException>());
        expect(exception.message, 'Timeout');
      });

      test('NetworkException should extend ApiException', () {
        final exception = NetworkException('Network error');
        expect(exception, isA<ApiException>());
        expect(exception.message, 'Network error');
      });

      test('UnknownException should extend ApiException', () {
        final exception = UnknownException('Unknown error');
        expect(exception, isA<ApiException>());
        expect(exception.message, 'Unknown error');
      });
    });
  });
}
