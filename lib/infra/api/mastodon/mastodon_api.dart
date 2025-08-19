import 'package:dio/dio.dart';
import 'package:collection/collection.dart';

import '../../../core/models/caps.dart';
import '../../../core/models/media.dart';
import '../../../core/models/post.dart';
import '../../../core/models/timeline.dart';
import '../../../core/result.dart';
import '../api_client.dart';

class MastodonApi {
  MastodonApi({required this.baseUrl, required this.accessToken}) {
    dio = createDio(baseUrl: baseUrl, accessToken: accessToken);
  }

  final String baseUrl;
  final String accessToken;
  late final Dio dio;

  Future<Result<InstanceCaps>> fetchInstanceCaps() async {
    try {
      final resp = await dio.get('/api/v2/instance');
      final data = resp.data as Map<String, dynamic>;
      // Mastodon standard: no stories, 4 attachments per status
      final caps = InstanceCaps(
        supportsStories: false,
        maxMediaPerPost: 4,
        supportsAlbums: false,
        supportsDMs: false,
        mediaLimits: {
          'supported_types': ['image', 'video'],
        },
        rateLimits: data['configuration'] as Map<String, dynamic>? ?? const {},
      );
      return Ok(caps);
    } catch (e) {
      return Err(AppError(AppErrorType.network, cause: e));
    }
  }

  Future<Result<Timeline>> getHomeTimeline({String? maxId}) async {
    try {
      final resp = await dio.get('/api/v1/timelines/home', queryParameters: {
        if (maxId != null) 'max_id': maxId,
        'limit': 40,
      });
      final list = (resp.data as List).cast<Map<String, dynamic>>();
      final posts = list.map(_mapStatusToPost).toList();
      return Ok(Timeline(items: posts));
    } catch (e) {
      return Err(AppError(AppErrorType.network, cause: e));
    }
  }

  Post _mapStatusToPost(Map<String, dynamic> s) {
    final attachments = (s['media_attachments'] as List? ?? [])
        .cast<Map<String, dynamic>>()
        .map(_mapAttachment)
        .toList();
    return Post(
      id: s['id'] as String,
      authorId: (s['account'] as Map<String, dynamic>)['id'] as String,
      createdAt: DateTime.parse(s['created_at'] as String),
      text: s['content'] as String?,
      kind: attachments.length > 1
          ? PostKind.album
          : attachments.isNotEmpty
              ? PostKind.photo
              : PostKind.text,
      media: attachments,
      contentWarning: s['spoiler_text'] as String?,
      replyCount: s['replies_count'] as int? ?? 0,
      reblogCount: s['reblogs_count'] as int? ?? 0,
      likeCount: s['favourites_count'] as int? ?? 0,
      visibility: s['visibility'] as String? ?? 'public',
      raw: s,
    );
  }

  Media _mapAttachment(Map<String, dynamic> a) {
    final typeStr = a['type'] as String? ?? 'image';
    final type = typeStr == 'video' ? MediaType.video : MediaType.image;
    return Media(
      id: a['id'].toString(),
      url: a['url'] as String? ?? a['remote_url'] as String? ?? '',
      previewUrl: a['preview_url'] as String?,
      alt: a['description'] as String?,
      type: type,
      raw: a,
    );
  }
}

