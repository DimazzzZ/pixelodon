import 'dart:collection';

class FollowCountsCacheEntry {
  final int followers;
  final int following;
  final DateTime fetchedAt;
  FollowCountsCacheEntry({required this.followers, required this.following, required this.fetchedAt});
}

/// In-memory TTL cache for account follow counts (followers/following)
/// Because official endpoints provide wrong count info
class AccountFollowCountsCache {
  final Map<String, FollowCountsCacheEntry> _cache = HashMap();
  final Duration ttl;

  AccountFollowCountsCache({Duration? ttl}) : ttl = ttl ?? const Duration(hours: 1);

  String _key(String domain, String accountId) => '$domain|$accountId';

  FollowCountsCacheEntry? getFresh(String domain, String accountId) {
    final key = _key(domain, accountId);
    final entry = _cache[key];
    if (entry == null) return null;
    final isFresh = DateTime.now().difference(entry.fetchedAt) < ttl;
    return isFresh ? entry : null;
  }

  void set(String domain, String accountId, {required int followers, required int following}) {
    final key = _key(domain, accountId);
    _cache[key] = FollowCountsCacheEntry(
      followers: followers,
      following: following,
      fetchedAt: DateTime.now(),
    );
  }

  void clear(String domain, String accountId) {
    _cache.remove(_key(domain, accountId));
  }

  void clearAll() {
    _cache.clear();
  }
}
