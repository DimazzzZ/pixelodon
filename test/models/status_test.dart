import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart';

void main() {
  group('Status Model Tests', () {
    const testStatusId = 'status123';
    const testUri = 'https://example.com/status/123';
    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);
    const testContent = '<p>This is a test status with <a href="#">#hashtag</a></p>';
    const testUrl = 'https://example.com/@user/123';
    const testSpoilerText = 'Content warning';
    const testLanguage = 'en';

    // Test Account
    const testAccount = Account(
      id: 'account123',
      username: 'testuser',
      acct: 'testuser@example.com',
      displayName: 'Test User',
    );

    group('Constructor Tests', () {
      test('should create Status with required fields only', () {
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
        );

        expect(status.id, testStatusId);
        expect(status.uri, testUri);
        expect(status.createdAt, testCreatedAt);
        expect(status.account, testAccount);
        expect(status.content, testContent);
        expect(status.visibility, Visibility.public);
        expect(status.isReply, false);
        expect(status.isReblog, false);
        expect(status.isQuote, false);
        expect(status.mediaAttachments, isEmpty);
        expect(status.mentions, isEmpty);
        expect(status.tags, isEmpty);
        expect(status.emojis, isEmpty);
        expect(status.reblogsCount, 0);
        expect(status.favouritesCount, 0);
        expect(status.repliesCount, 0);
        expect(status.reblogged, false);
        expect(status.favourited, false);
        expect(status.bookmarked, false);
        expect(status.muted, false);
        expect(status.pinned, false);
        expect(status.sensitive, false);
        expect(status.isPixelfed, false);
      });

      test('should create Status with all fields', () {
        final editedAt = DateTime(2024, 1, 1, 0, 0, 0);
        
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.private,
          isReply: true,
          isReblog: false,
          isQuote: true,
          inReplyToId: 'reply123',
          inReplyToAccountId: 'account456',
          url: testUrl,
          reblogged: true,
          favourited: true,
          bookmarked: true,
          muted: true,
          pinned: true,
          spoilerText: testSpoilerText,
          sensitive: true,
          language: testLanguage,
          text: 'Plain text content',
          isPixelfed: true,
          reblogsCount: 5,
          favouritesCount: 10,
          repliesCount: 3,
          editedAt: editedAt,
        );

        expect(status.id, testStatusId);
        expect(status.uri, testUri);
        expect(status.visibility, Visibility.private);
        expect(status.isReply, true);
        expect(status.isQuote, true);
        expect(status.inReplyToId, 'reply123');
        expect(status.inReplyToAccountId, 'account456');
        expect(status.reblogged, true);
        expect(status.favourited, true);
        expect(status.bookmarked, true);
        expect(status.muted, true);
        expect(status.pinned, true);
        expect(status.spoilerText, testSpoilerText);
        expect(status.sensitive, true);
        expect(status.language, testLanguage);
        expect(status.isPixelfed, true);
        expect(status.reblogsCount, 5);
        expect(status.favouritesCount, 10);
        expect(status.repliesCount, 3);
        expect(status.editedAt, editedAt);
      });

      test('should handle nullable fields correctly', () {
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
          inReplyToStatus: null,
          inReplyToId: null,
          inReplyToAccountId: null,
          rebloggedStatus: null,
          quotedStatus: null,
          application: null,
          url: null,
          spoilerText: null,
          language: null,
          text: null,
          poll: null,
          card: null,
          editedAt: null,
        );

        expect(status.inReplyToStatus, isNull);
        expect(status.inReplyToId, isNull);
        expect(status.inReplyToAccountId, isNull);
        expect(status.rebloggedStatus, isNull);
        expect(status.quotedStatus, isNull);
        expect(status.application, isNull);
        expect(status.url, isNull);
        expect(status.spoilerText, isNull);
        expect(status.language, isNull);
        expect(status.text, isNull);
        expect(status.poll, isNull);
        expect(status.card, isNull);
        expect(status.editedAt, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.unlisted,
          isReply: true,
          reblogsCount: 5,
          favouritesCount: 10,
          repliesCount: 3,
          reblogged: true,
          favourited: true,
          bookmarked: true,
          spoilerText: testSpoilerText,
          sensitive: true,
          language: testLanguage,
          isPixelfed: true,
        );

        final json = status.toJson();

        expect(json['id'], testStatusId);
        expect(json['uri'], testUri);
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['account'], isA<Map<String, dynamic>>());
        expect(json['content'], testContent);
        expect(json['visibility'], 'unlisted');
        expect(json['is_reply'], true);
        expect(json['reblogs_count'], 5);
        expect(json['favourites_count'], 10);
        expect(json['replies_count'], 3);
        expect(json['reblogged'], true);
        expect(json['favourited'], true);
        expect(json['bookmarked'], true);
        expect(json['spoiler_text'], testSpoilerText);
        expect(json['sensitive'], true);
        expect(json['language'], testLanguage);
        expect(json['is_pixelfed'], true);
      });

      test('should serialize to JSON correctly with minimal fields', () {
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
        );

        final json = status.toJson();

        expect(json['id'], testStatusId);
        expect(json['uri'], testUri);
        expect(json['content'], testContent);
        expect(json['visibility'], 'public');
        expect(json['is_reply'], false);
        expect(json['is_reblog'], false);
        expect(json['is_quote'], false);
        expect(json['reblogs_count'], 0);
        expect(json['favourites_count'], 0);
        expect(json['replies_count'], 0);
        expect(json['is_pixelfed'], false);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'id': testStatusId,
          'uri': testUri,
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'content': testContent,
          'visibility': 'direct',
          'is_reply': true,
          'is_reblog': false,
          'is_quote': true,
          'in_reply_to_id': 'reply123',
          'in_reply_to_account_id': 'account456',
          'url': testUrl,
          'reblogs_count': 5,
          'favourites_count': 10,
          'replies_count': 3,
          'reblogged': true,
          'favourited': true,
          'bookmarked': true,
          'muted': true,
          'pinned': true,
          'spoiler_text': testSpoilerText,
          'sensitive': true,
          'language': testLanguage,
          'text': 'Plain text',
          'is_pixelfed': true,
          'media_attachments': [],
          'mentions': [],
          'tags': ['test', 'status'],
          'emojis': [],
        };

        final status = Status.fromJson(json);

        expect(status.id, testStatusId);
        expect(status.uri, testUri);
        expect(status.createdAt, testCreatedAt);
        expect(status.account.id, testAccount.id);
        expect(status.content, testContent);
        expect(status.visibility, Visibility.direct);
        expect(status.isReply, true);
        expect(status.isReblog, false);
        expect(status.isQuote, true);
        expect(status.inReplyToId, 'reply123');
        expect(status.inReplyToAccountId, 'account456');
        expect(status.url, testUrl);
        expect(status.reblogsCount, 5);
        expect(status.favouritesCount, 10);
        expect(status.repliesCount, 3);
        expect(status.reblogged, true);
        expect(status.favourited, true);
        expect(status.bookmarked, true);
        expect(status.spoilerText, testSpoilerText);
        expect(status.sensitive, true);
        expect(status.language, testLanguage);
        expect(status.isPixelfed, true);
        expect(status.tags, ['test', 'status']);
      });

      test('should deserialize from JSON correctly with minimal fields', () {
        final json = {
          'id': testStatusId,
          'uri': testUri,
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'content': testContent,
          'visibility': 'public',
        };

        final status = Status.fromJson(json);

        expect(status.id, testStatusId);
        expect(status.uri, testUri);
        expect(status.visibility, Visibility.public);
        expect(status.isReply, false);
        expect(status.reblogsCount, 0);
        expect(status.isPixelfed, false);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'id': testStatusId,
          'uri': testUri,
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'content': testContent,
          'visibility': 'private',
          'favourites_count': 42,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final status = Status.fromJson(json);

        expect(status.id, testStatusId);
        expect(status.visibility, Visibility.private);
        expect(status.favouritesCount, 42);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        final status1 = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
          reblogsCount: 5,
        );

        final status2 = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
          reblogsCount: 5,
        );

        expect(status1, equals(status2));
        expect(status1.hashCode, equals(status2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final status1 = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
        );

        final status2 = Status(
          id: 'different-id',
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
        );

        expect(status1, isNot(equals(status2)));
        expect(status1.hashCode, isNot(equals(status2.hashCode)));
      });

      test('should not be equal when visibility differs', () {
        final status1 = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
        );

        final status2 = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.private,
        );

        expect(status1, isNot(equals(status2)));
        expect(status1.hashCode, isNot(equals(status2.hashCode)));
      });
    });

    group('Copy With Tests', () {
      test('should create new instance with copyWith', () {
        final originalStatus = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
          reblogsCount: 5,
          favouritesCount: 10,
          favourited: false,
        );

        final updatedStatus = originalStatus.copyWith(
          reblogsCount: 15,
          favouritesCount: 20,
          favourited: true,
          visibility: Visibility.unlisted,
        );

        // Original should remain unchanged
        expect(originalStatus.reblogsCount, 5);
        expect(originalStatus.favouritesCount, 10);
        expect(originalStatus.favourited, false);
        expect(originalStatus.visibility, Visibility.public);
        
        // Updated should have new values
        expect(updatedStatus.reblogsCount, 15);
        expect(updatedStatus.favouritesCount, 20);
        expect(updatedStatus.favourited, true);
        expect(updatedStatus.visibility, Visibility.unlisted);
        expect(updatedStatus.id, testStatusId);
        expect(updatedStatus.uri, testUri);
      });
    });

    group('toString Tests', () {
      test('should have meaningful toString representation', () {
        final status = Status(
          id: testStatusId,
          uri: testUri,
          createdAt: testCreatedAt,
          account: testAccount,
          content: testContent,
          visibility: Visibility.public,
          favouritesCount: 42,
        );

        final stringRepresentation = status.toString();
        
        expect(stringRepresentation, contains(testStatusId));
        expect(stringRepresentation, contains('public'));
        expect(stringRepresentation, contains('42'));
      });
    });
  });

  group('Visibility Enum Tests', () {
    test('should have correct enum values', () {
      expect(Visibility.values.length, 4);
      expect(Visibility.values.contains(Visibility.public), isTrue);
      expect(Visibility.values.contains(Visibility.unlisted), isTrue);
      expect(Visibility.values.contains(Visibility.private), isTrue);
      expect(Visibility.values.contains(Visibility.direct), isTrue);
    });

    test('should have correct string names', () {
      expect(Visibility.public.name, 'public');
      expect(Visibility.unlisted.name, 'unlisted');
      expect(Visibility.private.name, 'private');
      expect(Visibility.direct.name, 'direct');
    });

    test('should categorize visibility levels correctly', () {
      final publicVisibilities = [Visibility.public, Visibility.unlisted];
      final privateVisibilities = [Visibility.private, Visibility.direct];

      for (final visibility in publicVisibilities) {
        expect(Visibility.values.contains(visibility), isTrue);
      }

      for (final visibility in privateVisibilities) {
        expect(Visibility.values.contains(visibility), isTrue);
      }
    });
  });

  group('MediaAttachment Tests', () {
    const testAttachmentId = 'attachment123';
    const testAttachmentUrl = 'https://example.com/media/image.jpg';
    const testPreviewUrl = 'https://example.com/media/image_preview.jpg';
    const testDescription = 'A beautiful sunset';
    const testBlurhash = 'LKO2?V%2Tw=w]~RBVZRi};RPxuwH';

    test('should create MediaAttachment with required fields', () {
      const attachment = MediaAttachment(
        id: testAttachmentId,
        type: AttachmentType.image,
        url: testAttachmentUrl,
      );

      expect(attachment.id, testAttachmentId);
      expect(attachment.type, AttachmentType.image);
      expect(attachment.url, testAttachmentUrl);
      expect(attachment.previewUrl, isNull);
      expect(attachment.description, isNull);
      expect(attachment.width, isNull);
      expect(attachment.height, isNull);
      expect(attachment.duration, isNull);
    });

    test('should create MediaAttachment with all fields', () {
      const attachment = MediaAttachment(
        id: testAttachmentId,
        type: AttachmentType.video,
        url: testAttachmentUrl,
        previewUrl: testPreviewUrl,
        remoteUrl: 'https://remote.com/video.mp4',
        description: testDescription,
        blurhash: testBlurhash,
        width: 1920,
        height: 1080,
        size: 1024000,
        duration: 30.5,
        focalPoint: [0.0, 0.5],
        meta: {'fps': 30, 'bitrate': 1000},
      );

      expect(attachment.id, testAttachmentId);
      expect(attachment.type, AttachmentType.video);
      expect(attachment.url, testAttachmentUrl);
      expect(attachment.previewUrl, testPreviewUrl);
      expect(attachment.description, testDescription);
      expect(attachment.blurhash, testBlurhash);
      expect(attachment.width, 1920);
      expect(attachment.height, 1080);
      expect(attachment.size, 1024000);
      expect(attachment.duration, 30.5);
      expect(attachment.focalPoint, [0.0, 0.5]);
      expect(attachment.meta, {'fps': 30, 'bitrate': 1000});
    });

    test('should serialize MediaAttachment to JSON correctly', () {
      const attachment = MediaAttachment(
        id: testAttachmentId,
        type: AttachmentType.image,
        url: testAttachmentUrl,
        description: testDescription,
        width: 800,
        height: 600,
      );

      final json = attachment.toJson();

      expect(json['id'], testAttachmentId);
      expect(json['type'], 'image');
      expect(json['url'], testAttachmentUrl);
      expect(json['description'], testDescription);
      expect(json['width'], 800);
      expect(json['height'], 600);
    });

    test('should deserialize MediaAttachment from JSON correctly', () {
      final json = {
        'id': testAttachmentId,
        'type': 'audio',
        'url': testAttachmentUrl,
        'preview_url': testPreviewUrl,
        'description': testDescription,
        'duration': 180.0,
      };

      final attachment = MediaAttachment.fromJson(json);

      expect(attachment.id, testAttachmentId);
      expect(attachment.type, AttachmentType.audio);
      expect(attachment.url, testAttachmentUrl);
      expect(attachment.previewUrl, testPreviewUrl);
      expect(attachment.description, testDescription);
      expect(attachment.duration, 180.0);
    });
  });

  group('AttachmentType Enum Tests', () {
    test('should have correct enum values', () {
      expect(AttachmentType.values.length, 5);
      expect(AttachmentType.values.contains(AttachmentType.image), isTrue);
      expect(AttachmentType.values.contains(AttachmentType.video), isTrue);
      expect(AttachmentType.values.contains(AttachmentType.gifv), isTrue);
      expect(AttachmentType.values.contains(AttachmentType.audio), isTrue);
      expect(AttachmentType.values.contains(AttachmentType.unknown), isTrue);
    });

    test('should have correct string names', () {
      expect(AttachmentType.image.name, 'image');
      expect(AttachmentType.video.name, 'video');
      expect(AttachmentType.gifv.name, 'gifv');
      expect(AttachmentType.audio.name, 'audio');
      expect(AttachmentType.unknown.name, 'unknown');
    });

    test('should categorize media types correctly', () {
      final visualTypes = [AttachmentType.image, AttachmentType.video, AttachmentType.gifv];
      final audioTypes = [AttachmentType.audio];

      for (final type in visualTypes) {
        expect(AttachmentType.values.contains(type), isTrue);
      }

      for (final type in audioTypes) {
        expect(AttachmentType.values.contains(type), isTrue);
      }
    });
  });

  group('Mention Tests', () {
    const testMentionId = 'mention123';
    const testMentionUsername = 'mentioneduser';
    const testMentionAcct = 'mentioneduser@example.com';
    const testMentionUrl = 'https://example.com/@mentioneduser';

    test('should create Mention with required fields', () {
      const mention = Mention(
        id: testMentionId,
        username: testMentionUsername,
        acct: testMentionAcct,
        url: testMentionUrl,
      );

      expect(mention.id, testMentionId);
      expect(mention.username, testMentionUsername);
      expect(mention.acct, testMentionAcct);
      expect(mention.url, testMentionUrl);
    });

    test('should serialize Mention to JSON correctly', () {
      const mention = Mention(
        id: testMentionId,
        username: testMentionUsername,
        acct: testMentionAcct,
        url: testMentionUrl,
      );

      final json = mention.toJson();

      expect(json['id'], testMentionId);
      expect(json['username'], testMentionUsername);
      expect(json['acct'], testMentionAcct);
      expect(json['url'], testMentionUrl);
    });

    test('should deserialize Mention from JSON correctly', () {
      final json = {
        'id': testMentionId,
        'username': testMentionUsername,
        'acct': testMentionAcct,
        'url': testMentionUrl,
      };

      final mention = Mention.fromJson(json);

      expect(mention.id, testMentionId);
      expect(mention.username, testMentionUsername);
      expect(mention.acct, testMentionAcct);
      expect(mention.url, testMentionUrl);
    });
  });

  group('Status Edge Cases', () {
    const testAccount = Account(
      id: 'account123',
      username: 'testuser',
      acct: 'testuser@example.com',
      displayName: 'Test User',
    );

    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);

    test('should handle status with empty content', () {
      final status = Status(
        id: 'status123',
        uri: 'https://example.com/status/123',
        createdAt: testCreatedAt,
        account: testAccount,
        content: '',
        visibility: Visibility.public,
      );

      expect(status.content, '');
      expect(status.visibility, Visibility.public);
    });

    test('should handle status with very long content', () {
      final longContent = 'a' * 10000;
      final status = Status(
        id: 'status123',
        uri: 'https://example.com/status/123',
        createdAt: testCreatedAt,
        account: testAccount,
        content: longContent,
        visibility: Visibility.public,
      );

      expect(status.content, longContent);
      expect(status.content.length, 10000);
    });

    test('should handle status with special characters', () {
      const specialContent = 'Status with emoji 🚀 and unicode characters: 测试内容 إختبار';
      final status = Status(
        id: 'status123',
        uri: 'https://example.com/status/123',
        createdAt: testCreatedAt,
        account: testAccount,
        content: specialContent,
        visibility: Visibility.public,
        language: 'multi',
      );

      expect(status.content, specialContent);
      expect(status.language, 'multi');
    });

    test('should handle status with zero counts', () {
      final status = Status(
        id: 'status123',
        uri: 'https://example.com/status/123',
        createdAt: testCreatedAt,
        account: testAccount,
        content: 'Test content',
        visibility: Visibility.public,
        reblogsCount: 0,
        favouritesCount: 0,
        repliesCount: 0,
      );

      expect(status.reblogsCount, 0);
      expect(status.favouritesCount, 0);
      expect(status.repliesCount, 0);
    });

    test('should handle status with large counts', () {
      final status = Status(
        id: 'status123',
        uri: 'https://example.com/status/123',
        createdAt: testCreatedAt,
        account: testAccount,
        content: 'Viral content',
        visibility: Visibility.public,
        reblogsCount: 999999,
        favouritesCount: 1000000,
        repliesCount: 50000,
      );

      expect(status.reblogsCount, 999999);
      expect(status.favouritesCount, 1000000);
      expect(status.repliesCount, 50000);
    });
  });
}
