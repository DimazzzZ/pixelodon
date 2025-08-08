import 'package:flutter/foundation.dart';

/// Global application configuration
class AppConfig {
  /// App name
  static const String appName = 'Pixelodon';
  
  /// App version from pubspec.yaml
  static const String appVersion = '1.0.0';
  
  /// API timeout in milliseconds
  static const int apiTimeoutMs = 30000;
  
  /// Maximum number of retries for API calls
  static const int maxApiRetries = 3;
  
  /// Cache duration in hours
  static const int cacheDurationHours = 24;
  
  /// Maximum number of items to keep in memory cache
  static const int maxCacheItems = 500;
  
  /// Maximum number of accounts that can be added
  static const int maxAccounts = 5;
  
  /// Default image quality for uploads (0-100)
  static const int defaultImageQuality = 85;
  
  /// Maximum image dimensions for uploads
  static const int maxImageDimension = 4096;
  
  /// Maximum number of images in a post
  static const int maxImagesPerPost = 20;
  
  /// Maximum post text length
  static const int maxPostLength = 500;
  
  /// Debug mode flag
  static bool get isDebugMode => kDebugMode;
  
  /// API logging enabled flag
  static bool get enableApiLogging => isDebugMode;
}
