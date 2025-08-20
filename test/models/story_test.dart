import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/story.dart';

void main() {
  group('Story Model Tests', () {
    const testStoryId = 'story123';
    const testUrl = 'https://pixelfed.de/story/media/123.jpg';
    const testPreviewUrl = 'https://pixelfed.de/story/preview/123.jpg';
    const testBlurhash = 'LKO2?V%2Tw=w]~RBVZRi};RPxuwH';
    const testText = 'Hello Story!';
    const testDomain = 'pixelfed.de';
    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);
    final testExpiresAt = DateTime(2024, 1, 1, 23, 59, 59);

    // Test Account
    const testAccount = Account(
      id: 'account123',
      username: 'storyuser',
      acct: 'storyuser@pixelfed.de',
      displayName: 'Story User',
    );

    group('Constructor Tests', () {
      test('should create Story with required fields only', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
        );

        expect(story.id, testStoryId);
        expect(story.account, testAccount);
        expect(story.createdAt, testCreatedAt);
        expect(story.expiresAt, testExpiresAt);
        expect(story.url, testUrl);
        expect(story.mediaType, StoryMediaType.image);
        expect(story.previewUrl, isNull);
        expect(story.blurhash, isNull);
        expect(story.width, isNull);
        expect(story.height, isNull);
        expect(story.duration, isNull);
        expect(story.text, isNull);
        expect(story.mentions, isEmpty);
        expect(story.hashtags, isEmpty);
        expect(story.locations, isEmpty);
        expect(story.reactions, isEmpty);
        expect(story.seen, false);
        expect(story.canReply, false);
        expect(story.canReact, false);
        expect(story.domain, isNull);
      });

      test('should create Story with all fields', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          previewUrl: testPreviewUrl,
          blurhash: testBlurhash,
          mediaType: StoryMediaType.video,
          width: 1080,
          height: 1920,
          duration: 15.5,
          text: testText,
          fontFamily: 'Arial',
          fontSize: 24,
          fontColor: '#FFFFFF',
          textBackgroundColor: '#000000',
          textAlignment: TextAlignment.center,
          textPosition: TextPosition.middle,
          mentions: [],
          hashtags: ['pixelfed', 'story'],
          locations: [],
          reactions: [],
          seen: true,
          canReply: true,
          canReact: true,
          domain: testDomain,
        );

        expect(story.id, testStoryId);
        expect(story.account, testAccount);
        expect(story.createdAt, testCreatedAt);
        expect(story.expiresAt, testExpiresAt);
        expect(story.url, testUrl);
        expect(story.previewUrl, testPreviewUrl);
        expect(story.blurhash, testBlurhash);
        expect(story.mediaType, StoryMediaType.video);
        expect(story.width, 1080);
        expect(story.height, 1920);
        expect(story.duration, 15.5);
        expect(story.text, testText);
        expect(story.fontFamily, 'Arial');
        expect(story.fontSize, 24);
        expect(story.fontColor, '#FFFFFF');
        expect(story.textBackgroundColor, '#000000');
        expect(story.textAlignment, TextAlignment.center);
        expect(story.textPosition, TextPosition.middle);
        expect(story.hashtags, ['pixelfed', 'story']);
        expect(story.seen, true);
        expect(story.canReply, true);
        expect(story.canReact, true);
        expect(story.domain, testDomain);
      });

      test('should handle nullable fields correctly', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
          previewUrl: null,
          blurhash: null,
          width: null,
          height: null,
          duration: null,
          text: null,
          fontFamily: null,
          fontSize: null,
          fontColor: null,
          textBackgroundColor: null,
          textAlignment: null,
          textPosition: null,
          domain: null,
        );

        expect(story.previewUrl, isNull);
        expect(story.blurhash, isNull);
        expect(story.width, isNull);
        expect(story.height, isNull);
        expect(story.duration, isNull);
        expect(story.text, isNull);
        expect(story.fontFamily, isNull);
        expect(story.fontSize, isNull);
        expect(story.fontColor, isNull);
        expect(story.textBackgroundColor, isNull);
        expect(story.textAlignment, isNull);
        expect(story.textPosition, isNull);
        expect(story.domain, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          previewUrl: testPreviewUrl,
          blurhash: testBlurhash,
          mediaType: StoryMediaType.video,
          width: 1080,
          height: 1920,
          duration: 30.0,
          text: testText,
          fontFamily: 'Arial',
          fontSize: 24,
          fontColor: '#FFFFFF',
          textAlignment: TextAlignment.center,
          textPosition: TextPosition.top,
          hashtags: ['test'],
          seen: true,
          canReply: true,
          canReact: true,
          domain: testDomain,
        );

        final json = story.toJson();

        expect(json['id'], testStoryId);
        expect(json['account'], isA<Map<String, dynamic>>());
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['expires_at'], testExpiresAt.toIso8601String());
        expect(json['url'], testUrl);
        expect(json['preview_url'], testPreviewUrl);
        expect(json['blurhash'], testBlurhash);
        expect(json['media_type'], 'video');
        expect(json['width'], 1080);
        expect(json['height'], 1920);
        expect(json['duration'], 30.0);
        expect(json['text'], testText);
        expect(json['font_family'], 'Arial');
        expect(json['font_size'], 24);
        expect(json['font_color'], '#FFFFFF');
        expect(json['text_alignment'], 'center');
        expect(json['text_position'], 'top');
        expect(json['hashtags'], ['test']);
        expect(json['seen'], true);
        expect(json['can_reply'], true);
        expect(json['can_react'], true);
        expect(json['domain'], testDomain);
      });

      test('should serialize to JSON correctly with minimal fields', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
        );

        final json = story.toJson();

        expect(json['id'], testStoryId);
        expect(json['url'], testUrl);
        expect(json['media_type'], 'image');
        expect(json['seen'], false);
        expect(json['can_reply'], false);
        expect(json['can_react'], false);
        expect(json['mentions'], isEmpty);
        expect(json['hashtags'], isEmpty);
        expect(json['locations'], isEmpty);
        expect(json['reactions'], isEmpty);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'id': testStoryId,
          'account': testAccount.toJson(),
          'created_at': testCreatedAt.toIso8601String(),
          'expires_at': testExpiresAt.toIso8601String(),
          'url': testUrl,
          'preview_url': testPreviewUrl,
          'blurhash': testBlurhash,
          'media_type': 'video',
          'width': 1080,
          'height': 1920,
          'duration': 25.0,
          'text': testText,
          'font_family': 'Helvetica',
          'font_size': 20,
          'font_color': '#FF0000',
          'text_background_color': '#000000',
          'text_alignment': 'right',
          'text_position': 'bottom',
          'mentions': [],
          'hashtags': ['story', 'test'],
          'locations': [],
          'reactions': [],
          'seen': true,
          'can_reply': false,
          'can_react': true,
          'domain': testDomain,
        };

        final story = Story.fromJson(json);

        expect(story.id, testStoryId);
        expect(story.account.id, testAccount.id);
        expect(story.createdAt, testCreatedAt);
        expect(story.expiresAt, testExpiresAt);
        expect(story.url, testUrl);
        expect(story.previewUrl, testPreviewUrl);
        expect(story.blurhash, testBlurhash);
        expect(story.mediaType, StoryMediaType.video);
        expect(story.width, 1080);
        expect(story.height, 1920);
        expect(story.duration, 25.0);
        expect(story.text, testText);
        expect(story.fontFamily, 'Helvetica');
        expect(story.fontSize, 20);
        expect(story.fontColor, '#FF0000');
        expect(story.textBackgroundColor, '#000000');
        expect(story.textAlignment, TextAlignment.right);
        expect(story.textPosition, TextPosition.bottom);
        expect(story.hashtags, ['story', 'test']);
        expect(story.seen, true);
        expect(story.canReply, false);
        expect(story.canReact, true);
        expect(story.domain, testDomain);
      });

      test('should deserialize from JSON correctly with minimal fields', () {
        final json = {
          'id': testStoryId,
          'account': testAccount.toJson(),
          'created_at': testCreatedAt.toIso8601String(),
          'expires_at': testExpiresAt.toIso8601String(),
          'url': testUrl,
          'media_type': 'image',
        };

        final story = Story.fromJson(json);

        expect(story.id, testStoryId);
        expect(story.account.id, testAccount.id);
        expect(story.mediaType, StoryMediaType.image);
        expect(story.seen, false);
        expect(story.canReply, false);
        expect(story.canReact, false);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'id': testStoryId,
          'account': testAccount.toJson(),
          'created_at': testCreatedAt.toIso8601String(),
          'expires_at': testExpiresAt.toIso8601String(),
          'url': testUrl,
          'media_type': 'video',
          'seen': true,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final story = Story.fromJson(json);

        expect(story.id, testStoryId);
        expect(story.mediaType, StoryMediaType.video);
        expect(story.seen, true);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        final story1 = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
          seen: true,
        );

        final story2 = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
          seen: true,
        );

        expect(story1, equals(story2));
        expect(story1.hashCode, equals(story2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final story1 = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
        );

        final story2 = Story(
          id: 'different-id',
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
        );

        expect(story1, isNot(equals(story2)));
        expect(story1.hashCode, isNot(equals(story2.hashCode)));
      });
    });

    group('Copy With Tests', () {
      test('should create new instance with copyWith', () {
        final originalStory = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.image,
          seen: false,
          canReply: false,
        );

        final updatedStory = originalStory.copyWith(
          seen: true,
          canReply: true,
          mediaType: StoryMediaType.video,
        );

        // Original should remain unchanged
        expect(originalStory.seen, false);
        expect(originalStory.canReply, false);
        expect(originalStory.mediaType, StoryMediaType.image);
        
        // Updated should have new values
        expect(updatedStory.seen, true);
        expect(updatedStory.canReply, true);
        expect(updatedStory.mediaType, StoryMediaType.video);
        expect(updatedStory.id, testStoryId);
        expect(updatedStory.url, testUrl);
      });
    });

    group('toString Tests', () {
      test('should have meaningful toString representation', () {
        final story = Story(
          id: testStoryId,
          account: testAccount,
          createdAt: testCreatedAt,
          expiresAt: testExpiresAt,
          url: testUrl,
          mediaType: StoryMediaType.video,
          seen: true,
        );

        final stringRepresentation = story.toString();
        
        expect(stringRepresentation, contains(testStoryId));
        expect(stringRepresentation, contains('video'));
        expect(stringRepresentation, contains('true'));
      });
    });
  });

  group('StoryMediaType Enum Tests', () {
    test('should have correct enum values', () {
      expect(StoryMediaType.values.length, 3);
      expect(StoryMediaType.values.contains(StoryMediaType.image), isTrue);
      expect(StoryMediaType.values.contains(StoryMediaType.video), isTrue);
      expect(StoryMediaType.values.contains(StoryMediaType.unknown), isTrue);
    });

    test('should have correct string names', () {
      expect(StoryMediaType.image.name, 'image');
      expect(StoryMediaType.video.name, 'video');
      expect(StoryMediaType.unknown.name, 'unknown');
    });
  });

  group('TextAlignment Enum Tests', () {
    test('should have correct enum values', () {
      expect(TextAlignment.values.length, 3);
      expect(TextAlignment.values.contains(TextAlignment.left), isTrue);
      expect(TextAlignment.values.contains(TextAlignment.center), isTrue);
      expect(TextAlignment.values.contains(TextAlignment.right), isTrue);
    });

    test('should have correct string names', () {
      expect(TextAlignment.left.name, 'left');
      expect(TextAlignment.center.name, 'center');
      expect(TextAlignment.right.name, 'right');
    });
  });

  group('TextPosition Enum Tests', () {
    test('should have correct enum values', () {
      expect(TextPosition.values.length, 3);
      expect(TextPosition.values.contains(TextPosition.top), isTrue);
      expect(TextPosition.values.contains(TextPosition.middle), isTrue);
      expect(TextPosition.values.contains(TextPosition.bottom), isTrue);
    });

    test('should have correct string names', () {
      expect(TextPosition.top.name, 'top');
      expect(TextPosition.middle.name, 'middle');
      expect(TextPosition.bottom.name, 'bottom');
    });
  });

  group('StoryMention Tests', () {
    const testMentionId = 'mention123';
    const testMentionUsername = 'mentionuser';
    const testMentionDisplayName = 'Mention User';
    const testAvatarUrl = 'https://example.com/avatar.jpg';

    test('should create StoryMention with required fields', () {
      const mention = StoryMention(
        id: testMentionId,
        username: testMentionUsername,
        displayName: testMentionDisplayName,
      );

      expect(mention.id, testMentionId);
      expect(mention.username, testMentionUsername);
      expect(mention.displayName, testMentionDisplayName);
      expect(mention.avatarUrl, isNull);
      expect(mention.x, 50);
      expect(mention.y, 50);
      expect(mention.width, 20);
      expect(mention.height, 20);
    });

    test('should create StoryMention with all fields', () {
      const mention = StoryMention(
        id: testMentionId,
        username: testMentionUsername,
        displayName: testMentionDisplayName,
        avatarUrl: testAvatarUrl,
        x: 25.5,
        y: 75.0,
        width: 30.0,
        height: 25.0,
      );

      expect(mention.id, testMentionId);
      expect(mention.username, testMentionUsername);
      expect(mention.displayName, testMentionDisplayName);
      expect(mention.avatarUrl, testAvatarUrl);
      expect(mention.x, 25.5);
      expect(mention.y, 75.0);
      expect(mention.width, 30.0);
      expect(mention.height, 25.0);
    });

    test('should serialize StoryMention to JSON correctly', () {
      const mention = StoryMention(
        id: testMentionId,
        username: testMentionUsername,
        displayName: testMentionDisplayName,
        avatarUrl: testAvatarUrl,
        x: 10.0,
        y: 90.0,
      );

      final json = mention.toJson();

      expect(json['id'], testMentionId);
      expect(json['username'], testMentionUsername);
      expect(json['display_name'], testMentionDisplayName);
      expect(json['avatar_url'], testAvatarUrl);
      expect(json['x'], 10.0);
      expect(json['y'], 90.0);
      expect(json['width'], 20);
      expect(json['height'], 20);
    });

    test('should deserialize StoryMention from JSON correctly', () {
      final json = {
        'id': testMentionId,
        'username': testMentionUsername,
        'display_name': testMentionDisplayName,
        'avatar_url': testAvatarUrl,
        'x': 15.5,
        'y': 85.5,
        'width': 25.0,
        'height': 30.0,
      };

      final mention = StoryMention.fromJson(json);

      expect(mention.id, testMentionId);
      expect(mention.username, testMentionUsername);
      expect(mention.displayName, testMentionDisplayName);
      expect(mention.avatarUrl, testAvatarUrl);
      expect(mention.x, 15.5);
      expect(mention.y, 85.5);
      expect(mention.width, 25.0);
      expect(mention.height, 30.0);
    });
  });

  group('StoryLocation Tests', () {
    const testLocationId = 'location123';
    const testLocationName = 'Central Park';
    const testLocationAddress = 'New York, NY, USA';

    test('should create StoryLocation with required fields', () {
      const location = StoryLocation(
        id: testLocationId,
        name: testLocationName,
      );

      expect(location.id, testLocationId);
      expect(location.name, testLocationName);
      expect(location.address, isNull);
      expect(location.latitude, isNull);
      expect(location.longitude, isNull);
      expect(location.x, 50);
      expect(location.y, 50);
      expect(location.width, 20);
      expect(location.height, 20);
    });

    test('should create StoryLocation with all fields', () {
      const location = StoryLocation(
        id: testLocationId,
        name: testLocationName,
        address: testLocationAddress,
        latitude: 40.785091,
        longitude: -73.968285,
        x: 30.0,
        y: 70.0,
        width: 40.0,
        height: 35.0,
      );

      expect(location.id, testLocationId);
      expect(location.name, testLocationName);
      expect(location.address, testLocationAddress);
      expect(location.latitude, 40.785091);
      expect(location.longitude, -73.968285);
      expect(location.x, 30.0);
      expect(location.y, 70.0);
      expect(location.width, 40.0);
      expect(location.height, 35.0);
    });

    test('should serialize StoryLocation to JSON correctly', () {
      const location = StoryLocation(
        id: testLocationId,
        name: testLocationName,
        address: testLocationAddress,
        latitude: 40.785091,
        longitude: -73.968285,
      );

      final json = location.toJson();

      expect(json['id'], testLocationId);
      expect(json['name'], testLocationName);
      expect(json['address'], testLocationAddress);
      expect(json['latitude'], 40.785091);
      expect(json['longitude'], -73.968285);
      expect(json['x'], 50);
      expect(json['y'], 50);
      expect(json['width'], 20);
      expect(json['height'], 20);
    });

    test('should deserialize StoryLocation from JSON correctly', () {
      final json = {
        'id': testLocationId,
        'name': testLocationName,
        'address': testLocationAddress,
        'latitude': 40.785091,
        'longitude': -73.968285,
        'x': 20.0,
        'y': 80.0,
        'width': 35.0,
        'height': 25.0,
      };

      final location = StoryLocation.fromJson(json);

      expect(location.id, testLocationId);
      expect(location.name, testLocationName);
      expect(location.address, testLocationAddress);
      expect(location.latitude, 40.785091);
      expect(location.longitude, -73.968285);
      expect(location.x, 20.0);
      expect(location.y, 80.0);
      expect(location.width, 35.0);
      expect(location.height, 25.0);
    });
  });

  group('StoryReaction Tests', () {
    const testReactionId = 'reaction123';
    const testEmoji = '❤️';
    final testReactionCreatedAt = DateTime(2023, 12, 25, 12, 0, 0);

    // Test Account for reaction
    const testReactionAccount = Account(
      id: 'reaction_account123',
      username: 'reactionuser',
      acct: 'reactionuser@pixelfed.de',
      displayName: 'Reaction User',
    );

    test('should create StoryReaction with all required fields', () {
      final reaction = StoryReaction(
        id: testReactionId,
        account: testReactionAccount,
        emoji: testEmoji,
        createdAt: testReactionCreatedAt,
      );

      expect(reaction.id, testReactionId);
      expect(reaction.account, testReactionAccount);
      expect(reaction.emoji, testEmoji);
      expect(reaction.createdAt, testReactionCreatedAt);
    });

    test('should serialize StoryReaction to JSON correctly', () {
      final reaction = StoryReaction(
        id: testReactionId,
        account: testReactionAccount,
        emoji: testEmoji,
        createdAt: testReactionCreatedAt,
      );

      final json = reaction.toJson();

      expect(json['id'], testReactionId);
      expect(json['account'], isA<Map<String, dynamic>>());
      expect(json['emoji'], testEmoji);
      expect(json['created_at'], testReactionCreatedAt.toIso8601String());
    });

    test('should deserialize StoryReaction from JSON correctly', () {
      final json = {
        'id': testReactionId,
        'account': testReactionAccount.toJson(),
        'emoji': testEmoji,
        'created_at': testReactionCreatedAt.toIso8601String(),
      };

      final reaction = StoryReaction.fromJson(json);

      expect(reaction.id, testReactionId);
      expect(reaction.account.id, testReactionAccount.id);
      expect(reaction.emoji, testEmoji);
      expect(reaction.createdAt, testReactionCreatedAt);
    });
  });

  group('Story Edge Cases', () {
    const testAccount = Account(
      id: 'account123',
      username: 'testuser',
      acct: 'testuser@pixelfed.de',
      displayName: 'Test User',
    );

    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);
    final testExpiresAt = DateTime(2024, 1, 1, 23, 59, 59);

    test('should handle story with empty text', () {
      final story = Story(
        id: 'story123',
        account: testAccount,
        createdAt: testCreatedAt,
        expiresAt: testExpiresAt,
        url: 'https://example.com/story.jpg',
        mediaType: StoryMediaType.image,
        text: '',
      );

      expect(story.text, '');
      expect(story.mediaType, StoryMediaType.image);
    });

    test('should handle story with very long text', () {
      final longText = 'a' * 1000;
      final story = Story(
        id: 'story123',
        account: testAccount,
        createdAt: testCreatedAt,
        expiresAt: testExpiresAt,
        url: 'https://example.com/story.jpg',
        mediaType: StoryMediaType.image,
        text: longText,
      );

      expect(story.text, longText);
      expect(story.text?.length, 1000);
    });

    test('should handle story with special characters in text', () {
      const specialText = 'Story with emoji 🚀 and unicode: 测试内容 إختبار';
      final story = Story(
        id: 'story123',
        account: testAccount,
        createdAt: testCreatedAt,
        expiresAt: testExpiresAt,
        url: 'https://example.com/story.jpg',
        mediaType: StoryMediaType.image,
        text: specialText,
      );

      expect(story.text, specialText);
    });

    test('should handle story with extreme positioning values', () {
      const mention = StoryMention(
        id: 'mention123',
        username: 'user',
        displayName: 'User',
        x: 0.0,
        y: 100.0,
        width: 100.0,
        height: 0.0,
      );

      expect(mention.x, 0.0);
      expect(mention.y, 100.0);
      expect(mention.width, 100.0);
      expect(mention.height, 0.0);
    });

    test('should handle story with negative coordinates (edge case)', () {
      const location = StoryLocation(
        id: 'location123',
        name: 'Antarctica Research Station',
        latitude: -90.0,
        longitude: -180.0,
      );

      expect(location.latitude, -90.0);
      expect(location.longitude, -180.0);
    });

    test('should handle story with expired timestamp', () {
      final pastDate = DateTime(2020, 1, 1);
      final story = Story(
        id: 'story123',
        account: testAccount,
        createdAt: pastDate,
        expiresAt: pastDate.add(const Duration(hours: 24)),
        url: 'https://example.com/story.jpg',
        mediaType: StoryMediaType.image,
      );

      expect(story.createdAt, pastDate);
      expect(story.expiresAt.isAfter(story.createdAt), true);
      expect(story.expiresAt.isBefore(DateTime.now()), true);
    });

    test('should handle story with many hashtags', () {
      final manyHashtags = List.generate(50, (index) => 'hashtag$index');
      final story = Story(
        id: 'story123',
        account: testAccount,
        createdAt: testCreatedAt,
        expiresAt: testExpiresAt,
        url: 'https://example.com/story.jpg',
        mediaType: StoryMediaType.image,
        hashtags: manyHashtags,
      );

      expect(story.hashtags.length, 50);
      expect(story.hashtags.first, 'hashtag0');
      expect(story.hashtags.last, 'hashtag49');
    });
  });
}
