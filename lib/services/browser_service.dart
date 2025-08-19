import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:url_launcher/url_launcher.dart';

class BrowserService {
  static const _callbackUrlScheme = 'pixelodon';

  /// Launches the OAuth flow in an in-app browser
  /// Returns the callback URL with the authorization code
  Future<Uri> authenticate(String authUrl) async {
    try {
      // Use flutter_web_auth_2 for a more reliable OAuth flow
      final result = await FlutterWebAuth2.authenticate(
        url: authUrl,
        callbackUrlScheme: _callbackUrlScheme,
      );

      return Uri.parse(result);
    } catch (e) {
      // Fallback to url_launcher if flutter_web_auth_2 fails
      if (await canLaunchUrl(Uri.parse(authUrl))) {
        await launchUrl(
          Uri.parse(authUrl),
          mode: LaunchMode.externalApplication,
        );
        // Note: When using url_launcher, we rely on deep linking to handle the callback
        // The callback will be handled by our deep link handler
        throw Exception('Authentication flow started in external browser');
      }

      throw Exception('Could not launch authentication URL');
    }
  }

  /// Launches a URL in the default browser
  Future<void> launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    } else {
      throw Exception('Could not launch $url');
    }
  }
}
