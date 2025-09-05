import 'dart:io';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/features/onboarding/data/recommendation_engine.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/infra/api/discovery/discovery_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Provider for onboarding state
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  OnboardingState build() {
    // Initialize with default preferences from device locale
    final deviceLanguage = _getDeviceLanguage();
    final defaultPreferences = OnboardingPreferences(
      languages: deviceLanguage != null ? [deviceLanguage] : [],
      createdAt: DateTime.now(),
    );

    // Load persisted preferences if available
    _loadPersistedPreferences();

    return OnboardingState(
      preferences: defaultPreferences,
    );
  }

  /// Start the onboarding flow
  void startOnboarding() {
    state = state.copyWith(currentStep: OnboardingStep.welcome);
  }

  /// Move to quick quiz step
  void showQuickQuiz() {
    state = state.copyWith(currentStep: OnboardingStep.quickQuiz);
  }

  /// Update user preferences from quick quiz
  void updatePreferences(OnboardingPreferences preferences) {
    final updatedPreferences = preferences.copyWith(
      hasCompletedQuiz: true,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(preferences: updatedPreferences);

    // Persist preferences
    _persistPreferences(updatedPreferences);
  }

  /// Generate recommendations based on current preferences
  Future<void> generateRecommendations() async {
    if (state.preferences == null) return;

    state = state.copyWith(
      isLoadingRecommendations: true,
      recommendationError: null,
    );

    try {
      final engine = ref.read(recommendationEngineProvider);
      final recommendations = await engine.generateRecommendations(
        preferences: state.preferences!,
        maxResults: 3,
      );

      state = state.copyWith(
        recommendations: recommendations,
        isLoadingRecommendations: false,
        currentStep: OnboardingStep.recommendations,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingRecommendations: false,
        recommendationError: 'Failed to load recommendations. Please try again.',
      );
    }
  }

  /// Show manual instance picker
  Future<void> showManualPicker() async {
    state = state.copyWith(
      currentStep: OnboardingStep.manualPicker,
      isLoadingAllInstances: true,
    );

    try {
      final engine = ref.read(recommendationEngineProvider);
      final instances = await engine.getAllInstances(
        filter: state.filter,
        sortOrder: state.sortOrder,
        preferences: state.preferences,
      );

      state = state.copyWith(
        allInstances: instances,
        isLoadingAllInstances: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAllInstances: false,
        recommendationError: 'Failed to load instances. Please try again.',
      );
    }
  }

  /// Update filter for manual picker
  Future<void> updateFilter(InstanceFilter filter) async {
    state = state.copyWith(
      filter: filter,
      isLoadingAllInstances: true,
    );

    try {
      final engine = ref.read(recommendationEngineProvider);
      final instances = await engine.getAllInstances(
        filter: filter,
        sortOrder: state.sortOrder,
        preferences: state.preferences,
      );

      state = state.copyWith(
        allInstances: instances,
        isLoadingAllInstances: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAllInstances: false,
        recommendationError: 'Failed to filter instances. Please try again.',
      );
    }
  }

  /// Update sort order for manual picker
  Future<void> updateSortOrder(InstanceSortOrder sortOrder) async {
    state = state.copyWith(
      sortOrder: sortOrder,
      isLoadingAllInstances: true,
    );

    try {
      final engine = ref.read(recommendationEngineProvider);
      final instances = await engine.getAllInstances(
        filter: state.filter,
        sortOrder: sortOrder,
        preferences: state.preferences,
      );

      state = state.copyWith(
        allInstances: instances,
        isLoadingAllInstances: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingAllInstances: false,
        recommendationError: 'Failed to sort instances. Please try again.',
      );
    }
  }

  /// Discover instance by domain (for existing account flow)
  Future<void> discoverInstanceByDomain(String domain) async {
    state = state.copyWith(
      isDiscoveringInstance: true,
      discoveryError: null,
      manualInstanceDomain: domain,
    );

    try {
      final repository = ref.read(discoveryRepositoryProvider);
      final instance = await repository.discoverInstance(domain);
      
      state = state.copyWith(
        selectedInstance: instance,
        isDiscoveringInstance: false,
        currentStep: OnboardingStep.instanceSelected,
      );
    } catch (e) {
      state = state.copyWith(
        isDiscoveringInstance: false,
        discoveryError: 'Could not connect to instance. Please check the domain and try again.',
      );
    }
  }

  /// Select an instance for account creation
  void selectInstance(InstanceCaps instance) {
    state = state.copyWith(
      selectedInstance: instance,
      currentStep: OnboardingStep.instanceSelected,
    );
  }

  /// Start guest browsing mode
  Future<void> startGuestMode() async {
    // Set loading state
    state = state.copyWith(
      isLoadingAllInstances: true,
      recommendationError: null,
    );

    try {
      final engine = ref.read(recommendationEngineProvider);
      final guestInstances = await engine.getGuestModeInstances(count: 5);

      // For guest mode, we would typically navigate to a guest timeline
      // This would be handled by the UI layer
      state = state.copyWith(
        allInstances: guestInstances,
        currentStep: OnboardingStep.completed,
        isLoadingAllInstances: false,
      );
    } catch (e) {
      state = state.copyWith(
        recommendationError: 'Failed to load guest mode instances.',
        isLoadingAllInstances: false,
      );
    }
  }

  /// Reset onboarding state
  void reset() {
    final deviceLanguage = _getDeviceLanguage();
    final defaultPreferences = OnboardingPreferences(
      languages: deviceLanguage != null ? [deviceLanguage] : [],
      createdAt: DateTime.now(),
    );
    
    state = OnboardingState(
      preferences: defaultPreferences,
    );
  }

  /// Clear errors
  void clearErrors() {
    state = state.copyWith(
      recommendationError: null,
      discoveryError: null,
    );
  }

  /// Go back to previous step
  void goBack() {
    switch (state.currentStep) {
      case OnboardingStep.quickQuiz:
        state = state.copyWith(currentStep: OnboardingStep.welcome);
        break;
      case OnboardingStep.recommendations:
        state = state.copyWith(currentStep: OnboardingStep.quickQuiz);
        break;
      case OnboardingStep.manualPicker:
        state = state.copyWith(currentStep: OnboardingStep.recommendations);
        break;
      case OnboardingStep.instanceSelected:
        if (state.manualInstanceDomain != null) {
          // Came from manual domain entry
          state = state.copyWith(
            currentStep: OnboardingStep.welcome,
            selectedInstance: null,
            manualInstanceDomain: null,
          );
        } else {
          // Came from recommendations or manual picker
          state = state.copyWith(
            currentStep: state.allInstances.isNotEmpty 
                ? OnboardingStep.manualPicker 
                : OnboardingStep.recommendations,
            selectedInstance: null,
          );
        }
        break;
      case OnboardingStep.welcome:
      case OnboardingStep.creatingAccount:
      case OnboardingStep.completed:
        // No going back from these states
        break;
    }
  }

  /// Get device language code
  String? _getDeviceLanguage() {
    try {
      final locale = Platform.localeName;
      if (locale.isNotEmpty) {
        // Extract language code (e.g., 'en' from 'en_US')
        return locale.split('_').first.toLowerCase();
      }
    } catch (e) {
      // Fallback to system locale if Platform.localeName fails
    }
    return null;
  }

  /// Load persisted preferences from storage
  Future<void> _loadPersistedPreferences() async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      final preferencesMap = await settingsService.getOnboardingPreferences();

      if (preferencesMap != null) {
        final preferences = OnboardingPreferences.fromJson(preferencesMap);
        state = state.copyWith(preferences: preferences);
      }
    } catch (e) {
      // Ignore errors and use default preferences
    }
  }

  /// Persist preferences to storage
  Future<void> _persistPreferences(OnboardingPreferences preferences) async {
    try {
      final settingsService = ref.read(settingsServiceProvider);
      await settingsService.setOnboardingPreferences(preferences.toJson());

      // Don't mark onboarding as completed here - only when user actually logs in
    } catch (e) {
      // Ignore errors
    }
  }
}

/// Provider for quick access to current onboarding preferences
@riverpod
OnboardingPreferences? currentOnboardingPreferences(CurrentOnboardingPreferencesRef ref) {
  return ref.watch(onboardingControllerProvider).preferences;
}

/// Provider for current recommendations
@riverpod
List<InstanceRecommendation> currentRecommendations(CurrentRecommendationsRef ref) {
  return ref.watch(onboardingControllerProvider).recommendations;
}

/// Provider for current onboarding step
@riverpod
OnboardingStep currentOnboardingStep(CurrentOnboardingStepRef ref) {
  return ref.watch(onboardingControllerProvider).currentStep;
}

/// Provider for selected instance
@riverpod
InstanceCaps? selectedInstance(SelectedInstanceRef ref) {
  return ref.watch(onboardingControllerProvider).selectedInstance;
}

/// Provider for checking if onboarding is loading
@riverpod
bool isOnboardingLoading(IsOnboardingLoadingRef ref) {
  final state = ref.watch(onboardingControllerProvider);
  return state.isLoadingRecommendations || 
         state.isDiscoveringInstance || 
         state.isLoadingAllInstances;
}

/// Provider for onboarding errors
@riverpod
String? onboardingError(OnboardingErrorRef ref) {
  final state = ref.watch(onboardingControllerProvider);
  return state.recommendationError ?? state.discoveryError;
}

/// Helper provider for creating default preferences from device locale
@riverpod
OnboardingPreferences defaultOnboardingPreferences(DefaultOnboardingPreferencesRef ref) {
  String? deviceLanguage;
  try {
    final locale = Platform.localeName;
    if (locale.isNotEmpty) {
      deviceLanguage = locale.split('_').first.toLowerCase();
    }
  } catch (e) {
    // Ignore and use empty
  }
  
  return OnboardingPreferences(
    languages: deviceLanguage != null ? [deviceLanguage] : [],
    createdAt: DateTime.now(),
  );
}

/// Provider for checking if quiz is completed
@riverpod
bool isQuizCompleted(IsQuizCompletedRef ref) {
  final preferences = ref.watch(currentOnboardingPreferencesProvider);
  return preferences?.hasCompletedQuiz ?? false;
}

/// Provider for filtered instances in manual picker
@riverpod
List<InstanceCaps> filteredInstances(FilteredInstancesRef ref) {
  return ref.watch(onboardingControllerProvider).allInstances;
}

/// Provider for current instance filter
@riverpod
InstanceFilter currentInstanceFilter(CurrentInstanceFilterRef ref) {
  return ref.watch(onboardingControllerProvider).filter;
}

/// Provider for current sort order
@riverpod
InstanceSortOrder currentSortOrder(CurrentSortOrderRef ref) {
  return ref.watch(onboardingControllerProvider).sortOrder;
}
