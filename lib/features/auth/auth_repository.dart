import '../../services/oauth_service.dart';
import '../../services/browser_service.dart';

class AuthRepository {
  final OAuthService _oauthService;
  final BrowserService _browserService;

  AuthRepository({
    OAuthService? oauthService,
    BrowserService? browserService,
  })  : _oauthService = oauthService ?? OAuthService(),
        _browserService = browserService ?? BrowserService();

  Future<void> authenticateWithInstance(String instance) async {
    try {
      // Generate PKCE code verifier and challenge
      final codeVerifier = await _oauthService.generateCodeVerifier();
      final codeChallenge = _oauthService.generateCodeChallenge(codeVerifier);

      // Create OAuth URL
      final authUrl = Uri.https(instance, '/oauth/authorize', {
        'client_id': 'YOUR_CLIENT_ID', // TODO: Get from config
        'redirect_uri': 'pixelodon://oauth/callback',
        'response_type': 'code',
        'scope': 'read write follow push',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
      }).toString();

      // Launch authentication flow
      final callbackUri = await _browserService.authenticate(authUrl);

      // Extract authorization code from callback
      final code = callbackUri.queryParameters['code'];
      if (code == null) {
        throw Exception('No authorization code received');
      }

      // Exchange code for token
      await _oauthService.exchangeCodeForToken(
        code: code,
        redirectUri: 'pixelodon://oauth/callback',
        clientId: 'YOUR_CLIENT_ID', // TODO: Get from config
        tokenEndpoint: 'https://$instance/oauth/token',
      );

      // TODO: Store instance information
      // TODO: Fetch and store user profile
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refreshTokenIfNeeded() async {
    final isValid = await _oauthService.isTokenValid();
    if (!isValid) {
      // TODO: Get instance and client ID from stored config
      await _oauthService.refreshToken(
        clientId: 'YOUR_CLIENT_ID',
        tokenEndpoint: 'https://instance.example.com/oauth/token',
      );
    }
  }

  Future<void> logout() async {
    await _oauthService.clearTokens();
    // TODO: Clear other stored data
  }
}
