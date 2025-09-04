import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/infra/api/discovery/discovery_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recommendation_engine.g.dart';

/// Engine for generating instance recommendations based on user preferences
@riverpod
RecommendationEngine recommendationEngine(RecommendationEngineRef ref) {
  return RecommendationEngine(
    discoveryRepository: ref.watch(discoveryRepositoryProvider),
  );
}

class RecommendationEngine {
  final DiscoveryRepository discoveryRepository;
  
  List<InstanceCaps>? _curatedInstances;
  DateTime? _lastLoaded;
  static const Duration _cacheTimeout = Duration(hours: 6);

  RecommendationEngine({
    required this.discoveryRepository,
  });

  /// Load curated instances from assets
  Future<List<InstanceCaps>> _loadCuratedInstances() async {
    // Return cached instances if still valid
    if (_curatedInstances != null && _lastLoaded != null) {
      final age = DateTime.now().difference(_lastLoaded!);
      if (age < _cacheTimeout) {
        return _curatedInstances!;
      }
    }

    try {
      final jsonString = await rootBundle.loadString('assets/instances/curated.json');
      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      final instancesData = jsonData['instances'] as List;
      
      _curatedInstances = instancesData
          .cast<Map<String, dynamic>>()
          .map((data) => InstanceCaps.fromJson(data))
          .toList();
      
      _lastLoaded = DateTime.now();
      return _curatedInstances!;
    } catch (e) {
      // Return empty list if loading fails
      _curatedInstances = [];
      return _curatedInstances!;
    }
  }

  /// Generate recommendations based on user preferences
  Future<List<InstanceRecommendation>> generateRecommendations({
    required OnboardingPreferences preferences,
    int maxResults = 3,
  }) async {
    final instances = await _loadCuratedInstances();
    if (instances.isEmpty) return [];

    // Calculate scores and create recommendations
    final recommendations = <InstanceRecommendation>[];
    
    for (final instance in instances) {
      if (!instance.matchesPreferences(
        preferredLanguages: preferences.languages,
        focus: preferences.focus,
        moderationPreference: preferences.moderation,
      )) {
        continue; // Skip instances that don't match basic preferences
      }

      final score = instance.calculateScore(
        preferredLanguages: preferences.languages,
        focus: preferences.focus,
        moderationPreference: preferences.moderation,
        preferOpenRegistration: preferences.preferOpenRegistration,
      );

      final reasons = _generateReasons(instance, preferences, score);
      final badges = _generateBadges(instance);

      recommendations.add(InstanceRecommendation(
        instance: instance,
        score: score,
        reasons: reasons,
        badges: badges,
        isFeatured: _isFeaturedInstance(instance),
      ));
    }

    // Sort by score (descending) and take top results
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(maxResults).toList();
  }

  /// Get all instances for manual picker with filtering and sorting
  Future<List<InstanceCaps>> getAllInstances({
    InstanceFilter? filter,
    InstanceSortOrder sortOrder = InstanceSortOrder.recommended,
    OnboardingPreferences? preferences,
  }) async {
    var instances = await _loadCuratedInstances();
    
    // Apply filters
    if (filter != null) {
      instances = _applyFilters(instances, filter);
    }

    // Apply sorting
    instances = _applySorting(instances, sortOrder, preferences);

    return instances;
  }

  /// Apply filters to instance list
  List<InstanceCaps> _applyFilters(List<InstanceCaps> instances, InstanceFilter filter) {
    return instances.where((instance) {
      // Platform filter
      if (filter.platform != null && instance.platform != filter.platform) {
        return false;
      }

      // Registration filter
      if (filter.openRegistration != null && 
          instance.openRegistration != filter.openRegistration) {
        return false;
      }

      // Language filter
      if (filter.languages.isNotEmpty) {
        final hasLanguageMatch = filter.languages.any(
          (lang) => instance.languages.contains(lang),
        );
        if (!hasLanguageMatch && instance.languages.isNotEmpty) {
          return false;
        }
      }

      // Moderation filter
      if (filter.moderation != null && 
          instance.moderationStyle != filter.moderation) {
        return false;
      }

      // Region filter
      if (filter.region != null && filter.region!.isNotEmpty &&
          !instance.region.toLowerCase().contains(filter.region!.toLowerCase())) {
        return false;
      }

      // Photo focus filter
      if (filter.photoFocused != null && 
          instance.photoFocused != filter.photoFocused) {
        return false;
      }

      // User count filters
      if (filter.minActiveUsers != null && 
          instance.activeUsers < filter.minActiveUsers!) {
        return false;
      }
      
      if (filter.maxActiveUsers != null && 
          instance.activeUsers > filter.maxActiveUsers!) {
        return false;
      }

      // Load score filter
      if (filter.maxLoadScore != null && 
          instance.loadScore > filter.maxLoadScore!) {
        return false;
      }

      // Search query filter
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        final matchesTitle = instance.title.toLowerCase().contains(query);
        final matchesDescription = instance.description.toLowerCase().contains(query);
        final matchesDomain = instance.domain.toLowerCase().contains(query);
        
        if (!matchesTitle && !matchesDescription && !matchesDomain) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Apply sorting to instance list
  List<InstanceCaps> _applySorting(
    List<InstanceCaps> instances,
    InstanceSortOrder sortOrder,
    OnboardingPreferences? preferences,
  ) {
    switch (sortOrder) {
      case InstanceSortOrder.recommended:
        if (preferences != null) {
          // Sort by recommendation score
          instances.sort((a, b) {
            final scoreA = a.calculateScore(
              preferredLanguages: preferences.languages,
              focus: preferences.focus,
              moderationPreference: preferences.moderation,
              preferOpenRegistration: preferences.preferOpenRegistration,
            );
            final scoreB = b.calculateScore(
              preferredLanguages: preferences.languages,
              focus: preferences.focus,
              moderationPreference: preferences.moderation,
              preferOpenRegistration: preferences.preferOpenRegistration,
            );
            return scoreB.compareTo(scoreA);
          });
        } else {
          // Sort by load score (better performance first)
          instances.sort((a, b) => a.loadScore.compareTo(b.loadScore));
        }
        break;
        
      case InstanceSortOrder.alphabetical:
        instances.sort((a, b) => a.domain.compareTo(b.domain));
        break;
        
      case InstanceSortOrder.userCount:
        instances.sort((a, b) => b.activeUsers.compareTo(a.activeUsers));
        break;
        
      case InstanceSortOrder.loadScore:
        instances.sort((a, b) => a.loadScore.compareTo(b.loadScore));
        break;
        
      case InstanceSortOrder.newest:
        // For curated instances, we'll use activeUsers as a proxy for "newest"
        // (smaller communities are often newer)
        instances.sort((a, b) => a.activeUsers.compareTo(b.activeUsers));
        break;
    }

    return instances;
  }

  /// Generate recommendation reasons for an instance
  List<RecommendationReason> _generateReasons(
    InstanceCaps instance,
    OnboardingPreferences preferences,
    double score,
  ) {
    final reasons = <RecommendationReason>[];

    // Language match reason
    if (preferences.languages.isNotEmpty) {
      final matchingLanguages = preferences.languages.where(
        (lang) => instance.languages.contains(lang),
      );
      
      if (matchingLanguages.isNotEmpty) {
        reasons.add(RecommendationReason(
          type: RecommendationReasonType.languageMatch,
          description: 'Supports your preferred language${matchingLanguages.length > 1 ? 's' : ''}: ${matchingLanguages.join(', ')}',
          weight: 8,
        ));
      }
    }

    // Focus match reason
    switch (preferences.focus) {
      case InstanceFocus.photos:
        if (instance.photoFocused || instance.platform == InstancePlatform.pixelfed) {
          reasons.add(RecommendationReason(
            type: RecommendationReasonType.photoFocused,
            description: 'Perfect for photo sharing and visual content',
            weight: 9,
          ));
        }
        break;
      case InstanceFocus.text:
        if (!instance.photoFocused && instance.platform == InstancePlatform.mastodon) {
          reasons.add(RecommendationReason(
            type: RecommendationReasonType.focusMatch,
            description: 'Great for text-based discussions and microblogging',
            weight: 7,
          ));
        }
        break;
      case InstanceFocus.both:
        reasons.add(RecommendationReason(
          type: RecommendationReasonType.focusMatch,
          description: 'Supports both text and media content',
          weight: 6,
        ));
        break;
    }

    // Moderation style match
    if (instance.moderationStyle == preferences.moderation) {
      String description;
      switch (preferences.moderation) {
        case ModerationStyle.stricter:
          description = 'Well-moderated community with clear guidelines';
          break;
        case ModerationStyle.balanced:
          description = 'Balanced approach to community moderation';
          break;
        case ModerationStyle.freer:
          description = 'Minimal moderation with emphasis on free expression';
          break;
      }
      
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.moderationMatch,
        description: description,
        weight: 7,
      ));
    }

    // Open registration
    if (instance.openRegistration && preferences.preferOpenRegistration) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.openRegistration,
        description: 'Open for new registrations - join immediately',
        weight: 8,
      ));
    }

    // Low load/good performance
    if (instance.loadScore < 30) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.lowLoad,
        description: 'Fast and reliable performance',
        weight: 6,
      ));
    }

    // Active community
    if (instance.activeUsers > 1000 && instance.activeUsers < 50000) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.activeCommunity,
        description: 'Active community with ${_formatUserCount(instance.activeUsers)} users',
        weight: 5,
      ));
    }

    // Platform-specific reasons
    if (instance.platform == InstancePlatform.mastodon) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.platformPreference,
        description: 'Mastodon - the original fediverse microblogging platform',
        weight: 4,
      ));
    } else if (instance.platform == InstancePlatform.pixelfed) {
      reasons.add(RecommendationReason(
        type: RecommendationReasonType.platformPreference,
        description: 'Pixelfed - Instagram-like photo sharing experience',
        weight: 4,
      ));
    }

    return reasons;
  }

  /// Generate badges for an instance
  List<InstanceBadge> _generateBadges(InstanceCaps instance) {
    final badges = <InstanceBadge>[];

    // Platform badges
    if (instance.platform == InstancePlatform.mastodon) {
      badges.add(InstanceBadge.mastodon);
    } else if (instance.platform == InstancePlatform.pixelfed) {
      badges.add(InstanceBadge.pixelfed);
    }

    // Registration badge
    if (instance.openRegistration) {
      badges.add(InstanceBadge.openRegistration);
    }

    // Performance badge
    if (instance.loadScore < 30) {
      badges.add(InstanceBadge.lowLoad);
    }

    // Content focus badge
    if (instance.photoFocused) {
      badges.add(InstanceBadge.photoFocused);
    }

    // Language badge
    if (instance.languages.length > 2) {
      badges.add(InstanceBadge.multilingual);
    }

    // Moderation badges
    switch (instance.moderationStyle) {
      case ModerationStyle.stricter:
        badges.add(InstanceBadge.strictModeration);
        break;
      case ModerationStyle.balanced:
        badges.add(InstanceBadge.balancedModeration);
        break;
      case ModerationStyle.freer:
        badges.add(InstanceBadge.freeModeration);
        break;
    }

    // Community size badges
    if (instance.activeUsers > 100000) {
      badges.add(InstanceBadge.largeCommunity);
    } else if (instance.activeUsers > 5000 && instance.activeUsers < 50000) {
      badges.add(InstanceBadge.growingCommunity);
    } else if (instance.activeUsers < 1000) {
      badges.add(InstanceBadge.newInstance);
    }

    return badges;
  }

  /// Check if an instance should be featured
  bool _isFeaturedInstance(InstanceCaps instance) {
    // Feature well-known, stable instances
    const featuredDomains = {
      'mastodon.social',
      'pixelfed.social',
      'fosstodon.org',
      'mas.to',
    };
    
    return featuredDomains.contains(instance.domain);
  }

  /// Format user count for display
  String _formatUserCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  /// Refresh curated instances (force reload)
  Future<void> refreshCuratedInstances() async {
    _curatedInstances = null;
    _lastLoaded = null;
    await _loadCuratedInstances();
  }

  /// Get random sample of instances for guest mode
  Future<List<InstanceCaps>> getGuestModeInstances({int count = 5}) async {
    final instances = await _loadCuratedInstances();
    
    // Filter to safe, well-moderated instances for guest mode
    final safeInstances = instances.where((instance) =>
      instance.openRegistration &&
      instance.loadScore < 40 &&
      (instance.moderationStyle == ModerationStyle.balanced ||
       instance.moderationStyle == ModerationStyle.stricter)
    ).toList();

    // Shuffle and take requested count
    safeInstances.shuffle(Random());
    return safeInstances.take(count).toList();
  }
}
