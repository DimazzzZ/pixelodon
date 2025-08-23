import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixelodon/features/profile/screens/profile_screen.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/services/auth_service.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';

ApiService _dummyApi() => ApiService(authRepository: AuthRepository(authService: AuthService()));

/// A simple in-memory fake AccountService suitable for widget tests
class FakeAccountService extends AccountService {
  FakeAccountService() : super(apiService: _dummyApi());

  Account account = const Account(
    id: '123',
    username: 'jane',
    acct: 'jane',
    displayName: 'Jane Doe',
    // avatar and header intentionally null to avoid network in tests
    followersCount: 10,
    followingCount: 2,
    statusesCount: 3,
  );

  bool fail = false;
  String? errorMessage;

  @override
  Future<Account> getAccount(String domain, String id) async {
    if (fail) {
      throw Exception(errorMessage ?? 'Failed');
    }
    // Use a very short delay to avoid timeouts
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return account;
  }

  @override
  Future<Account> followAccount(String domain, String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    account = account.copyWith(following: true, requested: false);
    return account;
  }

  @override
  Future<Account> unfollowAccount(String domain, String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    account = account.copyWith(following: false, requested: false);
    return account;
  }
}

/// A simple in-memory fake TimelineService suitable for widget tests
class FakeTimelineService extends TimelineService {
  FakeTimelineService() : super(apiService: _dummyApi());

  List<model.Status> statuses = const [];
  bool fail = false;

  @override
  Future<List<model.Status>> getAccountStatuses(
    String domain,
    String accountId, {
    int? limit,
    String? maxId,
    String? sinceId,
    String? minId,
    int? offset,
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
    cancelToken,
  }) async {
    if (fail) throw Exception('Statuses failed');
    // Use a very short delay to avoid timeouts
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return statuses;
  }
}

void main() {
  group('ProfileScreen functional tests', () {
    testWidgets('renders Mastodon-style profile list with text posts', (tester) async {
      final fakeAccount = FakeAccountService();
      final fakeTimeline = FakeTimelineService()
        ..statuses = [
          model.Status(
            id: 'p1',
            content: '<p>Hello world</p>',
            account: fakeAccount.account,
          ),
          model.Status(
            id: 'p2',
            content: '<p>Another post</p>',
            account: fakeAccount.account,
          ),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // Active instance: Mastodon-like
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'example.social',
              name: 'Example',
              isPixelfed: false,
            )),
            activeAccountProvider.overrideWithValue(fakeAccount.account),
            accountServiceProvider.overrideWithValue(fakeAccount),
            timelineServiceProvider.overrideWithValue(fakeTimeline),
          ],
          child: const MaterialApp(
            home: SizedBox(
              width: 1000,
              height: 1000,
              child: ProfileScreen(accountId: '123'),
            ),
          ),
        ),
      );

      // Initial frame
      await tester.pump();

      // Wait for loading indicator to appear
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // We can't directly call private methods, so let's manually trigger account loading
      // by simulating getAccount call and status loads
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for network calls to complete with longer durations
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Display name and handle
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('@jane@example.social'), findsOneWidget);

      // Stats shown
      expect(find.text('3'), findsWidgets); // statuses count

      // Feed list (not grid) should be present
      expect(find.byType(FeedList), findsOneWidget);
    });

    testWidgets('renders Pixelfed-style grid and shows empty state when no media', (tester) async {
      final fakeAccount = FakeAccountService();
      final fakeTimeline = FakeTimelineService()..statuses = const [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'pix.example',
              name: 'Pix',
              isPixelfed: true,
            )),
            activeAccountProvider.overrideWithValue(fakeAccount.account),
            accountServiceProvider.overrideWithValue(fakeAccount),
            timelineServiceProvider.overrideWithValue(fakeTimeline),
          ],
          child: const MaterialApp(
            home: SizedBox(
              width: 1000,
              height: 1000,
              child: ProfileScreen(accountId: '123'),
            ),
          ),
        ),
      );

      // First frame should be rendered
      await tester.pump();

      // Manually trigger account loading by simulating getAccount call
      await fakeAccount.getAccount('pix.example', '123');
      await fakeTimeline.getAccountStatuses('pix.example', '123');

      // Wait for initial network calls with longer duration
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Check that we've moved past the loading state
      expect(find.text('Jane Doe'), findsOneWidget);

      // Look for any widgets that contain our target text - more flexible approach
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data == 'No posts yet';
          }
          return false;
        }),
        findsOneWidget,
      );
    });

    testWidgets('follow/unfollow toggles button state', (tester) async {
      final fakeAccount = FakeAccountService();
      final fakeTimeline = FakeTimelineService()..statuses = const [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'example.social',
              name: 'Example',
              isPixelfed: false,
            )),
            activeAccountProvider.overrideWithValue(fakeAccount.account.copyWith(id: 'self')), // not current user to show follow
            accountServiceProvider.overrideWithValue(fakeAccount),
            timelineServiceProvider.overrideWithValue(fakeTimeline),
          ],
          // Use a SizedBox with defined height to avoid overflow issues
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Manually trigger account loading
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for async operations with longer duration
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Initially should show Follow
      expect(find.widgetWithText(ElevatedButton, 'Follow'), findsOneWidget);

      // Tap Follow button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Follow'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Now should show Unfollow
      expect(find.widgetWithText(ElevatedButton, 'Unfollow'), findsOneWidget);

      // Tap Unfollow button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Unfollow'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Back to Follow
      expect(find.widgetWithText(ElevatedButton, 'Follow'), findsOneWidget);
    });

    testWidgets('shows error state when account service fails', (tester) async {
      final fakeAccount = FakeAccountService()
        ..fail = true
        ..errorMessage = 'Failed: Unauthorized';
      final fakeTimeline = FakeTimelineService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'example.social',
              name: 'Example',
              isPixelfed: false,
            )),
            activeAccountProvider.overrideWithValue(fakeAccount.account),
            accountServiceProvider.overrideWithValue(fakeAccount),
            timelineServiceProvider.overrideWithValue(fakeTimeline),
          ],
          // Using fixed size to avoid layout issues
          child: const MaterialApp(
            home: SizedBox(
              width: 1000,
              height: 1000,
              child: ProfileScreen(accountId: '123'),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      try {
        // This should trigger the error state
        await fakeAccount.getAccount('example.social', '123');
      } catch (e) {
        // Expected to fail
      }

      // Wait for async operations with longer duration
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Look for any error message
      expect(find.textContaining('Failed'), findsOneWidget);

      // Look for any error icon and retry button
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('refresh action triggers reload of statuses', (tester) async {
      final fakeAccount = FakeAccountService();
      final fakeTimeline = FakeTimelineService()
        ..statuses = [
          model.Status(id: 'a', content: '<p>First</p>', account: fakeAccount.account),
        ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'example.social',
              name: 'Example',
              isPixelfed: false,
            )),
            activeAccountProvider.overrideWithValue(fakeAccount.account),
            accountServiceProvider.overrideWithValue(fakeAccount),
            timelineServiceProvider.overrideWithValue(fakeTimeline),
          ],
          // Use a fixed size container to avoid overflow issues
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 1000,
                height: 1000,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Manually trigger account loading
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Multiple pumps to ensure content is fully rendered
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Use a more flexible way to find the text "First" in any widget
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final String text = widget.text.toPlainText();
            return text.contains('First');
          }
          if (widget is Text) {
            return widget.data != null && widget.data!.contains('First');
          }
          return false;
        }),
        findsOneWidget,
      );

      // Update the statuses
      fakeTimeline.statuses = [
        model.Status(id: 'b', content: '<p>Second</p>', account: fakeAccount.account),
      ];

      // Trigger a refresh using the RefreshIndicator
      await tester.drag(find.byType(RefreshIndicator), const Offset(0, 500));
      await tester.pumpAndSettle();

      // Manually retrieve statuses to simulate the refresh
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for refresh to complete with multiple pumps
      await tester.pumpAndSettle(const Duration(milliseconds: 300));

      // Use the same flexible approach to find "Second"
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final String text = widget.text.toPlainText();
            return text.contains('Second');
          }
          if (widget is Text) {
            return widget.data != null && widget.data!.contains('Second');
          }
          return false;
        }),
        findsOneWidget,
      );
    });
  });
}
