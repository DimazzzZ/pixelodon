import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/services/auth_service.dart';

void main() {
  late AuthService authService;

  setUp(() {
    authService = AuthService();
  });

  test('Test redirect URI validation', () {
    bool isRedirectUriSafe(String uri) {
      return authService.isRedirectUriSafeForTesting(uri);
    }

    // Test valid URIs
    expect(isRedirectUriSafe('pixelodon://oauth/callback'), isTrue);
    expect(isRedirectUriSafe('https://example.com/callback'), isTrue);

    // Test invalid URIs
    expect(isRedirectUriSafe('javascript:alert(1)'), isFalse);
    expect(isRedirectUriSafe('data:text/html,<script>alert(1)</script>'), isFalse);
    expect(isRedirectUriSafe('file:///etc/passwd'), isFalse);
    expect(isRedirectUriSafe('vbscript:msgbox(1)'), isFalse);
    expect(isRedirectUriSafe('http://example.com'), isFalse); // Only https is allowed
    expect(isRedirectUriSafe('custom://callback'), isFalse); // Only pixelodon:// is allowed
  });
}
