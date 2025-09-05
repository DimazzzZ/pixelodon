import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for managing app settings persistence
class SettingsService {
  static const _storage = FlutterSecureStorage();
  
  // Storage keys
  static const _themeModeKey = 'theme_mode';
  static const _languageKey = 'language';
  static const _notificationSettingsKey = 'notification_settings';
  static const _onboardingCompletedKey = 'onboarding_completed';
  static const _onboardingPreferencesKey = 'onboarding_preferences';

  /// Get the current theme mode
  Future<ThemeMode> getThemeMode() async {
    try {
      final themeModeString = await _storage.read(key: _themeModeKey);
      if (themeModeString == null) return ThemeMode.system;
      
      switch (themeModeString) {
        case 'light':
          return ThemeMode.light;
        case 'dark':
          return ThemeMode.dark;
        case 'system':
        default:
          return ThemeMode.system;
      }
    } catch (e) {
      return ThemeMode.system;
    }
  }

  /// Set the theme mode
  Future<void> setThemeMode(ThemeMode themeMode) async {
    try {
      String themeModeString;
      switch (themeMode) {
        case ThemeMode.light:
          themeModeString = 'light';
          break;
        case ThemeMode.dark:
          themeModeString = 'dark';
          break;
        case ThemeMode.system:
          themeModeString = 'system';
          break;
      }
      await _storage.write(key: _themeModeKey, value: themeModeString);
    } catch (e) {
      // Handle error silently - settings will default to system
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
      // Handle error silently - language will default to English
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
      
      final Map<String, dynamic> decoded = jsonDecode(settingsString);
      return decoded.map((key, value) => MapEntry(key, value as bool));
    } catch (e) {
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
      // Handle error silently - settings will use defaults
    }
  }

  /// Get onboarding completion status
  Future<bool> getOnboardingCompleted() async {
    try {
      final completedString = await _storage.read(key: _onboardingCompletedKey);
      return completedString == 'true';
    } catch (e) {
      return false;
    }
  }

  /// Set onboarding completion status
  Future<void> setOnboardingCompleted(bool completed) async {
    try {
      await _storage.write(key: _onboardingCompletedKey, value: completed.toString());
    } catch (e) {
      // Handle error silently
    }
  }

  /// Get onboarding preferences
  Future<Map<String, dynamic>?> getOnboardingPreferences() async {
    try {
      final preferencesString = await _storage.read(key: _onboardingPreferencesKey);
      if (preferencesString == null) return null;
      return jsonDecode(preferencesString) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Set onboarding preferences
  Future<void> setOnboardingPreferences(Map<String, dynamic> preferences) async {
    try {
      final preferencesString = jsonEncode(preferences);
      await _storage.write(key: _onboardingPreferencesKey, value: preferencesString);
    } catch (e) {
      // Handle error silently
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
      // Handle error silently
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
  String getLanguageDisplayName(Locale locale) {
    switch (locale.languageCode) {
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

  /// Get display name for theme mode
  String getThemeModeDisplayName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }
}
