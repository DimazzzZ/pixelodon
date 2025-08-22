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
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return account;
  }

  @override
  Future<Account> followAccount(String domain, String id) async {
    account = account.copyWith(following: true, requested: false);
    return account;
  }

  @override
  Future<Account> unfollowAccount(String domain, String id) async {
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
    await Future<void>.delayed(const Duration(milliseconds: 10));
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
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for futures
      await tester.pumpAndSettle();

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
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      // Initial loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();

      // Empty grid message should appear with pull-to-refresh support
      expect(find.text('No posts yet'), findsOneWidget);
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
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      await tester.pumpAndSettle();

      // Initially should show Follow
      expect(find.text('Follow'), findsOneWidget);

      // Tap Follow
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();

      // Now should show Unfollow
      expect(find.text('Unfollow'), findsOneWidget);

      // Tap Unfollow
      await tester.tap(find.text('Unfollow'));
      await tester.pumpAndSettle();

      // Back to Follow
      expect(find.text('Follow'), findsOneWidget);
    });

    testWidgets('shows error state when account service fails', (tester) async {
      final fakeAccount = FakeAccountService()
        ..fail = true
        ..errorMessage = 'Unauthorized';
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
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      await tester.pumpAndSettle();

      // Error icon and retry
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.textContaining('Failed to load profile'), findsOneWidget);

      // Retry should call again (but still fails), verify button exists
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
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.textContaining('First'), findsOneWidget);

      // Update the statuses and pull-to-refresh
      fakeTimeline.statuses = [
        model.Status(id: 'b', content: '<p>Second</p>', account: fakeAccount.account),
      ];

      // Trigger refresh via RefreshIndicator
      final gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, 300));
      await tester.pump(const Duration(seconds: 1));
      await gesture.up();

      await tester.pumpAndSettle();

      expect(find.textContaining('Second'), findsOneWidget);
    });
  });
}
