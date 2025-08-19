import 'dart:async';
import 'package:app_links/app_links.dart';

class DeepLinkService {
  final AppLinks _appLinks;
  final _linkStreamController = StreamController<Uri>.broadcast();

  Stream<Uri> get links => _linkStreamController.stream;

  DeepLinkService({AppLinks? appLinks}) : _appLinks = appLinks ?? AppLinks();

  Future<void> init() async {
    // Get initial link if app was launched from link
    final uri = await _appLinks.getInitialLink();
    if (uri != null) {
      _linkStreamController.add(uri);
    }

    // Listen for links while app is running
    _appLinks.uriLinkStream.listen(
      (uri) => _linkStreamController.add(uri),
      onError: (err) => print('Deep link error: $err'),
    );
  }

  void dispose() {
    _linkStreamController.close();
  }

  /// Extracts OAuth parameters from deep link URI
  static Map<String, String> extractOAuthParams(Uri uri) {
    final params = <String, String>{};
    
    // Check both query parameters and fragment
    final queryParams = uri.queryParameters;
    final fragmentParams = uri.fragment.isNotEmpty 
        ? Uri.splitQueryString(uri.fragment) 
        : <String, String>{};
    
    // Combine both sources, with fragment taking precedence
    params.addAll(queryParams);
    params.addAll(fragmentParams);

    return params;
  }

  /// Validates that the URI is a valid OAuth callback
  static bool isValidOAuthCallback(Uri uri) {
    final params = extractOAuthParams(uri);
    return params.containsKey('code') || params.containsKey('error');
  }
}
