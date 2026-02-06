import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:pixelodon/services/deep_link_service.dart';

import 'deep_link_service_test.mocks.dart';

@GenerateMocks([AppLinks])
void main() {
  group('DeepLinkService Tests', () {
    late MockAppLinks mockAppLinks;
    late DeepLinkService deepLinkService;
    late StreamController<Uri> mockUriStream;

    setUp(() {
      mockAppLinks = MockAppLinks();
      mockUriStream = StreamController<Uri>.broadcast();
      deepLinkService = DeepLinkService(appLinks: mockAppLinks);

      // Setup mock stream
      when(mockAppLinks.uriLinkStream).thenAnswer((_) => mockUriStream.stream);
    });

    tearDown(() {
      mockUriStream.close();
      deepLinkService.dispose();
    });

    group('Constructor Tests', () {
      test('should create with default AppLinks when none provided', () {
        final service = DeepLinkService();
        expect(service, isA<DeepLinkService>());
      });

      test('should create with provided AppLinks instance', () {
        final service = DeepLinkService(appLinks: mockAppLinks);
        expect(service, isA<DeepLinkService>());
      });
    });

    group('Initialization Tests', () {
      test('should handle initial link when present', () async {
        final testUri = Uri.parse('pixelodon://oauth/callback?code=test123');
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => testUri);

        final linksFuture = deepLinkService.links.first;
        
        await deepLinkService.init();
        
        final receivedUri = await linksFuture;
        expect(receivedUri, equals(testUri));
        verify(mockAppLinks.getInitialLink()).called(1);
      });

      test('should handle no initial link', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        await deepLinkService.init();

        verify(mockAppLinks.getInitialLink()).called(1);
        expect(deepLinkService.links, isA<Stream<Uri>>());
      });

      test('should listen to uri link stream after initialization', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        await deepLinkService.init();

        final testUri = Uri.parse('pixelodon://oauth/callback?code=test456');
        final linksFuture = deepLinkService.links.first;

        mockUriStream.add(testUri);

        final receivedUri = await linksFuture;
        expect(receivedUri, equals(testUri));
      });

      test('should handle stream errors gracefully', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        await deepLinkService.init();

        // Add an error to the stream
        mockUriStream.addError('Test error');

        // Service should continue to work after error
        final testUri = Uri.parse('pixelodon://test');
        final linksFuture = deepLinkService.links.first;

        mockUriStream.add(testUri);

        final receivedUri = await linksFuture;
        expect(receivedUri, equals(testUri));
      });
    });

    group('Stream Management Tests', () {
      test('should provide broadcast stream', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        await deepLinkService.init();

        final stream = deepLinkService.links;
        expect(stream.isBroadcast, isTrue);
      });

      test('should handle multiple listeners', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);
        await deepLinkService.init();

        final testUri = Uri.parse('pixelodon://test');
        final completer1 = Completer<Uri>();
        final completer2 = Completer<Uri>();

        deepLinkService.links.listen((uri) {
          if (!completer1.isCompleted) completer1.complete(uri);
        });

        deepLinkService.links.listen((uri) {
          if (!completer2.isCompleted) completer2.complete(uri);
        });

        mockUriStream.add(testUri);

        final uri1 = await completer1.future;
        final uri2 = await completer2.future;

        expect(uri1, equals(testUri));
        expect(uri2, equals(testUri));
      });

      test('should dispose stream controller properly', () {
        deepLinkService.dispose();
        // Stream controller should be closed, so adding to it should not work
        expect(() => deepLinkService.links.listen((_) {}), returnsNormally);
      });
    });

    group('OAuth Parameter Extraction Tests', () {
      test('should extract parameters from query string', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=test123&state=abc&domain=example.com');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params['code'], 'test123');
        expect(params['state'], 'abc');
        expect(params['domain'], 'example.com');
      });

      test('should extract parameters from fragment', () {
        final uri = Uri.parse('pixelodon://oauth/callback#code=test456&state=def&domain=pixelfed.de');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params['code'], 'test456');
        expect(params['state'], 'def');
        expect(params['domain'], 'pixelfed.de');
      });

      test('should combine query and fragment parameters with fragment taking precedence', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=query123&state=shared#code=fragment456&domain=example.com');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params['code'], 'fragment456'); // Fragment takes precedence
        expect(params['state'], 'shared'); // From query since not in fragment
        expect(params['domain'], 'example.com'); // From fragment
      });

      test('should handle empty query parameters', () {
        final uri = Uri.parse('pixelodon://oauth/callback');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params, isEmpty);
      });

      test('should handle empty fragment', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=test');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params['code'], 'test');
        expect(params.length, 1);
      });

      test('should handle special characters in parameters', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=test%2B123&state=ab%20cd');
        final params = DeepLinkService.extractOAuthParams(uri);

        expect(params['code'], 'test+123');
        expect(params['state'], 'ab cd');
      });
    });

    group('OAuth Validation Tests', () {
      test('should validate OAuth callback with code parameter', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=test123&state=abc');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
      });

      test('should validate OAuth callback with error parameter', () {
        final uri = Uri.parse('pixelodon://oauth/callback?error=access_denied&state=abc');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
      });

      test('should validate OAuth callback with code in fragment', () {
        final uri = Uri.parse('pixelodon://oauth/callback#code=test123&state=abc');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
      });

      test('should validate OAuth callback with error in fragment', () {
        final uri = Uri.parse('pixelodon://oauth/callback#error=access_denied&state=abc');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
      });

      test('should reject callback without code or error', () {
        final uri = Uri.parse('pixelodon://oauth/callback?state=abc');
        expect(DeepLinkService.isValidOAuthCallback(uri), isFalse);
      });

      test('should reject non-OAuth URIs', () {
        final uri = Uri.parse('pixelodon://home');
        expect(DeepLinkService.isValidOAuthCallback(uri), isFalse);
      });

      test('should handle empty URI', () {
        final uri = Uri.parse('pixelodon://oauth/callback');
        expect(DeepLinkService.isValidOAuthCallback(uri), isFalse);
      });
    });

    group('Static Method Tests', () {
      test('extractOAuthParams should be accessible without instance', () {
        final uri = Uri.parse('test://callback?code=123');
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['code'], '123');
      });

      test('isValidOAuthCallback should be accessible without instance', () {
        final uri = Uri.parse('test://callback?code=123');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
      });
    });

    group('Edge Cases', () {
      test('should handle malformed URIs gracefully', () {
        // This tests the robustness of URI parsing
        final uri = Uri.parse('pixelodon://oauth/callback?code=test&invalid=param=value');
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['code'], 'test');
      });

      test('should handle very long parameter values', () {
        final longCode = 'a' * 1000;
        final uri = Uri.parse('pixelodon://oauth/callback?code=$longCode');
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['code'], longCode);
        expect(params['code']?.length, 1000);
      });

      test('should handle multiple initialization calls', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        await deepLinkService.init();
        await deepLinkService.init(); // Second initialization

        // Should not cause errors and still work
        verify(mockAppLinks.getInitialLink()).called(2);
      });

      test('should handle disposal after initialization', () async {
        when(mockAppLinks.getInitialLink()).thenAnswer((_) async => null);

        await deepLinkService.init();
        deepLinkService.dispose();

        // Should not throw errors
        expect(() => deepLinkService.dispose(), returnsNormally);
      });

      test('should handle special OAuth parameters', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=test&error_description=User%20denied%20access');
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['code'], 'test');
        expect(params['error_description'], 'User denied access');
      });
    });

    group('Real-world Scenarios', () {
      test('should handle Mastodon OAuth callback', () {
        final uri = Uri.parse('pixelodon://oauth/callback?code=abcd1234&state=random_state');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
        
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['code'], 'abcd1234');
        expect(params['state'], 'random_state');
      });

      test('should handle Pixelfed OAuth callback with fragment', () {
        final uri = Uri.parse('pixelodon://oauth/callback#access_token=token123&code=abcd&state=state456');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
        
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['access_token'], 'token123');
        expect(params['code'], 'abcd');
        expect(params['state'], 'state456');
      });

      test('should handle OAuth error callback', () {
        final uri = Uri.parse('pixelodon://oauth/callback?error=access_denied&error_description=User%20cancelled');
        expect(DeepLinkService.isValidOAuthCallback(uri), isTrue);
        
        final params = DeepLinkService.extractOAuthParams(uri);
        expect(params['error'], 'access_denied');
        expect(params['error_description'], 'User cancelled');
      });
    });
  });
}
