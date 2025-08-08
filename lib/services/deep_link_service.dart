import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:uni_links/uni_links.dart';

/// Service for handling deep links
class DeepLinkService {
  /// Stream of incoming links
  late Stream<Uri?> _linkStream;
  
  /// Singleton instance
  static final DeepLinkService _instance = DeepLinkService._internal();
  
  /// Factory constructor
  factory DeepLinkService() => _instance;
  
  /// Internal constructor
  DeepLinkService._internal();
  
  /// Initialize the deep link service
  Future<void> init() async {
    // Handle initial link if the app was started from a link
    try {
      final initialLink = await getInitialUri();
      if (initialLink != null) {
        debugPrint('Initial link: $initialLink');
        // Process the initial link
        _processLink(initialLink);
      }
    } on PlatformException {
      debugPrint('Failed to get initial link');
    }
    
    // Listen for incoming links
    _linkStream = uriLinkStream;
    _linkStream.listen((Uri? uri) {
      if (uri != null) {
        debugPrint('Incoming link: $uri');
        _processLink(uri);
      }
    }, onError: (Object error) {
      debugPrint('Error handling link: $error');
    });
  }
  
  /// Process an incoming link
  void _processLink(Uri uri) {
    debugPrint('Processing link: ${uri.toString()}');
    debugPrint('Path: ${uri.path}');
    debugPrint('Query parameters: ${uri.queryParameters}');
    debugPrint('Fragment: ${uri.fragment}');
    
    // Check if this is an OAuth callback
    // The URI scheme is 'pixelodon' and the path might be 'oauth/callback' or just '/callback'
    if (uri.path.contains('oauth/callback') || uri.path == '/callback' || uri.path == 'callback') {
      // Try to get parameters from query string
      String? code = uri.queryParameters['code'];
      String? state = uri.queryParameters['state'];
      String? domain = uri.queryParameters['domain'];
      
      // If parameters are not in query string, check if they're in the fragment
      if ((code == null || state == null || domain == null) && uri.fragment.isNotEmpty) {
        debugPrint('Checking fragment for parameters: ${uri.fragment}');
        final fragmentParams = Uri.splitQueryString(uri.fragment);
        code = code ?? fragmentParams['code'];
        state = state ?? fragmentParams['state'];
        domain = domain ?? fragmentParams['domain'];
      }
      
      debugPrint('OAuth callback parameters:');
      debugPrint('- code: $code');
      debugPrint('- state: $state');
      debugPrint('- domain: $domain');
      
      if (code != null && state != null && domain != null) {
        debugPrint('OAuth callback received with all required parameters');
        // The router will handle this URI
      } else {
        debugPrint('OAuth callback missing required parameters');
      }
    } else {
      debugPrint('Not an OAuth callback link');
    }
  }
}
