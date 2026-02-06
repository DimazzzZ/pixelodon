import 'dart:collection';
import 'package:pixelodon/models/status.dart' as model;

/// Simple in-memory cache for account statuses with TTL
class AccountStatusesCacheEntry {
  final List<model.Status> statuses;
  final DateTime fetchedAt;
  AccountStatusesCacheEntry({required this.statuses, required this.fetchedAt});
}

class AccountStatusesCache {
  final Map<String, AccountStatusesCacheEntry> _cache = HashMap();
  final Duration ttl;

  AccountStatusesCache({Duration? ttl}) : ttl = ttl ?? const Duration(hours: 1);

  String _key(String domain, String accountId) => '$domain|$accountId';

  /// Get cached entry if fresh, else null
  AccountStatusesCacheEntry? getFresh(String domain, String accountId) {
    final key = _key(domain, accountId);
    final entry = _cache[key];
    if (entry == null) return null;
    final isFresh = DateTime.now().difference(entry.fetchedAt) < ttl;
    return isFresh ? entry : null;
    }

  /// Store or replace cache entry
  void set(String domain, String accountId, List<model.Status> statuses) {
    final key = _key(domain, accountId);
    _cache[key] = AccountStatusesCacheEntry(
      statuses: List.unmodifiable(statuses),
      fetchedAt: DateTime.now(),
    );
  }

  /// Clear specific account cache
  void clear(String domain, String accountId) {
    _cache.remove(_key(domain, accountId));
  }

  /// Clear all
  void clearAll() {
    _cache.clear();
  }
}
