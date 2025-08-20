import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/user.dart';

void main() {
  group('User Model Tests', () {
    const testUserId = '12345';
    const testUsername = 'testuser';
    const testEmail = 'test@example.com';
    const testDisplayName = 'Test User';
    const testAvatarUrl = 'https://example.com/avatar.jpg';

    group('Constructor Tests', () {
      test('should create User with required fields only', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
        );

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, isNull);
        expect(user.avatarUrl, isNull);
      });

      test('should create User with all fields', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, testDisplayName);
        expect(user.avatarUrl, testAvatarUrl);
      });

      test('should create User with nullable fields as null', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: null,
          avatarUrl: null,
        );

        expect(user.displayName, isNull);
        expect(user.avatarUrl, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        final json = user.toJson();

        expect(json['id'], testUserId);
        expect(json['username'], testUsername);
        expect(json['email'], testEmail);
        expect(json['displayName'], testDisplayName);
        expect(json['avatarUrl'], testAvatarUrl);
      });

      test('should serialize to JSON correctly with nullable fields as null', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: null,
          avatarUrl: null,
        );

        final json = user.toJson();

        expect(json['id'], testUserId);
        expect(json['username'], testUsername);
        expect(json['email'], testEmail);
        expect(json['displayName'], isNull);
        expect(json['avatarUrl'], isNull);
      });

      test('should serialize to JSON correctly with only required fields', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
        );

        final json = user.toJson();

        expect(json['id'], testUserId);
        expect(json['username'], testUsername);
        expect(json['email'], testEmail);
        expect(json.containsKey('displayName'), isTrue);
        expect(json.containsKey('avatarUrl'), isTrue);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'id': testUserId,
          'username': testUsername,
          'email': testEmail,
          'displayName': testDisplayName,
          'avatarUrl': testAvatarUrl,
        };

        final user = User.fromJson(json);

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, testDisplayName);
        expect(user.avatarUrl, testAvatarUrl);
      });

      test('should deserialize from JSON correctly with nullable fields as null', () {
        final json = {
          'id': testUserId,
          'username': testUsername,
          'email': testEmail,
          'displayName': null,
          'avatarUrl': null,
        };

        final user = User.fromJson(json);

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, isNull);
        expect(user.avatarUrl, isNull);
      });

      test('should deserialize from JSON correctly with missing optional fields', () {
        final json = {
          'id': testUserId,
          'username': testUsername,
          'email': testEmail,
        };

        final user = User.fromJson(json);

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, isNull);
        expect(user.avatarUrl, isNull);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'id': testUserId,
          'username': testUsername,
          'email': testEmail,
          'displayName': testDisplayName,
          'avatarUrl': testAvatarUrl,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final user = User.fromJson(json);

        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, testDisplayName);
        expect(user.avatarUrl, testAvatarUrl);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        const user1 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        const user2 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });

      test('should not be equal when required fields differ', () {
        const user1 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
        );

        const user2 = User(
          id: 'different-id',
          username: testUsername,
          email: testEmail,
        );

        expect(user1, isNot(equals(user2)));
        expect(user1.hashCode, isNot(equals(user2.hashCode)));
      });

      test('should not be equal when optional fields differ', () {
        const user1 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
        );

        const user2 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: 'Different Name',
        );

        expect(user1, isNot(equals(user2)));
        expect(user1.hashCode, isNot(equals(user2.hashCode)));
      });

      test('should be equal when both have null optional fields', () {
        const user1 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: null,
          avatarUrl: null,
        );

        const user2 = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
        );

        expect(user1, equals(user2));
        expect(user1.hashCode, equals(user2.hashCode));
      });
    });

    group('Immutability Tests', () {
      test('should be immutable', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        // Attempting to modify fields should not be possible
        // (This is enforced by the compiler with const and final fields)
        expect(user.id, testUserId);
        expect(user.username, testUsername);
        expect(user.email, testEmail);
        expect(user.displayName, testDisplayName);
        expect(user.avatarUrl, testAvatarUrl);
      });

      test('should create new instance with copyWith', () {
        const originalUser = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        final updatedUser = originalUser.copyWith(
          displayName: 'Updated Name',
        );

        // Original should remain unchanged
        expect(originalUser.displayName, testDisplayName);
        
        // Updated should have new value
        expect(updatedUser.displayName, 'Updated Name');
        expect(updatedUser.id, testUserId);
        expect(updatedUser.username, testUsername);
        expect(updatedUser.email, testEmail);
        expect(updatedUser.avatarUrl, testAvatarUrl);
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        const user = User(
          id: '',
          username: '',
          email: '',
          displayName: '',
          avatarUrl: '',
        );

        expect(user.id, '');
        expect(user.username, '');
        expect(user.email, '');
        expect(user.displayName, '');
        expect(user.avatarUrl, '');
      });

      test('should handle special characters in fields', () {
        const specialId = '用户-123';
        const specialUsername = 'test_user@domain';
        const specialEmail = 'test+user@example.com';
        const specialDisplayName = 'Test User 测试用户';
        
        const user = User(
          id: specialId,
          username: specialUsername,
          email: specialEmail,
          displayName: specialDisplayName,
        );

        expect(user.id, specialId);
        expect(user.username, specialUsername);
        expect(user.email, specialEmail);
        expect(user.displayName, specialDisplayName);
      });
    });

    group('toString Tests', () {
      test('should have meaningful toString representation', () {
        const user = User(
          id: testUserId,
          username: testUsername,
          email: testEmail,
          displayName: testDisplayName,
          avatarUrl: testAvatarUrl,
        );

        final stringRepresentation = user.toString();
        
        expect(stringRepresentation, contains(testUserId));
        expect(stringRepresentation, contains(testUsername));
        expect(stringRepresentation, contains(testEmail));
        expect(stringRepresentation, contains(testDisplayName));
        expect(stringRepresentation, contains(testAvatarUrl));
      });
    });
  });
}
