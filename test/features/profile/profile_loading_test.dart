import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pixelodon/features/profile/screens/profile_screen.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/repositories/auth_repository.dart';
import 'package:pixelodon/services/auth_service.dart';

ApiService _dummyApi() => ApiService(authRepository: AuthRepository(authService: AuthService()));

class TinyFakeAccountService extends AccountService {
  TinyFakeAccountService() : super(apiService: _dummyApi());

  Account account = const Account(
    id: '123',
    username: 'tester',
    acct: 'tester',
    displayName: 'Test User',
    // avatar/header null to avoid network
  );

  bool delay = true;

  @override
  Future<Account> getAccount(String domain, String id) async {
    if (delay) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    return account;
  }
}

class TinyFakeTimelineService extends TimelineService {
  TinyFakeTimelineService() : super(apiService: _dummyApi());

  List<model.Status> statuses = const [];

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
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return statuses;
  }
}

void main() {
  group('ProfileScreen Loading Tests', () {
    testWidgets('shows loading indicator while profile is loading', (tester) async {
      final acc = TinyFakeAccountService();
      final tl = TinyFakeTimelineService();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'example.social',
              name: 'Example',
              isPixelfed: false,
            )),
            activeAccountProvider.overrideWithValue(acc.account),
            accountServiceProvider.overrideWithValue(acc),
            timelineServiceProvider.overrideWithValue(tl),
          ],
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      // Before futures resolve, a loading indicator is shown
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Pixelfed: shows "No posts yet" when not loading and there are no posts', (tester) async {
      final acc = TinyFakeAccountService()..delay = false; // faster
      final tl = TinyFakeTimelineService()..statuses = const [];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeInstanceProvider.overrideWithValue(const Instance(
              domain: 'pix.example',
              name: 'Pix',
              isPixelfed: true,
            )),
            activeAccountProvider.overrideWithValue(acc.account),
            accountServiceProvider.overrideWithValue(acc),
            timelineServiceProvider.overrideWithValue(tl),
          ],
          child: const MaterialApp(home: ProfileScreen(accountId: '123')),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('No posts yet'), findsOneWidget);
    });
  });
}
