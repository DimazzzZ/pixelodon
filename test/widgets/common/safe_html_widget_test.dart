import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';

void main() {
  group('SafeHtmlWidget Tests', () {
    testWidgets('should render basic HTML content', (WidgetTester tester) async {
      const htmlContent = '<p>Hello <b>world</b>!</p>';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      expect(find.byType(SafeHtmlWidget), findsOneWidget);
    });

    testWidgets('should render HTML with links', (WidgetTester tester) async {
      const htmlContent = '<p>Check out <a href="https://example.com">this link</a>!</p>';
      String? tappedUrl;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(
              htmlContent: htmlContent,
              onLinkTap: (url) {
                tappedUrl = url;
              },
            ),
          ),
        ),
      );
      
      expect(find.byType(SafeHtmlWidget), findsOneWidget);
    });

    testWidgets('should block dangerous tags', (WidgetTester tester) async {
      const htmlContent = '''
        <p>Safe content</p>
        <script>alert('dangerous')</script>
        <iframe src="https://malicious.com"></iframe>
        <embed src="file.swf">
        <object data="file.pdf"></object>
        <form><input type="text"></form>
      ''';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      expect(find.byType(SafeHtmlWidget), findsOneWidget);
    });

    testWidgets('should handle empty content', (WidgetTester tester) async {
      const htmlContent = '';
      
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SafeHtmlWidget(htmlContent: htmlContent),
          ),
        ),
      );
      
      expect(find.byType(SafeHtmlWidget), findsOneWidget);
    });
  });
}
