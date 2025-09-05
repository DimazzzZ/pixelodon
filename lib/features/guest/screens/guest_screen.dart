import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/explore/screens/explore_screen.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

/// Guest mode screen that allows browsing public timelines without authentication
class GuestScreen extends ConsumerStatefulWidget {
  const GuestScreen({super.key});

  @override
  ConsumerState<GuestScreen> createState() => _GuestScreenState();
}

class _GuestScreenState extends ConsumerState<GuestScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure guest mode instances are loaded when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final onboardingState = ref.read(onboardingControllerProvider);
      // Only start guest mode if instances aren't already loaded or loading
      if (onboardingState.allInstances.isEmpty && !onboardingState.isLoadingAllInstances) {
        ref.read(onboardingControllerProvider.notifier).startGuestMode();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onboardingState = ref.watch(onboardingControllerProvider);
    
    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          title: const Text('Guest Mode'),
          leading: PlatformIconButton(
            icon: Icon(PlatformIcons(context).back),
            onPressed: () => context.go('/onboarding'),
          ),
          trailingActions: [
            PlatformIconButton(
              icon: Icon(PlatformIcons(context).accountCircle),
              onPressed: () => _showLoginOptions(context),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Guest mode info banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.visibility,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Browsing as Guest',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'You can view public content. Sign in to interact with posts.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Tab bar for different public timelines
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTabButton(
                    context: context,
                    title: 'Public',
                    isSelected: _selectedIndex == 0,
                    onTap: () => setState(() => _selectedIndex = 0),
                  ),
                ),
                Expanded(
                  child: _buildTabButton(
                    context: context,
                    title: 'Trending',
                    isSelected: _selectedIndex == 1,
                    onTap: () => setState(() => _selectedIndex = 1),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Content area
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showLoginOptions(context),
        icon: Icon(PlatformIcons(context).accountCircle),
        label: const Text('Sign In'),
      ),
    );
  }
  
  Widget _buildTabButton({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleSmall?.copyWith(
            color: isSelected 
                ? theme.colorScheme.onPrimary 
                : theme.colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildContent() {
    final onboardingState = ref.watch(onboardingControllerProvider);
    final theme = Theme.of(context);

    // Show loading if guest instances are being loaded
    if (onboardingState.allInstances.isEmpty && onboardingState.isLoadingAllInstances) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text('Loading public servers...'),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () => _showLoginOptions(context),
              child: const Text('Skip to Sign In'),
            ),
          ],
        ),
      );
    }

    // Show error if loading failed
    if (onboardingState.recommendationError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to Load Servers',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                onboardingState.recommendationError!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => ref.read(onboardingControllerProvider.notifier).startGuestMode(),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    // Show guest mode content
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.public,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Guest Mode Active',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (onboardingState.allInstances.isNotEmpty) ...[
              Text(
                'Found ${onboardingState.allInstances.length} public servers available for browsing.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Public timeline browsing will be available here in a future update.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ] else ...[
              Text(
                'Public timeline browsing will be available here.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => _showLoginOptions(context),
              icon: Icon(PlatformIcons(context).accountCircle),
              label: const Text('Sign In for Full Features'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showLoginOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Sign In Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.login),
              title: const Text('Sign in to existing account'),
              subtitle: const Text('Login to your Mastodon or Pixelfed account'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/auth/login');
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_back),
              title: const Text('Back to onboarding'),
              subtitle: const Text('Choose a server or create a new account'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/onboarding');
              },
            ),
          ],
        ),
      ),
    );
  }
}
