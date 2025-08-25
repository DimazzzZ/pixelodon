/// Simple HTML sanitizer and link builders for mentions/hashtags.
/// This is intentionally minimal and should be run in pure Dart (no widget deps).
library;

class HtmlSanitizer {
  static const allowedTags = {
    'p', 'br', 'a', 'em', 'strong', 'code', 'blockquote'
  };

  /// Very basic sanitizer: removes <script>/<style> blocks and strips tags not in allowed list.
  /// It keeps href/rel/target on <a> only; all other allowed tags lose attributes.
  static String sanitize(String html) {
    if (html.isEmpty) return '';
    var out = html;
    // Remove script/style blocks
    out = out.replaceAll(RegExp(r'<\s*(script|style)[^>]*>[\s\S]*?<\/\s*\1\s*>', caseSensitive: false), '');
    // Replace tags, keeping only a safe subset without inline attributes/styles
    out = out.replaceAllMapped(RegExp(r'<\/?([a-zA-Z0-9]+)([^>]*)>', multiLine: true), (m) {
      final tag = m.group(1)!.toLowerCase();
      if (allowedTags.contains(tag)) {
        final isClosing = m.group(0)!.startsWith('</');
        // Only keep safe attributes on <a>; drop all other attributes
        if (tag == 'a') {
          final raw = m.group(0)!;
          final hrefMatch = RegExp('href\\s*=\\s*(?:"|\')?([^"\' >]+)(?:"|\')?', caseSensitive: false).firstMatch(raw);
          final href = hrefMatch?.group(1);
          final safeHref = href != null ? ' href="${_escapeHtml(href)}" rel="nofollow noopener" target="_blank"' : '';
          return isClosing ? '</a>' : '<a$safeHref>';
        }
        // For all other allowed tags, emit bare open/close tag (no attributes)
        return isClosing ? '</$tag>' : '<$tag>';
      }
      // Strip tag entirely
      return '';
    });
    return out;
  }

  /// Convert @mentions and #hashtags to simple anchor tags; real tapping handled by widget layer.
  static String linkifyMentionsHashtags(String text) {
    var t = text;
    t = t.replaceAllMapped(RegExp(r'(^|\s)@([A-Za-z0-9_\.]+(?:@[A-Za-z0-9\-\.]+)?)'), (m) => '${m.group(1)}<a href="mention:${m.group(2)}">@${m.group(2)}</a>');
    t = t.replaceAllMapped(RegExp(r'(^|\s)#([A-Za-z0-9_]+)'), (m) => '${m.group(1)}<a href="hashtag:${m.group(2)}">#${m.group(2)}</a>');
    return t;
  }
}

String _escapeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');
}
