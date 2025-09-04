import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';

void main() {
  group('InstanceCaps Tests', () {
    group('fromJson and toJson', () {
      test('should serialize and deserialize correctly', () {
        const instanceCaps = InstanceCaps(
          domain: 'mastodon.social',
          platform: InstancePlatform.mastodon,
          openRegistration: true,
          maxMediaPerPost: 4,
          supportsStories: false,
          languages: ['en', 'es'],
          moderationStyle: ModerationStyle.balanced,
          loadScore: 45.0,
          title: 'Mastodon Social',
          description: 'The original Mastodon instance',
          activeUsers: 850000,
          region: 'Global',
          photoFocused: false,
          rules: ['Be respectful', 'No spam'],
        );

        final json = instanceCaps.toJson();
        final fromJson = InstanceCaps.fromJson(json);

        expect(fromJson, equals(instanceCaps));
        expect(fromJson.domain, equals('mastodon.social'));
        expect(fromJson.platform, equals(InstancePlatform.mastodon));
        expect(fromJson.openRegistration, isTrue);
        expect(fromJson.maxMediaPerPost, equals(4));
        expect(fromJson.supportsStories, isFalse);
        expect(fromJson.languages, equals(['en', 'es']));
        expect(fromJson.moderationStyle, equals(ModerationStyle.balanced));
        expect(fromJson.loadScore, equals(45.0));
        expect(fromJson.title, equals('Mastodon Social'));
        expect(fromJson.description, equals('The original Mastodon instance'));
        expect(fromJson.activeUsers, equals(850000));
        expect(fromJson.region, equals('Global'));
        expect(fromJson.photoFocused, isFalse);
        expect(fromJson.rules, equals(['Be respectful', 'No spam']));
      });

      test('should handle default values', () {
        const instanceCaps = InstanceCaps(
          domain: 'example.com',
          platform: InstancePlatform.unknown,
          openRegistration: false,
          maxMediaPerPost: 4,
          moderationStyle: ModerationStyle.balanced,
          loadScore: 50.0,
        );

        final json = instanceCaps.toJson();
        final fromJson = InstanceCaps.fromJson(json);

        expect(fromJson.supportsStories, isFalse);
        expect(fromJson.languages, isEmpty);
        expect(fromJson.title, equals(''));
        expect(fromJson.description, equals(''));
        expect(fromJson.activeUsers, equals(0));
        expect(fromJson.region, equals(''));
        expect(fromJson.photoFocused, isFalse);
        expect(fromJson.rules, isEmpty);
      });
    });

    group('defaultMaxMedia', () {
      test('should return 4 for Mastodon', () {
        const instanceCaps = InstanceCaps(
          domain: 'mastodon.social',
          platform: InstancePlatform.mastodon,
          openRegistration: true,
          maxMediaPerPost: 8, // This is overridden by defaultMaxMedia
          moderationStyle: ModerationStyle.balanced,
          loadScore: 45.0,
        );

        expect(instanceCaps.defaultMaxMedia, equals(4));
      });

      test('should return 20 for Pixelfed', () {
        const instanceCaps = InstanceCaps(
          domain: 'pixelfed.social',
          platform: InstancePlatform.pixelfed,
          openRegistration: true,
          maxMediaPerPost: 10, // This is overridden by defaultMaxMedia
          moderationStyle: ModerationStyle.balanced,
          loadScore: 25.0,
        );

        expect(instanceCaps.defaultMaxMedia, equals(20));
      });

      test('should return 4 for unknown platform', () {
        const instanceCaps = InstanceCaps(
          domain: 'unknown.social',
          platform: InstancePlatform.unknown,
          openRegistration: true,
          maxMediaPerPost: 10,
          moderationStyle: ModerationStyle.balanced,
          loadScore: 50.0,
        );

        expect(instanceCaps.defaultMaxMedia, equals(4));
      });
    });

    group('matchesPreferences', () {
      const instance = InstanceCaps(
        domain: 'mastodon.art',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        languages: ['en', 'fr'],
        moderationStyle: ModerationStyle.balanced,
        loadScore: 20.0,
        photoFocused: true,
      );

      test('should match when languages overlap', () {
        final matches = instance.matchesPreferences(
          preferredLanguages: ['en', 'de'],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        expect(matches, isTrue);
      });

      test('should not match when no language overlap', () {
        final matches = instance.matchesPreferences(
          preferredLanguages: ['ja', 'ko'],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        expect(matches, isFalse);
      });

      test('should match when instance has no specified languages', () {
        const noLangInstance = InstanceCaps(
          domain: 'example.com',
          platform: InstancePlatform.mastodon,
          openRegistration: true,
          maxMediaPerPost: 4,
          languages: [],
          moderationStyle: ModerationStyle.balanced,
          loadScore: 30.0,
        );

        final matches = noLangInstance.matchesPreferences(
          preferredLanguages: ['ja', 'ko'],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        expect(matches, isTrue);
      });

      test('should match photo focus correctly', () {
        final matchesPhoto = instance.matchesPreferences(
          preferredLanguages: ['en'],
          focus: InstanceFocus.photos,
          moderationPreference: ModerationStyle.balanced,
        );

        final matchesText = instance.matchesPreferences(
          preferredLanguages: ['en'],
          focus: InstanceFocus.text,
          moderationPreference: ModerationStyle.balanced,
        );

        final matchesBoth = instance.matchesPreferences(
          preferredLanguages: ['en'],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        expect(matchesPhoto, isTrue); // photo-focused instance matches photos
        expect(matchesText, isFalse); // photo-focused instance doesn't match text-only
        expect(matchesBoth, isTrue); // both is always acceptable
      });

      test('should handle Pixelfed platform for photo focus', () {
        const pixelfedInstance = InstanceCaps(
          domain: 'pixelfed.social',
          platform: InstancePlatform.pixelfed,
          openRegistration: true,
          maxMediaPerPost: 20,
          languages: ['en'],
          moderationStyle: ModerationStyle.balanced,
          loadScore: 25.0,
          photoFocused: false, // Even if not explicitly photo-focused, Pixelfed is for photos
        );

        final matchesPhoto = pixelfedInstance.matchesPreferences(
          preferredLanguages: ['en'],
          focus: InstanceFocus.photos,
          moderationPreference: ModerationStyle.balanced,
        );

        expect(matchesPhoto, isTrue);
      });
    });

    group('calculateScore', () {
      const instance = InstanceCaps(
        domain: 'mastodon.art',
        platform: InstancePlatform.mastodon,
        openRegistration: true,
        maxMediaPerPost: 4,
        languages: ['en', 'fr'],
        moderationStyle: ModerationStyle.balanced,
        loadScore: 20.0,
        activeUsers: 5000,
        photoFocused: true,
      );

      test('should calculate base score correctly', () {
        final score = instance.calculateScore(
          preferredLanguages: [],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        // Base score: 100
        // Open registration bonus: +10
        // Load score penalty: -20 * 0.3 = -6
        // Active user bonus (1000-50000): +10
        // Focus bonus for 'both': +10
        // Moderation match bonus: +15
        // Expected: 100 + 10 - 6 + 10 + 10 + 15 = 139
        expect(score, closeTo(139, 0.1));
      });

      test('should give language bonus', () {
        final score = instance.calculateScore(
          preferredLanguages: ['en', 'fr'],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        // Base calculation + language bonus: 2 matches * 15 = +30
        final baseScore = 139.0; // From previous test
        expect(score, closeTo(150.0, 0.1)); // Capped at 150
      });

      test('should give focus bonus for photos', () {
        final score = instance.calculateScore(
          preferredLanguages: [],
          focus: InstanceFocus.photos,
          moderationPreference: ModerationStyle.balanced,
        );

        // Base calculation + photo focus bonus: +20 (instead of +10 for 'both')
        // Base: 139 - 10 (both) + 20 (photos) = 149
        expect(score, closeTo(149, 0.1));
      });

      test('should give moderation match bonus', () {
        final score = instance.calculateScore(
          preferredLanguages: [],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
        );

        // Base calculation already includes moderation match: +15
        // Same as base score test since moderation already matches
        expect(score, closeTo(139, 0.1));
      });

      test('should penalize closed registration when open preferred', () {
        const closedInstance = InstanceCaps(
          domain: 'closed.social',
          platform: InstancePlatform.mastodon,
          openRegistration: false,
          maxMediaPerPost: 4,
          moderationStyle: ModerationStyle.balanced,
          loadScore: 20.0,
          activeUsers: 5000,
        );

        final score = closedInstance.calculateScore(
          preferredLanguages: [],
          focus: InstanceFocus.both,
          moderationPreference: ModerationStyle.balanced,
          preferOpenRegistration: true,
        );

        // Base score: 100
        // Closed registration penalty: -30
        // No open registration bonus: 0
        // Load score penalty: -20 * 0.3 = -6
        // Active user bonus (1000-50000): +10
        // Focus bonus for 'both': +10
        // Moderation match bonus: +15
        // Expected: 100 - 30 + 0 - 6 + 10 + 10 + 15 = 99
        expect(score, closeTo(99, 0.1));
      });

      test('should cap score at 150', () {
        const perfectInstance = InstanceCaps(
          domain: 'perfect.social',
          platform: InstancePlatform.mastodon,
          openRegistration: true,
          maxMediaPerPost: 4,
          languages: ['en', 'fr', 'de', 'es', 'it'], // Many language matches
          moderationStyle: ModerationStyle.balanced,
          loadScore: 0.0, // Perfect performance
          activeUsers: 5000, // Sweet spot for active users
          photoFocused: true,
        );

        final score = perfectInstance.calculateScore(
          preferredLanguages: ['en', 'fr', 'de', 'es', 'it'], // All matches
          focus: InstanceFocus.photos, // Perfect match
          moderationPreference: ModerationStyle.balanced, // Perfect match
          preferOpenRegistration: true,
        );

        expect(score, equals(150.0)); // Should be capped at 150
      });

      test('should not go below 0', () {
        const badInstance = InstanceCaps(
          domain: 'bad.social',
          platform: InstancePlatform.unknown,
          openRegistration: false,
          maxMediaPerPost: 4,
          languages: [],
          moderationStyle: ModerationStyle.freer,
          loadScore: 100.0, // Terrible performance
          activeUsers: 0, // No users
        );

        final score = badInstance.calculateScore(
          preferredLanguages: ['en'],
          focus: InstanceFocus.text,
          moderationPreference: ModerationStyle.stricter, // Mismatch
          preferOpenRegistration: true,
        );

        expect(score, greaterThanOrEqualTo(0.0)); // Should not go below 0
      });
    });
  });

  group('InstanceFocus enum', () {
    test('should have correct values', () {
      expect(InstanceFocus.values.length, equals(3));
      expect(InstanceFocus.values, contains(InstanceFocus.text));
      expect(InstanceFocus.values, contains(InstanceFocus.photos));
      expect(InstanceFocus.values, contains(InstanceFocus.both));
    });
  });

  group('InstancePlatform enum', () {
    test('should have correct JSON values', () {
      expect(InstancePlatform.values.length, equals(3));
      expect(InstancePlatform.values, contains(InstancePlatform.mastodon));
      expect(InstancePlatform.values, contains(InstancePlatform.pixelfed));
      expect(InstancePlatform.values, contains(InstancePlatform.unknown));
    });
  });

  group('ModerationStyle enum', () {
    test('should have correct JSON values', () {
      expect(ModerationStyle.values.length, equals(3));
      expect(ModerationStyle.values, contains(ModerationStyle.stricter));
      expect(ModerationStyle.values, contains(ModerationStyle.balanced));
      expect(ModerationStyle.values, contains(ModerationStyle.freer));
    });
  });
}
