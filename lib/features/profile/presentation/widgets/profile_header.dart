import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../data/profile_models.dart';
import 'profile_action_button.dart';
import 'shimmer_placeholders.dart';

/// Profile header widget with cover image and overlapping avatar
class ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onEditProfile;
  final bool isLoading;

  const ProfileHeader({
    super.key,
    this.profile,
    this.onFollowToggle,
    this.onEditProfile,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading || profile == null) {
      return SliverList(
        delegate: SliverChildListDelegate([
          const ProfileHeaderShimmer(),
          const ProfileInfoShimmer(),
        ]),
      );
    }

    return SliverList(
      delegate: SliverChildListDelegate([
        _buildSliverAppBarContent(context),
        _buildProfileInfo(context),
      ]),
    );
  }

  Widget _buildSliverAppBarContent(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 280, // Extended height to accommodate larger avatar (200 cover + 80 avatar overlap)
      child: Stack(
        children: [
          // Cover image with FlexibleSpaceBar-like behavior
          SizedBox(
            height: 200,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image with default fallback
                _buildCoverImage(theme),
                // Gradient overlay for text legibility
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.3),
                      ],
                      stops: const [0.6, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Overlapping avatar centered below cover, stacked on top of content
          Positioned(
            left: screenWidth / 2 - 80, // Center horizontally (160px avatar / 2)
            top: 120, // Position below cover with overlap onto stats/bio section
            child: _buildAvatar(context),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverImage(ThemeData theme) {
    // Use profile cover if available, otherwise fall back to default
    // Trim whitespace and check if the URL is valid
    final coverUrl = profile!.coverUrl.trim();
    final imageUrl = coverUrl.isNotEmpty ? coverUrl : null;

    if (imageUrl != null) {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => _buildDefaultBackground(),
        errorWidget: (context, url, error) => _buildDefaultBackground(),
      );
    } else {
      return _buildDefaultBackground();
    }
  }

  Widget _buildDefaultBackground() {
    return Image.asset(
      'assets/images/bg_default.png',
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: const Color(0xFF6366F1), // Purple gradient fallback
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1),
                  const Color(0xFF8B5CF6),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 160,
      height: 160,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 6,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: CachedNetworkImage(
          imageUrl: profile!.avatarUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfo(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 16.0), // Increased top padding for avatar overlap
      child: Column(
        children: [
          // Username and action button row
          _buildUsernameRow(context),
          const SizedBox(height: 16), // Increased spacing for better layout
          // Bio
          if (profile!.bio.isNotEmpty) ...[
            Text(
              profile!.bio,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
          ],
          // Interests
          if (profile!.interests.isNotEmpty)
            Text(
              profile!.interests.join(' • '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildUsernameRow(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Centered username
        Text(
          profile!.displayName ?? profile!.username,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
        // Right-aligned action button
        Align(
          alignment: Alignment.centerRight,
          child: ProfileActionButton(
            followState: profile!.followState,
            isCurrentUser: profile!.isCurrentUser,
            onPressed: profile!.isCurrentUser ? onEditProfile : onFollowToggle,
          ),
        ),
      ],
    );
  }
}

/// Sliver version of profile header for use in CustomScrollView
class SliverProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final VoidCallback? onFollowToggle;
  final VoidCallback? onEditProfile;
  final bool isLoading;

  const SliverProfileHeader({
    super.key,
    this.profile,
    this.onFollowToggle,
    this.onEditProfile,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileHeader(
      profile: profile,
      onFollowToggle: onFollowToggle,
      onEditProfile: onEditProfile,
      isLoading: isLoading,
    );
  }
}
