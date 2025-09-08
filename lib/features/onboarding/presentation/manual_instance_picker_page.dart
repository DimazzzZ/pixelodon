import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/domain/instance_caps.dart';
import 'package:pixelodon/features/onboarding/domain/recommendation_models.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/services/browser_service.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/features/common/widgets/sliver_fixed_header.dart';
import 'package:pixelodon/widgets/common/server_card.dart';
import 'dart:io';

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

    return AppPageScaffold.sliver(
      largeTitle: 'Choose Server',
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.of(context).pop(),
      ),
      actions: [
        Platform.isIOS
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                minSize: 44.0,
                child: Icon(_showFilters ? CupertinoIcons.line_horizontal_3_decrease : CupertinoIcons.line_horizontal_3_decrease_circle),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              )
            : IconButton(
                icon: Icon(_showFilters ? Icons.filter_list : Icons.filter_list_outlined),
                onPressed: () {
                  setState(() {
                    _showFilters = !_showFilters;
                  });
                },
              ),
      ],
      sliverBodyBuilder: () => CustomScrollView(
        slivers: [
          _buildSearchHeader(context, theme),
          _buildChipsHeader(context, theme, currentFilter, sortOrder),
          _buildContentSliver(context, instances, isLoading, error),
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

  Widget _buildContentSliver(
    BuildContext context,
    List<InstanceCaps> instances,
    bool isLoading,
    String? error,
  ) {
    if (isLoading) {
      return SliverFillRemaining(
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading servers...'),
            ],
          ),
        ),
      );
    }

    if (error != null) {
      return SliverFillRemaining(
        child: Center(
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
        ),
      );
    }

    if (instances.isEmpty) {
      return SliverFillRemaining(
        child: Center(
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
        ),
      );
    }

    final horizontalPadding = Platform.isIOS ? 20.0 : 16.0;

    return SliverPadding(
      padding: EdgeInsets.only(
        left: horizontalPadding,
        right: horizontalPadding,
        bottom: MediaQuery.of(context).viewPadding.bottom + 8,
      ),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              // Results count header
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '${instances.length} server${instances.length == 1 ? '' : 's'} found',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              );
            }

            final instanceIndex = index - 1;
            if (instanceIndex >= instances.length) return null;

            final instance = instances[instanceIndex];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: ServerCard(
                instance: instance,
                onPreview: () => _previewInstance(context, instance),
                onJoin: () => _selectInstance(context, instance),
                primaryActionText: 'Select',
                secondaryActionText: 'Preview',
                badges: _getInstanceBadges(instance),
                maxDescriptionLines: 2,
                isFeatured: _isFlagshipInstance(instance),
              ),
            );
          },
          childCount: instances.length + 1, // +1 for the header
        ),
      ),
    );
  }

  List<InstanceBadge> _getInstanceBadges(InstanceCaps instance) {
    final badges = <InstanceBadge>[];

    if (instance.openRegistration) {
      badges.add(InstanceBadge.openRegistration);
    }

    // Add community size badges
    if (instance.activeUsers > 50000) {
      badges.add(InstanceBadge.largeCommunity);
    } else if (instance.activeUsers > 10000) {
      badges.add(InstanceBadge.growingCommunity);
    }

    // Don't add performance badges since we show performance in stats
    // if (instance.loadScore < 50) {
    //   badges.add(InstanceBadge.lowLoad);
    // }

    if (instance.platform == InstancePlatform.mastodon) {
      badges.add(InstanceBadge.mastodon);
    } else if (instance.platform == InstancePlatform.pixelfed) {
      badges.add(InstanceBadge.pixelfed);
    }

    return badges;
  }

  bool _isFlagshipInstance(InstanceCaps instance) {
    return instance.domain == 'mastodon.social' || instance.domain == 'pixelfed.social';
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

    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        content: Text(message),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchHeader(BuildContext context, ThemeData theme) {
    final horizontalPadding = Platform.isIOS ? 20.0 : 16.0;

    return SliverFixedHeader(
      baseHeight: 60,
      child: Container(
        height: 60,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 8),
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
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          onChanged: _updateSearch,
        ),
      ),
    );
  }

  Widget _buildChipsHeader(
    BuildContext context,
    ThemeData theme,
    InstanceFilter currentFilter,
    InstanceSortOrder sortOrder,
  ) {
    final horizontalPadding = Platform.isIOS ? 20.0 : 16.0;

    return SliverFixedHeader(
      baseHeight: 48,
      child: Container(
        height: 48,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              // Sort chips
              ...InstanceSortOrder.values.map((order) {
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
              }),

              // Filter toggle if filters are available
              if (_showFilters) ...[
                const SizedBox(width: 8),
                const VerticalDivider(),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Filters'),
                  selected: true,
                  onSelected: (selected) {
                    setState(() {
                      _showFilters = !_showFilters;
                    });
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
