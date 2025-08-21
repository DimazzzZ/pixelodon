import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/providers/api_provider.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/media_service.dart';
import 'package:pixelodon/services/notification_service.dart';
import 'package:pixelodon/services/timeline_service.dart';

/// Provider for the AccountService
final accountServiceProvider = Provider<AccountService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AccountService(apiService: apiService);
});

/// Provider for the TimelineService
final timelineServiceProvider = Provider<TimelineService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TimelineService(apiService: apiService);
});

/// Provider for the MediaService
final mediaServiceProvider = Provider<MediaService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MediaService(apiService: apiService);
});

/// Provider for the NotificationService
final notificationServiceProvider = Provider<NotificationService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService: apiService);
});
