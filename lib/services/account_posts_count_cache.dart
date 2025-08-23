import 'dart:collection';

class PostsCountCacheEntry {
  final int posts;
  final DateTime fetchedAt;
  PostsCountCacheEntry({required this.posts, required this.fetchedAt});
}

/// In-memory TTL cache for account posts count (statuses_count)
class AccountPostsCountCache {
  final Map<String, PostsCountCacheEntry> _cache = HashMap();
  final Duration ttl;

  AccountPostsCountCache({Duration? ttl}) : ttl = ttl ?? const Duration(hours: 1);

  String _key(String domain, String accountId) => '$domain|$accountId';

  PostsCountCacheEntry? getFresh(String domain, String accountId) {
    final key = _key(domain, accountId);
    final entry = _cache[key];
    if (entry == null) return null;
    final isFresh = DateTime.now().difference(entry.fetchedAt) < ttl;
    return isFresh ? entry : null;
  }

  void set(String domain, String accountId, {required int posts}) {
    final key = _key(domain, accountId);
    _cache[key] = PostsCountCacheEntry(
      posts: posts,
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
