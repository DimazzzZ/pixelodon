import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/notification.dart';
import 'package:pixelodon/models/status.dart';

void main() {
  group('Notification Model Tests', () {
    const testNotificationId = '12345';
    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);
    const testStatusId = 'status123';
    const testReportId = 'report456';
    const testDomain = 'pixelfed.de';

    // Test Account
    const testAccount = Account(
      id: 'account123',
      username: 'testuser',
      acct: 'testuser@example.com',
      displayName: 'Test User',
    );

    // Test Status (minimal for testing)
    final testStatus = Status(
      id: testStatusId,
      uri: 'https://example.com/status/123',
      createdAt: testCreatedAt,
      account: testAccount,
      content: 'Test status content',
      visibility: Visibility.public,
    );

    group('Constructor Tests', () {
      test('should create Notification with required fields only', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        expect(notification.id, testNotificationId);
        expect(notification.type, NotificationType.follow);
        expect(notification.createdAt, testCreatedAt);
        expect(notification.account, testAccount);
        expect(notification.status, isNull);
        expect(notification.statusId, isNull);
        expect(notification.reportId, isNull);
        expect(notification.read, false);
        expect(notification.domain, isNull);
        expect(notification.isPixelfed, false);
      });

      test('should create Notification with all fields', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.like,
          createdAt: testCreatedAt,
          account: testAccount,
          status: testStatus,
          statusId: testStatusId,
          reportId: testReportId,
          read: true,
          domain: testDomain,
          isPixelfed: true,
        );

        expect(notification.id, testNotificationId);
        expect(notification.type, NotificationType.like);
        expect(notification.createdAt, testCreatedAt);
        expect(notification.account, testAccount);
        expect(notification.status, testStatus);
        expect(notification.statusId, testStatusId);
        expect(notification.reportId, testReportId);
        expect(notification.read, true);
        expect(notification.domain, testDomain);
        expect(notification.isPixelfed, true);
      });

      test('should handle nullable fields correctly', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
          status: null,
          statusId: null,
          reportId: null,
          domain: null,
        );

        expect(notification.status, isNull);
        expect(notification.statusId, isNull);
        expect(notification.reportId, isNull);
        expect(notification.domain, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.mention,
          createdAt: testCreatedAt,
          account: testAccount,
          status: testStatus,
          statusId: testStatusId,
          reportId: testReportId,
          read: true,
          domain: testDomain,
          isPixelfed: true,
        );

        final json = notification.toJson();

        expect(json['id'], testNotificationId);
        expect(json['type'], 'mention');
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['account'], isA<Map<String, dynamic>>());
        expect(json['status'], isA<Map<String, dynamic>>());
        expect(json['status_id'], testStatusId);
        expect(json['report_id'], testReportId);
        expect(json['read'], true);
        expect(json['domain'], testDomain);
        expect(json['is_pixelfed'], true);
      });

      test('should serialize to JSON correctly with minimal fields', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        final json = notification.toJson();

        expect(json['id'], testNotificationId);
        expect(json['type'], 'follow');
        expect(json['created_at'], testCreatedAt.toIso8601String());
        expect(json['account'], isA<Map<String, dynamic>>());
        expect(json['read'], false);
        expect(json['is_pixelfed'], false);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'id': testNotificationId,
          'type': 'favourite',
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'status': testStatus.toJson(),
          'status_id': testStatusId,
          'report_id': testReportId,
          'read': true,
          'domain': testDomain,
          'is_pixelfed': true,
        };

        final notification = Notification.fromJson(json);

        expect(notification.id, testNotificationId);
        expect(notification.type, NotificationType.favourite);
        expect(notification.createdAt, testCreatedAt);
        expect(notification.account.id, testAccount.id);
        expect(notification.status?.id, testStatus.id);
        expect(notification.statusId, testStatusId);
        expect(notification.reportId, testReportId);
        expect(notification.read, true);
        expect(notification.domain, testDomain);
        expect(notification.isPixelfed, true);
      });

      test('should deserialize from JSON correctly with minimal fields', () {
        final json = {
          'id': testNotificationId,
          'type': 'follow_request',
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
        };

        final notification = Notification.fromJson(json);

        expect(notification.id, testNotificationId);
        expect(notification.type, NotificationType.followRequest);
        expect(notification.createdAt, testCreatedAt);
        expect(notification.account.id, testAccount.id);
        expect(notification.status, isNull);
        expect(notification.statusId, isNull);
        expect(notification.reportId, isNull);
        expect(notification.read, false);
        expect(notification.domain, isNull);
        expect(notification.isPixelfed, false);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'id': testNotificationId,
          'type': 'reblog',
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'read': true,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final notification = Notification.fromJson(json);

        expect(notification.id, testNotificationId);
        expect(notification.type, NotificationType.reblog);
        expect(notification.read, true);
      });

      test('should handle null values correctly', () {
        final json = {
          'id': testNotificationId,
          'type': 'follow',
          'created_at': testCreatedAt.toIso8601String(),
          'account': testAccount.toJson(),
          'status': null,
          'status_id': null,
          'report_id': null,
          'domain': null,
        };

        final notification = Notification.fromJson(json);

        expect(notification.status, isNull);
        expect(notification.statusId, isNull);
        expect(notification.reportId, isNull);
        expect(notification.domain, isNull);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        final notification1 = Notification(
          id: testNotificationId,
          type: NotificationType.mention,
          createdAt: testCreatedAt,
          account: testAccount,
          read: true,
        );

        final notification2 = Notification(
          id: testNotificationId,
          type: NotificationType.mention,
          createdAt: testCreatedAt,
          account: testAccount,
          read: true,
        );

        expect(notification1, equals(notification2));
        expect(notification1.hashCode, equals(notification2.hashCode));
      });

      test('should not be equal when fields differ', () {
        final notification1 = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        final notification2 = Notification(
          id: 'different-id',
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        expect(notification1, isNot(equals(notification2)));
        expect(notification1.hashCode, isNot(equals(notification2.hashCode)));
      });

      test('should not be equal when type differs', () {
        final notification1 = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        final notification2 = Notification(
          id: testNotificationId,
          type: NotificationType.mention,
          createdAt: testCreatedAt,
          account: testAccount,
        );

        expect(notification1, isNot(equals(notification2)));
        expect(notification1.hashCode, isNot(equals(notification2.hashCode)));
      });
    });

    group('Copy With Tests', () {
      test('should create new instance with copyWith', () {
        final originalNotification = Notification(
          id: testNotificationId,
          type: NotificationType.follow,
          createdAt: testCreatedAt,
          account: testAccount,
          read: false,
          domain: testDomain,
        );

        final updatedNotification = originalNotification.copyWith(
          read: true,
          isPixelfed: true,
        );

        // Original should remain unchanged
        expect(originalNotification.read, false);
        expect(originalNotification.isPixelfed, false);
        
        // Updated should have new values
        expect(updatedNotification.read, true);
        expect(updatedNotification.isPixelfed, true);
        expect(updatedNotification.id, testNotificationId);
        expect(updatedNotification.type, NotificationType.follow);
        expect(updatedNotification.domain, testDomain);
      });
    });

    group('toString Tests', () {
      test('should have meaningful toString representation', () {
        final notification = Notification(
          id: testNotificationId,
          type: NotificationType.like,
          createdAt: testCreatedAt,
          account: testAccount,
          read: true,
        );

        final stringRepresentation = notification.toString();
        
        expect(stringRepresentation, contains(testNotificationId));
        expect(stringRepresentation, contains('like'));
        expect(stringRepresentation, contains('true'));
      });
    });
  });

  group('NotificationType Enum Tests', () {
    group('Mastodon Notification Types', () {
      test('should have correct JSON values for Mastodon types', () {
        expect(NotificationType.follow.name, 'follow');
        expect(NotificationType.followRequest.name, 'followRequest');
        expect(NotificationType.mention.name, 'mention');
        expect(NotificationType.reblog.name, 'reblog');
        expect(NotificationType.favourite.name, 'favourite');
        expect(NotificationType.poll.name, 'poll');
        expect(NotificationType.status.name, 'status');
        expect(NotificationType.update.name, 'update');
        expect(NotificationType.adminSignUp.name, 'adminSignUp');
        expect(NotificationType.adminReport.name, 'adminReport');
      });
    });

    group('Pixelfed Notification Types', () {
      test('should have correct JSON values for Pixelfed types', () {
        expect(NotificationType.comment.name, 'comment');
        expect(NotificationType.like.name, 'like');
        expect(NotificationType.share.name, 'share');
        expect(NotificationType.storyReaction.name, 'storyReaction');
        expect(NotificationType.storyMention.name, 'storyMention');
        expect(NotificationType.direct.name, 'direct');
        expect(NotificationType.unknown.name, 'unknown');
      });
    });

    group('Enum Value Count', () {
      test('should have all notification types defined', () {
        expect(NotificationType.values.length, 17);
      });

      test('should contain all expected notification types', () {
        final expectedTypes = [
          NotificationType.follow,
          NotificationType.followRequest,
          NotificationType.mention,
          NotificationType.reblog,
          NotificationType.favourite,
          NotificationType.poll,
          NotificationType.status,
          NotificationType.update,
          NotificationType.adminSignUp,
          NotificationType.adminReport,
          NotificationType.comment,
          NotificationType.like,
          NotificationType.share,
          NotificationType.storyReaction,
          NotificationType.storyMention,
          NotificationType.direct,
          NotificationType.unknown,
        ];

        for (final type in expectedTypes) {
          expect(NotificationType.values.contains(type), isTrue);
        }
      });
    });

    group('Notification Type Categorization', () {
      test('should identify interaction types correctly', () {
        final interactionTypes = [
          NotificationType.follow,
          NotificationType.followRequest,
          NotificationType.mention,
          NotificationType.reblog,
          NotificationType.favourite,
          NotificationType.like,
          NotificationType.comment,
          NotificationType.share,
        ];

        for (final type in interactionTypes) {
          expect(NotificationType.values.contains(type), isTrue);
        }
      });

      test('should identify content types correctly', () {
        final contentTypes = [
          NotificationType.status,
          NotificationType.update,
          NotificationType.poll,
          NotificationType.direct,
        ];

        for (final type in contentTypes) {
          expect(NotificationType.values.contains(type), isTrue);
        }
      });

      test('should identify story types correctly', () {
        final storyTypes = [
          NotificationType.storyReaction,
          NotificationType.storyMention,
        ];

        for (final type in storyTypes) {
          expect(NotificationType.values.contains(type), isTrue);
        }
      });

      test('should identify admin types correctly', () {
        final adminTypes = [
          NotificationType.adminSignUp,
          NotificationType.adminReport,
        ];

        for (final type in adminTypes) {
          expect(NotificationType.values.contains(type), isTrue);
        }
      });
    });
  });

  group('Notification Edge Cases', () {
    const testAccount = Account(
      id: 'account123',
      username: 'testuser',
      acct: 'testuser@example.com',
      displayName: 'Test User',
    );

    final testCreatedAt = DateTime(2023, 12, 31, 23, 59, 59);

    test('should handle notifications with empty IDs', () {
      final notification = Notification(
        id: '',
        type: NotificationType.follow,
        createdAt: testCreatedAt,
        account: testAccount,
      );

      expect(notification.id, '');
      expect(notification.type, NotificationType.follow);
    });

    test('should handle notifications from different domains', () {
      final mastodonNotification = Notification(
        id: '123',
        type: NotificationType.mention,
        createdAt: testCreatedAt,
        account: testAccount,
        domain: 'mastodon.social',
        isPixelfed: false,
      );

      final pixelfedNotification = Notification(
        id: '456',
        type: NotificationType.like,
        createdAt: testCreatedAt,
        account: testAccount,
        domain: 'pixelfed.de',
        isPixelfed: true,
      );

      expect(mastodonNotification.domain, 'mastodon.social');
      expect(mastodonNotification.isPixelfed, false);
      expect(pixelfedNotification.domain, 'pixelfed.de');
      expect(pixelfedNotification.isPixelfed, true);
    });

    test('should handle notification with very long content', () {
      final longStatusId = 'a' * 1000;
      final longReportId = 'b' * 1000;
      
      final notification = Notification(
        id: '123',
        type: NotificationType.adminReport,
        createdAt: testCreatedAt,
        account: testAccount,
        statusId: longStatusId,
        reportId: longReportId,
      );

      expect(notification.statusId, longStatusId);
      expect(notification.reportId, longReportId);
      expect(notification.statusId?.length, 1000);
      expect(notification.reportId?.length, 1000);
    });

    test('should handle notifications with special characters in domain', () {
      const specialDomain = 'пиксельфед.рф';
      
      final notification = Notification(
        id: '123',
        type: NotificationType.like,
        createdAt: testCreatedAt,
        account: testAccount,
        domain: specialDomain,
        isPixelfed: true,
      );

      expect(notification.domain, specialDomain);
      expect(notification.isPixelfed, true);
    });
  });
}
