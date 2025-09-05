import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/features/onboarding/presentation/manual_instance_picker_page.dart';
import 'package:pixelodon/providers/settings_provider.dart';

/// Sheet showing recommended instances based on user preferences
class RecommendInstancesSheet extends ConsumerWidget {
  const RecommendInstancesSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final recommendations = ref.watch(currentRecommendationsProvider);
    final isLoading = ref.watch(isOnboardingLoadingProvider);
    final error = ref.watch(onboardingErrorProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
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
          
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(
                  Icons.recommend,
                  size: 48,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'Perfect matches for you',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on your preferences, here are the best servers to get started',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _buildContent(context, ref, recommendations, isLoading, error),
          ),
          
          // Footer actions
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: PlatformTextButton(
                    onPressed: () => _showManualPicker(context, ref),
                    child: const Text('See more servers'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You can always change servers later',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    List<InstanceRecommendation> recommendations,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Finding perfect servers for you...'),
          ],
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to load recommendations',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            PlatformElevatedButton(
              onPressed: () {
                ref.read(onboardingControllerProvider.notifier).clearErrors();
                ref.read(onboardingControllerProvider.notifier).generateRecommendations();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No recommendations found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try browsing all servers manually',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            PlatformElevatedButton(
              onPressed: () => _showManualPicker(context, ref),
              child: const Text('Browse All Servers'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: recommendations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final recommendation = recommendations[index];
        return _buildRecommendationCard(context, ref, recommendation);
      },
    );
  }

  Widget _buildRecommendationCard(
    BuildContext context,
    WidgetRef ref,
    InstanceRecommendation recommendation,
  ) {
    final theme = Theme.of(context);
    final instance = recommendation.instance;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: recommendation.isFeatured
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with featured badge
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              instance.title.isNotEmpty ? instance.title : instance.domain,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (recommendation.isFeatured)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Featured',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        instance.domain,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Description
            if (instance.description.isNotEmpty) ...[
              Text(
                instance.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            
            // Primary reason
            if (recommendation.primaryReason != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation.primaryReason!.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Badges
            if (recommendation.displayBadges.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: recommendation.displayBadges.take(4).map((badge) {
                  return _buildBadge(context, badge);
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
            
            // Stats row
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatUserCount(instance.activeUsers),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.speed,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  _getLoadDescription(instance.loadScore),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: PlatformElevatedButton(
                    onPressed: () => _selectInstance(context, ref, instance),
                    child: const Text('Create Account'),
                  ),
                ),
                const SizedBox(width: 12),
                PlatformTextButton(
                  onPressed: () => _showWhySuggested(context, recommendation),
                  child: const Text('Why suggested?'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, InstanceBadge badge) {
    final theme = Theme.of(context);
    
    final badgeInfo = _getBadgeInfo(badge);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeInfo.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badgeInfo.color.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeInfo.icon,
            size: 14,
            color: badgeInfo.color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeInfo.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: badgeInfo.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  BadgeInfo _getBadgeInfo(InstanceBadge badge) {
    switch (badge) {
      case InstanceBadge.openRegistration:
        return BadgeInfo(Icons.how_to_reg, 'Open Registration', Colors.green);
      case InstanceBadge.lowLoad:
        return BadgeInfo(Icons.speed, 'Fast', Colors.blue);
      case InstanceBadge.mastodon:
        return BadgeInfo(Icons.forum, 'Mastodon', Colors.purple);
      case InstanceBadge.pixelfed:
        return BadgeInfo(Icons.photo_camera, 'Pixelfed', Colors.pink);
      case InstanceBadge.photoFocused:
        return BadgeInfo(Icons.photo, 'Photo-focused', Colors.orange);
      case InstanceBadge.multilingual:
        return BadgeInfo(Icons.language, 'Multilingual', Colors.teal);
      case InstanceBadge.strictModeration:
        return BadgeInfo(Icons.shield, 'Well-moderated', Colors.indigo);
      case InstanceBadge.balancedModeration:
        return BadgeInfo(Icons.balance, 'Balanced', Colors.grey);
      case InstanceBadge.freeModeration:
        return BadgeInfo(Icons.forum, 'Free Expression', Colors.amber);
      case InstanceBadge.largeCommunity:
        return BadgeInfo(Icons.people, 'Large Community', Colors.red);
      case InstanceBadge.growingCommunity:
        return BadgeInfo(Icons.trending_up, 'Growing', Colors.lightGreen);
      case InstanceBadge.newInstance:
        return BadgeInfo(Icons.new_releases, 'New', Colors.cyan);
    }
  }

  String _formatUserCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M users';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K users';
    }
    return '$count users';
  }

  String _getLoadDescription(double loadScore) {
    if (loadScore < 30) return 'Very Fast';
    if (loadScore < 50) return 'Fast';
    if (loadScore < 70) return 'Good';
    return 'Moderate';
  }

  void _selectInstance(BuildContext context, WidgetRef ref, InstanceCaps instance) async {
    ref.read(onboardingControllerProvider.notifier).selectInstance(instance);
    Navigator.of(context).pop();

    // Mark onboarding as completed
    await ref.read(onboardingCompletedProvider.notifier).setOnboardingCompleted(true);

    // Show success message and navigate to login
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected ${instance.domain}! Redirecting to login...'),
        ),
      );

      // Navigate to login screen
      context.go('/auth/login');
    }
  }

  void _showWhySuggested(BuildContext context, InstanceRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => _WhySuggestedDialog(recommendation: recommendation),
    );
  }

  void _showManualPicker(BuildContext context, WidgetRef ref) {
    Navigator.of(context).pop(); // Close current sheet
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ManualInstancePickerPage(),
      ),
    );
  }
}

class BadgeInfo {
  final IconData icon;
  final String label;
  final Color color;

  BadgeInfo(this.icon, this.label, this.color);
}

class _WhySuggestedDialog extends StatelessWidget {
  final InstanceRecommendation recommendation;

  const _WhySuggestedDialog({required this.recommendation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AlertDialog(
      title: Text('Why ${recommendation.instance.domain}?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This server was recommended because:',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            ...recommendation.reasons.map((reason) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        reason.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Text(
              'Recommendation score: ${recommendation.score.toInt()}/150',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      actions: [
        PlatformTextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
