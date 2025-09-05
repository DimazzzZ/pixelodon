import 'package:dio/dio.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'discovery_repository.g.dart';

/// Repository for discovering and fetching instance capabilities
@riverpod
DiscoveryRepository discoveryRepository(DiscoveryRepositoryRef ref) {
  return DiscoveryRepository();
}

class DiscoveryRepository {
  final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {
        'User-Agent': 'Pixelodon/1.0.0',
      },
    ),
  );

  /// Discover instance capabilities by domain
  Future<InstanceCaps> discoverInstance(String domain) async {
    // Clean up the domain
    final cleanDomain = _cleanDomain(domain);
    
    try {
      // Try nodeinfo discovery first
      final nodeInfoCaps = await _tryNodeInfoDiscovery(cleanDomain);
      if (nodeInfoCaps != null) {
        return nodeInfoCaps;
      }
    } catch (e) {
      // Fall back to API discovery
    }

    try {
      // Try Mastodon API discovery
      final mastodonCaps = await _tryMastodonApiDiscovery(cleanDomain);
      if (mastodonCaps != null) {
        return mastodonCaps;
      }
    } catch (e) {
      // Fall back to Pixelfed API discovery
    }

    try {
      // Try Pixelfed API discovery
      final pixelfedCaps = await _tryPixelfedApiDiscovery(cleanDomain);
      if (pixelfedCaps != null) {
        return pixelfedCaps;
      }
    } catch (e) {
      // Final fallback
    }

    // Return basic instance if all discovery methods fail
    return InstanceCaps(
      domain: cleanDomain,
      platform: InstancePlatform.unknown,
      openRegistration: false,
      maxMediaPerPost: 4,
      moderationStyle: ModerationStyle.balanced,
      loadScore: 50.0,
      title: cleanDomain,
      description: 'Instance details could not be determined',
    );
  }

  /// Try to discover instance capabilities using nodeinfo
  Future<InstanceCaps?> _tryNodeInfoDiscovery(String domain) async {
    try {
      // Step 1: Get nodeinfo discovery document
      final wellKnownResponse = await _dio.get(
        'https://$domain/.well-known/nodeinfo',
      );
      
      final wellKnownData = wellKnownResponse.data as Map<String, dynamic>;
      final links = wellKnownData['links'] as List?;
      
      if (links == null || links.isEmpty) return null;

      // Find the highest version nodeinfo schema
      String? nodeInfoUrl;
      for (final link in links.reversed) {
        if (link is Map<String, dynamic>) {
          final rel = link['rel'] as String?;
          if (rel != null && 
              (rel.contains('nodeinfo/2.1') || rel.contains('nodeinfo/2.0'))) {
            nodeInfoUrl = link['href'] as String?;
            break;
          }
        }
      }

      if (nodeInfoUrl == null) return null;

      // Step 2: Get actual nodeinfo data
      final nodeInfoResponse = await _dio.get(nodeInfoUrl);
      final nodeInfoData = nodeInfoResponse.data as Map<String, dynamic>;
      
      return _parseNodeInfoData(domain, nodeInfoData);
    } catch (e) {
      return null;
    }
  }

  /// Try to discover instance capabilities using Mastodon API
  Future<InstanceCaps?> _tryMastodonApiDiscovery(String domain) async {
    try {
      // Try v2 API first, then fall back to v1
      Response? instanceResponse;
      
      try {
        instanceResponse = await _dio.get('https://$domain/api/v2/instance');
      } catch (e) {
        instanceResponse = await _dio.get('https://$domain/api/v1/instance');
      }

      final instanceData = instanceResponse.data as Map<String, dynamic>;
      return _parseMastodonInstanceData(domain, instanceData);
    } catch (e) {
      return null;
    }
  }

  /// Try to discover instance capabilities using Pixelfed API  
  Future<InstanceCaps?> _tryPixelfedApiDiscovery(String domain) async {
    try {
      final instanceResponse = await _dio.get(
        'https://$domain/api/v1/instance',
      );
      
      final instanceData = instanceResponse.data as Map<String, dynamic>;
      return _parsePixelfedInstanceData(domain, instanceData);
    } catch (e) {
      return null;
    }
  }

  /// Parse nodeinfo data into InstanceCaps
  InstanceCaps _parseNodeInfoData(String domain, Map<String, dynamic> data) {
    final software = data['software'] as Map<String, dynamic>?;
    final softwareName = software?['name'] as String? ?? 'unknown';
    final platform = _determinePlatform(softwareName);
    
    final metadata = data['metadata'] as Map<String, dynamic>? ?? {};
    final usage = data['usage'] as Map<String, dynamic>? ?? {};
    final users = usage['users'] as Map<String, dynamic>? ?? {};
    final activeUsers = users['activeMonth'] as int? ?? 
                       users['total'] as int? ?? 0;

    // Check for stories support in features
    final features = metadata['features'] as List?;
    final supportsStories = features?.contains('stories') ?? false;

    // Parse languages
    final languages = <String>[];
    final nodeLanguages = metadata['languages'] as List?;
    if (nodeLanguages != null) {
      languages.addAll(nodeLanguages.cast<String>());
    }

    // Determine moderation style (basic heuristic)
    final moderationStyle = _determineModerationStyle(metadata);
    
    // Registration status
    final openRegistration = data['openRegistrations'] as bool? ?? false;

    // Load score estimation based on user count
    final loadScore = _estimateLoadScore(activeUsers);

    return InstanceCaps(
      domain: domain,
      platform: platform,
      openRegistration: openRegistration,
      maxMediaPerPost: platform == InstancePlatform.pixelfed ? 20 : 4,
      supportsStories: supportsStories,
      languages: languages,
      moderationStyle: moderationStyle,
      loadScore: loadScore,
      title: data['metadata']?['nodeName'] as String? ?? domain,
      description: data['metadata']?['nodeDescription'] as String? ?? '',
      thumbnail: data['metadata']?['thumbnail'] as String?,
      activeUsers: activeUsers,
    );
  }

  /// Parse Mastodon instance data into InstanceCaps
  InstanceCaps _parseMastodonInstanceData(String domain, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? domain;
    final description = data['short_description'] as String? ?? 
                       data['description'] as String? ?? '';
    final languages = (data['languages'] as List?)?.cast<String>() ?? <String>[];
    final registrations = data['registrations'] as bool? ?? false;
    
    // Parse stats
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final userCount = stats['user_count'] as int? ?? 0;
    final loadScore = _estimateLoadScore(userCount);

    // Parse configuration for max media
    final configuration = data['configuration'] as Map<String, dynamic>? ?? {};
    final statuses = configuration['statuses'] as Map<String, dynamic>? ?? {};
    final maxMediaAttachments = statuses['max_media_attachments'] as int? ?? 4;

    return InstanceCaps(
      domain: domain,
      platform: InstancePlatform.mastodon,
      openRegistration: registrations,
      maxMediaPerPost: maxMediaAttachments,
      languages: languages,
      moderationStyle: ModerationStyle.balanced, // Default for Mastodon
      loadScore: loadScore,
      title: title,
      description: description,
      thumbnail: data['thumbnail'] as String?,
      activeUsers: userCount,
    );
  }

  /// Parse Pixelfed instance data into InstanceCaps
  InstanceCaps _parsePixelfedInstanceData(String domain, Map<String, dynamic> data) {
    final title = data['title'] as String? ?? domain;
    final description = data['short_description'] as String? ?? 
                       data['description'] as String? ?? '';
    final languages = (data['languages'] as List?)?.cast<String>() ?? <String>[];
    final registrations = data['registrations'] as bool? ?? false;
    
    // Parse stats
    final stats = data['stats'] as Map<String, dynamic>? ?? {};
    final userCount = stats['user_count'] as int? ?? 0;
    final loadScore = _estimateLoadScore(userCount);

    return InstanceCaps(
      domain: domain,
      platform: InstancePlatform.pixelfed,
      openRegistration: registrations,
      maxMediaPerPost: 20, // Pixelfed default
      supportsStories: true, // Pixelfed supports stories
      languages: languages,
      moderationStyle: ModerationStyle.balanced, // Default for Pixelfed
      loadScore: loadScore,
      title: title,
      description: description,
      thumbnail: data['thumbnail'] as String?,
      activeUsers: userCount,
      photoFocused: true, // Pixelfed is photo-focused
    );
  }

  /// Determine platform from software name
  InstancePlatform _determinePlatform(String softwareName) {
    final lowerName = softwareName.toLowerCase();
    if (lowerName.contains('mastodon')) {
      return InstancePlatform.mastodon;
    } else if (lowerName.contains('pixelfed')) {
      return InstancePlatform.pixelfed;
    }
    return InstancePlatform.unknown;
  }

  /// Determine moderation style from metadata (basic heuristic)
  ModerationStyle _determineModerationStyle(Map<String, dynamic> metadata) {
    // This is a simple heuristic - in practice, this would need more sophisticated analysis
    final nodeDescription = metadata['nodeDescription'] as String? ?? '';
    final lowerDesc = nodeDescription.toLowerCase();
    
    if (lowerDesc.contains('strict') || lowerDesc.contains('family-friendly') || 
        lowerDesc.contains('moderated')) {
      return ModerationStyle.stricter;
    } else if (lowerDesc.contains('free speech') || lowerDesc.contains('minimal moderation')) {
      return ModerationStyle.freer;
    }
    
    return ModerationStyle.balanced;
  }

  /// Estimate load score based on user count
  double _estimateLoadScore(int userCount) {
    if (userCount < 1000) return 10.0;
    if (userCount < 5000) return 20.0;
    if (userCount < 10000) return 30.0;
    if (userCount < 50000) return 40.0;
    if (userCount < 100000) return 50.0;
    return 60.0; // Large instances
  }

  /// Clean up domain input
  String _cleanDomain(String domain) {
    // Remove protocol if present
    domain = domain.replaceAll(RegExp(r'https?://'), '');
    // Remove trailing slash
    domain = domain.replaceAll(RegExp(r'/$'), '');
    // Handle @user@domain format
    if (domain.contains('@')) {
      final parts = domain.split('@');
      if (parts.length >= 2) {
        domain = parts.last;
      }
    }
    return domain.toLowerCase().trim();
  }

  /// Validate that a domain is reachable
  Future<bool> validateDomain(String domain) async {
    try {
      final cleanDomain = _cleanDomain(domain);
      await _dio.get('https://$cleanDomain', 
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Dispose resources
  void dispose() {
    _dio.close();
  }
}
