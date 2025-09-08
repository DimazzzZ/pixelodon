import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/features/onboarding/presentation/recommend_instances_sheet.dart';

/// Quick quiz sheet for collecting user preferences
class QuickQuizSheet extends ConsumerStatefulWidget {
  const QuickQuizSheet({super.key});

  @override
  ConsumerState<QuickQuizSheet> createState() => _QuickQuizSheetState();
}

class _QuickQuizSheetState extends ConsumerState<QuickQuizSheet> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Quiz state
  List<String> _selectedLanguages = [];
  InstanceFocus _selectedFocus = InstanceFocus.both;
  ModerationStyle _selectedModeration = ModerationStyle.balanced;
  bool _preferOpenRegistration = true;
  
  final List<String> _popularLanguages = [
    'en', 'es', 'fr', 'de', 'ja', 'pt', 'it', 'ru', 'zh', 'ko', 'ar', 'hi'
  ];
  
  final Map<String, String> _languageNames = {
    'en': 'English',
    'es': 'Español',
    'fr': 'Français', 
    'de': 'Deutsch',
    'ja': '日本語',
    'pt': 'Português',
    'it': 'Italiano',
    'ru': 'Русский',
    'zh': '中文',
    'ko': '한국어',
    'ar': 'العربية',
    'hi': 'हिन्दी',
  };

  @override
  void initState() {
    super.initState();
    // Initialize with device language if available
    final currentPreferences = ref.read(currentOnboardingPreferencesProvider);
    if (currentPreferences != null && currentPreferences.languages.isNotEmpty) {
      _selectedLanguages = List.from(currentPreferences.languages);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(isOnboardingLoadingProvider);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 32,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Progress indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: (_currentPage + 1) / 3,
                    backgroundColor: theme.colorScheme.surfaceVariant,
                    valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  '${_currentPage + 1}/3',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (page) {
                setState(() {
                  _currentPage = page;
                });
              },
              children: [
                _buildLanguagePage(),
                _buildFocusPage(),
                _buildModerationPage(),
              ],
            ),
          ),
          
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: PlatformTextButton(
                      onPressed: isLoading ? null : _previousPage,
                      child: const Text('Back'),
                    ),
                  )
                else
                  const Expanded(child: SizedBox()),
                
                const SizedBox(width: 16),
                
                Expanded(
                  flex: 2,
                  child: PlatformElevatedButton(
                    onPressed: isLoading ? null : _handleNextOrFinish,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(_currentPage == 2 ? 'Get Servers' : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguagePage() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What languages do you speak?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This helps us find communities in your preferred languages',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _popularLanguages.length,
              itemBuilder: (context, index) {
                final languageCode = _popularLanguages[index];
                final languageName = _languageNames[languageCode] ?? languageCode;
                final isSelected = _selectedLanguages.contains(languageCode);
                
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedLanguages.remove(languageCode);
                      } else {
                        _selectedLanguages.add(languageCode);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected 
                            ? theme.colorScheme.primary 
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: isSelected 
                          ? theme.colorScheme.primary.withOpacity(0.1) 
                          : null,
                    ),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (isSelected) ...[
                            Icon(
                              Icons.check_circle,
                              size: 16,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            languageName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isSelected 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.onSurface,
                              fontWeight: isSelected 
                                  ? FontWeight.w600 
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusPage() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What interests you most?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your primary focus to find the right communities',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: Column(
              children: [
                _buildFocusOption(
                  focus: InstanceFocus.text,
                  icon: Icons.chat_bubble_outline,
                  title: 'Text & Discussions',
                  subtitle: 'Microblogging, conversations, news, and thoughts',
                ),
                const SizedBox(height: 16),
                _buildFocusOption(
                  focus: InstanceFocus.photos,
                  icon: Icons.photo_camera_outlined,
                  title: 'Photos & Media',
                  subtitle: 'Share photos, art, videos, and visual content',
                ),
                const SizedBox(height: 16),
                _buildFocusOption(
                  focus: InstanceFocus.both,
                  icon: Icons.dashboard_outlined,
                  title: 'Both',
                  subtitle: 'I want to share both text and visual content',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusOption({
    required InstanceFocus focus,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedFocus == focus;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedFocus = focus;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1) 
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildModerationPage() {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Community moderation style?',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Different communities have different approaches to content moderation',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          
          Expanded(
            child: Column(
              children: [
                _buildModerationOption(
                  moderation: ModerationStyle.stricter,
                  icon: Icons.shield_outlined,
                  title: 'Stricter',
                  subtitle: 'Well-moderated with clear community guidelines',
                ),
                const SizedBox(height: 16),
                _buildModerationOption(
                  moderation: ModerationStyle.balanced,
                  icon: Icons.balance_outlined,
                  title: 'Balanced',
                  subtitle: 'Moderate content policies with fair enforcement',
                ),
                const SizedBox(height: 16),
                _buildModerationOption(
                  moderation: ModerationStyle.freer,
                  icon: Icons.forum_outlined,
                  title: 'Freer',
                  subtitle: 'Minimal moderation with emphasis on free expression',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationOption({
    required ModerationStyle moderation,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedModeration == moderation;
    
    return InkWell(
      onTap: () {
        setState(() {
          _selectedModeration = moderation;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected 
                ? theme.colorScheme.primary 
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isSelected 
              ? theme.colorScheme.primary.withOpacity(0.1) 
              : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: isSelected 
                    ? theme.colorScheme.onPrimary 
                    : theme.colorScheme.onSurfaceVariant,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isSelected 
                          ? theme.colorScheme.primary 
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.colorScheme.primary,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleNextOrFinish() {
    if (_currentPage < 2) {
      _nextPage();
    } else {
      _finishQuiz();
    }
  }

  void _finishQuiz() async {
    // Create preferences from quiz responses
    final preferences = OnboardingPreferences(
      languages: _selectedLanguages,
      focus: _selectedFocus,
      moderation: _selectedModeration,
      preferOpenRegistration: _preferOpenRegistration,
      hasCompletedQuiz: true,
      createdAt: DateTime.now(),
    );
    
    // Update preferences in controller
    ref.read(onboardingControllerProvider.notifier).updatePreferences(preferences);
    
    // Generate recommendations
    await ref.read(onboardingControllerProvider.notifier).generateRecommendations();
    
    // Close current sheet and show recommendations
    if (mounted) {
      Navigator.of(context).pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const RecommendInstancesSheet(),
      );
    }
  }
}
