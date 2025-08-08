import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([Dio, FlutterSecureStorage])
import 'auth_service_test.mocks.dart';

void main() {
  late AuthService authService;
  late MockDio mockDio;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockDio = MockDio();
    mockSecureStorage = MockFlutterSecureStorage();
    authService = AuthService(
      dio: mockDio,
      secureStorage: mockSecureStorage,
    );
  });

  test('Test redirect URI validation', () {
    // This test directly tests the private method _isRedirectUriSafe
    // We're using a workaround to access it via reflection
    final isRedirectUriSafe = (String uri) {
      return authService.isRedirectUriSafeForTesting(uri);
    };

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
