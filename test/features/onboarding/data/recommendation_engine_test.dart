import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/features/onboarding/data/recommendation_engine.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/infra/api/discovery/discovery_repository.dart';

import '../../../test_support/mock_asset_loader.dart';
import 'recommendation_engine_test.mocks.dart';

@GenerateMocks([DiscoveryRepository])
void main() {
  group('RecommendationEngine Tests', () {
    late MockDiscoveryRepository mockDiscoveryRepository;

    setUp(() {
      mockDiscoveryRepository = MockDiscoveryRepository();
    });

    group('generateRecommendations', () {
      test('should generate recommendations based on preferences', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        final preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.photos,
          moderation: ModerationStyle.balanced,
          preferOpenRegistration: true,
        );

        // Act
        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
          maxResults: 3,
        );

        // Assert
        expect(recommendations, isNotEmpty);
        expect(recommendations.length, lessThanOrEqualTo(3));
        // Photo-focused instances should score higher for photo focus preference
        final hasPhotoFocused = recommendations.any(
          (r) => r.instance.photoFocused || r.instance.platform == InstancePlatform.pixelfed,
        );
        expect(hasPhotoFocused, isTrue);
      });

      test('should return empty list when no instances match', () async {
        // Arrange - use instances that won't match the preferences
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson(
          instances: [
            TestInstanceData.instance(
              domain: 'german.only',
              languages: ['de'],
              moderationStyle: 'stricter',
              photoFocused: false,
            ),
          ],
        ));
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Preferences that won't match the German instance
        final preferences = OnboardingPreferences(
          languages: ['ja'], // Japanese - won't match
          focus: InstanceFocus.photos,
          moderation: ModerationStyle.freer,
          preferOpenRegistration: true,
        );

        // Act
        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
        );

        // Assert
        expect(recommendations, isEmpty);
      });

      test('should handle asset loading failure gracefully', () async {
        // Arrange
        final assetLoader = MockAssetLoader.failing();
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        final preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.both,
          moderation: ModerationStyle.balanced,
          preferOpenRegistration: true,
        );

        // Act
        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
        );

        // Assert - should return empty list, not throw
        expect(recommendations, isEmpty);
      });
    });

    group('getAllInstances', () {
      test('should return all instances with filtering', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - filter for pixelfed only
        final instances = await engine.getAllInstances(
          filter: InstanceFilter(
            platform: InstancePlatform.pixelfed,
          ),
        );

        // Assert
        expect(instances, isNotEmpty);
        for (final instance in instances) {
          expect(instance.platform, equals(InstancePlatform.pixelfed));
        }
      });

      test('should apply sorting correctly', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - sort by user count (descending)
        final instances = await engine.getAllInstances(
          sortOrder: InstanceSortOrder.userCount,
        );

        // Assert - should be sorted by active users descending
        expect(instances.length, greaterThan(1));
        for (var i = 0; i < instances.length - 1; i++) {
          expect(
            instances[i].activeUsers,
            greaterThanOrEqualTo(instances[i + 1].activeUsers),
            reason: 'Instances should be sorted by user count descending',
          );
        }
      });

      test('should handle search query filtering', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - search for "photo"
        final instances = await engine.getAllInstances(
          filter: InstanceFilter(searchQuery: 'photo'),
        );

        // Assert - should find photo-related instances
        expect(instances, isNotEmpty);
        for (final instance in instances) {
          final matchesSearch = 
            instance.title.toLowerCase().contains('photo') ||
            instance.description.toLowerCase().contains('photo') ||
            instance.domain.toLowerCase().contains('photo');
          expect(matchesSearch, isTrue);
        }
      });
    });

    group('getGuestModeInstances', () {
      test('should return safe instances for guest mode', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act
        final instances = await engine.getGuestModeInstances(count: 5);

        // Assert - all should be safe for guest mode
        for (final instance in instances) {
          expect(instance.openRegistration, isTrue, 
            reason: 'Guest mode instances should have open registration');
          expect(instance.loadScore, lessThan(40),
            reason: 'Guest mode instances should have reasonable load');
          expect(
            instance.moderationStyle == ModerationStyle.balanced ||
            instance.moderationStyle == ModerationStyle.stricter,
            isTrue,
            reason: 'Guest mode instances should be well-moderated',
          );
        }
      });

      test('should limit results to requested count', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act
        final instances = await engine.getGuestModeInstances(count: 2);

        // Assert
        expect(instances.length, lessThanOrEqualTo(2));
      });
    });

    group('refreshCuratedInstances', () {
      test('should force reload of cached instances', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Load instances first time
        await engine.getAllInstances();
        final firstLoadCount = assetLoader.loadCallCount;
        expect(firstLoadCount, equals(1));

        // Load again - should use cache
        await engine.getAllInstances();
        expect(assetLoader.loadCallCount, equals(1), 
          reason: 'Should use cached data');

        // Act - force refresh
        await engine.refreshCuratedInstances();

        // Assert - should have loaded again
        expect(assetLoader.loadCallCount, equals(2),
          reason: 'Refresh should force reload');
      });
    });

    group('caching behavior', () {
      test('should cache instances and reuse within timeout', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - load multiple times
        await engine.getAllInstances();
        await engine.getAllInstances();
        await engine.getAllInstances();

        // Assert - should only load once due to caching
        expect(assetLoader.loadCallCount, equals(1));
      });
    });

    group('recommendation reasons and badges', () {
      test('should generate appropriate reasons for language match', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson(
          instances: [
            TestInstanceData.instance(
              domain: 'test.instance',
              languages: ['en', 'de'],
              moderationStyle: 'balanced',
            ),
          ],
        ));
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        final preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.both,
          moderation: ModerationStyle.balanced,
          preferOpenRegistration: true,
        );

        // Act
        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
        );

        // Assert
        expect(recommendations, isNotEmpty);
        final reasons = recommendations.first.reasons;
        final hasLanguageReason = reasons.any(
          (r) => r.type == RecommendationReasonType.languageMatch,
        );
        expect(hasLanguageReason, isTrue);
      });

      test('should mark featured instances correctly', () async {
        // Arrange - include featured domain
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson(
          instances: [
            TestInstanceData.instance(
              domain: 'mastodon.social', // Featured domain
              moderationStyle: 'balanced',
            ),
            TestInstanceData.instance(
              domain: 'random.instance',
              moderationStyle: 'balanced',
            ),
          ],
        ));
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        final preferences = OnboardingPreferences(
          languages: ['en'],
          focus: InstanceFocus.both,
          moderation: ModerationStyle.balanced,
          preferOpenRegistration: true,
        );

        // Act
        final recommendations = await engine.generateRecommendations(
          preferences: preferences,
          maxResults: 10,
        );

        // Assert
        final mastodonSocial = recommendations.where(
          (r) => r.instance.domain == 'mastodon.social',
        );
        expect(mastodonSocial, isNotEmpty);
        expect(mastodonSocial.first.isFeatured, isTrue);

        final randomInstance = recommendations.where(
          (r) => r.instance.domain == 'random.instance',
        );
        if (randomInstance.isNotEmpty) {
          expect(randomInstance.first.isFeatured, isFalse);
        }
      });
    });

    group('filtering edge cases', () {
      test('should handle empty filter', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - no filter
        final instances = await engine.getAllInstances();

        // Assert - should return all instances
        expect(instances.length, equals(7)); // All default test instances
      });

      test('should filter by open registration', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act - filter for open registration only
        final openInstances = await engine.getAllInstances(
          filter: InstanceFilter(openRegistration: true),
        );
        final closedInstances = await engine.getAllInstances(
          filter: InstanceFilter(openRegistration: false),
        );

        // Assert
        for (final instance in openInstances) {
          expect(instance.openRegistration, isTrue);
        }
        for (final instance in closedInstances) {
          expect(instance.openRegistration, isFalse);
        }
      });

      test('should filter by region', () async {
        // Arrange
        final assetLoader = MockAssetLoader.withJson(TestInstanceData.curatedJson());
        final engine = RecommendationEngine(
          discoveryRepository: mockDiscoveryRepository,
          assetLoader: assetLoader,
        );

        // Act
        final europeInstances = await engine.getAllInstances(
          filter: InstanceFilter(region: 'Europe'),
        );

        // Assert
        expect(europeInstances, isNotEmpty);
        for (final instance in europeInstances) {
          expect(instance.region.toLowerCase(), contains('europe'));
        }
      });
    });
  });
}
