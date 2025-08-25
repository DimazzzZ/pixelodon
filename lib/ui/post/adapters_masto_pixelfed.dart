
class Counts {
  int replies;
  int boosts;
  int favourites;
  Counts({required this.replies, required this.boosts, required this.favourites});
}

class Author {
  String displayName;
  String handle;
  String host;
  String avatarUrl;
  bool isVerified;
  Author({required this.displayName, required this.handle, required this.host, required this.avatarUrl, required this.isVerified});
}

class MediaThumb {
  String previewUrl;
  String type;
  String? alt;
  MediaThumb({required this.previewUrl, required this.type, this.alt});
}

class SocialPost {
  final String id;
  final Author author;
  final DateTime createdAt;
  final String htmlBody;
  final String? contentWarning;
  final List<MediaThumb> media;
  final Counts counts;
  final bool isEdited;
  final bool isSensitive;
  final String canonicalUrl;
  final String? inReplyToId;
  const SocialPost({
    required this.id,
    required this.author,
    required this.createdAt,
    required this.htmlBody,
    required this.contentWarning,
    required this.media,
    required this.counts,
    required this.isEdited,
    required this.isSensitive,
    required this.canonicalUrl,
    required this.inReplyToId,
  });
}

SocialPost fromMastodonJson(Map<String, dynamic> json) {
  final account = json['account'] as Map<String, dynamic>? ?? const {};
  final media = (json['media_attachments'] as List?)?.cast<Map>() ?? const [];
  final createdAtRaw = json['created_at'] as String?;
  final createdAt = DateTime.tryParse(createdAtRaw ?? '') ?? DateTime.now();

  return SocialPost(
    id: '${json['id']}',
    author: Author(
      displayName: (account['display_name'] as String?)?.trim().isNotEmpty == true ? account['display_name'] as String : (account['username'] as String? ?? ''),
      handle: account['acct']?.toString() ?? '',
      host: _extractHostFromAcct(account['acct']?.toString() ?? ''),
      avatarUrl: account['avatar_static']?.toString() ?? account['avatar']?.toString() ?? '',
      isVerified: (account['verified'] as bool?) ?? false,
    ),
    createdAt: createdAt,
    htmlBody: json['content']?.toString() ?? '',
    contentWarning: (json['spoiler_text']?.toString().trim().isEmpty ?? true) ? null : json['spoiler_text']?.toString(),
    media: media
        .map((m) => MediaThumb(
              previewUrl: m['preview_url']?.toString() ?? m['url']?.toString() ?? '',
              type: m['type']?.toString() ?? 'image',
              alt: m['description']?.toString(),
            ))
        .toList(),
    counts: Counts(
      replies: (json['replies_count'] as num?)?.toInt() ?? 0,
      boosts: (json['reblogs_count'] as num?)?.toInt() ?? 0,
      favourites: (json['favourites_count'] as num?)?.toInt() ?? 0,
    ),
    isEdited: (json['edited_at'] != null),
    isSensitive: (json['sensitive'] as bool?) ?? false,
    canonicalUrl: json['url']?.toString() ?? '',
    inReplyToId: json['in_reply_to_id']?.toString(),
  );
}

SocialPost fromPixelfedJson(Map<String, dynamic> json) {
  // Pixelfed mirrors Mastodon API for statuses, but fields may be missing; default safely
  return fromMastodonJson(json);
}

/// Helper to guess source by base URL; extend as needed
enum ServerKind { mastodon, pixelfed, unknown }

ServerKind guessServerKind(String baseUrl) {
  final u = baseUrl.toLowerCase();
  if (u.contains('pixelfed')) return ServerKind.pixelfed;
  if (u.contains('mastodon')) return ServerKind.mastodon;
  return ServerKind.unknown;
}

String _extractHostFromAcct(String acct) {
  if (acct.contains('@')) {
    return acct.split('@').last;
  }
  return '';
}
