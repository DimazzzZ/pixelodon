import 'package:flutter/material.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'settings_provider.g.dart';

/// State notifier for theme mode management
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  ThemeMode build() {
    _loadThemeMode();
    return ThemeMode.system;
  }

  Future<void> _loadThemeMode() async {
    final service = ref.read(settingsServiceProvider);
    final themeMode = await service.getThemeMode();
    state = themeMode;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    final service = ref.read(settingsServiceProvider);
    await service.setThemeMode(themeMode);
    state = themeMode;
  }

  String get themeModeDisplayName {
    final service = ref.read(settingsServiceProvider);
    return service.getThemeModeDisplayName(state);
  }
}

/// State notifier for language management
@Riverpod(keepAlive: true)
class LanguageNotifier extends _$LanguageNotifier {
  @override
  Locale build() {
    _loadLanguage();
    return const Locale('en', 'US');
  }

  Future<void> _loadLanguage() async {
    final service = ref.read(settingsServiceProvider);
    final locale = await service.getLanguage();
    state = locale;
  }

  Future<void> setLanguage(Locale locale) async {
    final service = ref.read(settingsServiceProvider);
    await service.setLanguage(locale);
    state = locale;
  }

  String get languageDisplayName {
    final service = ref.read(settingsServiceProvider);
    return service.getLanguageDisplayName(state);
  }
}

/// State notifier for notification settings management
@Riverpod(keepAlive: true)
class NotificationSettingsNotifier extends _$NotificationSettingsNotifier {
  @override
  Map<String, bool> build() {
    _loadNotificationSettings();
    return {
      'mentions': true,
      'follows': true,
      'likes': true,
      'reposts': true,
      'posts': true,
    };
  }

  Future<void> _loadNotificationSettings() async {
    final service = ref.read(settingsServiceProvider);
    final settings = await service.getNotificationSettings();
    state = settings;
  }

  Future<void> updateSetting(String key, bool value) async {
    final service = ref.read(settingsServiceProvider);
    final newSettings = {...state, key: value};
    await service.setNotificationSettings(newSettings);
    state = newSettings;
  }
}

/// State notifier for onboarding completion status
@Riverpod(keepAlive: true)
class OnboardingCompletedNotifier extends _$OnboardingCompletedNotifier {
  @override
  bool build() {
    _loadOnboardingCompleted();
    return false;
  }

  Future<void> _loadOnboardingCompleted() async {
    final service = ref.read(settingsServiceProvider);
    final completed = await service.getOnboardingCompleted();
    state = completed;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    final service = ref.read(settingsServiceProvider);
    await service.setOnboardingCompleted(completed);
    state = completed;
  }
}

/// State notifier for home view mode management
@Riverpod(keepAlive: true)
class HomeViewModeNotifier extends _$HomeViewModeNotifier {
  @override
  String build() {
    _loadHomeViewMode();
    return 'list';
  }

  Future<void> _loadHomeViewMode() async {
    final service = ref.read(settingsServiceProvider);
    final activeInstance = ref.read(activeInstanceProvider);
    final viewMode = await service.getHomeViewMode(activeInstance);
    state = viewMode;
  }

  Future<void> setHomeViewMode(String viewMode) async {
    final service = ref.read(settingsServiceProvider);
    await service.setHomeViewMode(viewMode);
    state = viewMode;
  }

  String get viewModeDisplayName {
    final service = ref.read(settingsServiceProvider);
    return service.getHomeViewModeDisplayName(state);
  }
}

/// State notifier for home content filter management
@Riverpod(keepAlive: true)
class HomeContentFilterNotifier extends _$HomeContentFilterNotifier {
  @override
  String build() {
    _loadHomeContentFilter();
    return 'all';
  }

  Future<void> _loadHomeContentFilter() async {
    final service = ref.read(settingsServiceProvider);
    final filter = await service.getHomeContentFilter();
    state = filter;
  }

  Future<void> setHomeContentFilter(String filter) async {
    final service = ref.read(settingsServiceProvider);
    await service.setHomeContentFilter(filter);
    state = filter;
  }

  String get filterDisplayName {
    final service = ref.read(settingsServiceProvider);
    return service.getHomeContentFilterDisplayName(state);
  }
}
