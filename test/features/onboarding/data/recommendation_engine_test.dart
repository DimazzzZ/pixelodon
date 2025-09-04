import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/features/onboarding/data/recommendation_engine.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/infra/api/discovery/discovery_repository.dart';

import 'recommendation_engine_test.mocks.dart';

@GenerateMocks([DiscoveryRepository])
void main() {
  group('RecommendationEngine Tests', () {
    late RecommendationEngine engine;
    late MockDiscoveryRepository mockDiscoveryRepository;

    setUp(() {
      mockDiscoveryRepository = MockDiscoveryRepository();
      engine = RecommendationEngine(discoveryRepository: mockDiscoveryRepository);
    });

    group('generateRecommendations', () {
      testWidgets('should generate recommendations based on preferences', (tester) async {
        // Mock asset loading
        const assetData = '''
{
  "instances": [
    {
      "domain": "mastodon.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "supportsStories": false,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 45.0,
      "title": "Mastodon Social",
      "description": "The original Mastodon instance",
      "activeUsers": 850000,
      "region": "Global",
      "photoFocused": false,
      "rules": ["Be respectful", "No spam"]
    },
    {
      "domain": "pixelfed.social",
      "platform": "pixelfed",
      "openRegistration": true,
      "maxMediaPerPost": 20,
      "supportsStories": true,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 25.0,
      "title": "Pixelfed Social",
      "description": "Photo sharing platform",
      "activeUsers": 45000,
      "region": "Global",
      "photoFocused": true,
      "rules": ["Photos only", "Be kind"]
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        const preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.photos,
          moderation: ModerationStyle.balanced,
        );

        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
          maxResults: 2,
        );

        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(2));
        
        // Pixelfed should score higher for photo focus
        final pixelfedRec = recommendations.firstWhere(
          (r) => r.instance.platform == InstancePlatform.pixelfed,
          orElse: () => recommendations.first,
        );
        
        expect(pixelfedRec.instance.domain, equals('pixelfed.social'));
        expect(pixelfedRec.reasons, isNotEmpty);
        expect(pixelfedRec.badges, isNotEmpty);
      });

      testWidgets('should return empty list when no instances match', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "japanese.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "supportsStories": false,
      "languages": ["ja"],
      "moderationStyle": "balanced",
      "loadScore": 30.0,
      "title": "Japanese Social",
      "description": "Japanese only",
      "activeUsers": 5000,
      "region": "Asia",
      "photoFocused": false,
      "rules": ["Japanese only"]
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        const preferences = OnboardingPreferences(
          languages: ['en'], // No match with Japanese instance
          focus: InstanceFocus.text,
          moderation: ModerationStyle.balanced,
        );

        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
          maxResults: 3,
        );

        expect(recommendations, isEmpty);
      });

      testWidgets('should handle asset loading failure gracefully', (tester) async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            throw Exception('Asset loading failed');
          },
        );

        const preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.both,
          moderation: ModerationStyle.balanced,
        );

        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
          maxResults: 3,
        );

        expect(recommendations, isEmpty);
      });
    });

    group('getAllInstances', () {
      testWidgets('should return all instances with filtering', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "mastodon.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 45.0,
      "title": "Mastodon Social",
      "activeUsers": 850000
    },
    {
      "domain": "pixelfed.social",
      "platform": "pixelfed",
      "openRegistration": false,
      "maxMediaPerPost": 20,
      "languages": ["en"],
      "moderationStyle": "stricter",
      "loadScore": 25.0,
      "title": "Pixelfed Social",
      "activeUsers": 45000,
      "photoFocused": true
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        // Test platform filtering
        final mastodonInstances = await engine.getAllInstances(
          filter: const InstanceFilter(platform: InstancePlatform.mastodon),
        );

        expect(mastodonInstances.length, equals(1));
        expect(mastodonInstances.first.domain, equals('mastodon.social'));

        // Test registration filtering
        final openInstances = await engine.getAllInstances(
          filter: const InstanceFilter(openRegistration: true),
        );

        expect(openInstances.length, equals(1));
        expect(openInstances.first.openRegistration, isTrue);

        // Test photo focus filtering
        const photoFilter = InstanceFilter(photoFocused: true);
        final photoInstances = await engine.getAllInstances(filter: photoFilter);

        expect(photoInstances.length, equals(1));
        expect(photoInstances.first.photoFocused, isTrue);
      });

      testWidgets('should apply sorting correctly', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "z-last.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 10.0,
      "activeUsers": 1000
    },
    {
      "domain": "a-first.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 50.0,
      "activeUsers": 10000
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        // Test alphabetical sorting
        final alphabetical = await engine.getAllInstances(
          sortOrder: InstanceSortOrder.alphabetical,
        );

        expect(alphabetical.first.domain, equals('a-first.social'));
        expect(alphabetical.last.domain, equals('z-last.social'));

        // Test user count sorting
        final byUsers = await engine.getAllInstances(
          sortOrder: InstanceSortOrder.userCount,
        );

        expect(byUsers.first.activeUsers, equals(10000)); // Highest first
        expect(byUsers.last.activeUsers, equals(1000));

        // Test load score sorting
        final byLoad = await engine.getAllInstances(
          sortOrder: InstanceSortOrder.loadScore,
        );

        expect(byLoad.first.loadScore, equals(10.0)); // Lowest first (best performance)
        expect(byLoad.last.loadScore, equals(50.0));
      });

      testWidgets('should handle search query filtering', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "mastodon.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 45.0,
      "title": "Mastodon Social",
      "description": "The original Mastodon instance",
      "activeUsers": 850000
    },
    {
      "domain": "pixelfed.social",
      "platform": "pixelfed",
      "openRegistration": true,
      "maxMediaPerPost": 20,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 25.0,
      "title": "Pixelfed Social",
      "description": "Photo sharing platform",
      "activeUsers": 45000
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        // Test domain search
        final domainSearch = await engine.getAllInstances(
          filter: const InstanceFilter(searchQuery: 'pixelfed'),
        );

        expect(domainSearch.length, equals(1));
        expect(domainSearch.first.domain, contains('pixelfed'));

        // Test title search
        final titleSearch = await engine.getAllInstances(
          filter: const InstanceFilter(searchQuery: 'original'),
        );

        expect(titleSearch.length, equals(1));
        expect(titleSearch.first.description, contains('original'));

        // Test case insensitive search
        final caseSearch = await engine.getAllInstances(
          filter: const InstanceFilter(searchQuery: 'PHOTO'),
        );

        expect(caseSearch.length, equals(1));
        expect(caseSearch.first.description.toLowerCase(), contains('photo'));
      });
    });

    group('getGuestModeInstances', () {
      testWidgets('should return safe instances for guest mode', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "safe.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 20.0,
      "activeUsers": 5000
    },
    {
      "domain": "unsafe.social",
      "platform": "mastodon",
      "openRegistration": false,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "freer",
      "loadScore": 60.0,
      "activeUsers": 1000
    },
    {
      "domain": "moderated.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "stricter",
      "loadScore": 15.0,
      "activeUsers": 8000
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        final guestInstances = await engine.getGuestModeInstances(count: 5);

        expect(guestInstances, isNotEmpty);
        
        // All instances should be safe for guest mode
        for (final instance in guestInstances) {
          expect(instance.openRegistration, isTrue);
          expect(instance.loadScore, lessThan(40));
          expect([ModerationStyle.balanced, ModerationStyle.stricter], 
                 contains(instance.moderationStyle));
        }

        // Should not include the unsafe instance
        expect(guestInstances.any((i) => i.domain == 'unsafe.social'), isFalse);
      });

      testWidgets('should limit results to requested count', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "safe1.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 20.0,
      "activeUsers": 5000
    },
    {
      "domain": "safe2.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 25.0,
      "activeUsers": 3000
    },
    {
      "domain": "safe3.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "stricter",
      "loadScore": 15.0,
      "activeUsers": 8000
    }
  ]
}
        ''';

        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              return assetData;
            }
            return null;
          },
        );

        final limitedInstances = await engine.getGuestModeInstances(count: 2);

        expect(limitedInstances.length, equals(2));
      });
    });

    group('refreshCuratedInstances', () {
      testWidgets('should force reload of cached instances', (tester) async {
        const assetData1 = '''
{
  "instances": [
    {
      "domain": "first.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 30.0,
      "activeUsers": 5000
    }
  ]
}
        ''';

        const assetData2 = '''
{
  "instances": [
    {
      "domain": "second.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 25.0,
      "activeUsers": 7000
    }
  ]
}
        ''';

        var callCount = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              callCount++;
              return callCount == 1 ? assetData1 : assetData2;
            }
            return null;
          },
        );

        // First call should load first dataset
        var instances = await engine.getAllInstances();
        expect(instances.first.domain, equals('first.social'));

        // Refresh and get instances again - should load second dataset
        await engine.refreshCuratedInstances();
        instances = await engine.getAllInstances();
        expect(instances.first.domain, equals('second.social'));
        expect(callCount, equals(2)); // Should have made two calls
      });
    });

    group('caching behavior', () {
      testWidgets('should cache instances and reuse within timeout', (tester) async {
        const assetData = '''
{
  "instances": [
    {
      "domain": "cached.social",
      "platform": "mastodon",
      "openRegistration": true,
      "maxMediaPerPost": 4,
      "languages": ["en"],
      "moderationStyle": "balanced",
      "loadScore": 30.0,
      "activeUsers": 5000
    }
  ]
}
        ''';

        var callCount = 0;
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('flutter/assets'),
          (MethodCall methodCall) async {
            if (methodCall.method == 'loadString') {
              callCount++;
              return assetData;
            }
            return null;
          },
        );

        // Multiple calls should use cached data
        await engine.getAllInstances();
        await engine.getAllInstances();
        await engine.getAllInstances();

        expect(callCount, equals(1)); // Should have made only one call due to caching
      });
    });
  });
}
