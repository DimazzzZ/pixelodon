import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart' as dom;

import 'package:pixelodon/ui/post/adapters_masto_pixelfed.dart';
import 'package:pixelodon/ui/post/indent_guide.dart';
import 'package:pixelodon/ui/post/platform_adaptive.dart';
import 'package:pixelodon/ui/post/tree_builder.dart';
import 'package:pixelodon/ui/post/reply_action_bar.dart';

typedef MentionTap = void Function(String handle);
typedef HashtagTap = void Function(String tag);

typedef NodeCallback = void Function(ReplyNode node);
typedef AuthorCallback = void Function(Author author);

class ReplyNodeTile extends StatelessWidget {
  final ReplyNode node;
  final NodeCallback? onReply;
  final NodeCallback? onBoost;
  final NodeCallback? onFavourite;
  final NodeCallback? onShare;
  final NodeCallback? onOpenReplies;
  final AuthorCallback? onProfileTap;
  final MentionTap? onTapMention;
  final HashtagTap? onTapHashtag;

  const ReplyNodeTile({super.key, required this.node, this.onReply, this.onBoost, this.onFavourite, this.onShare, this.onOpenReplies, this.onProfileTap, this.onTapMention, this.onTapHashtag});

  @override
  Widget build(BuildContext context) {
    final ap = currentPlatform(context);
    final p = node.post;
    final avatar = _Avatar(url: p.author.avatarUrl, label: p.author.displayName, onTap: () => onProfileTap?.call(p.author));

    final header = _Header(post: p);
    final content = _Content(post: p, onTapHashtag: onTapHashtag, onTapMention: onTapMention);
    final media = _Media(media: p.media);

    // Check if body text is empty or whitespace only for vertical rhythm
    final sanitized = sanitizeHtmlToText(p.htmlBody);
    final hasBody = sanitized.isNotEmpty;

    final tile = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              avatar,
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    if (hasBody) const SizedBox(height: 8),
                    if (hasBody) content,
                    if (p.media.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      media,
                    ],
                    SizedBox(height: hasBody ? 8 : 6),
                    ReplyActionBar(
                      node: node,
                      onReply: () => onReply?.call(node),
                      onBoost: () => onBoost?.call(node),
                      onFavourite: () => onFavourite?.call(node),
                      onShare: () => onShare?.call(node),
                      onOpenReplies: () => onOpenReplies?.call(node),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );

    final collapseIndicator = node.isCollapsed ? _CollapsedPill(count: countDescendants(node)) : const SizedBox.shrink();

    return IndentGuide(
      depth: node.depth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          tile,
          collapseIndicator,
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String label;
  final VoidCallback? onTap;
  const _Avatar({required this.url, required this.label, this.onTap});
  @override
  Widget build(BuildContext context) {
    final img = url.isNotEmpty
        ? ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: CachedNetworkImage(imageUrl: url, width: 40, height: 40, fit: BoxFit.cover),
          )
        : CircleAvatar(radius: 20, child: Text(_initials(label)));
    return Semantics(
      label: 'Open profile for $label',
      child: GestureDetector(onTap: onTap, child: img),
    );
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  if (parts.length >= 2) return (parts[0].isNotEmpty ? parts[0][0] : '') + (parts[1].isNotEmpty ? parts[1][0] : '');
  return parts.isNotEmpty && parts[0].isNotEmpty ? parts[0][0] : '?';
}

class _Header extends StatelessWidget {
  final SocialPost post;
  const _Header({required this.post});
  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7));
    
    // Title block: displayName + @handle@host (joined with a middot)
    final titleBlock = Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: post.author.displayName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          TextSpan(text: ' · ', style: secondary),
          TextSpan(
            text: '@${post.author.handle}${post.author.host.isNotEmpty ? '@${post.author.host}' : ''}',
            style: secondary,
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        // Title block is the only shrinkable area
        Flexible(child: titleBlock),
        const SizedBox(width: 6), // Small fixed gap
        // Timestamp stays at natural width, never truncated
        Text(timeago.format(post.createdAt), style: secondary),
      ],
    );
  }
}

/// Strips all styles/colors/fonts and flattens headings/mark into plain text.
/// Keeps paragraph/line breaks and links/mentions/hashtags as text only.
String sanitizeHtmlToText(String? htmlInput) {
  if (htmlInput == null || htmlInput.isEmpty) return '';

  final dom.DocumentFragment frag = html.parseFragment(htmlInput);

  // Allow only a minimal set of inline semantics
  const whitelist = <String>{
    'p','br','a','em','strong','b','i','code','blockquote','span'
  };

  // Drop dangerous or style-carrying elements entirely
  const blacklist = <String>{
    'script','style','svg','iframe','video','audio','img','hr','font'
  };

  // Tags to flatten (remove tag but keep text; also headings & mark)
  const flatten = <String>{
    'h1','h2','h3','h4','h5','h6','mark','u','s','del','ins','pre','div'
  };

  void cleanse(dom.Node node) {
    if (node is dom.Element) {
      final tag = node.localName ?? '';

      if (blacklist.contains(tag)) {
        node.remove();
        return;
      }

      // Remove attributes that can carry styles
      node.attributes.remove('style');
      node.attributes.remove('color');
      node.attributes.remove('class');
      node.attributes.remove('id');

      // Recurse
      for (final c in List<dom.Node>.from(node.nodes)) {
        cleanse(c);
      }

      if (flatten.contains(tag)) {
        node.replaceWith(dom.Text(node.text));
        return;
      }

      if (!whitelist.contains(tag)) {
        node.replaceWith(dom.Text(node.text));
      }
    }
  }

  for (final n in List<dom.Node>.from(frag.nodes)) {
    cleanse(n);
  }

  String extractText(dom.Node node) {
    if (node is dom.Text) return node.text;
    if (node is dom.Element) {
      final tag = node.localName ?? '';
      final buf = StringBuffer();
      for (final c in node.nodes) {
        buf.write(extractText(c));
      }
      if (tag == 'p' || tag == 'blockquote') buf.write('\n\n');
      if (tag == 'br') buf.write('\n');
      return buf.toString();
    }
    if (node is dom.DocumentFragment) {
      final buf = StringBuffer();
      for (final c in node.nodes) {
        buf.write(extractText(c));
      }
      return buf.toString();
    }
    return '';
  }

  return extractText(frag)
      .replaceAll(RegExp(r'[ \t]+\n'), '\n')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

// 2) Linkify mentions/hashtags/urls into TextSpans (no CSS).
TextSpan linkifiedSpan(
  String input,
  TextStyle base,
  {void Function(String url)? onTapUrl,
   void Function(String tag)? onTapHashtag,
   void Function(String handle)? onTapMention}
) {
  final children = <InlineSpan>[];
  final regex = RegExp(r'(https?://\S+)|(#\w+)|(@[a-zA-Z0-9_\.]+@[a-zA-Z0-9\.\-]+)');
  int idx = 0;
  for (final m in regex.allMatches(input)) {
    if (m.start > idx) {
      children.add(TextSpan(text: input.substring(idx, m.start), style: base));
    }
    final match = m.group(0)!;
    if (match.startsWith('http')) {
      children.add(TextSpan(
        text: match,
        style: base.copyWith(decoration: TextDecoration.underline),
        recognizer: (TapGestureRecognizer()..onTap = () => onTapUrl?.call(match)),
        semanticsLabel: 'Link to $match',
      ));
    } else if (match.startsWith('#')) {
      children.add(TextSpan(
        text: match,
        style: base.copyWith(decoration: TextDecoration.underline),
        recognizer: (TapGestureRecognizer()..onTap = () => onTapHashtag?.call(match.substring(1))),
        semanticsLabel: 'Hashtag ${match.substring(1)}',
      ));
    } else {
      children.add(TextSpan(
        text: match,
        style: base.copyWith(decoration: TextDecoration.underline),
        recognizer: (TapGestureRecognizer()..onTap = () => onTapMention?.call(match.substring(1))),
        semanticsLabel: 'Mention ${match.substring(1)}',
      ));
    }
    idx = m.end;
  }
  if (idx < input.length) {
    children.add(TextSpan(text: input.substring(idx), style: base));
  }
  return TextSpan(children: children);
}

class ReplyBody extends StatefulWidget {
  final String htmlBody;
  final ValueChanged<String>? onUrl;
  final ValueChanged<String>? onHashtag;
  final ValueChanged<String>? onMention;
  const ReplyBody({super.key, required this.htmlBody, this.onUrl, this.onHashtag, this.onMention});

  @override
  State<ReplyBody> createState() => _ReplyBodyState();
}

class _ReplyBodyState extends State<ReplyBody> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final TextStyle base = Theme.of(context).platform == TargetPlatform.iOS
        ? CupertinoTheme.of(context).textTheme.textStyle.copyWith(
            fontSize: 15, fontWeight: FontWeight.w400, height: 1.25,
          )
        : Theme.of(context).textTheme.bodyMedium!.copyWith(
            height: 1.25,
          );
    
    // Guard against nulls and exceptions from sanitizer
    String sanitized;
    try {
      sanitized = sanitizeHtmlToText(widget.htmlBody);
    } catch (_) {
      sanitized = widget.htmlBody ?? '';
    }

    // Optional guard (dev-only)
    assert(!RegExp(r'style\s*=').hasMatch(widget.htmlBody ?? ''),
      'ReplyBody received inline-styled HTML; sanitizer should remove it.');

    final span = linkifiedSpan(
      sanitized,
      base,
      onTapUrl: widget.onUrl,
      onTapHashtag: widget.onHashtag,
      onTapMention: widget.onMention,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final tp = TextPainter(
          text: span,
          textAlign: TextAlign.start,
          textDirection: Directionality.of(context),
          maxLines: expanded ? null : 4,
        )..layout(maxWidth: constraints.maxWidth);

        final needsMore = !expanded && tp.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText.rich(
              span,
              maxLines: expanded ? null : 4,
            ),
            if (needsMore) const SizedBox(height: 4),
            if (needsMore)
              _PlatformTextButton(
                label: 'Read more',
                onPressed: () => setState(() => expanded = true),
              ),
          ],
        );
      },
    );
  }
}

class _PlatformTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _PlatformTextButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    if (currentPlatform(context) == AppPlatform.iOS) {
      return CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minSize: 44,
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(minimumSize: const Size(44, 44), visualDensity: VisualDensity.compact),
      child: Text(label),
    );
  }
}

class _Content extends StatelessWidget {
  final SocialPost post;
  final MentionTap? onTapMention;
  final HashtagTap? onTapHashtag;
  const _Content({required this.post, this.onTapMention, this.onTapHashtag});
  @override
  Widget build(BuildContext context) {
    final body = ReplyBody(
      htmlBody: post.htmlBody,
      onUrl: (_) {},
      onHashtag: onTapHashtag,
      onMention: onTapMention,
    );

    if (post.contentWarning != null) {
      return _ContentWarning(cw: post.contentWarning!, child: body);
    }
    return body;
  }
}

class _ContentWarning extends StatefulWidget {
  final Widget child;
  final String cw;
  const _ContentWarning({required this.child, required this.cw});
  @override
  State<_ContentWarning> createState() => _ContentWarningState();
}

class _ContentWarningState extends State<_ContentWarning> {
  bool show = false;
  @override
  Widget build(BuildContext context) {
    if (show) return widget.child;
    return GestureDetector(
      onTap: () => setState(() => show = true),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
        child: Text('${widget.cw} · Show content'),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  final List<MediaThumb> media;
  const _Media({required this.media});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: media
          .map((m) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(imageUrl: m.previewUrl, width: 96, height: 96, fit: BoxFit.cover),
              ))
          .toList(),
    );
  }
}

class _CollapsedPill extends StatelessWidget {
  final int count;
  const _CollapsedPill({required this.count});
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(start: 52),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Text('+$count replies'),
    );
  }
}
