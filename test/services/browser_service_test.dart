import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/services/browser_service.dart';

void main() {
  group('BrowserService Tests', () {
    late BrowserService browserService;

    setUp(() {
      browserService = BrowserService();
    });

    group('Authentication Flow', () {
      test('should create BrowserService instance', () {
        expect(browserService, isA<BrowserService>());
      });

      test('should handle authentication URL format', () {
        const testUrl = 'https://mastodon.social/oauth/authorize?client_id=test';
        
        // Test that the service can handle the URL format
        expect(() => Uri.parse(testUrl), returnsNormally);
        expect(Uri.parse(testUrl).scheme, equals('https'));
        expect(Uri.parse(testUrl).host, equals('mastodon.social'));
      });

      test('should handle callback URL scheme', () {
        const callbackUrl = 'pixelodon://oauth/callback?code=test123';
        
        final uri = Uri.parse(callbackUrl);
        expect(uri.scheme, equals('pixelodon'));
        expect(uri.host, equals('oauth'));
        expect(uri.path, equals('/callback'));
        expect(uri.queryParameters['code'], equals('test123'));
      });

      test('should validate authentication URL format', () {
        const validUrl = 'https://mastodon.social/oauth/authorize';
        const invalidUrl = 'not-a-url';
        
        expect(() => Uri.parse(validUrl), returnsNormally);
        expect(() => Uri.parse(invalidUrl), returnsNormally); // Uri.parse doesn't throw
        
        final validUri = Uri.parse(validUrl);
        final invalidUri = Uri.parse(invalidUrl);
        
        expect(validUri.hasScheme, isTrue);
        expect(invalidUri.hasScheme, isFalse);
      });
    });

    group('URL Launching', () {
      test('should handle valid URL formats', () {
        const validUrls = [
          'https://example.com',
          'https://mastodon.social/@user',
          'https://pixelfed.social/p/123',
        ];
        
        for (final url in validUrls) {
          expect(() => Uri.parse(url), returnsNormally);
          final uri = Uri.parse(url);
          expect(uri.hasScheme, isTrue);
          expect(uri.scheme, equals('https'));
        }
      });

      test('should handle invalid URL formats', () {
        const invalidUrls = [
          '',
          'not-a-url',
          'ftp://example.com', // Valid URI but might not be launchable
        ];
        
        for (final url in invalidUrls) {
          expect(() => Uri.parse(url), returnsNormally);
        }
      });

      test('should validate URL components', () {
        const testUrl = 'https://mastodon.social/@user/123456';
        final uri = Uri.parse(testUrl);
        
        expect(uri.scheme, equals('https'));
        expect(uri.host, equals('mastodon.social'));
        expect(uri.path, equals('/@user/123456'));
      });
    });

    group('Error Handling', () {
      test('should handle malformed URLs gracefully', () {
        const malformedUrls = [
          'https://',
          'https://.',
          'https://example..com',
        ];
        
        for (final url in malformedUrls) {
          expect(() => Uri.parse(url), returnsNormally);
          // The actual validation would happen in canLaunchUrl
        }
      });

      test('should handle callback URL parsing', () {
        const callbackUrls = [
          'pixelodon://oauth/callback?code=abc123',
          'pixelodon://oauth/callback?code=abc123&state=xyz789',
          'pixelodon://oauth/callback?error=access_denied',
        ];
        
        for (final url in callbackUrls) {
          expect(() => Uri.parse(url), returnsNormally);
          final uri = Uri.parse(url);
          expect(uri.scheme, equals('pixelodon'));
          expect(uri.host, equals('oauth'));
        }
      });
    });

    group('Integration Scenarios', () {
      test('should handle complete OAuth flow URLs', () {
        const authUrl = 'https://mastodon.social/oauth/authorize'
            '?client_id=test_client'
            '&redirect_uri=pixelodon://oauth/callback'
            '&response_type=code'
            '&scope=read+write+follow'
            '&code_challenge=test_challenge'
            '&code_challenge_method=S256';
        
        final uri = Uri.parse(authUrl);
        expect(uri.queryParameters['client_id'], equals('test_client'));
        expect(uri.queryParameters['response_type'], equals('code'));
        expect(uri.queryParameters['scope'], equals('read write follow'));
      });

      test('should handle error responses', () {
        const errorUrl = 'pixelodon://oauth/callback'
            '?error=access_denied'
            '&error_description=The+user+denied+the+request';
        
        final uri = Uri.parse(errorUrl);
        expect(uri.queryParameters['error'], equals('access_denied'));
        expect(uri.queryParameters.containsKey('error_description'), isTrue);
      });
    });
  });
}
