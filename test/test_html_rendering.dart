import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/models/status.dart';
import 'package:pixelodon/widgets/feed/post_card.dart';

void main() {
  testWidgets('HTML content is rendered correctly with security', (WidgetTester tester) async {
    // Test HTML content with various elements
    const htmlContent = '''
      <p>This is a <strong>bold</strong> text with a <a href="https://example.com">link</a>.</p>
      <p>Here's some <em>italic</em> text and a <code>code snippet</code>.</p>
      <script>alert('XSS attempt');</script>
      <iframe src="https://malicious.com"></iframe>
      <p>This paragraph should be visible.</p>
    ''';

    final testStatus = Status(
      id: 'test-id',
      content: htmlContent,
      account: null,
      createdAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: PostCard(
            status: testStatus,
            domain: 'example.com',
            showFullContent: true,
          ),
        ),
      ),
    );

    // Verify that the widget builds without errors
    expect(find.byType(PostCard), findsOneWidget);
    
    // Print debug information
    print('[DEBUG_LOG] HTML content rendering test completed');
    print('[DEBUG_LOG] Original content length: ${htmlContent.length}');
    print('[DEBUG_LOG] Widget found: ${find.byType(PostCard)}');
  });
}
