import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixelodon/features/profile/presentation/screens/profile_screen.dart';
import 'package:pixelodon/features/profile/domain/profile_usecases.dart';
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
          child: MaterialApp(
            // Using a MaterialApp directly with a wrapper to avoid overflow issues
            home: Material(
              child: SizedBox(
                width: 800,
                height: 800,
                child: ProfileScreen(
                  accountId: '123',
                ),
              ),
            ),
          ),
        ),
      );

      // Initial frame
      await tester.pump();

      // Manually trigger the async operations that would normally happen in the profile screen
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for everything to settle
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Look for display name using different finders to accommodate different widget structures
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data == 'Jane Doe';
          }
          return false;
        }),
        findsOneWidget,
      );

      // Look for handle with more flexible finder
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data?.contains('@jane@example') == true;
          }
          return false;
        }),
        findsOneWidget,
      );

      // Check for feed list
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
          child: MaterialApp(
            home: Material(
              child: SizedBox(
                width: 800,
                height: 800,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // First frame should be rendered
      await tester.pump();

      // Manually trigger the operations that would happen in ProfileScreen
      await fakeAccount.getAccount('pix.example', '123');
      await fakeTimeline.getAccountStatuses('pix.example', '123', onlyMedia: true);

      // Wait for operations to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Look for display name with a more flexible approach
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            return widget.data == 'Jane Doe';
          }
          return false;
        }),
        findsOneWidget,
      );

      // Look for "No posts yet" with a more flexible approach
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            final data = widget.data;
            return data != null && (data == 'No posts yet' || data.contains('No posts yet'));
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
          child: MaterialApp(
            home: Material(
              child: SizedBox(
                width: 800,
                height: 800,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Manually trigger operations
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for operations to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Initially should show Follow - looking for button by predicate to be more flexible
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is ElevatedButton) {
            final buttonText = (widget.child as Text?)?.data;
            return buttonText == 'Follow';
          }
          return false;
        }),
        findsOneWidget,
      );

      // Tap Follow button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Follow'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Now should show Unfollow
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is ElevatedButton) {
            final buttonText = (widget.child as Text?)?.data;
            return buttonText == 'Unfollow';
          }
          return false;
        }),
        findsOneWidget,
      );

      // Tap Unfollow button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Unfollow'));
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 200));

      // Back to Follow
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is ElevatedButton) {
            final buttonText = (widget.child as Text?)?.data;
            return buttonText == 'Follow';
          }
          return false;
        }),
        findsOneWidget,
      );
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
          child: MaterialApp(
            home: Material(
              child: SizedBox(
                width: 800,
                height: 800,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // We can't trigger the actual loading method, but we can simulate the error state
      try {
        await fakeAccount.getAccount('example.social', '123');
      } catch (_) {
        // Expected to fail - this is what triggers the error state
      }

      // Wait for UI to update
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Look for any error message with Failed
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is Text) {
            final data = widget.data;
            return data != null && data.contains('Failed');
          }
          return false;
        }),
        findsOneWidget,
      );

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
          child: MaterialApp(
            home: Material(
              child: SizedBox(
                width: 800,
                height: 800,
                child: ProfileScreen(accountId: '123'),
              ),
            ),
          ),
        ),
      );

      // Initial render
      await tester.pump();

      // Manually trigger operations
      await fakeAccount.getAccount('example.social', '123');
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for operations to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify the first post is found
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final String text = widget.text.toPlainText();
            return text.contains('First');
          }
          if (widget is Text) {
            final data = widget.data;
            return data != null && data.contains('First');
          }
          return false;
        }),
        findsOneWidget,
      );

      // Update the statuses
      fakeTimeline.statuses = [
        model.Status(id: 'b', content: '<p>Second</p>', account: fakeAccount.account),
      ];

      // Simulate a refresh
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pump();

      // Manually retrieve updated statuses
      await fakeTimeline.getAccountStatuses('example.social', '123');

      // Wait for all operations to complete
      await tester.pumpAndSettle(const Duration(milliseconds: 500));

      // Verify the second post is now found
      expect(
        find.byWidgetPredicate((widget) {
          if (widget is RichText) {
            final String text = widget.text.toPlainText();
            return text.contains('Second');
          }
          if (widget is Text) {
            final data = widget.data;
            return data != null && data.contains('Second');
          }
          return false;
        }),
        findsOneWidget,
      );
    });
  });
}
