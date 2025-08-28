import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_html/flutter_html.dart';
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
        _buildSliverAppBar(context),
        _buildProfileContent(context),
      ]),
    );
  }

  /// Build SliverAppBar with cover image and gradient
  Widget _buildSliverAppBar(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      height: 130, // Reduced by 50% from 210px (within 120-140px range)
      child: Stack(
        clipBehavior: Clip.none, // Allow avatar to overflow
        children: [
          // Cover image with gradient overlay
          Container(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Cover image
                _buildCoverImage(theme),
                // Gradient overlay (0 → 0.25 opacity)
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.25),
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build profile content with overlapping avatar
  Widget _buildProfileContent(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Main profile content
        Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 76.0, 16.0, 16.0), // contentTopPadding = avatarDiameter/2 + 8 = 68 + 8 = 76px
          child: Column(
            children: [
              const SizedBox(height: 8), // Avatar bottom → Username: 8px (reduced by 50%)
              // Username and action button row
              _buildUsernameRow(context),
              const SizedBox(height: 8), // Username to bio spacing (kept compact at 8px)
              // Bio
              if (profile!.bio.isNotEmpty) ...[
                Html(
                  data: profile!.bio,
                  style: {
                    "body": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      fontSize: FontSize(theme.textTheme.bodyMedium?.fontSize ?? 14),
                      color: theme.colorScheme.onSurfaceVariant,
                      textAlign: TextAlign.center,
                    ),
                    "p": Style(
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                      textAlign: TextAlign.center,
                    ),
                    "a": Style(
                      color: theme.colorScheme.primary,
                      textDecoration: TextDecoration.underline,
                    ),
                    "strong, b": Style(
                      fontWeight: FontWeight.bold,
                    ),
                    "em, i": Style(
                      fontStyle: FontStyle.italic,
                    ),
                  },
                ),
                const SizedBox(height: 8), // Bio to stats row spacing (reduced by 50% from 16px)
              ] else ...[
                const SizedBox(height: 8), // Direct username to stats spacing if no bio (reduced by 50% from 16px)
              ],
              // Interests
              if (profile!.interests.isNotEmpty) ...[
                Text(
                  profile!.interests.join(' • '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
        // Overlapping avatar positioned 72px above content
        Positioned(
          left: screenWidth / 2 - 68, // Center horizontally (136px avatar / 2)
          top: -72, // Increased overlap by 72px
          child: _buildAvatar(context),
        ),
      ],
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
      width: 136, // 136px diameter (2× larger, within 128-144px range)
      height: 136,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 4, // 4px white ring (within 3-4px range)
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12), // 12% opacity as required
            blurRadius: 20,
            offset: const Offset(0, 8), // y-offset 8 as required
            spreadRadius: 0,
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
              size: 48, // Adjusted icon size for larger avatar (proportional to 136px)
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.person,
              size: 48, // Adjusted icon size for larger avatar (proportional to 136px)
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildUsernameRow(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Centered username and handle
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Display name
            Text(
              profile!.displayName ?? profile!.username,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4), // Small spacing between display name and handle
            // Username with instance (@username@instance)
            Text(
              '@${profile!.acct}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                fontWeight: FontWeight.w400,
              ),
              textAlign: TextAlign.center,
            ),
          ],
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
