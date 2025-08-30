import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class FollowButton extends StatelessWidget {
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowRequestPending;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onFollow;
  final VoidCallback? onUnfollow;
  final VoidCallback? onEditProfile;
  final String? username; // For accessibility announcements

  const FollowButton({
    super.key,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.isFollowRequestPending,
    this.isLoading = false,
    this.isDisabled = false,
    this.onFollow,
    this.onUnfollow,
    this.onEditProfile,
    this.username,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isButtonDisabled = isLoading || isDisabled;
    
    // Common button styling constants
    const double buttonHeight = 36.0;
    const double minButtonWidth = 92.0;
    const double borderRadius = 12.0;
    const EdgeInsets buttonPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 0);
    
    Widget buildLoadingSpinner() {
      return SizedBox(
        width: 16,
        height: 16,
        child: PlatformWidget(
          material: (_, __) => CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              theme.colorScheme.onPrimary,
            ),
          ),
          cupertino: (_, __) => const CupertinoActivityIndicator(
            radius: 8,
            color: CupertinoColors.white,
          ),
        ),
      );
    }

    String getSemanticLabel() {
      if (isCurrentUser) return 'Edit Profile';
      final handle = username != null ? '@$username' : '';
      if (isLoading) return 'Loading...';
      if (isFollowRequestPending) return 'Cancel follow request for $handle';
      if (isFollowing) return 'Unfollow $handle';
      return 'Follow $handle';
    }

    // Current user - Edit Profile button
    if (isCurrentUser) {
      return Semantics(
        label: getSemanticLabel(),
        button: true,
        child: PlatformElevatedButton(
          onPressed: isButtonDisabled ? null : onEditProfile,
          child: isLoading 
              ? buildLoadingSpinner()
              : const Text('Edit Profile'),
          material: (_, __) => MaterialElevatedButtonData(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              foregroundColor: theme.colorScheme.onSurface,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
              disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.5),
              minimumSize: const Size(minButtonWidth, buttonHeight),
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          cupertino: (_, __) => CupertinoElevatedButtonData(
            padding: buttonPadding,
            borderRadius: BorderRadius.circular(borderRadius),
            minSize: buttonHeight,
          ),
        ),
      );
    }

    // Follow request pending - Requested button (tonal with clock icon)
    if (isFollowRequestPending) {
      return Semantics(
        label: getSemanticLabel(),
        button: true,
        child: PlatformElevatedButton(
          onPressed: isButtonDisabled ? null : onUnfollow,
          child: isLoading 
              ? buildLoadingSpinner()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    const Text('Requested'),
                  ],
                ),
          material: (_, __) => MaterialElevatedButtonData(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              disabledBackgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              disabledForegroundColor: theme.colorScheme.onSecondaryContainer.withOpacity(0.5),
              minimumSize: const Size(minButtonWidth, buttonHeight),
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          cupertino: (_, __) => CupertinoElevatedButtonData(
            padding: buttonPadding,
            borderRadius: BorderRadius.circular(borderRadius),
            minSize: buttonHeight,
          ),
        ),
      );
    }

    // Following - Unfollow button (tonal/outlined)
    if (isFollowing) {
      return Semantics(
        label: getSemanticLabel(),
        button: true,
        child: PlatformElevatedButton(
          onPressed: isButtonDisabled ? null : onUnfollow,
          child: isLoading 
              ? buildLoadingSpinner()
              : const Text('Unfollow'),
          material: (_, __) => MaterialElevatedButtonData(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.secondaryContainer,
              foregroundColor: theme.colorScheme.onSecondaryContainer,
              disabledBackgroundColor: theme.colorScheme.secondaryContainer.withOpacity(0.5),
              disabledForegroundColor: theme.colorScheme.onSecondaryContainer.withOpacity(0.5),
              minimumSize: const Size(minButtonWidth, buttonHeight),
              padding: buttonPadding,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(borderRadius),
                side: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.5),
                  width: 1,
                ),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          cupertino: (_, __) => CupertinoElevatedButtonData(
            padding: buttonPadding,
            borderRadius: BorderRadius.circular(borderRadius),
            minSize: buttonHeight,
          ),
        ),
      );
    }

    // Default - Follow button (filled primary)
    return Semantics(
      label: getSemanticLabel(),
      button: true,
      child: PlatformElevatedButton(
        onPressed: isButtonDisabled ? null : onFollow,
        child: isLoading 
            ? buildLoadingSpinner()
            : const Text('Follow'),
        material: (_, __) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            disabledBackgroundColor: theme.colorScheme.primary.withOpacity(0.5),
            disabledForegroundColor: theme.colorScheme.onPrimary.withOpacity(0.5),
            minimumSize: const Size(minButtonWidth, buttonHeight),
            padding: buttonPadding,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        cupertino: (_, __) => CupertinoElevatedButtonData(
          padding: buttonPadding,
          borderRadius: BorderRadius.circular(borderRadius),
          minSize: buttonHeight,
        ),
      ),
    );
  }
}
