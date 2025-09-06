import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/services/browser_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

/// Full-page manual instance picker with filtering and search
class ManualInstancePickerPage extends ConsumerStatefulWidget {
  const ManualInstancePickerPage({super.key});

  @override
  ConsumerState<ManualInstancePickerPage> createState() => _ManualInstancePickerPageState();
}

class _ManualInstancePickerPageState extends ConsumerState<ManualInstancePickerPage> {
  final _searchController = TextEditingController();
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    // Load instances when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(onboardingControllerProvider.notifier).showManualPicker();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instances = ref.watch(filteredInstancesProvider);
    final isLoading = ref.watch(isOnboardingLoadingProvider);
    final error = ref.watch(onboardingErrorProvider);
    final currentFilter = ref.watch(currentInstanceFilterProvider);
    final sortOrder = ref.watch(currentSortOrderProvider);

    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          title: const Text('Choose Server'),
          leading: PlatformIconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          trailingActions: [
            PlatformIconButton(
              icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
              onPressed: () {
                setState(() {
                  _showFilters = !_showFilters;
                });
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Search and filters
          _buildSearchAndFilters(context, theme, currentFilter, sortOrder),
          
          // Content
          Expanded(
            child: _buildContent(context, instances, isLoading, error),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(
    BuildContext context,
    ThemeData theme,
    InstanceFilter currentFilter,
    InstanceSortOrder sortOrder,
  ) {
    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search servers...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _updateSearch('');
                      },
                    )
                  : null,
              border: const OutlineInputBorder(),
            ),
            onChanged: _updateSearch,
          ),
        ),
        
        // Sort options (always visible)
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Text(
                'Sort by:',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: InstanceSortOrder.values.map((order) {
                      final isSelected = sortOrder == order;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(_getSortOrderLabel(order)),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref.read(onboardingControllerProvider.notifier)
                                  .updateSortOrder(order);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Filters panel (collapsible)
        if (_showFilters) _buildFiltersPanel(context, theme, currentFilter),
        
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildFiltersPanel(
    BuildContext context,
    ThemeData theme,
    InstanceFilter currentFilter,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Platform filter
          _buildFilterSection(
            title: 'Platform',
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: currentFilter.platform == null,
                  onSelected: (selected) => _updatePlatformFilter(null),
                ),
                ...InstancePlatform.values.where((p) => p != InstancePlatform.unknown).map((platform) {
                  return FilterChip(
                    label: Text(_getPlatformLabel(platform)),
                    selected: currentFilter.platform == platform,
                    onSelected: (selected) => _updatePlatformFilter(selected ? platform : null),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Registration filter
          _buildFilterSection(
            title: 'Registration',
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: currentFilter.openRegistration == null,
                  onSelected: (selected) => _updateRegistrationFilter(null),
                ),
                FilterChip(
                  label: const Text('Open Registration'),
                  selected: currentFilter.openRegistration == true,
                  onSelected: (selected) => _updateRegistrationFilter(selected ? true : null),
                ),
                FilterChip(
                  label: const Text('Closed Registration'),
                  selected: currentFilter.openRegistration == false,
                  onSelected: (selected) => _updateRegistrationFilter(selected ? false : null),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Moderation filter
          _buildFilterSection(
            title: 'Moderation Style',
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: currentFilter.moderation == null,
                  onSelected: (selected) => _updateModerationFilter(null),
                ),
                ...ModerationStyle.values.map((moderation) {
                  return FilterChip(
                    label: Text(_getModerationLabel(moderation)),
                    selected: currentFilter.moderation == moderation,
                    onSelected: (selected) => _updateModerationFilter(selected ? moderation : null),
                  );
                }),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Quick filters
          _buildFilterSection(
            title: 'Quick Filters',
            child: Wrap(
              spacing: 8,
              children: [
                FilterChip(
                  label: const Text('Photo-focused'),
                  selected: currentFilter.photoFocused == true,
                  onSelected: (selected) => _updatePhotoFocusFilter(selected ? true : null),
                ),
                FilterChip(
                  label: const Text('Fast Performance'),
                  selected: currentFilter.maxLoadScore != null && currentFilter.maxLoadScore! <= 30,
                  onSelected: (selected) => _updateLoadFilter(selected ? 30.0 : null),
                ),
                FilterChip(
                  label: const Text('Large Community'),
                  selected: currentFilter.minActiveUsers != null && currentFilter.minActiveUsers! >= 10000,
                  onSelected: (selected) => _updateUserCountFilter(selected ? 10000 : null, null),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Clear filters button
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              PlatformTextButton(
                onPressed: _clearFilters,
                child: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection({required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildContent(
    BuildContext context,
    List<InstanceCaps> instances,
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
            Text('Loading servers...'),
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
              'Failed to load servers',
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
                ref.read(onboardingControllerProvider.notifier).showManualPicker();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    if (instances.isEmpty) {
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
              'No servers found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            PlatformElevatedButton(
              onPressed: _clearFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results count
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${instances.length} server${instances.length == 1 ? '' : 's'} found',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Instance list
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: instances.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final instance = instances[index];
              return _buildInstanceCard(context, instance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInstanceCard(BuildContext context, InstanceCaps instance) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _selectInstance(context, instance),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          instance.title.isNotEmpty ? instance.title : instance.domain,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          instance.domain,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    instance.platform == InstancePlatform.pixelfed
                        ? Icons.photo_camera
                        : Icons.forum,
                    color: theme.colorScheme.primary,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Description
              if (instance.description.isNotEmpty) ...[
                Text(
                  instance.description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],

              // Server thumbnail - only show if available
              if (instance.thumbnail != null && instance.thumbnail!.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      instance.thumbnail!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        // If image fails to load, show nothing
                        return const SizedBox.shrink();
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // Stats and badges row
              Row(
                children: [
                  // Registration status
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: instance.openRegistration 
                          ? Colors.green.withOpacity(0.1)
                          : Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      instance.openRegistration ? 'Open' : 'Closed',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: instance.openRegistration ? Colors.green : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // User count
                  Text(
                    _formatUserCount(instance.activeUsers),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Load indicator
                  if (instance.loadScore < 30) ...[
                    Icon(
                      Icons.speed,
                      size: 14,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'Fast',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                      ),
                    ),
                  ],
                  
                  const Spacer(),

                  // Action buttons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlatformTextButton(
                        onPressed: () => _previewInstance(context, instance),
                        child: const Text('Preview'),
                      ),
                      const SizedBox(width: 8),
                      PlatformElevatedButton(
                        onPressed: () => _selectInstance(context, instance),
                        child: const Text('Select'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getSortOrderLabel(InstanceSortOrder order) {
    switch (order) {
      case InstanceSortOrder.recommended:
        return 'Recommended';
      case InstanceSortOrder.alphabetical:
        return 'A-Z';
      case InstanceSortOrder.userCount:
        return 'Users';
      case InstanceSortOrder.loadScore:
        return 'Performance';
      case InstanceSortOrder.newest:
        return 'Newest';
    }
  }

  String _getPlatformLabel(InstancePlatform platform) {
    switch (platform) {
      case InstancePlatform.mastodon:
        return 'Mastodon';
      case InstancePlatform.pixelfed:
        return 'Pixelfed';
      case InstancePlatform.unknown:
        return 'Unknown';
    }
  }

  String _getModerationLabel(ModerationStyle moderation) {
    switch (moderation) {
      case ModerationStyle.stricter:
        return 'Stricter';
      case ModerationStyle.balanced:
        return 'Balanced';
      case ModerationStyle.freer:
        return 'Freer';
    }
  }

  String _formatUserCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  void _updateSearch(String query) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(searchQuery: query.isEmpty ? null : query);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updatePlatformFilter(InstancePlatform? platform) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(platform: platform);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updateRegistrationFilter(bool? openRegistration) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(openRegistration: openRegistration);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updateModerationFilter(ModerationStyle? moderation) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(moderation: moderation);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updatePhotoFocusFilter(bool? photoFocused) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(photoFocused: photoFocused);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updateLoadFilter(double? maxLoadScore) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(maxLoadScore: maxLoadScore);
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _updateUserCountFilter(int? minActiveUsers, int? maxActiveUsers) {
    final currentFilter = ref.read(currentInstanceFilterProvider);
    final newFilter = currentFilter.copyWith(
      minActiveUsers: minActiveUsers,
      maxActiveUsers: maxActiveUsers,
    );
    ref.read(onboardingControllerProvider.notifier).updateFilter(newFilter);
  }

  void _clearFilters() {
    _searchController.clear();
    ref.read(onboardingControllerProvider.notifier).updateFilter(const InstanceFilter());
  }

  void _selectInstance(BuildContext context, InstanceCaps instance) async {
    Navigator.of(context).pop();

    // Start OAuth flow directly for the selected instance
    if (context.mounted) {
      _showSafeSnackBar(
        context,
        SnackBar(
          content: Text('Starting registration for ${instance.domain}...'),
        ),
      );

      await _startDirectOAuthFlow(context, instance.domain);
    }
  }

  void _previewInstance(BuildContext context, InstanceCaps instance) {
    Navigator.of(context).pop();

    // Navigate to guest mode with the specific instance
    if (context.mounted) {
      _showSafeSnackBar(
        context,
        SnackBar(
          content: Text('Previewing ${instance.domain}...'),
        ),
      );

      // Navigate to guest mode
      context.go('/guest?instance=${instance.domain}');
    }
  }

  /// Start OAuth flow directly for the selected instance
  Future<void> _startDirectOAuthFlow(BuildContext context, String domain) async {
    try {
      // Get the authorization URL from the auth repository (for registration)
      final authRepository = ref.read(authRepositoryProvider);
      final authInfo = await authRepository.startOAuthFlow(domain, forRegistration: true);

      // Launch the authorization URL in browser
      final browser = BrowserService();
      await browser.launchURL(authInfo['url']!);

      // Navigate to the callback screen to wait for the OAuth response
      if (context.mounted) {
        context.push('/oauth/callback', extra: {
          'domain': domain,
          'state': authInfo['state'],
        });
      }
    } catch (e) {
      if (context.mounted) {
        _showSafeSnackBar(
          context,
          SnackBar(
            content: Text('Failed to start registration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Safely shows a SnackBar, handling cases where ScaffoldMessenger is not available
  void _showSafeSnackBar(BuildContext context, SnackBar snackBar) {
    try {
      // Check if ScaffoldMessenger is available in the widget tree
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
      if (scaffoldMessenger != null) {
        scaffoldMessenger.showSnackBar(snackBar);
      } else {
        // Fallback: show as a dialog if no ScaffoldMessenger
        _showSnackBarAsDialog(context, snackBar);
      }
    } catch (e) {
      // If all else fails, print to debug console
      debugPrint('Could not show SnackBar: ${snackBar.content}');
    }
  }

  /// Fallback method to show SnackBar content as a dialog
  void _showSnackBarAsDialog(BuildContext context, SnackBar snackBar) {
    String message = 'Notification';
    if (snackBar.content is Text) {
      final textWidget = snackBar.content as Text;
      message = textWidget.data ?? 'Notification';
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
