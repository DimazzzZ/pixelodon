import 'package:dio/dio.dart';
import '../../core/env.dart';

Dio createDio({String? baseUrl, String? accessToken}) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl ?? '',
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {
        'User-Agent': env.userAgent,
      },
    ),
  );
  if (accessToken != null) {
    dio.options.headers['Authorization'] = 'Bearer $accessToken';
  }
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.next(options),
      onError: (error, handler) => handler.next(error),
      onResponse: (response, handler) => handler.next(response),
    ),
  );
  return dio;
}

