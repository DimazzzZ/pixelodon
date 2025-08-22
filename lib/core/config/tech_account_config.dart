import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Configuration for the technical Mastodon account used by the app when
/// interacting with Mastodon APIs without a user-authenticated session
/// on that specific Mastodon instance.
class TechAccountConfig {
  /// Domain of the technical Mastodon account (e.g., mastodon.social)
  static String? get domain {
    final value = dotenv.maybeGet('TECH_MASTODON_DOMAIN');
    return _normalize(value);
  }

  /// Access token for the technical Mastodon account on [domain]
  static String? get accessToken {
    final token = dotenv.maybeGet('TECH_MASTODON_ACCESS_TOKEN');
    if (token == null || token.trim().isEmpty) return null;
    return token.trim();
  }

  /// Whether tech account config is effectively available
  static bool get isConfigured =>
      (domain != null && domain!.isNotEmpty) && (accessToken != null);

  static String? _normalize(String? d) {
    if (d == null) return null;
    final v = d.trim().toLowerCase();
    // remove protocol if provided
    if (v.startsWith('https://')) return v.substring(8);
    if (v.startsWith('http://')) return v.substring(7);
    return v;
  }
}
