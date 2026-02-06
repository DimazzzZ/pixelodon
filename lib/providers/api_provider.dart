import 'package:dio/dio.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_provider.g.dart';

/// Provider for the ApiService
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) {
  final authRepository = ref.watch(authRepositoryProvider.notifier);
  return ApiService(authRepository: authRepository);
}

/// Provider for a pre-configured Dio instance
@Riverpod(keepAlive: true)
Dio dio(DioRef ref) {
  return Dio();
}
