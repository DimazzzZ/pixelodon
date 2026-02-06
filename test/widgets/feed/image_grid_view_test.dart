import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/widgets/feed/image_grid_view.dart';
import 'package:pixelodon/models/status.dart' as status_model;
import 'package:pixelodon/models/account.dart';

void main() {
  group('ImageGridView', () {
    testWidgets('should render without viewport errors', (WidgetTester tester) async {
      // Create a mock status with image attachment
      final mockStatus = status_model.Status(
        id: '1',
        uri: 'https://example.com/status/1',
        url: 'https://example.com/status/1',
        account: Account(
          id: '1',
          username: 'testuser',
          acct: 'testuser',
          displayName: 'Test User',
          locked: false,
          bot: false,
          discoverable: true,
          group: false,
          createdAt: DateTime.now(),
          note: '',
          url: 'https://example.com/users/testuser',
          avatar: 'https://example.com/avatar.jpg',
          avatarStatic: 'https://example.com/avatar.jpg',
          header: 'https://example.com/header.jpg',
          headerStatic: 'https://example.com/header.jpg',
          followersCount: 0,
          followingCount: 0,
          statusesCount: 0,
          lastStatusAt: DateTime.now(),
          fields: [],
        ),
        inReplyToId: null,
        inReplyToAccountId: null,
        rebloggedStatus: null,
        content: 'Test status with image',
        createdAt: DateTime.now(),
        emojis: [],
        repliesCount: 0,
        reblogsCount: 0,
        favouritesCount: 0,
        reblogged: false,
        favourited: false,
        bookmarked: false,
        sensitive: false,
        spoilerText: '',
        visibility: status_model.Visibility.public,
        mediaAttachments: [
          const status_model.MediaAttachment(
            id: '1',
            type: status_model.AttachmentType.image,
            url: 'https://example.com/image.jpg',
            previewUrl: 'https://example.com/image_preview.jpg',
            remoteUrl: null,
            description: 'Test image',
            blurhash: null,
          ),
        ],
        mentions: [],
        tags: [],
        application: null,
        language: null,
        pinned: false,
        card: null,
        poll: null,
      );

      // Build the widget
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImageGridView(
                statuses: [mockStatus],
                isLoading: false,
                hasError: false,
                hasMore: false,
              ),
            ),
          ),
        ),
      );

      // Verify that the widget builds without errors
      expect(find.byType(ImageGridView), findsOneWidget);
      expect(find.byType(CustomScrollView), findsOneWidget);
      expect(find.byType(SliverGrid), findsOneWidget);
      
      // Verify no viewport errors are thrown
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle empty status list', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImageGridView(
                statuses: [],
                isLoading: false,
                hasError: false,
                hasMore: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ImageGridView), findsOneWidget);
      expect(find.text('No images found'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle error state', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ImageGridView(
                statuses: [],
                isLoading: false,
                hasError: true,
                errorMessage: 'Test error',
                hasMore: false,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ImageGridView), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
