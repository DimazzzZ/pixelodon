# Changelog

## [Unreleased]

### Fixed
- Fixed OAuth authentication flow by correcting the redirect URI validation in AuthService. The app now properly recognizes 'pixelodon://' as a valid URI scheme for OAuth callbacks.
- Fixed OAuth callback handling to properly extract authorization code from deep links. The app now checks for parameters in both query string and URI fragments.
- Fixed go_router configuration by ensuring all route paths start with a forward slash, resolving the "top-level path must start with '/'" assertion error.
- Fixed issue with OAuth callback not receiving authorization code by updating OAuthCallbackScreen to accept code parameter directly and ensuring all router paths pass the code parameter correctly.

## Details of the Fixes

### URI Scheme Validation Fix

The issue was in the `_isRedirectUriSafe` method in `AuthService` class. The method was incorrectly validating custom URI schemes by checking if the scheme ended with '://', but `Uri.parse()` already separates the scheme from the '://' part.

For example, when parsing 'pixelodon://oauth/callback':
- `Uri.parse()` extracts 'pixelodon' as the scheme
- The previous check `parsedUri.scheme.endsWith('://')` would always fail

The fix changes the validation to explicitly allow the 'pixelodon' scheme alongside 'https', which properly handles the app's custom URI scheme for OAuth callbacks.

### OAuth Callback Handling Fix

The second issue was in the OAuth callback handling. The app was not properly extracting the authorization code from deep links. The following changes were made:

1. Updated the deep link service to handle multiple callback path formats ('oauth/callback', '/callback', 'callback')
2. Modified the app router to properly handle both '/auth/callback' and '/oauth/callback' routes, with and without leading slashes
3. Enhanced the OAuthCallbackScreen to check for authorization code in both query parameters and URI fragments
4. Improved the DeepLinkService to extract parameters from both query string and fragments
5. Updated the web OAuth callback page to use URI fragments instead of query parameters for more reliable parameter passing

These changes ensure that the app can properly handle OAuth callbacks regardless of how the parameters are passed (query string or fragment) and which path is used. The use of URI fragments in the web callback is particularly important as it helps avoid issues with parameter encoding and truncation that can occur with query parameters.

### Go Router Path Fix

The third issue was in the app_router.dart file where some routes were defined without a leading slash in their paths. The go_router package requires that all top-level paths start with a forward slash ('/').

The following changes were made:
1. Fixed the 'auth/callback' route path to '/auth/callback'
2. Fixed the 'oauth/callback' route path to '/oauth/callback'
3. Updated all related debug print statements to maintain consistency

This fix resolves the assertion error: "top-level path must start with '/'" that was occurring during app initialization.

### OAuth Callback Code Parameter Fix

The latest issue was that the OAuth callback was not receiving the authorization code, even though the app was correctly generating the authorization URL with all necessary parameters. The logs showed that when the callback was processed, the query parameters were empty, resulting in no authorization code being received.

The following changes were made:

1. Updated OAuthCallbackScreen to accept a code parameter directly:
   - Added a `code` parameter to the OAuthCallbackScreen widget
   - Modified the `_processCallback` method to check for the code in the widget parameter first

2. Improved parameter extraction in the callback screen:
   - Updated the code to check for the code parameter in the widget first, then in query parameters, and finally in the fragment

3. Fixed router configuration:
   - Updated both '/oauth/callback' routes to pass the code parameter to OAuthCallbackScreen
   - Ensured consistent parameter handling across all routes

These changes ensure that the app can properly extract the authorization code from the callback URL, whether it's passed directly to the widget, in the query parameters, or in the fragment. This resolves the authentication issue where the logs showed "OAuth callback - No authorization code received".
