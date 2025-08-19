import 'package:dio/dio.dart';

import '../../../core/models/caps.dart';
import '../../../core/models/media.dart';
import '../../../core/models/post.dart';
import '../../../core/models/story.dart';
import '../../../core/models/timeline.dart';
import '../../../core/result.dart';
import '../api_client.dart';

/// Pixelfed is partially Mastodon-compatible but adds albums (up to 20) and stories.
class PixelfedApi {
  PixelfedApi({required this.baseUrl, required this.accessToken}) {
    dio = createDio(baseUrl: baseUrl, accessToken: accessToken);
  }

  final String baseUrl;
  final String accessToken;
  late final Dio dio;

  Future<Result<InstanceCaps>> fetchInstanceCaps() async {
    try {
      // Attempt to read nodeinfo to detect stories/albums capability
      // Fallback to Mastodon-like defaults if not available.
      final node = await dio.get('/.well-known/nodeinfo');
      bool supportsStories = false;
      int maxMediaPerPost = 20;
      bool supportsAlbums = true;
      bool supportsDMs = false;
      Map<String, dynamic> rateLimits = const {};
      if (node.data is Map<String, dynamic>) {
        final links = (node.data['links'] as List?)?.cast<Map<String, dynamic>>();
        final url = links?.firstWhere(
          (e) => (e['rel'] as String?)?.contains('nodeinfo') ?? false,
          orElse: () => const {},
        )['href'] as String?;
        if (url != null) {
          final info = await Dio(BaseOptions()).get(url);
          final sw = info.data as Map<String, dynamic>;
          final metadata = sw['metadata'] as Map<String, dynamic>? ?? const {};
          supportsStories = (metadata['stories'] as bool?) ?? false;
          supportsDMs = (metadata['dms'] as bool?) ?? false;
          rateLimits = sw['rateLimits'] as Map<String, dynamic>? ?? const {};
        }
      }
      return Ok(
        InstanceCaps(
          supportsStories: supportsStories,
          maxMediaPerPost: maxMediaPerPost,
          supportsAlbums: supportsAlbums,
          supportsDMs: supportsDMs,
          rateLimits: rateLimits,
        ),
      );
    } catch (e) {
      return Err(AppError(AppErrorType.network, cause: e));
    }
  }

  Future<Result<Timeline>> getHomeTimeline({String? maxId}) async {
    try {
      // Pixelfed supports Mastodon-compatible timeline endpoints mostly
      final resp = await dio.get('/api/v1/timelines/home', queryParameters: {
        if (maxId != null) 'max_id': maxId,
        'limit': 40,
      });
      final list = (resp.data as List).cast<Map<String, dynamic>>();
      final posts = list.map(_mapObjectToPost).toList();
      return Ok(Timeline(items: posts));
    } catch (e) {
      return Err(AppError(AppErrorType.network, cause: e));
    }
  }

  Post _mapObjectToPost(Map<String, dynamic> obj) {
    // Pixelfed may return either Mastodon-like status or photo/album objects.
    final attachments = (obj['media_attachments'] as List? ?? obj['media'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapMedia)
        .toList();
    final kind = attachments.length > 1
        ? PostKind.album
        : attachments.isNotEmpty
            ? PostKind.photo
            : PostKind.text;
    return Post(
      id: obj['id'].toString(),
      authorId: (obj['account'] as Map<String, dynamic>? ?? obj['author'] as Map<String, dynamic>? ?? const {})['id']?.toString() ?? '',
      createdAt: DateTime.tryParse(obj['created_at'] as String? ?? obj['published'] as String? ?? '') ?? DateTime.now(),
      text: obj['content'] as String? ?? obj['caption'] as String?,
      kind: kind,
      media: attachments,
      contentWarning: obj['spoiler_text'] as String?,
      replyCount: obj['replies_count'] as int? ?? 0,
      reblogCount: obj['reblogs_count'] as int? ?? 0,
      likeCount: obj['favourites_count'] as int? ?? obj['likes_count'] as int? ?? 0,
      visibility: obj['visibility'] as String? ?? 'public',
      raw: obj,
    );
  }

  Media _mapMedia(Map<String, dynamic> m) {
    final typeStr = (m['type'] as String?) ?? (m['media_type'] as String?) ?? 'image';
    final type = typeStr == 'video' ? MediaType.video : MediaType.image;
    return Media(
      id: m['id'].toString(),
      url: m['url'] as String? ?? m['original_url'] as String? ?? '',
      previewUrl: m['preview_url'] as String? ?? m['thumbnail_url'] as String?,
      alt: m['description'] as String? ?? m['alt'] as String?,
      type: type,
      exif: m['exif'] as Map<String, dynamic>?,
      raw: m,
    );
  }

  Future<Result<List<Story>>> getStories() async {
    try {
      final resp = await dio.get('/api/pixelfed/v1/stories');
      final list = (resp.data as List).cast<Map<String, dynamic>>();
      final stories = list.map((e) {
        final media = _mapMedia((e['media'] as Map<String, dynamic>));
        return Story(
          id: e['id'].toString(),
          authorId: (e['author'] as Map<String, dynamic>)['id'].toString(),
          media: media,
          expiresAt: DateTime.parse(e['expires_at'] as String),
          raw: e,
        );
      }).toList();
      return Ok(stories);
    } catch (e) {
      return Err(AppError(AppErrorType.network, cause: e));
    }
  }
}

