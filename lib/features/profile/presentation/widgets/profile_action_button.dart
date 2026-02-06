import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:pixelodon/features/profile/data/profile_models.dart';

/// Compact action button for profile header (Edit Profile / Follow / Unfollow)
class ProfileActionButton extends StatelessWidget {
  final FollowState followState;
  final bool isCurrentUser;
  final VoidCallback? onPressed;
  final bool isLoading;

  const ProfileActionButton({
    super.key,
    required this.followState,
    required this.isCurrentUser,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isCurrentUser) {
      return _buildEditButton(context, theme);
    }

    return _buildFollowButton(context, theme);
  }

  Widget _buildEditButton(BuildContext context, ThemeData theme) {
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        minimumSize: const Size(80, 34),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        side: BorderSide(
          color: theme.colorScheme.outline,
          width: 1,
        ),
      ),
      child: _buildButtonContent(
        'Edit Profile',
        theme,
        theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildFollowButton(BuildContext context, ThemeData theme) {
    final buttonData = _getFollowButtonData(theme);
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
      child: _buildButton(
        context,
        theme,
        key: ValueKey(followState),
        text: buttonData.text,
        backgroundColor: buttonData.backgroundColor,
        foregroundColor: buttonData.foregroundColor,
        borderColor: buttonData.borderColor,
        isFilled: buttonData.isFilled,
      ),
    );
  }

  Widget _buildButton(
    BuildContext context,
    ThemeData theme, {
    required Key key,
    required String text,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
    required bool isFilled,
  }) {
    if (isFilled) {
      return FilledButton(
        key: key,
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(80, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: _buildButtonContent(text, theme, foregroundColor),
      );
    } else {
      return OutlinedButton(
        key: key,
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          minimumSize: const Size(80, 34),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          side: BorderSide(
            color: borderColor ?? theme.colorScheme.outline,
            width: 1,
          ),
        ),
        child: _buildButtonContent(text, theme, foregroundColor),
      );
    }
  }

  Widget _buildButtonContent(String text, ThemeData theme, Color foregroundColor) {
    if (isLoading) {
      return SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
        ),
      );
    }

    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w500,
        color: foregroundColor,
      ),
    ).animate(
      effects: [
        if (text == 'Unfollow') ...[
          const SlideEffect(
            duration: Duration(milliseconds: 200),
            begin: Offset(0, -0.2),
            end: Offset.zero,
          ),
          const FadeEffect(
            duration: Duration(milliseconds: 200),
          ),
        ],
      ],
    );
  }

  _ButtonData _getFollowButtonData(ThemeData theme) {
    switch (followState) {
      case FollowState.following:
        return _ButtonData(
          text: 'Unfollow',
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          borderColor: theme.colorScheme.outline,
          isFilled: false,
        );
        
      case FollowState.notFollowing:
        return _ButtonData(
          text: 'Follow',
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          isFilled: true,
        );
        
      case FollowState.unknown:
      case FollowState.self:
      default:
        return _ButtonData(
          text: 'Follow',
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface.withOpacity(0.6),
          borderColor: theme.colorScheme.outline.withOpacity(0.5),
          isFilled: false,
        );
    }
  }
}

/// Data class for button configuration
class _ButtonData {
  final String text;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool isFilled;

  const _ButtonData({
    required this.text,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    required this.isFilled,
  });
}

/// Extension to provide optimistic follow state animations
extension ProfileActionButtonExtensions on ProfileActionButton {
  /// Create a version with loading state for optimistic updates
  ProfileActionButton withLoading() {
    return ProfileActionButton(
      followState: followState,
      isCurrentUser: isCurrentUser,
      onPressed: onPressed,
      isLoading: true,
    );
  }

  /// Create a version with optimistic follow state
  ProfileActionButton withOptimisticState(FollowState optimisticState) {
    return ProfileActionButton(
      followState: optimisticState,
      isCurrentUser: isCurrentUser,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }
}
