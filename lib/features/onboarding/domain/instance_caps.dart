import 'package:freezed_annotation/freezed_annotation.dart';

part 'instance_caps.freezed.dart';
part 'instance_caps.g.dart';

/// Represents the capabilities and characteristics of a Fediverse instance
@freezed
class InstanceCaps with _$InstanceCaps {
  const factory InstanceCaps({
    /// The domain name of the instance
    required String domain,
    
    /// Platform type (mastodon, pixelfed)
    required InstancePlatform platform,
    
    /// Whether the instance accepts new registrations
    required bool openRegistration,
    
    /// Maximum number of media attachments per post
    required int maxMediaPerPost,
    
    /// Whether the instance supports stories
    @Default(false) bool supportsStories,
    
    /// Primary languages supported by the instance
    @Default([]) List<String> languages,
    
    /// Moderation style of the instance
    required ModerationStyle moderationStyle,
    
    /// Load score (0-100, lower is better performance)
    required double loadScore,
    
    /// Instance title/name
    @Default('') String title,
    
    /// Instance description
    @Default('') String description,
    
    /// Number of active users
    @Default(0) int activeUsers,
    
    /// Instance region/location
    @Default('') String region,
    
    /// Whether this instance focuses on photos/media
    @Default(false) bool photoFocused,
    
    /// Instance rules/policies summary
    @Default([]) List<String> rules,
  }) = _InstanceCaps;

  factory InstanceCaps.fromJson(Map<String, dynamic> json) =>
      _$InstanceCapsFromJson(json);
}

/// Platform types supported
enum InstancePlatform {
  @JsonValue('mastodon')
  mastodon,
  @JsonValue('pixelfed')
  pixelfed,
  @JsonValue('unknown')
  unknown,
}

/// Moderation styles
enum ModerationStyle {
  @JsonValue('stricter')
  stricter,
  @JsonValue('balanced')
  balanced,
  @JsonValue('freer')
  freer,
}

/// Extension methods for InstanceCaps
extension InstanceCapsExtension on InstanceCaps {
  /// Get default max media per post based on platform
  int get defaultMaxMedia {
    switch (platform) {
      case InstancePlatform.mastodon:
        return 4;
      case InstancePlatform.pixelfed:
        return 20;
      case InstancePlatform.unknown:
        return 4;
    }
  }
  
  /// Check if instance matches user preferences
  bool matchesPreferences({
    List<String>? preferredLanguages,
    InstanceFocus? focus,
    ModerationStyle? moderationPreference,
  }) {
    // Language match
    if (preferredLanguages != null && preferredLanguages.isNotEmpty) {
      final hasLanguageMatch = preferredLanguages.any(
        (lang) => languages.contains(lang),
      );
      if (!hasLanguageMatch && languages.isNotEmpty) {
        return false;
      }
    }
    
    // Focus match
    if (focus != null) {
      switch (focus) {
        case InstanceFocus.photos:
          if (!photoFocused && platform != InstancePlatform.pixelfed) {
            return false;
          }
          break;
        case InstanceFocus.text:
          if (photoFocused || platform == InstancePlatform.pixelfed) {
            return false;
          }
          break;
        case InstanceFocus.both:
          // Both is always acceptable
          break;
      }
    }
    
    // Moderation match (exact match preferred, but not required)
    if (moderationPreference != null && 
        moderationStyle != moderationPreference) {
      // Still acceptable, just lower score
    }
    
    return true;
  }
  
  /// Calculate recommendation score based on preferences
  double calculateScore({
    List<String>? preferredLanguages,
    InstanceFocus? focus,
    ModerationStyle? moderationPreference,
    bool preferOpenRegistration = true,
  }) {
    double score = 100.0; // Start with perfect score
    
    // Penalize if registration is closed and user wants open registration
    if (preferOpenRegistration && !openRegistration) {
      score -= 30;
    }
    
    // Reward open registration
    if (openRegistration) {
      score += 10;
    }
    
    // Load score penalty (higher load = lower score)
    score -= loadScore * 0.3;
    
    // Language bonus
    if (preferredLanguages != null && preferredLanguages.isNotEmpty) {
      final languageMatches = preferredLanguages.where(
        (lang) => languages.contains(lang),
      ).length;
      score += languageMatches * 15;
    }
    
    // Focus bonus
    if (focus != null) {
      switch (focus) {
        case InstanceFocus.photos:
          if (photoFocused || platform == InstancePlatform.pixelfed) {
            score += 20;
          }
          break;
        case InstanceFocus.text:
          if (!photoFocused && platform == InstancePlatform.mastodon) {
            score += 20;
          }
          break;
        case InstanceFocus.both:
          score += 10; // Moderate bonus for flexibility
          break;
      }
    }
    
    // Moderation style bonus
    if (moderationPreference != null && moderationStyle == moderationPreference) {
      score += 15;
    }
    
    // Active user bonus (but not too crowded)
    if (activeUsers > 100 && activeUsers < 10000) {
      score += 10;
    } else if (activeUsers >= 10000) {
      score += 5; // Still good but potentially crowded
    }
    
    return score.clamp(0, 150); // Cap the score
  }
}

/// User preference for instance focus
enum InstanceFocus {
  text,
  photos,
  both,
}
