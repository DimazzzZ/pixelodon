import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/providers/new_auth_provider.dart';

/// Provider for the API service
final apiServiceProvider = Provider<ApiService>((ref) {
  final authRepository = ref.watch(newAuthRepositoryProvider);
  return ApiService(authRepository: authRepository);
});

/// Provider for building API URLs for a specific instance
final apiUrlProvider = Provider.family<String, ({String domain, String endpoint})>((ref, params) {
  return 'https://${params.domain}/api/v1/${params.endpoint}';
});

/// Provider for checking if an instance is Pixelfed
final isPixelfedProvider = Provider.family<bool, String>((ref, domain) {
  final instances = ref.watch(newInstancesProvider);
  final instance = instances.firstWhere(
    (instance) => instance.domain == domain,
    orElse: () => throw Exception('Instance not found: $domain'),
  );
  return instance.isPixelfed;
});
