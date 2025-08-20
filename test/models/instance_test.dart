import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/instance.dart';

void main() {
  group('Instance Model Tests', () {
    const testDomain = 'pixelfed.de';
    const testName = 'Pixelfed Deutschland';
    const testDescription = 'A German Pixelfed instance';
    const testVersion = '0.11.4';
    const testThumbnail = 'https://pixelfed.de/img/logo.png';
    const testLanguages = ['en', 'de', 'fr'];
    const testTosUrl = 'https://pixelfed.de/site/terms';
    const testPrivacyPolicyUrl = 'https://pixelfed.de/site/privacy';
    const testContactEmail = 'admin@pixelfed.de';

    group('Constructor Tests', () {
      test('should create Instance with required fields only', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
        );

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, isNull);
        expect(instance.version, isNull);
        expect(instance.thumbnail, isNull);
        expect(instance.languages, isNull);
        expect(instance.maxCharsPerPost, isNull);
        expect(instance.maxMediaAttachments, isNull);
        expect(instance.isPixelfed, false);
        expect(instance.supportsStories, false);
        expect(instance.tosUrl, isNull);
        expect(instance.privacyPolicyUrl, isNull);
        expect(instance.contactEmail, isNull);
      });

      test('should create Instance with all fields', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          version: testVersion,
          thumbnail: testThumbnail,
          languages: testLanguages,
          maxCharsPerPost: 500,
          maxMediaAttachments: 4,
          isPixelfed: true,
          supportsStories: true,
          tosUrl: testTosUrl,
          privacyPolicyUrl: testPrivacyPolicyUrl,
          contactEmail: testContactEmail,
        );

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, testDescription);
        expect(instance.version, testVersion);
        expect(instance.thumbnail, testThumbnail);
        expect(instance.languages, testLanguages);
        expect(instance.maxCharsPerPost, 500);
        expect(instance.maxMediaAttachments, 4);
        expect(instance.isPixelfed, true);
        expect(instance.supportsStories, true);
        expect(instance.tosUrl, testTosUrl);
        expect(instance.privacyPolicyUrl, testPrivacyPolicyUrl);
        expect(instance.contactEmail, testContactEmail);
      });

      test('should handle nullable fields correctly', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          description: null,
          version: null,
          thumbnail: null,
          languages: null,
          maxCharsPerPost: null,
          maxMediaAttachments: null,
          tosUrl: null,
          privacyPolicyUrl: null,
          contactEmail: null,
        );

        expect(instance.description, isNull);
        expect(instance.version, isNull);
        expect(instance.thumbnail, isNull);
        expect(instance.languages, isNull);
        expect(instance.maxCharsPerPost, isNull);
        expect(instance.maxMediaAttachments, isNull);
        expect(instance.tosUrl, isNull);
        expect(instance.privacyPolicyUrl, isNull);
        expect(instance.contactEmail, isNull);
      });
    });

    group('JSON Serialization Tests', () {
      test('should serialize to JSON correctly with all fields', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          version: testVersion,
          thumbnail: testThumbnail,
          languages: testLanguages,
          maxCharsPerPost: 500,
          maxMediaAttachments: 4,
          isPixelfed: true,
          supportsStories: true,
          tosUrl: testTosUrl,
          privacyPolicyUrl: testPrivacyPolicyUrl,
          contactEmail: testContactEmail,
        );

        final json = instance.toJson();

        expect(json['domain'], testDomain);
        expect(json['name'], testName);
        expect(json['description'], testDescription);
        expect(json['version'], testVersion);
        expect(json['thumbnail'], testThumbnail);
        expect(json['languages'], testLanguages);
        expect(json['max_chars_per_post'], 500);
        expect(json['max_media_attachments'], 4);
        expect(json['is_pixelfed'], true);
        expect(json['supports_stories'], true);
        expect(json['tos_url'], testTosUrl);
        expect(json['privacy_policy_url'], testPrivacyPolicyUrl);
        expect(json['contact_email'], testContactEmail);
      });

      test('should serialize to JSON correctly with minimal fields', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
        );

        final json = instance.toJson();

        expect(json['domain'], testDomain);
        expect(json['name'], testName);
        expect(json['is_pixelfed'], false);
        expect(json['supports_stories'], false);
        expect(json.containsKey('description'), isTrue);
        expect(json.containsKey('version'), isTrue);
      });
    });

    group('JSON Deserialization Tests', () {
      test('should deserialize from JSON correctly with all fields', () {
        final json = {
          'domain': testDomain,
          'name': testName,
          'description': testDescription,
          'version': testVersion,
          'thumbnail': testThumbnail,
          'languages': testLanguages,
          'max_chars_per_post': 500,
          'max_media_attachments': 4,
          'is_pixelfed': true,
          'supports_stories': true,
          'tos_url': testTosUrl,
          'privacy_policy_url': testPrivacyPolicyUrl,
          'contact_email': testContactEmail,
        };

        final instance = Instance.fromJson(json);

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, testDescription);
        expect(instance.version, testVersion);
        expect(instance.thumbnail, testThumbnail);
        expect(instance.languages, testLanguages);
        expect(instance.maxCharsPerPost, 500);
        expect(instance.maxMediaAttachments, 4);
        expect(instance.isPixelfed, true);
        expect(instance.supportsStories, true);
        expect(instance.tosUrl, testTosUrl);
        expect(instance.privacyPolicyUrl, testPrivacyPolicyUrl);
        expect(instance.contactEmail, testContactEmail);
      });

      test('should deserialize from JSON correctly with minimal fields', () {
        final json = {
          'domain': testDomain,
          'name': testName,
        };

        final instance = Instance.fromJson(json);

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, isNull);
        expect(instance.version, isNull);
        expect(instance.isPixelfed, false);
        expect(instance.supportsStories, false);
      });

      test('should handle JSON string input', () {
        final jsonString = jsonEncode({
          'domain': testDomain,
          'name': testName,
          'description': testDescription,
          'is_pixelfed': true,
        });

        final json = jsonDecode(jsonString) as Map<String, dynamic>;
        final instance = Instance.fromJson(json);

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, testDescription);
        expect(instance.isPixelfed, true);
      });

      test('should handle null values correctly', () {
        final json = {
          'domain': testDomain,
          'name': testName,
          'description': null,
          'version': null,
          'thumbnail': null,
          'languages': null,
          'max_chars_per_post': null,
          'max_media_attachments': null,
          'tos_url': null,
          'privacy_policy_url': null,
          'contact_email': null,
        };

        final instance = Instance.fromJson(json);

        expect(instance.domain, testDomain);
        expect(instance.name, testName);
        expect(instance.description, isNull);
        expect(instance.version, isNull);
        expect(instance.thumbnail, isNull);
        expect(instance.languages, isNull);
        expect(instance.maxCharsPerPost, isNull);
        expect(instance.maxMediaAttachments, isNull);
        expect(instance.tosUrl, isNull);
        expect(instance.privacyPolicyUrl, isNull);
        expect(instance.contactEmail, isNull);
      });
    });

    group('Equality and Hash Code Tests', () {
      test('should be equal when all fields are the same', () {
        const instance1 = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          isPixelfed: true,
        );

        const instance2 = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          isPixelfed: true,
        );

        expect(instance1, equals(instance2));
        expect(instance1.hashCode, equals(instance2.hashCode));
      });

      test('should not be equal when fields differ', () {
        const instance1 = Instance(
          domain: testDomain,
          name: testName,
        );

        const instance2 = Instance(
          domain: 'different-domain.com',
          name: testName,
        );

        expect(instance1, isNot(equals(instance2)));
        expect(instance1.hashCode, isNot(equals(instance2.hashCode)));
      });

      test('should not be equal when optional fields differ', () {
        const instance1 = Instance(
          domain: testDomain,
          name: testName,
          isPixelfed: true,
        );

        const instance2 = Instance(
          domain: testDomain,
          name: testName,
          isPixelfed: false,
        );

        expect(instance1, isNot(equals(instance2)));
        expect(instance1.hashCode, isNot(equals(instance2.hashCode)));
      });
    });

    group('Copy With Tests', () {
      test('should create new instance with copyWith', () {
        const originalInstance = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          isPixelfed: false,
        );

        final updatedInstance = originalInstance.copyWith(
          description: 'Updated description',
          isPixelfed: true,
        );

        // Original should remain unchanged
        expect(originalInstance.description, testDescription);
        expect(originalInstance.isPixelfed, false);
        
        // Updated should have new values
        expect(updatedInstance.description, 'Updated description');
        expect(updatedInstance.isPixelfed, true);
        expect(updatedInstance.domain, testDomain);
        expect(updatedInstance.name, testName);
      });
    });

    group('Edge Cases', () {
      test('should handle empty strings', () {
        const instance = Instance(
          domain: '',
          name: '',
          description: '',
          version: '',
          thumbnail: '',
          tosUrl: '',
          privacyPolicyUrl: '',
          contactEmail: '',
        );

        expect(instance.domain, '');
        expect(instance.name, '');
        expect(instance.description, '');
        expect(instance.version, '');
        expect(instance.thumbnail, '');
        expect(instance.tosUrl, '');
        expect(instance.privacyPolicyUrl, '');
        expect(instance.contactEmail, '');
      });

      test('should handle special characters in fields', () {
        const specialDomain = 'пиксельфед.рф';
        const specialName = 'Pixelfed Россия 🇷🇺';
        const specialDescription = 'Русскоязычный инстанс с эмодзи 😀';
        
        const instance = Instance(
          domain: specialDomain,
          name: specialName,
          description: specialDescription,
        );

        expect(instance.domain, specialDomain);
        expect(instance.name, specialName);
        expect(instance.description, specialDescription);
      });

      test('should handle empty languages list', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          languages: [],
        );

        expect(instance.languages, isEmpty);
      });

      test('should handle large numbers', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          maxCharsPerPost: 100000,
          maxMediaAttachments: 50,
        );

        expect(instance.maxCharsPerPost, 100000);
        expect(instance.maxMediaAttachments, 50);
      });

      test('should handle zero values', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          maxCharsPerPost: 0,
          maxMediaAttachments: 0,
        );

        expect(instance.maxCharsPerPost, 0);
        expect(instance.maxMediaAttachments, 0);
      });
    });

    group('Instance Type Tests', () {
      test('should identify Pixelfed instance correctly', () {
        const pixelfedInstance = Instance(
          domain: testDomain,
          name: testName,
          isPixelfed: true,
          supportsStories: true,
        );

        expect(pixelfedInstance.isPixelfed, true);
        expect(pixelfedInstance.supportsStories, true);
      });

      test('should identify Mastodon instance correctly', () {
        const mastodonInstance = Instance(
          domain: 'mastodon.social',
          name: 'Mastodon Social',
          isPixelfed: false,
          supportsStories: false,
        );

        expect(mastodonInstance.isPixelfed, false);
        expect(mastodonInstance.supportsStories, false);
      });
    });

    group('toString Tests', () {
      test('should have meaningful toString representation', () {
        const instance = Instance(
          domain: testDomain,
          name: testName,
          description: testDescription,
          isPixelfed: true,
        );

        final stringRepresentation = instance.toString();
        
        expect(stringRepresentation, contains(testDomain));
        expect(stringRepresentation, contains(testName));
        expect(stringRepresentation, contains(testDescription));
        expect(stringRepresentation, contains('true'));
      });
    });
  });
}
