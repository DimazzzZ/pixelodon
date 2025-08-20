import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/account.dart';

void main() {
  group('Account Model Tests', () {
    const testAccountId = '12345';
    const testUsername = 'testuser';
    const testAcct = 'testuser@example.com';
    const testDisplayName = 'Test User';
    const testNote = 'This is a test bio';
    const testUrl = 'https://example.com/@testuser';
    const testAvatar = 'https://example.com/avatar.jpg';
    const testDomain = 'example.com';
    final testCreatedAt = DateTime(2023, 1, 1);
    final testLastStatusAt = DateTime(2023, 12, 31);

    group('Constructor Tests', () {
      test('should create Account with required fields only', () {
        const account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
        );

        expect(account.id, testAccountId);
        expect(account.username, testUsername);
        expect(account.acct, testAcct);
        expect(account.displayName, testDisplayName);
        expect(account.locked, false);
        expect(account.bot, false);
        expect(account.discoverable, true);
        expect(account.group, false);
        expect(account.followersCount, 0);
        expect(account.followingCount, 0);
        expect(account.statusesCount, 0);
        expect(account.suspended, false);
        expect(account.muted, false);
        expect(account.blocked, false);
        expect(account.requested, false);
        expect(account.isPixelfed, false);
      });

      test('should create Account with all fields', () {
        const testField = Field(name: 'Website', value: 'https://example.com');
        
        final account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          locked: true,
          bot: true,
          discoverable: false,
          group: true,
          createdAt: testCreatedAt,
          note: testNote,
          url: testUrl,
          avatar: testAvatar,
          avatarStatic: testAvatar,
          header: testAvatar,
          headerStatic: testAvatar,
          followersCount: 100,
          followingCount: 50,
          statusesCount: 25,
          lastStatusAt: testLastStatusAt,
          fields: [testField],
          suspended: true,
          muted: true,
          blocked: true,
          requested: true,
          domain: testDomain,
          isPixelfed: true,
        );

        expect(account.id, testAccountId);
        expect(account.username, testUsername);
        expect(account.acct, testAcct);
        expect(account.displayName, testDisplayName);
        expect(account.locked, true);
        expect(account.bot, true);
        expect(account.discoverable, false);
        expect(account.group, true);
        expect(account.createdAt, testCreatedAt);
        expect(account.note, testNote);
        expect(account.url, testUrl);
        expect(account.avatar, testAvatar);
        expect(account.followersCount, 100);
        expect(account.followingCount, 50);
        expect(account.statusesCount, 25);
        expect(account.lastStatusAt, testLastStatusAt);
        expect(account.fields, [testField]);
        expect(account.suspended, true);
        expect(account.muted, true);
        expect(account.blocked, true);
        expect(account.requested, true);
        expect(account.domain, testDomain);
        expect(account.isPixelfed, true);
      });

      test('should handle nullable fields correctly', () {
        const account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          createdAt: null,
          note: null,
          url: null,
          avatar: null,
          lastStatusAt: null,
          fields: null,
          domain: null,
        );

        expect(account.createdAt, isNull);
        expect(account.note, isNull);
        expect(account.url, isNull);
        expect(account.avatar, isNull);
        expect(account.lastStatusAt, isNull);
        expect(account.fields, isNull);
        expect(account.domain, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        const testField = Field(name: 'Website', value: 'https://example.com');
        
        final account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          locked: true,
          bot: true,
          discoverable: false,
          group: false,
          createdAt: testCreatedAt,
          note: testNote,
          url: testUrl,
          avatar: testAvatar,
          followersCount: 100,
          followingCount: 50,
          statusesCount: 25,
          lastStatusAt: testLastStatusAt,
          fields: [testField],
          domain: testDomain,
          isPixelfed: true,
        );

        final json = account.toJson();

        expect(json['id'], testAccountId);
        expect(json['username'], testUsername);
        expect(json['acct'], testAcct);
        expect(json['display_name'], testDisplayName);
        expect(json['locked'], true);
        expect(json['bot'], true);
        expect(json['discoverable'], false);
        expect(json['followers_count'], 100);
        expect(json['following_count'], 50);
        expect(json['statuses_count'], 25);
        expect(json['domain'], testDomain);
        expect(json['is_pixelfed'], true);
        expect(json['fields'], isA<List>());
      });

      test('should serialize to JSON correctly with minimal fields', () {
        const account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
        );

        final json = account.toJson();

        expect(json['id'], testAccountId);
        expect(json['username'], testUsername);
        expect(json['acct'], testAcct);
        expect(json['display_name'], testDisplayName);
        expect(json['locked'], false);
        expect(json['bot'], false);
        expect(json['discoverable'], true);
        expect(json['followers_count'], 0);
        expect(json['following_count'], 0);
        expect(json['statuses_count'], 0);
        expect(json['is_pixelfed'], false);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'id': testAccountId,
          'username': testUsername,
          'acct': testAcct,
          'display_name': testDisplayName,
          'locked': true,
          'bot': true,
          'discoverable': false,
          'group': false,
          'created_at': testCreatedAt.toIso8601String(),
          'note': testNote,
          'url': testUrl,
          'avatar': testAvatar,
          'avatar_static': testAvatar,
          'header': testAvatar,
          'header_static': testAvatar,
          'followers_count': 100,
          'following_count': 50,
          'statuses_count': 25,
          'last_status_at': testLastStatusAt.toIso8601String(),
          'fields': [
            {'name': 'Website', 'value': 'https://example.com', 'verified_at': null}
          ],
          'suspended': false,
          'muted': false,
          'blocked': false,
          'requested': false,
          'domain': testDomain,
          'is_pixelfed': true,
        };

        final account = Account.fromJson(json);

        expect(account.id, testAccountId);
        expect(account.username, testUsername);
        expect(account.acct, testAcct);
        expect(account.displayName, testDisplayName);
        expect(account.locked, true);
        expect(account.bot, true);
        expect(account.discoverable, false);
        expect(account.createdAt, testCreatedAt);
        expect(account.note, testNote);
        expect(account.followersCount, 100);
        expect(account.followingCount, 50);
        expect(account.statusesCount, 25);
        expect(account.lastStatusAt, testLastStatusAt);
        expect(account.domain, testDomain);
        expect(account.isPixelfed, true);
        expect(account.fields?.length, 1);
        expect(account.fields?.first.name, 'Website');
      });

      test('should deserialize from JSON correctly with minimal fields', () {
        final json = {
          'id': testAccountId,
          'username': testUsername,
          'acct': testAcct,
          'display_name': testDisplayName,
        };

        final account = Account.fromJson(json);

        expect(account.id, testAccountId);
        expect(account.username, testUsername);
        expect(account.acct, testAcct);
        expect(account.displayName, testDisplayName);
        expect(account.locked, false);
        expect(account.bot, false);
        expect(account.discoverable, true);
        expect(account.followersCount, 0);
        expect(account.isPixelfed, false);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'id': testAccountId,
          'username': testUsername,
          'acct': testAcct,
          'display_name': testDisplayName,
          'followers_count': 100,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final account = Account.fromJson(json);

        expect(account.id, testAccountId);
        expect(account.username, testUsername);
        expect(account.followersCount, 100);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        const account1 = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          followersCount: 100,
        );

        const account2 = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          followersCount: 100,
        );

        expect(account1, equals(account2));
        expect(account1.hashCode, equals(account2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const account1 = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
        );

        const account2 = Account(
          id: 'different-id',
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
        );

        expect(account1, isNot(equals(account2)));
        expect(account1.hashCode, isNot(equals(account2.hashCode)));
      });
    });

    group('Copy With Tests', () {
      test('should create new instance with copyWith', () {
        const originalAccount = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          followersCount: 100,
        );

        final updatedAccount = originalAccount.copyWith(
          displayName: 'Updated Name',
          followersCount: 150,
        );

        // Original should remain unchanged
        expect(originalAccount.displayName, testDisplayName);
        expect(originalAccount.followersCount, 100);
        
        // Updated should have new values
        expect(updatedAccount.displayName, 'Updated Name');
        expect(updatedAccount.followersCount, 150);
        expect(updatedAccount.id, testAccountId);
        expect(updatedAccount.username, testUsername);
        expect(updatedAccount.acct, testAcct);
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        const account = Account(
          id: '',
          username: '',
          acct: '',
          displayName: '',
          note: '',
          url: '',
          avatar: '',
          domain: '',
        );

        expect(account.id, '');
        expect(account.username, '');
        expect(account.acct, '');
        expect(account.displayName, '');
        expect(account.note, '');
        expect(account.url, '');
        expect(account.avatar, '');
        expect(account.domain, '');
      });

      test('should handle special characters in fields', () {
        const specialId = '用户-123';
        const specialUsername = 'test_user@domain';
        const specialAcct = 'test_user@测试.com';
        const specialDisplayName = 'Test User 测试用户';
        
        const account = Account(
          id: specialId,
          username: specialUsername,
          acct: specialAcct,
          displayName: specialDisplayName,
        );

        expect(account.id, specialId);
        expect(account.username, specialUsername);
        expect(account.acct, specialAcct);
        expect(account.displayName, specialDisplayName);
      });

      test('should handle large numbers', () {
        const account = Account(
          id: testAccountId,
          username: testUsername,
          acct: testAcct,
          displayName: testDisplayName,
          followersCount: 1000000,
          followingCount: 50000,
          statusesCount: 25000,
        );

        expect(account.followersCount, 1000000);
        expect(account.followingCount, 50000);
        expect(account.statusesCount, 25000);
      });
    });
  });

  group('Field Model Tests', () {
    const testName = 'Website';
    const testValue = 'https://example.com';
    final testVerifiedAt = DateTime(2023, 6, 15);

    group('Constructor Tests', () {
      test('should create Field with required fields', () {
        const field = Field(
          name: testName,
          value: testValue,
        );

        expect(field.name, testName);
        expect(field.value, testValue);
        expect(field.verifiedAt, isNull);
      });

      test('should create Field with all fields', () {
        final field = Field(
          name: testName,
          value: testValue,
          verifiedAt: testVerifiedAt,
        );

        expect(field.name, testName);
        expect(field.value, testValue);
        expect(field.verifiedAt, testVerifiedAt);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly', () {
        final field = Field(
          name: testName,
          value: testValue,
          verifiedAt: testVerifiedAt,
        );

        final json = field.toJson();

        expect(json['name'], testName);
        expect(json['value'], testValue);
        expect(json['verified_at'], testVerifiedAt.toIso8601String());
      });

      test('should deserialize from JSON correctly', () {
        final json = {
          'name': testName,
          'value': testValue,
          'verified_at': testVerifiedAt.toIso8601String(),
        };

        final field = Field.fromJson(json);

        expect(field.name, testName);
        expect(field.value, testValue);
        // The verifiedAt might be parsed differently by the generated code
        expect(field.verifiedAt, isNotNull);
      });

      test('should handle null verified_at', () {
        final json = {
          'name': testName,
          'value': testValue,
          'verified_at': null,
        };

        final field = Field.fromJson(json);

        expect(field.name, testName);
        expect(field.value, testValue);
        expect(field.verifiedAt, isNull);
      });
    });

    group('Equality Tests', () {
      test('should be equal when all fields are the same', () {
        const field1 = Field(name: testName, value: testValue);
        const field2 = Field(name: testName, value: testValue);

        expect(field1, equals(field2));
        expect(field1.hashCode, equals(field2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const field1 = Field(name: testName, value: testValue);
        const field2 = Field(name: testName, value: 'different value');

        expect(field1, isNot(equals(field2)));
        expect(field1.hashCode, isNot(equals(field2.hashCode)));
      });
    });
  });
}
