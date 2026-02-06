import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/utils/link_tap_handler.dart';
import 'package:pixelodon/features/profile/widgets/profile_stat_item.dart';
import 'package:pixelodon/features/media/screens/image_viewer_screen.dart';
import 'package:pixelodon/utils/account_utils.dart';
import 'package:pixelodon/features/profile/widgets/profile_field_item.dart';

class ProfileHeader extends StatelessWidget {
  final Account account;
  final bool isPixelfed;
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowRequestPending;
  final String? activeDomain;
  final VoidCallback onFollow;
  final VoidCallback onUnfollow;
  final VoidCallback onEditProfile;

  const ProfileHeader({
    super.key,
    required this.account,
    required this.isPixelfed,
    required this.isCurrentUser,
    required this.isFollowing,
    required this.isFollowRequestPending,
    this.activeDomain,
    required this.onFollow,
    required this.onUnfollow,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 768;
    final safeAreaTop = MediaQuery.of(context).padding.top;
    final headerHeight = 240.0 + safeAreaTop; // 240dp + safe area

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Gradient Background
        Container(
          height: headerHeight,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.8),
                theme.colorScheme.primary.withOpacity(0.6),
              ],
            ),
          ),
        ),
        
        // Curved White Card
        Positioned(
          top: safeAreaTop + 120 + 16, // Safe area + offset + padding
          left: 16,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 60, 16, isTablet ? 24 : 20),
              child: Column(
                children: [
                  // Display name
                  Text(
                    account.displayName,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Subtitle/Handle
                  Text(
                    AccountUtils.formatHandle(
                      acct: account.acct,
                      username: account.username,
                      accountDomain: account.domain,
                      fallbackDomain: activeDomain,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),

                  // Bio (if exists)
                  if (account.note != null && account.note!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 60),
                      child: Center(
                        child: SafeHtmlWidget(
                          htmlContent: account.note!,
                          onLinkTap: (url) => LinkTapHandler.handleLinkTap(context, url),
                          customStyles: {
                            'body': Style(
                              margin: Margins.zero,
                              padding: HtmlPaddings.zero,
                              textAlign: TextAlign.center,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: FontSize(theme.textTheme.bodySmall?.fontSize ?? 12),
                              maxLines: 3,
                              textOverflow: TextOverflow.ellipsis,
                            ),
                            'p': Style(
                              margin: Margins.zero,
                              textAlign: TextAlign.center,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontSize: FontSize(theme.textTheme.bodySmall?.fontSize ?? 12),
                            ),
                            'a': Style(
                              color: theme.colorScheme.primary,
                              textDecoration: TextDecoration.none,
                            ),
                          },
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Action Buttons (Follow + Message)
                  if (!isCurrentUser) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Follow Button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: isFollowing ? onUnfollow : onFollow,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isFollowing 
                                ? theme.colorScheme.surfaceContainerHighest
                                : theme.colorScheme.primary,
                              foregroundColor: isFollowing
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              isFollowRequestPending 
                                ? 'Pending' 
                                : (isFollowing ? 'Unfollow' : 'Follow'),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Message Button
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              // TODO: Implement message functionality
                            },
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              'Message',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Stats Row (Photos, Followers, Following)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ProfileStatItem(
                        count: account.statusesCount.toString(),
                        label: 'Photos',
                      ),
                      ProfileStatItem(
                        count: account.followersCount.toString(),
                        label: 'Followers',
                        onTap: () {
                          final qp = (account.domain != null && account.domain!.isNotEmpty) ? '?domain=${account.domain}' : '';
                          context.push('/profile/${account.id}/followers$qp');
                        },
                      ),
                      ProfileStatItem(
                        count: account.followingCount.toString(),
                        label: 'Following',
                        onTap: () {
                          final qp = (account.domain != null && account.domain!.isNotEmpty) ? '?domain=${account.domain}' : '';
                          context.push('/profile/${account.id}/following$qp');
                        },
                      ),
                    ],
                  ),

                  // Additional profile fields
                  if ((account.fields?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 20),
                    Column(
                      children: [
                        for (final f in account.fields!) ProfileFieldItem(field: f),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),

        // Profile Avatar (overlapping the card)
        Positioned(
          top: safeAreaTop + 40 + 16, // Safe area + offset + 16dp padding
          left: 0,
          right: 0,
          child: Center(
            child: Material(
              elevation: 8,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.cardColor,
                    width: 4,
                  ),
                ),
                child: GestureDetector(
                  onTap: () {
                    if (account.avatar != null && account.avatar!.isNotEmpty) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ImageViewerScreen(
                            imageUrls: [account.avatar!],
                            initialIndex: 0,
                            heroTagPrefix: 'profile_avatar_${account.id}',
                          ),
                        ),
                      );
                    }
                  },
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage: account.avatar != null
                        ? CachedNetworkImageProvider(account.avatar!)
                        : null,
                    child: account.avatar == null
                        ? Text(
                            account.displayName.isNotEmpty ? account.displayName[0] : '?',
                            style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
        ),

        // Edit Profile Button (top-right of card for current user)
        if (isCurrentUser)
          Positioned(
            top: safeAreaTop + 130 + 16, // Safe area + offset + padding
            right: 24,
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: onEditProfile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Profile',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
