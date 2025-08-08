# Authorization Fix Summary

## Issue
The application was experiencing an OAuth authorization error with the following message:
```
{"error":"invalid_client","error_description":"Client authentication failed","message":"Client authentication failed"}
```

## Root Cause
The issue was identified in multiple OAuth-related methods in `auth_service.dart`. The application was sending client credentials twice:

1. In the Authorization header using HTTP Basic Auth:
   ```dart
   final basicAuth = 'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}';
   ```

2. In the request body:
   ```dart
   final Map<String, dynamic> requestData = {
     // Other parameters...
     'client_id': clientId,
     'client_secret': clientSecret,
   };
   ```

According to the OAuth 2.0 specification (RFC 6749), client credentials should be sent using only one method, not both. When both methods are used, the server may reject the request with an "invalid_client" error.

## Fix
The fix was to remove the client credentials from the request body in all OAuth-related methods, keeping them only in the Authorization header:

1. In `exchangeAuthorizationCode`:
   ```dart
   final Map<String, dynamic> requestData = {
     'redirect_uri': _redirectUri,
     'grant_type': 'authorization_code',
     'code': code,
     'scope': _scopes,
   };
   ```

2. In `_refreshAccessToken`:
   ```dart
   final Map<String, dynamic> requestData = {
     'grant_type': 'refresh_token',
     'refresh_token': refreshToken,
     'scope': _scopes,
   };
   ```

3. In `revokeAccessToken`:
   ```dart
   final Map<String, dynamic> requestData = {
     'token': token,
   };
   ```

This ensures that client authentication is performed using only one method (HTTP Basic Auth) across all OAuth endpoints, which is more secure and compliant with the OAuth 2.0 specification.

## Verification
The fix was verified by:
1. Reviewing the OAuth 2.0 specification
2. Creating test cases to ensure client credentials are only sent in the Authorization header for all OAuth methods
3. Manual testing with the Pixelfed.de instance

## References
- [OAuth 2.0 RFC 6749, Section 2.3 - Client Authentication](https://tools.ietf.org/html/rfc6749#section-2.3)
- [OAuth 2.0 RFC 6749, Section 4.1.3 - Access Token Request](https://tools.ietf.org/html/rfc6749#section-4.1.3)
- [OAuth 2.0 RFC 6749, Section 6 - Refreshing an Access Token](https://tools.ietf.org/html/rfc6749#section-6)
