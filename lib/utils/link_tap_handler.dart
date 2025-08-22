import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';

/// Centralized handler for links inside HTML content across the app.
/// Handles:
/// - Tag links (e.g., /tags/<tag>)
/// - Mention links: prefer resolving via provided mentions list when available
/// - Fallback mention resolution: parse /@username and resolve via search
class LinkTapHandler {
  static final RegExp _tagPattern = RegExp(r"/tags/([^/?#]+)");
  static final RegExp _atUserPattern = RegExp(r"/@([A-Za-z0-9_\.]+)");

  /// Handle a tapped URL from rich text/HTML.
  ///
  /// [mentions] can be provided to quickly map mention URLs to account IDs when available.
  static Future<void> handleLinkTap(
    BuildContext context,
    String? url, {
    List<Mention>? mentions,
  }) async {
    if (url == null) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    // 1) Tags: /tags/<tag>
    final tagMatch = _tagPattern.firstMatch(uri.path);
    if (tagMatch != null) {
      final tag = tagMatch.group(1)!;
      if (tag.isNotEmpty && context.mounted) {
        context.push('/tag/$tag');
      }
      return;
    }

    // 2) Mentions via provided mention list (fast path)
    if (mentions != null && mentions.isNotEmpty) {
      final matched = mentions.where((m) => m.url == url);
      if (matched.isNotEmpty) {
        final m = matched.first;
        if (m.id.isNotEmpty && context.mounted) {
          // Pass the origin host so profile screen fetches from the correct instance
          final mUri = Uri.tryParse(m.url ?? '');
          final mHost = mUri?.host;
          final qp = (mHost != null && mHost.isNotEmpty) ? '?domain=$mHost' : '';
          context.push('/profile/${m.id}$qp');
          return;
        }
      }
    }

    // 3) Fallback: parse /@username and resolve account via search
    final atPath = _atUserPattern.firstMatch(uri.path);
    if (atPath != null) {
      final username = atPath.group(1)!;
      final host = uri.host;
      final container = ProviderScope.containerOf(context);
      final active = container.read(activeInstanceProvider);
      final acct = host.isNotEmpty && host != (active?.domain ?? '') ? '$username@$host' : username;
      try {
        final accountService = container.read(accountServiceProvider);
        final results = await accountService.searchAccounts(
          active?.domain ?? host,
          query: acct,
          limit: 1,
          resolve: true,
        );
        if (results.isNotEmpty && context.mounted) {
          final acc = results.first;
          String? host;
          try {
            final u = Uri.tryParse(acc.url ?? '');
            host = u?.host;
          } catch (_) {}
          final qp = (host != null && host.isNotEmpty) ? '?domain=$host' : '';
          context.push('/profile/${acc.id}$qp');
          return;
        }
      } catch (_) {
        // Silently ignore resolution errors; we might handle externally in future.
      }
    }

    // 4) Otherwise: no-op for now. Could add external launching in future.
  }
}
