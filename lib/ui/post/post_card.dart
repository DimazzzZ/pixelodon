import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart' as flutter_html;
import 'package:timeago/timeago.dart' as timeago;

import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/html_sanitizer.dart';
import 'package:pixelodon/ui/post/platform_adaptive.dart';

class PostCard extends StatelessWidget {
  final SocialPost post;
  final VoidCallback? onShare;
  final VoidCallback? onOpenAuthor;

  const PostCard({super.key, required this.post, this.onShare, this.onOpenAuthor});

  @override
  Widget build(BuildContext context) {
    final sanitized = HtmlSanitizer.sanitize(post.htmlBody);
    return Card(
      elevation: currentPlatform(context) == AppPlatform.iOS ? 0 : 1,
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            CircleAvatar(backgroundImage: NetworkImage(post.author.avatarUrl), radius: 20),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(post.author.displayName, style: Theme.of(context).textTheme.titleMedium),
              Text('@${post.author.handle}${post.author.host.isNotEmpty ? '@${post.author.host}' : ''}', style: Theme.of(context).textTheme.bodySmall),
            ])),
            AdaptiveIconButton(cupertinoIcon: CupertinoIcons.share, materialIcon: Icons.share_outlined, semanticsLabel: 'Share', onPressed: onShare),
          ]),
          const SizedBox(height: 8),
          flutter_html.Html(
            data: sanitized,
            style: {
              'body': flutter_html.Style(margin: flutter_html.Margins.zero, padding: flutter_html.HtmlPaddings.zero),
              'p': flutter_html.Style(margin: flutter_html.Margins.zero),
            },
          ),
          const SizedBox(height: 8),
          Text(timeago.format(post.createdAt), style: Theme.of(context).textTheme.bodySmall),
        ]),
      ),
    );
  }
}
