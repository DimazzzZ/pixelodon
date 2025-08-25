import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/ui/post/html_sanitizer.dart';

void main() {
  test('removes script/style and keeps allowed tags', () {
    const dirty = '<p>Hello<script>alert(1)</script><strong>World</strong><img src=x onerror=1></p>';
    final clean = HtmlSanitizer.sanitize(dirty);
    expect(clean.contains('<script>'), isFalse);
    expect(clean.contains('<img'), isFalse); // not allowed
    expect(clean.contains('<strong>World</strong>'), isTrue);
  });

  test('linkifies mentions and hashtags', () {
    const text = 'Hi @alice@example.com and #Flutter';
    final linked = HtmlSanitizer.linkifyMentionsHashtags(text);
    expect(linked.contains('href="mention:alice@example.com"'), isTrue);
    expect(linked.contains('href="hashtag:Flutter"'), isTrue);
  });
}
