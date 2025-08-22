import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/utils/link_tap_handler.dart';
import 'package:pixelodon/features/profile/widgets/profile_stat_item.dart';
import 'package:pixelodon/features/media/screens/image_viewer_screen.dart';
import 'package:pixelodon/utils/account_utils.dart';
import 'package:pixelodon/features/profile/widgets/follow_button.dart';

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

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header image
            Stack(
              children: [
                Builder(
                  builder: (context) {
                    final headerUrl = (account.header != null && account.header!.isNotEmpty)
                        ? account.header!
                        : ((account.headerStatic != null && account.headerStatic!.isNotEmpty)
                            ? account.headerStatic!
                            : '');
                    if (headerUrl.isNotEmpty) {
                      return CachedNetworkImage(
                        imageUrl: headerUrl,
                        height: 75,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          height: 75,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                        errorWidget: (context, url, error) => Container(
                          height: 75,
                          color: theme.colorScheme.primary.withOpacity(0.1),
                        ),
                      );
                    }
                    return Container(
                      height: 75,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    );
                  },
                ),

              ],
            ),

            const SizedBox(height: 4),

            // Avatar + Profile info in one container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Material(
                      elevation: 4,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 3,
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
                            radius: 48,
                            backgroundImage: account.avatar != null
                                ? CachedNetworkImageProvider(account.avatar!)
                                : null,
                            child: account.avatar == null
                                ? Text(
                                    account.displayName.isNotEmpty ? account.displayName[0] : '?',
                                    style: const TextStyle(fontSize: 32),
                                  )
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 6),

                  // Profile info
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          account.displayName,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      FollowButton(
                        isCurrentUser: isCurrentUser,
                        isFollowing: isFollowing,
                        isFollowRequestPending: isFollowRequestPending,
                        onFollow: onFollow,
                        onUnfollow: onUnfollow,
                        onEditProfile: onEditProfile,
                      ),
                    ],
                  ),
                  Text(
                    AccountUtils.formatHandle(
                      acct: account.acct,
                      username: account.username,
                      accountDomain: account.domain,
                      fallbackDomain: activeDomain,
                    ),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),

                  if (account.note != null && account.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SafeHtmlWidget(
                      htmlContent: account.note!,
                      onLinkTap: (url) => LinkTapHandler.handleLinkTap(context, url),
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ProfileStatItem(
                        count: account.statusesCount.toString(),
                        label: 'Posts',
                      ),
                      ProfileStatItem(
                        count: account.followingCount.toString(),
                        label: 'Following',
                        onTap: () {
                          final qp = (account.domain != null && account.domain!.isNotEmpty) ? '?domain=${account.domain}' : '';
                          context.push('/profile/${account.id}/following$qp');
                        },
                      ),
                      ProfileStatItem(
                        count: account.followersCount.toString(),
                        label: 'Followers',
                        onTap: () {
                          final qp = (account.domain != null && account.domain!.isNotEmpty) ? '?domain=${account.domain}' : '';
                          context.push('/profile/${account.id}/followers$qp');
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
