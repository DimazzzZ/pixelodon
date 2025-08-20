import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/core/config/app_config.dart';

void main() {
  group('AppConfig Tests', () {
    group('Basic App Configuration', () {
      test('should have correct app name', () {
        expect(AppConfig.appName, 'Pixelodon');
      });

      test('should have correct app version', () {
        expect(AppConfig.appVersion, '1.0.0');
      });
    });

    group('API Configuration', () {
      test('should have correct API timeout', () {
        expect(AppConfig.apiTimeoutMs, 30000);
      });

      test('should have correct max API retries', () {
        expect(AppConfig.maxApiRetries, 3);
        expect(AppConfig.maxApiRetries, greaterThan(0));
      });
    });

    group('Cache Configuration', () {
      test('should have correct cache duration', () {
        expect(AppConfig.cacheDurationHours, 24);
        expect(AppConfig.cacheDurationHours, greaterThan(0));
      });

      test('should have correct max cache items', () {
        expect(AppConfig.maxCacheItems, 500);
        expect(AppConfig.maxCacheItems, greaterThan(0));
      });
    });

    group('Account Configuration', () {
      test('should have correct max accounts limit', () {
        expect(AppConfig.maxAccounts, 5);
        expect(AppConfig.maxAccounts, greaterThan(0));
      });
    });

    group('Image Configuration', () {
      test('should have correct default image quality', () {
        expect(AppConfig.defaultImageQuality, 85);
        expect(AppConfig.defaultImageQuality, inInclusiveRange(0, 100));
      });

      test('should have correct max image dimension', () {
        expect(AppConfig.maxImageDimension, 4096);
        expect(AppConfig.maxImageDimension, greaterThan(0));
      });

      test('should have correct max images per post', () {
        expect(AppConfig.maxImagesPerPost, 20);
        expect(AppConfig.maxImagesPerPost, greaterThan(0));
      });
    });

    group('Post Configuration', () {
      test('should have correct max post length', () {
        expect(AppConfig.maxPostLength, 500);
        expect(AppConfig.maxPostLength, greaterThan(0));
      });
    });

    group('Debug Configuration', () {
      test('should return debug mode status', () {
        expect(AppConfig.isDebugMode, isA<bool>());
        expect(AppConfig.isDebugMode, kDebugMode);
      });

      test('should return API logging status', () {
        expect(AppConfig.enableApiLogging, isA<bool>());
        expect(AppConfig.enableApiLogging, AppConfig.isDebugMode);
      });

      test('API logging should match debug mode', () {
        expect(AppConfig.enableApiLogging, equals(AppConfig.isDebugMode));
      });
    });

    group('Configuration Value Ranges', () {
      test('should have reasonable API timeout value', () {
        expect(AppConfig.apiTimeoutMs, inInclusiveRange(5000, 60000));
      });

      test('should have reasonable retry count', () {
        expect(AppConfig.maxApiRetries, inInclusiveRange(1, 10));
      });

      test('should have reasonable cache duration', () {
        expect(AppConfig.cacheDurationHours, inInclusiveRange(1, 168)); // 1 hour to 1 week
      });

      test('should have reasonable max cache items', () {
        expect(AppConfig.maxCacheItems, inInclusiveRange(100, 10000));
      });

      test('should have reasonable max accounts', () {
        expect(AppConfig.maxAccounts, inInclusiveRange(1, 20));
      });

      test('should have reasonable image quality', () {
        expect(AppConfig.defaultImageQuality, inInclusiveRange(50, 100));
      });

      test('should have reasonable max image dimension', () {
        expect(AppConfig.maxImageDimension, inInclusiveRange(1024, 8192));
      });

      test('should have reasonable max images per post', () {
        expect(AppConfig.maxImagesPerPost, inInclusiveRange(1, 50));
      });

      test('should have reasonable max post length', () {
        expect(AppConfig.maxPostLength, inInclusiveRange(140, 10000));
      });
    });

    group('Configuration Constants Immutability', () {
      test('all configuration values should be const', () {
        // These should be compile-time constants
        const appName = AppConfig.appName;
        const appVersion = AppConfig.appVersion;
        const apiTimeout = AppConfig.apiTimeoutMs;
        const maxRetries = AppConfig.maxApiRetries;
        const cacheDuration = AppConfig.cacheDurationHours;
        const maxCache = AppConfig.maxCacheItems;
        const maxAccounts = AppConfig.maxAccounts;
        const imageQuality = AppConfig.defaultImageQuality;
        const maxImageDim = AppConfig.maxImageDimension;
        const maxImages = AppConfig.maxImagesPerPost;
        const maxPostLen = AppConfig.maxPostLength;

        // Verify they are not null
        expect(appName, isNotNull);
        expect(appVersion, isNotNull);
        expect(apiTimeout, isNotNull);
        expect(maxRetries, isNotNull);
        expect(cacheDuration, isNotNull);
        expect(maxCache, isNotNull);
        expect(maxAccounts, isNotNull);
        expect(imageQuality, isNotNull);
        expect(maxImageDim, isNotNull);
        expect(maxImages, isNotNull);
        expect(maxPostLen, isNotNull);
      });
    });
  });
}
