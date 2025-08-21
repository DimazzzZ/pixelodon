import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pixelodon/models/account.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/features/profile/widgets/profile_stat_item.dart';
import 'package:pixelodon/features/profile/widgets/follow_button.dart';
import 'package:pixelodon/features/media/screens/image_viewer_screen.dart';

class ProfileHeader extends StatelessWidget {
  final Account account;
  final bool isPixelfed;
  final bool isCurrentUser;
  final bool isFollowing;
  final bool isFollowRequestPending;
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
                if (account.header != null)
                  CachedNetworkImage(
                    imageUrl: account.header!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                    errorWidget: (context, url, error) => Container(
                      height: 150,
                      color: theme.colorScheme.primary.withOpacity(0.1),
                    ),
                  )
                else
                  Container(
                    height: 150,
                    color: theme.colorScheme.primary.withOpacity(0.1),
                  ),

                Positioned(
                  bottom: 8,
                  right: 16,
                  child: FollowButton(
                    isCurrentUser: isCurrentUser,
                    isFollowing: isFollowing,
                    isFollowRequestPending: isFollowRequestPending,
                    onFollow: onFollow,
                    onUnfollow: onUnfollow,
                    onEditProfile: onEditProfile,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 80),

            // Profile info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.displayName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '@${account.username}${account.domain != null ? '@${account.domain}' : ''}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
                  ),

                  if (account.note != null && account.note!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    SafeHtmlWidget(
                      htmlContent: account.note!,
                      onLinkTap: (url) async {
                        if (url == null) return;
                        final uri = Uri.tryParse(url);
                        if (uri == null) return;

                        // Hashtag
                        final tagMatch = RegExp(r"/tags/([^/?#]+)").firstMatch(uri.path);
                        if (tagMatch != null) {
                          final tag = tagMatch.group(1)!;
                          if (tag.isNotEmpty) {
                            if (context.mounted) {
                              context.push('/tag/$tag');
                            }
                          }
                        }

                        // Mention: try to resolve by search
                        final atPath = RegExp(r"/@([A-Za-z0-9_\.]+)").firstMatch(uri.path);
                        if (atPath != null) {
                          final username = atPath.group(1)!;
                          final host = uri.host;
                          final container = ProviderScope.containerOf(context);
                          final active = container.read(activeInstanceProvider);
                          final acct = host.isNotEmpty && host != (active?.domain ?? '') ? '$username@$host' : username;
                          try {
                            final accountService = container.read(accountServiceProvider);
                            final results = await accountService.searchAccounts(
                              active?.domain ?? host,
                              query: acct,
                              limit: 1,
                              resolve: true,
                            );
                            if (results.isNotEmpty) {
                              if (context.mounted) {
                                // Use go_router if available
                                // ignore: use_build_context_synchronously
                                context.push('/profile/${results.first.id}');
                              }
                              return;
                            }
                          } catch (_) {}
                        }
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      ProfileStatItem(
                        count: account.statusesCount.toString(),
                        label: isPixelfed ? 'Posts' : 'Toots',
                      ),
                      ProfileStatItem(
                        count: account.followingCount.toString(),
                        label: 'Following',
                      ),
                      ProfileStatItem(
                        count: account.followersCount.toString(),
                        label: 'Followers',
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),

        // Avatar (topmost)
        Positioned(
          top: 110,
          left: 16,
          child: Material(
            elevation: 8,
            shape: const CircleBorder(),
            clipBehavior: Clip.antiAlias,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
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
                  radius: 40,
                  backgroundImage: account.avatar != null
                      ? CachedNetworkImageProvider(account.avatar!)
                      : null,
                  child: account.avatar == null
                      ? Text(
                          account.displayName[0],
                          style: const TextStyle(fontSize: 32),
                        )
                      : null,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
