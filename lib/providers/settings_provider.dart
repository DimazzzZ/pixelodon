import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/services/settings_service.dart';

/// Provider for the SettingsService
final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

/// Provider for the current theme mode
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return ThemeModeNotifier(settingsService);
});

/// Provider for the current language locale
final languageProvider = StateNotifierProvider<LanguageNotifier, Locale>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return LanguageNotifier(settingsService);
});

/// Provider for notification settings
final notificationSettingsProvider = StateNotifierProvider<NotificationSettingsNotifier, Map<String, bool>>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return NotificationSettingsNotifier(settingsService);
});

/// Provider for onboarding completion status
final onboardingCompletedProvider = StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final settingsService = ref.watch(settingsServiceProvider);
  return OnboardingCompletedNotifier(settingsService);
});

/// State notifier for theme mode management
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SettingsService _settingsService;

  ThemeModeNotifier(this._settingsService) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  Future<void> _loadThemeMode() async {
    final themeMode = await _settingsService.getThemeMode();
    state = themeMode;
  }

  Future<void> setThemeMode(ThemeMode themeMode) async {
    await _settingsService.setThemeMode(themeMode);
    state = themeMode;
  }

  String get themeModeDisplayName {
    switch (state) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}

/// State notifier for language management
class LanguageNotifier extends StateNotifier<Locale> {
  final SettingsService _settingsService;

  LanguageNotifier(this._settingsService) : super(const Locale('en', 'US')) {
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final locale = await _settingsService.getLanguage();
    state = locale;
  }

  Future<void> setLanguage(Locale locale) async {
    await _settingsService.setLanguage(locale);
    state = locale;
  }

  String get languageDisplayName {
    switch (state.languageCode) {
      case 'en':
        return 'English';
      case 'es':
        return 'Español';
      case 'fr':
        return 'Français';
      case 'de':
        return 'Deutsch';
      default:
        return 'English';
    }
  }
}

/// State notifier for notification settings management
class NotificationSettingsNotifier extends StateNotifier<Map<String, bool>> {
  final SettingsService _settingsService;

  NotificationSettingsNotifier(this._settingsService) : super({
    'mentions': true,
    'follows': true,
    'likes': true,
    'reposts': true,
    'posts': true,
  }) {
    _loadNotificationSettings();
  }

  Future<void> _loadNotificationSettings() async {
    final settings = await _settingsService.getNotificationSettings();
    state = settings;
  }

  Future<void> updateSetting(String key, bool value) async {
    final newSettings = {...state, key: value};
    await _settingsService.setNotificationSettings(newSettings);
    state = newSettings;
  }
}

/// State notifier for onboarding completion status
class OnboardingCompletedNotifier extends StateNotifier<bool> {
  final SettingsService _settingsService;

  OnboardingCompletedNotifier(this._settingsService) : super(false) {
    _loadOnboardingCompleted();
  }

  Future<void> _loadOnboardingCompleted() async {
    final completed = await _settingsService.getOnboardingCompleted();
    state = completed;
  }

  Future<void> setOnboardingCompleted(bool completed) async {
    await _settingsService.setOnboardingCompleted(completed);
    state = completed;
  }
}
