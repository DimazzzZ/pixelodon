import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/presentation/quick_quiz_sheet.dart';
import 'package:pixelodon/features/onboarding/presentation/tooltip_fediverse_dialog.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

/// Main onboarding screen with welcome message and three primary actions
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _domainController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDiscovering = false;

  @override
  void dispose() {
    _domainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(isOnboardingLoadingProvider);
    final error = ref.watch(onboardingErrorProvider);

    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          // title: const Text(''),
          backgroundColor: Colors.transparent,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                         MediaQuery.of(context).padding.top -
                         MediaQuery.of(context).padding.bottom -
                         kToolbarHeight - 48, // Account for app bar and padding
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // App logo/icon (placeholder)
                // App logo
                Image.asset(
                  'assets/images/logo.png',
                  width: 100,
                  height: 100,
                ),

                const SizedBox(height: 70),
            
            // Welcome title
            Text(
              'Welcome to Pixelodon',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),

            // Subtitle with Fediverse info
            Text(
              'One app for Mastodon & Pixelfed. Start in one tap — you can change servers later.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Fediverse info chip
            Center(
              child: InkWell(
                onTap: () => _showFediverseInfo(context),
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.5),
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'What is Fediverse?',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            
            // Error message
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.onErrorContainer,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(onboardingControllerProvider.notifier).clearErrors(),
                      icon: Icon(
                        Icons.close,
                        size: 18,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Primary action buttons
            _buildActionButton(
              context: context,
              icon: Icons.rocket_launch,
              title: 'Start in 1 step',
              subtitle: 'Quick setup with recommendations',
              onPressed: isLoading ? null : () => _startQuickSetup(context),
              isPrimary: true,
            ),
            
            const SizedBox(height: 12),

            _buildActionButton(
              context: context,
              icon: Icons.account_circle,
              title: 'I already have an account',
              subtitle: 'Sign in to your existing server',
              onPressed: isLoading ? null : () => _showExistingAccountFlow(context),
            ),

            const SizedBox(height: 12),

            _buildActionButton(
              context: context,
              icon: Icons.explore,
              title: 'Browse as guest',
              subtitle: 'Explore public content without signing up',
              onPressed: isLoading ? null : () => _startGuestMode(context),
            ),

            const SizedBox(height: 24),
            
            // Loading indicator
            if (isLoading) ...[
              const Center(
                child: CircularProgressIndicator(),
              ),
              const SizedBox(height: 12),
            ],

            // Footer text
            Text(
              'Pixelodon is free, open source, and respects your privacy.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Add some bottom padding to ensure content is not cut off
            const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 72,
      child: PlatformElevatedButton(
        onPressed: onPressed,
        material: (context, platform) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: isPrimary
                ? theme.colorScheme.primary
                : theme.colorScheme.surface,
            foregroundColor: isPrimary
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface,
            elevation: isPrimary ? 2 : 1,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: isPrimary
                  ? BorderSide.none
                  : BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
            ),
          ),
        ),
        cupertino: (context, platform) => CupertinoElevatedButtonData(
          color: isPrimary
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: isPrimary
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isPrimary
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isPrimary
                          ? theme.colorScheme.onPrimary.withOpacity(0.8)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isPrimary
                  ? theme.colorScheme.onPrimary.withOpacity(0.7)
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickSetup(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickQuizSheet(),
    );
  }

  void _showExistingAccountFlow(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _buildExistingAccountSheet(context),
    );
  }

  Widget _buildExistingAccountSheet(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
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
                Text(
                  'Sign in to your account',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your username@server or just the server domain',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          // Form
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _domainController,
                      decoration: InputDecoration(
                        labelText: 'Username or server',
                        hintText: '@user@mastodon.social or mastodon.social',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a username or server';
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) => _discoverExistingAccount(),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    SizedBox(
                      width: double.infinity,
                      child: PlatformElevatedButton(
                        onPressed: _isDiscovering ? null : _discoverExistingAccount,
                        child: _isDiscovering
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _discoverExistingAccount() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isDiscovering = true;
    });
    
    final domain = _domainController.text.trim();
    await ref.read(onboardingControllerProvider.notifier)
        .discoverInstanceByDomain(domain);
    
    setState(() {
      _isDiscovering = false;
    });
    
    // Check if discovery was successful
    final selectedInstance = ref.read(selectedInstanceProvider);
    if (selectedInstance != null && mounted) {
      Navigator.of(context).pop(); // Close the sheet

      if (mounted) {
        // Navigate to login screen (don't mark onboarding as completed yet)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${selectedInstance.domain}! Redirecting to login...'),
          ),
        );

        // Navigate to login
        context.go('/auth/login');
      }
    }
  }

  void _startGuestMode(BuildContext context) async {
    await ref.read(onboardingControllerProvider.notifier).startGuestMode();

    if (mounted) {
      // Navigate to guest mode (don't mark onboarding as completed)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Guest mode activated! Browsing public timelines...'),
        ),
      );

      // Navigate to guest mode
      context.go('/guest');
    }
  }

  void _showFediverseInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TooltipFediverseDialog(),
    );
  }
}
