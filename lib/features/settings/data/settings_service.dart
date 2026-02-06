import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/utils/logger.dart';

/// Service for managing app settings persistence
class SettingsService {
  final FlutterSecureStorage _storage;
  
  /// Constructor
  SettingsService({
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage();
  
  // Storage keys
  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _notificationSettingsKey = 'notification_settings';
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _onboardingPreferencesKey = 'onboarding_preferences';
  static const _homeViewModeKey = 'home_view_mode';
  static const _homeContentFilterKey = 'home_content_filter';

  /// Get the current theme mode
  Future<ThemeMode> getThemeMode() async {
    try {
      final themeModeString = await _storage.read(key: _themeModeKey);
      if (themeModeString == null) return ThemeMode.system;

      return switch (themeModeString) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        'system' || _ => ThemeMode.system,
      };
    } catch (e) {
      logger.e('Failed to get theme mode', error: e);
      return ThemeMode.system;
    }
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      final themeModeString = switch (themeMode) {
        ThemeMode.light => 'light',
        ThemeMode.dark => 'dark',
        ThemeMode.system => 'system',
      };
      await _storage.write(key: _themeModeKey, value: themeModeString);
    } catch (e) {
      logger.e('Failed to set theme mode', error: e);
    }
  }

  /// Get the current language
  Future<Locale> getLanguage() async {
    try {
      final languageString = await _storage.read(key: _languageKey);
      if (languageString == null) return const Locale('en', 'US');
      
      final parts = languageString.split('_');
      if (parts.length == 2) {
        return Locale(parts[0], parts[1]);
      }
      return Locale(parts[0]);
    } catch (e) {
      logger.e('Failed to get language', error: e);
      return const Locale('en', 'US');
    }
  }

  /// Set the language
  Future<void> setLanguage(Locale locale) async {
    try {
      final languageString = locale.countryCode != null
          ? '${locale.languageCode}_${locale.countryCode}'
          : locale.languageCode;
      await _storage.write(key: _languageKey, value: languageString);
    } catch (e) {
      logger.e('Failed to set language', error: e);
    }
  }

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    try {
      final settingsString = await _storage.read(key: _notificationSettingsKey);
      if (settingsString == null) {
        return {
          'mentions': true,
          'follows': true,
          'likes': true,
          'reposts': true,
          'posts': true,
        };
      }
      
      final dynamic decoded = jsonDecode(settingsString);
      if (decoded is Map) {
        return decoded.map((key, value) => MapEntry(key.toString(), value as bool));
      }
      return {
        'mentions': true,
        'follows': true,
        'likes': true,
        'reposts': true,
        'posts': true,
      };
    } catch (e) {
      logger.e('Failed to get notification settings', error: e);
      return {
        'mentions': true,
        'follows': true,
        'likes': true,
        'reposts': true,
        'posts': true,
      };
    }
  }

  /// Set notification settings
  Future<void> setNotificationSettings(Map<String, bool> settings) async {
    try {
      final settingsString = jsonEncode(settings);
      await _storage.write(key: _notificationSettingsKey, value: settingsString);
    } catch (e) {
      logger.e('Failed to set notification settings', error: e);
    }
  }

  /// Get onboarding completion status
  Future<bool> getOnboardingCompleted() async {
    try {
      final completedString = await _storage.read(key: _onboardingCompletedKey);
      return completedString == 'true';
    } catch (e) {
      logger.e('Failed to get onboarding completion status', error: e);
      return false;
    }
  }

  /// Set onboarding completion status
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _storage.write(key: _onboardingCompletedKey, value: completed.toString());
    } catch (e) {
      logger.e('Failed to set onboarding completion status', error: e);
    }
  }

  /// Get onboarding preferences
  Future<Map<String, dynamic>?> getOnboardingPreferences() async {
    try {
      final preferencesString = await _storage.read(key: _onboardingPreferencesKey);
      if (preferencesString == null) return null;
      return jsonDecode(preferencesString) as Map<String, dynamic>;
    } catch (e) {
      logger.e('Failed to get onboarding preferences', error: e);
      return null;
    }
  }

  /// Set onboarding preferences
  Future<void> setOnboardingPreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesString = jsonEncode(preferences);
      await _storage.write(key: _onboardingPreferencesKey, value: preferencesString);
    } catch (e) {
      logger.e('Failed to set onboarding preferences', error: e);
    }
  }

  /// Reset onboarding status (useful for testing)
  Future<void> resetOnboarding() async {
    try {
      await _storage.delete(key: _onboardingCompletedKey);
      await _storage.delete(key: _onboardingPreferencesKey);
    } catch (e) {
      logger.e('Failed to reset onboarding', error: e);
    }
  }

  /// Clear all settings (useful for logout/reset)
  Future<void> clearAllSettings() async {
    try {
      await _storage.delete(key: _themeModeKey);
      await _storage.delete(key: _languageKey);
      await _storage.delete(key: _notificationSettingsKey);
      await _storage.delete(key: _onboardingCompletedKey);
      await _storage.delete(key: _onboardingPreferencesKey);
    } catch (e) {
      logger.e('Failed to clear all settings', error: e);
    }
  }

  /// Get available theme modes
  List<ThemeMode> getAvailableThemeModes() {
    return [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
  }

  /// Get available languages
  List<Locale> getAvailableLanguages() {
    return [
      const Locale('en', 'US'), // English
      const Locale('es', 'ES'), // Spanish
      const Locale('fr', 'FR'), // French
      const Locale('de', 'DE'), // German
    ];
  }

  /// Get display name for a locale
  String getLanguageDisplayName(Locale locale) => switch (locale.languageCode) {
        'en' => 'English',
        'es' => 'Español',
        'fr' => 'Français',
        'de' => 'Deutsch',
        _ => 'English',
      };

  /// Get display name for theme mode
  String getThemeModeDisplayName(ThemeMode themeMode) => switch (themeMode) {
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
        ThemeMode.system => 'System',
      };

  /// Get the current home view mode with instance-based defaults
  Future<String> getHomeViewMode([Instance? activeInstance]) async {
    try {
      final viewMode = await _storage.read(key: _homeViewModeKey);
      if (viewMode != null) {
        return viewMode; // User has explicitly set a preference
      }

      // Set default based on instance type
      if (activeInstance != null) {
        final defaultMode = activeInstance.isPixelfed ? 'images' : 'list';
        return defaultMode;
      }

      return 'list'; // Fallback default
    } catch (e) {
      logger.e('Failed to get home view mode', error: e);
      return 'list';
    }
  }

  /// Set the home view mode
  Future<void> setHomeViewMode(String viewMode) async {
    try {
      await _storage.write(key: _homeViewModeKey, value: viewMode);
    } catch (e) {
      logger.e('Failed to set home view mode', error: e);
    }
  }

  /// Get the current home content filter
  Future<String> getHomeContentFilter() async {
    try {
      final filter = await _storage.read(key: _homeContentFilterKey);
      return filter ?? 'all'; // Default to all content
    } catch (e) {
      logger.e('Failed to get home content filter', error: e);
      return 'all';
    }
  }

  /// Set the home content filter
  Future<void> setHomeContentFilter(String filter) async {
    try {
      await _storage.write(key: _homeContentFilterKey, value: filter);
    } catch (e) {
      logger.e('Failed to set home content filter', error: e);
    }
  }

  /// Get available home view modes
  List<String> getAvailableHomeViewModes() {
    return ['list', 'images', 'grid'];
  }

  /// Get available home content filters
  List<String> getAvailableHomeContentFilters() {
    return ['all', 'images'];
  }

  /// Get display name for home view mode
  String getHomeViewModeDisplayName(String viewMode) => switch (viewMode) {
        'list' => 'Posts List',
        'images' => 'Images List',
        'grid' => 'Images Grid',
        _ => 'Classic Posts',
      };

  /// Get display name for home content filter
  String getHomeContentFilterDisplayName(String filter) => switch (filter) {
        'all' => 'All Posts',
        'images' => 'Images Only',
        _ => 'All Posts',
      };
}
