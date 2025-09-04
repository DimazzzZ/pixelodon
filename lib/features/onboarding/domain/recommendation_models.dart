import 'package:freezed_annotation/freezed_annotation.dart';
import 'instance_caps.dart';

part 'recommendation_models.freezed.dart';
part 'recommendation_models.g.dart';

/// User preferences collected during onboarding
@freezed
class OnboardingPreferences with _$OnboardingPreferences {
  const factory OnboardingPreferences({
    /// Primary languages (from device locale or user selection)
    @Default([]) List<String> languages,
    
    /// Content focus preference
    @Default(InstanceFocus.both) InstanceFocus focus,
    
    /// Moderation style preference
    @Default(ModerationStyle.balanced) ModerationStyle moderation,
    
    /// Whether user prefers open registration instances
    @Default(true) bool preferOpenRegistration,
    
    /// Whether user has completed the quick quiz
    @Default(false) bool hasCompletedQuiz,
    
    /// Timestamp when preferences were set
    DateTime? createdAt,
  }) = _OnboardingPreferences;

  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) =>
      _$OnboardingPreferencesFromJson(json);
}

/// Recommended instance with score and reasoning
@freezed
class InstanceRecommendation with _$InstanceRecommendation {
  const factory InstanceRecommendation({
    /// The instance capabilities
    required InstanceCaps instance,
    
    /// Recommendation score (0-150)
    required double score,
    
    /// Reasons why this instance was recommended
    required List<RecommendationReason> reasons,
    
    /// Badges to display for this instance
    @Default([]) List<InstanceBadge> badges,
    
    /// Whether this is a featured/priority recommendation
    @Default(false) bool isFeatured,
  }) = _InstanceRecommendation;

  factory InstanceRecommendation.fromJson(Map<String, dynamic> json) =>
      _$InstanceRecommendationFromJson(json);
}

/// Reasons for recommending an instance
@freezed
class RecommendationReason with _$RecommendationReason {
  const factory RecommendationReason({
    /// Type of reason
    required RecommendationReasonType type,
    
    /// Human-readable description
    required String description,
    
    /// Weight/importance of this reason (0-10)
    @Default(5) int weight,
  }) = _RecommendationReason;

  factory RecommendationReason.fromJson(Map<String, dynamic> json) =>
      _$RecommendationReasonFromJson(json);
}

/// Types of recommendation reasons
enum RecommendationReasonType {
  @JsonValue('language_match')
  languageMatch,
  @JsonValue('focus_match')
  focusMatch,
  @JsonValue('moderation_match')
  moderationMatch,
  @JsonValue('open_registration')
  openRegistration,
  @JsonValue('low_load')
  lowLoad,
  @JsonValue('active_community')
  activeCommunity,
  @JsonValue('regional_proximity')
  regionalProximity,
  @JsonValue('platform_preference')
  platformPreference,
  @JsonValue('photo_focused')
  photoFocused,
  @JsonValue('well_moderated')
  wellModerated,
}

/// Instance badges to display
enum InstanceBadge {
  @JsonValue('open_registration')
  openRegistration,
  @JsonValue('low_load')
  lowLoad,
  @JsonValue('mastodon')
  mastodon,
  @JsonValue('pixelfed')
  pixelfed,
  @JsonValue('photo_focused')
  photoFocused,
  @JsonValue('multilingual')
  multilingual,
  @JsonValue('strict_moderation')
  strictModeration,
  @JsonValue('balanced_moderation')
  balancedModeration,
  @JsonValue('free_moderation')
  freeModeration,
  @JsonValue('large_community')
  largeCommunity,
  @JsonValue('growing_community')
  growingCommunity,
  @JsonValue('new_instance')
  newInstance,
}

/// Filter options for manual instance picker
@freezed
class InstanceFilter with _$InstanceFilter {
  const factory InstanceFilter({
    /// Filter by platform
    InstancePlatform? platform,
    
    /// Filter by open registration
    bool? openRegistration,
    
    /// Filter by languages
    @Default([]) List<String> languages,
    
    /// Filter by moderation style
    ModerationStyle? moderation,
    
    /// Filter by region
    String? region,
    
    /// Filter by photo focus
    bool? photoFocused,
    
    /// Minimum number of active users
    int? minActiveUsers,
    
    /// Maximum number of active users
    int? maxActiveUsers,
    
    /// Maximum load score
    double? maxLoadScore,
    
    /// Search query for name/description
    String? searchQuery,
  }) = _InstanceFilter;

  factory InstanceFilter.fromJson(Map<String, dynamic> json) =>
      _$InstanceFilterFromJson(json);
}

/// Sort options for instance lists
enum InstanceSortOrder {
  @JsonValue('recommended')
  recommended,
  @JsonValue('alphabetical')
  alphabetical,
  @JsonValue('user_count')
  userCount,
  @JsonValue('load_score')
  loadScore,
  @JsonValue('newest')
  newest,
}

/// Onboarding flow state
@freezed
class OnboardingState with _$OnboardingState {
  const factory OnboardingState({
    /// Current step in the onboarding flow
    @Default(OnboardingStep.welcome) OnboardingStep currentStep,
    
    /// User preferences
    OnboardingPreferences? preferences,
    
    /// Current recommendations
    @Default([]) List<InstanceRecommendation> recommendations,
    
    /// Whether recommendations are being loaded
    @Default(false) bool isLoadingRecommendations,
    
    /// Error message if recommendation loading failed
    String? recommendationError,
    
    /// Selected instance for account creation
    InstanceCaps? selectedInstance,
    
    /// Whether instance discovery is in progress
    @Default(false) bool isDiscoveringInstance,
    
    /// Discovery error message
    String? discoveryError,
    
    /// Manual instance input (domain)
    String? manualInstanceDomain,
    
    /// Current filter settings for manual picker
    @Default(InstanceFilter()) InstanceFilter filter,
    
    /// Sort order for manual picker
    @Default(InstanceSortOrder.recommended) InstanceSortOrder sortOrder,
    
    /// All available instances for manual selection
    @Default([]) List<InstanceCaps> allInstances,
    
    /// Whether all instances are being loaded
    @Default(false) bool isLoadingAllInstances,
  }) = _OnboardingState;

  factory OnboardingState.fromJson(Map<String, dynamic> json) =>
      _$OnboardingStateFromJson(json);
}

/// Steps in the onboarding flow
enum OnboardingStep {
  welcome,
  quickQuiz,
  recommendations,
  manualPicker,
  instanceSelected,
  creatingAccount,
  completed,
}

/// Extension methods for OnboardingPreferences
extension OnboardingPreferencesExtension on OnboardingPreferences {
  /// Create default preferences from device locale
  static OnboardingPreferences fromDeviceLocale(String? deviceLanguage) {
    final languages = deviceLanguage != null ? [deviceLanguage] : <String>[];
    return OnboardingPreferences(
      languages: languages,
      createdAt: DateTime.now(),
    );
  }
  
  /// Check if preferences are complete enough for recommendations
  bool get isComplete {
    return languages.isNotEmpty || hasCompletedQuiz;
  }
}

/// Extension methods for InstanceRecommendation
extension InstanceRecommendationExtension on InstanceRecommendation {
  /// Get display badges based on instance capabilities
  List<InstanceBadge> get displayBadges {
    final badges = <InstanceBadge>[];
    
    // Platform badges
    switch (instance.platform) {
      case InstancePlatform.mastodon:
        badges.add(InstanceBadge.mastodon);
        break;
      case InstancePlatform.pixelfed:
        badges.add(InstanceBadge.pixelfed);
        break;
      case InstancePlatform.unknown:
        break;
    }
    
    // Registration badge
    if (instance.openRegistration) {
      badges.add(InstanceBadge.openRegistration);
    }
    
    // Load badge
    if (instance.loadScore < 30) {
      badges.add(InstanceBadge.lowLoad);
    }
    
    // Photo focus badge
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
    if (instance.activeUsers > 10000) {
      badges.add(InstanceBadge.largeCommunity);
    } else if (instance.activeUsers > 1000 && instance.activeUsers < 5000) {
      badges.add(InstanceBadge.growingCommunity);
    } else if (instance.activeUsers < 500) {
      badges.add(InstanceBadge.newInstance);
    }
    
    return badges;
  }
  
  /// Get primary reason for recommendation (highest weight)
  RecommendationReason? get primaryReason {
    if (reasons.isEmpty) return null;
    return reasons.reduce((a, b) => a.weight > b.weight ? a : b);
  }
}
