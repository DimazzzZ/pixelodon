import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/onboarding/application/onboarding_controller.dart';
import 'package:pixelodon/features/onboarding/presentation/quick_quiz_sheet.dart';
import 'package:pixelodon/features/onboarding/presentation/tooltip_fediverse_dialog.dart';

/// Main onboarding/welcome screen with platform-appropriate design
class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isLoading = ref.watch(isOnboardingLoadingProvider);
    final error = ref.watch(onboardingErrorProvider);
    final mediaQuery = MediaQuery.of(context);
    final isIOS = Platform.isIOS;

    // Platform-specific padding
    final horizontalPadding = isIOS ? 24.0 : 16.0;
    final bottomPadding = math.max(mediaQuery.viewInsets.bottom, 16.0);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Calculate spacing for true vertical centering
            final screenHeight = constraints.maxHeight;
            final footerHeight = 100.0; // Approximate footer height
            final availableHeight = screenHeight - footerHeight;
            final contentHeight = 600.0; // Approximate content height
            final topSpacing = math.max(24.0, (availableHeight - contentHeight) / 2);

            return Column(
              children: [
                // Main scrollable content
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Dynamic top spacing for true centering
                        SizedBox(height: topSpacing),

                        // Main content
                        _buildMainContent(context, theme, isIOS, isLoading, error, ref),

                        // Bottom spacing to ensure content doesn't touch footer
                        SizedBox(height: math.max(32.0, topSpacing)),
                      ],
                    ),
                  ),
                ),

                // Footer pinned to bottom
                _buildFooter(context, theme, bottomPadding),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, ThemeData theme, bool isIOS, bool isLoading, String? error, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // App logo with simple animation
        TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 800),
          tween: Tween<double>(begin: 0.0, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, value, child) {
            // Clamp values to ensure they're within valid ranges
            final clampedOpacity = value.clamp(0.0, 1.0);
            final clampedScale = (0.8 + (0.2 * value)).clamp(0.1, 2.0);

            return Opacity(
              opacity: clampedOpacity,
              child: Transform.scale(
                scale: clampedScale,
                child: child,
              ),
            );
          },
          child: Semantics(
            label: 'Pixelodon logo', // TODO: Localize
            child: Image.asset(
              'assets/images/logo.png',
              width: _getLogoSize(context),
              height: _getLogoSize(context),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Welcome title with platform-appropriate typography
        Text(
          'Welcome to Pixelodon', // TODO: Localize
          style: _getTitleStyle(theme, isIOS),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 12),

        // Subtitle with platform-appropriate styling
        Text(
          'One app for Mastodon & Pixelfed. Start in one tap — you can change servers later.', // TODO: Localize
          style: _getSubtitleStyle(theme, isIOS),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 12),

        // Fediverse info link
        _buildFediverseInfoLink(context, theme, isIOS),

        const SizedBox(height: 24),

        // Error message
        if (error != null) ...[
          _buildErrorMessage(context, theme, error, ref),
          const SizedBox(height: 24),
        ],

        // Primary CTA
        _buildPrimaryCTA(context, theme, isIOS, isLoading),

        const SizedBox(height: 12),

        // Secondary CTA
        _buildSecondaryCTA(context, theme, isIOS, isLoading),

        const SizedBox(height: 16),

        // Tertiary CTA (Browse as guest)
        _buildTertiaryCTA(context, theme, isIOS, isLoading, ref),

        // Loading indicator
        if (isLoading) ...[
          const SizedBox(height: 16),
          Center(
            child: isIOS
                ? const CupertinoActivityIndicator()
                : const CircularProgressIndicator(),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context, ThemeData theme, double bottomPadding) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        bottom: bottomPadding,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Pixelodon is free, open source, and respects your privacy.', // TODO: Localize
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton(
                onPressed: () => _showPrivacyPolicy(context),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  'Privacy', // TODO: Localize
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Text(
                ' • ',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => _showLicenses(context),
                style: TextButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: const Size(44, 44),
                ),
                child: Text(
                  'Licenses', // TODO: Localize
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for responsive design and platform-specific styling

  double _getLogoSize(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final textScaleFactor = mediaQuery.textScaler.scale(1.0);
    final baseSize = 96.0;
    final scaledSize = baseSize * textScaleFactor;
    return scaledSize.clamp(72.0, 144.0); // Min 72, max 144
  }

  TextStyle _getTitleStyle(ThemeData theme, bool isIOS) {
    if (isIOS) {
      // iOS Large Title (~34pt)
      return theme.textTheme.headlineLarge?.copyWith(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ) ?? TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      );
    } else {
      // Android headlineMedium
      return theme.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ) ?? TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      );
    }
  }

  TextStyle _getSubtitleStyle(ThemeData theme, bool isIOS) {
    if (isIOS) {
      // iOS Body with 60-70% opacity
      return theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurface.withOpacity(0.65),
      ) ?? TextStyle(
        fontSize: 17,
        color: theme.colorScheme.onSurface.withOpacity(0.65),
      );
    } else {
      // Android bodyLarge with onSurfaceVariant
      return theme.textTheme.bodyLarge?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ) ?? TextStyle(
        fontSize: 16,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
  }

  Widget _buildFediverseInfoLink(BuildContext context, ThemeData theme, bool isIOS) {
    return Semantics(
      button: true,
      label: 'What is the Fediverse?', // TODO: Localize
      child: GestureDetector(
        onTap: () => _showFediverseInfo(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isIOS ? CupertinoIcons.info_circle : Icons.info_outline,
              size: isIOS ? 17 : 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              'What is the Fediverse?', // TODO: Localize
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage(BuildContext context, ThemeData theme, String error, WidgetRef ref) {
    return Container(
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
    );
  }

  Widget _buildPrimaryCTA(BuildContext context, ThemeData theme, bool isIOS, bool isLoading) {
    final onPressed = isLoading ? null : () => _startQuickSetup(context);

    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: Semantics(
          button: true,
          label: 'Start setup', // TODO: Localize
          child: CupertinoButton.filled(
            onPressed: onPressed,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  CupertinoIcons.rocket_fill,
                  size: 20,
                  color: CupertinoColors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  'Start in One Step', // TODO: Localize (iOS Title Case)
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: Semantics(
          button: true,
          label: 'Start setup', // TODO: Localize
          child: FilledButton.icon(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.rocket_launch,
              size: 20,
            ),
            label: Text(
              'Start in one step', // TODO: Localize (Android sentence case)
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSecondaryCTA(BuildContext context, ThemeData theme, bool isIOS, bool isLoading) {
    final onPressed = isLoading ? null : () => _navigateToLogin(context);

    if (isIOS) {
      return SizedBox(
        width: double.infinity,
        height: 52,
        child: Semantics(
          button: true,
          label: 'Sign in to existing account', // TODO: Localize
          child: CupertinoButton(
            onPressed: onPressed,
            color: Colors.transparent,
            padding: EdgeInsets.zero,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.systemBlue),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  'I Already Have an Account', // TODO: Localize (iOS Title Case)
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemBlue,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      return SizedBox(
        width: double.infinity,
        height: 48,
        child: Semantics(
          button: true,
          label: 'Sign in to existing account', // TODO: Localize
          child: OutlinedButton.icon(
            onPressed: onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.outline, width: 1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: Icon(
              Icons.account_circle,
              size: 20,
            ),
            label: Text(
              'I already have an account', // TODO: Localize (Android sentence case)
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildTertiaryCTA(BuildContext context, ThemeData theme, bool isIOS, bool isLoading, WidgetRef ref) {
    final onPressed = isLoading ? null : () => _startGuestMode(context, ref);

    if (isIOS) {
      return Semantics(
        button: true,
        label: 'Browse as guest', // TODO: Localize
        child: CupertinoButton(
          onPressed: onPressed,
          minSize: 44,
          child: Text(
            'Browse as guest', // TODO: Localize
            style: TextStyle(
              fontSize: 17,
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    } else {
      return Semantics(
        button: true,
        label: 'Browse as guest', // TODO: Localize
        child: TextButton(
          onPressed: onPressed,
          style: TextButton.styleFrom(
            foregroundColor: theme.colorScheme.primary,
            minimumSize: const Size(0, 48),
          ),
          child: Text(
            'Browse as guest', // TODO: Localize
            style: TextStyle(
              fontSize: 16,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }
  }

  // Action methods with haptic feedback

  void _startQuickSetup(BuildContext context) {
    _triggerHapticFeedback();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const QuickQuizSheet(),
    );
  }

  void _navigateToLogin(BuildContext context) {
    _triggerHapticFeedback();
    context.go('/auth/login');
  }

  void _startGuestMode(BuildContext context, WidgetRef ref) async {
    _triggerHapticFeedback();
    try {
      debugPrint('Starting guest mode...');
      await ref.read(onboardingControllerProvider.notifier).startGuestMode();
      debugPrint('Guest mode controller completed');

      if (context.mounted) {
        // Navigate to guest mode (don't mark onboarding as completed)
        _showSnackBar(context, const SnackBar(
          content: Text('Guest mode activated! Browsing public timelines...'),
        ));

        debugPrint('Navigating to /guest...');
        // Navigate to guest mode
        context.go('/guest');
        debugPrint('Navigation to /guest completed');
      }
    } catch (e) {
      debugPrint('Error in _startGuestMode: $e');
      if (context.mounted) {
        _showSnackBar(context, SnackBar(
          content: Text('Failed to start guest mode: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  void _triggerHapticFeedback() {
    if (Platform.isIOS) {
      HapticFeedback.selectionClick();
    } else {
      HapticFeedback.lightImpact();
    }
  }

  void _showFediverseInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TooltipFediverseDialog(),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    // TODO: Implement privacy policy display
    // For now, show a simple dialog instead of SnackBar
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Privacy policy coming soon. We respect your privacy and will provide detailed information about our data practices.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showLicenses(BuildContext context) {
    showLicensePage(
      context: context,
      applicationName: 'Pixelodon',
      applicationVersion: '0.1.0',
    );
  }

  /// Safely shows a SnackBar, handling cases where ScaffoldMessenger is not available
  void _showSnackBar(BuildContext context, SnackBar snackBar) {
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
