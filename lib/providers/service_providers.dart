import 'package:pixelodon/features/settings/data/settings_service.dart';
import 'package:pixelodon/providers/api_provider.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/media_service.dart';
import 'package:pixelodon/services/notification_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'service_providers.g.dart';

/// Provider for SettingsService
@Riverpod(keepAlive: true)
SettingsService settingsService(SettingsServiceRef ref) {
  return SettingsService();
}

/// Provider for TimelineService
@Riverpod(keepAlive: true)
TimelineService timelineService(TimelineServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return TimelineService(apiService: apiService);
}

/// Provider for AccountService
@Riverpod(keepAlive: true)
AccountService accountService(AccountServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AccountService(apiService: apiService);
}

/// Provider for MediaService
@Riverpod(keepAlive: true)
MediaService mediaService(MediaServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return MediaService(apiService: apiService);
}

/// Provider for NotificationService
@Riverpod(keepAlive: true)
NotificationService notificationService(NotificationServiceRef ref) {
  final apiService = ref.watch(apiServiceProvider);
  return NotificationService(apiService: apiService);
}
