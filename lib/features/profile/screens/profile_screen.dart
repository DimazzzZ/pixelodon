import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/core/network/api_service.dart';
import 'package:pixelodon/services/account_service.dart';
import 'package:pixelodon/services/timeline_service.dart';
import 'package:pixelodon/features/profile/widgets/profile_header.dart';
import 'package:pixelodon/features/profile/widgets/posts_tab.dart';
import 'package:pixelodon/features/profile/widgets/info_item.dart';
import 'package:pixelodon/features/profile/widgets/profile_field_item.dart';

/// Provider for a user profile
final profileProvider =
    StateNotifierProvider.family<ProfileNotifier, ProfileState, String>(
        (ref, accountId) {
  final accountService = ref.watch(accountServiceProvider);
  final timelineService = ref.watch(timelineServiceProvider);
  final activeInstance = ref.watch(activeInstanceProvider);

  return ProfileNotifier(
    accountService: accountService,
    timelineService: timelineService,
    domain: activeInstance?.domain,
    accountId: accountId,
  );
});

/// State for a profile
class ProfileState {
  final Account? account;
  final List<model.Status> statuses;
  final bool isLoading;
  final bool isLoadingStatuses;
  final bool hasError;
  final String? errorMessage;
  final bool hasMore;
  final String? maxId;
  final bool onlyMedia;
  final bool excludeReplies;
  final bool excludeReblogs;
  final bool pinned;
  final bool isFollowing;
  final bool isFollowRequestPending;

  ProfileState({
    this.account,
    this.statuses = const [],
    this.isLoading = false,
    this.isLoadingStatuses = false,
    this.hasError = false,
    this.errorMessage,
    this.hasMore = true,
    this.maxId,
    this.onlyMedia = false,
    this.excludeReplies = false,
    this.excludeReblogs = false,
    this.pinned = false,
    this.isFollowing = false,
    this.isFollowRequestPending = false,
  });

  ProfileState copyWith({
    Account? account,
    List<model.Status>? statuses,
    bool? isLoading,
    bool? isLoadingStatuses,
    bool? hasError,
    String? errorMessage,
    bool? hasMore,
    String? maxId,
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
    bool? isFollowing,
    bool? isFollowRequestPending,
  }) {
    return ProfileState(
      account: account ?? this.account,
      statuses: statuses ?? this.statuses,
      isLoading: isLoading ?? this.isLoading,
      isLoadingStatuses: isLoadingStatuses ?? this.isLoadingStatuses,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      maxId: maxId ?? this.maxId,
      onlyMedia: onlyMedia ?? this.onlyMedia,
      excludeReplies: excludeReplies ?? this.excludeReplies,
      excludeReblogs: excludeReblogs ?? this.excludeReblogs,
      pinned: pinned ?? this.pinned,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowRequestPending:
          isFollowRequestPending ?? this.isFollowRequestPending,
    );
  }
}

/// Notifier for a profile
class ProfileNotifier extends StateNotifier<ProfileState> {
  final AccountService accountService;
  final TimelineService timelineService;
  final String? domain;
  final String accountId;
  CancelToken? _cancelToken;

  ProfileNotifier({
    required this.accountService,
    required this.timelineService,
    this.domain,
    required this.accountId,
  }) : super(ProfileState()) {
    if (domain != null) {
      loadProfile();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel('Profile navigation cancelled');
    super.dispose();
  }

  /// Set timeline filters
  void setFilters({
    bool? onlyMedia,
    bool? excludeReplies,
    bool? excludeReblogs,
    bool? pinned,
  }) {
    state = state.copyWith(
      onlyMedia: onlyMedia,
      excludeReplies: excludeReplies,
      excludeReblogs: excludeReblogs,
      pinned: pinned,
    );

    loadStatuses();
  }

  /// Load the profile
  Future<void> loadProfile() async {
    if (domain == null) return;

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

    try {
      final account = await accountService.getAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isLoading: false,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );

      loadStatuses();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load profile: $e',
      );
    }
  }

  /// Load the account's statuses
  Future<void> loadStatuses({int retryCount = 0, bool isRetry = false}) async {
    if (domain == null) return;

    // Only cancel if this is NOT a retry attempt - let retries use existing token
    if (!isRetry) {
      if (_cancelToken != null && !_cancelToken!.isCancelled) {
        _cancelToken!.cancel('New status request');
      }
      _cancelToken = CancelToken();
    }

    state = state.copyWith(
      isLoadingStatuses: true,
    );

    try {
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
        limit: 20,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
        cancelToken: _cancelToken,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        isLoadingStatuses: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      // Automatic retry for cancellation errors with longer delays to allow network requests to complete
      if (e is CancellationException && retryCount < 3) {
        final delay = Duration(
            milliseconds: 1000 *
                (retryCount +
                    1)); // 1s, 2s, 3s - more reasonable for network requests
        await Future.delayed(delay);
        return loadStatuses(retryCount: retryCount + 1, isRetry: true);
      }

      state = state.copyWith(
        isLoadingStatuses: false,
        hasError: true,
        errorMessage: 'Failed to load statuses: $e',
      );
    }
  }

  /// Refresh the profile and statuses
  Future<void> refreshProfile() async {
    if (domain == null) return;

    try {
      final account = await accountService.getAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
        hasError: false,
        errorMessage: null,
      );

      await refreshStatuses();
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to refresh profile: $e',
      );
    }
  }

  /// Refresh the account's statuses
  Future<void> refreshStatuses() async {
    if (domain == null) return;

    try {
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
        limit: 20,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: statuses,
        hasMore: statuses.length >= 20,
        maxId: maxId,
        hasError: false,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to refresh statuses: $e',
      );
    }
  }

  /// Load more statuses
  Future<void> loadMoreStatuses() async {
    if (domain == null || state.isLoadingStatuses || !state.hasMore) return;

    state = state.copyWith(
      isLoadingStatuses: true,
    );

    try {
      final statuses = await timelineService.getAccountStatuses(
        domain!,
        accountId,
        limit: 20,
        maxId: state.maxId,
        onlyMedia: state.onlyMedia,
        excludeReplies: state.excludeReplies,
        excludeReblogs: state.excludeReblogs,
        pinned: state.pinned,
      );

      String? maxId;
      if (statuses.isNotEmpty) {
        maxId = statuses.last.id;
      }

      state = state.copyWith(
        statuses: [...state.statuses, ...statuses],
        isLoadingStatuses: false,
        hasMore: statuses.length >= 20,
        maxId: maxId,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingStatuses: false,
        hasError: true,
        errorMessage: 'Failed to load more statuses: $e',
      );
    }
  }

  /// Follow the account
  Future<void> followAccount() async {
    if (domain == null || state.account == null) return;

    state = state.copyWith(
      isFollowRequestPending: state.account!.locked,
      isFollowing: !state.account!.locked,
    );

    try {
      final account = await accountService.followAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );
    } catch (e) {
      // Revert state if the API call fails
      state = state.copyWith(
        isFollowRequestPending: false,
        isFollowing: false,
        hasError: true,
        errorMessage: 'Failed to follow account: $e',
      );
    }
  }

  /// Unfollow the account
  Future<void> unfollowAccount() async {
    if (domain == null || state.account == null) return;

    state = state.copyWith(
      isFollowing: false,
      isFollowRequestPending: false,
    );

    try {
      final account = await accountService.unfollowAccount(domain!, accountId);

      state = state.copyWith(
        account: account,
        isFollowing: account.following,
        isFollowRequestPending: account.requested,
      );
    } catch (e) {
      // Revert state if the API call fails
      state = state.copyWith(
        isFollowing: true,
        hasError: true,
        errorMessage: 'Failed to unfollow account: $e',
      );
    }
  }

  /// Update a status in the timeline
  void updateStatus(model.Status status) {
    final index = state.statuses.indexWhere((s) => s.id == status.id);

    if (index != -1) {
      final updatedStatuses = List<model.Status>.from(state.statuses);
      updatedStatuses[index] = status;

      state = state.copyWith(
        statuses: updatedStatuses,
      );
    }
  }
}

/// Screen for displaying a user profile
class ProfileScreen extends ConsumerStatefulWidget {
  /// The ID of the account to display
  final String accountId;

  /// Constructor
  const ProfileScreen({
    super.key,
    required this.accountId,
  });

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.accountId));
    final profileNotifier =
        ref.read(profileProvider(widget.accountId).notifier);
    final activeInstance = ref.watch(activeInstanceProvider);
    final isPixelfed = activeInstance?.isPixelfed ?? false;

    return Scaffold(
      body: profileState.isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : profileState.hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profileState.errorMessage ?? 'An error occurred',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: profileNotifier.loadProfile,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : profileState.account == null
                  ? const Center(
                      child: Text('Account not found'),
                    )
                  : RefreshIndicator(
                      onRefresh: profileNotifier.refreshProfile,
                      child: NestedScrollView(
                        headerSliverBuilder: (context, innerBoxIsScrolled) {
                          return [
                            SliverToBoxAdapter(
                              child: ProfileHeader(
                                account: profileState.account!,
                                isPixelfed: isPixelfed,
                                isCurrentUser:
                                    (ref.read(activeAccountProvider)?.id ==
                                        widget.accountId),
                                isFollowing: profileState.isFollowing,
                                isFollowRequestPending:
                                    profileState.isFollowRequestPending,
                                activeDomain: activeInstance?.domain,
                                onFollow: profileNotifier.followAccount,
                                onUnfollow: profileNotifier.unfollowAccount,
                                onEditProfile: () {
                                  /* TODO: Navigate to edit profile */
                                },
                              ),
                            ),
                            // About section moved below description
                            SliverToBoxAdapter(
                              child: _AboutSection(account: profileState.account!),
                            ),
                          ];
                        },
                        body: PostsTab(
                          statuses: profileState.statuses,
                          isLoading: profileState.isLoadingStatuses,
                          hasError: profileState.hasError,
                          errorMessage: profileState.errorMessage,
                          hasMore: profileState.hasMore,
                          isPixelfed: isPixelfed,
                          onlyMedia: profileState.onlyMedia,
                          onLoadMore: profileNotifier.loadMoreStatuses,
                          onRefresh: profileNotifier.refreshStatuses,
                          onEnsureOnlyMedia: (onlyMedia) =>
                              profileNotifier.setFilters(onlyMedia: onlyMedia),
                          onStatusUpdated: (status) =>
                              profileNotifier.updateStatus(status),
                        ),
                      ),
                    ),
    );
  }
}


/// About section content moved from the About tab to below profile description
class _AboutSection extends StatelessWidget {
  final Account account;
  const _AboutSection({required this.account});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (account.fields != null && account.fields!.isNotEmpty) ...[
            const Text(
              'Profile Fields',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...account.fields!.map((field) => ProfileFieldItem(field: field)),
            const SizedBox(height: 16),
          ],
          const Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          InfoItem(
            label: 'Account created',
            value: account.createdAt != null
                ? '${account.createdAt!.day}/${account.createdAt!.month}/${account.createdAt!.year}'
                : 'Unknown',
          ),
          if (account.lastStatusAt != null)
            InfoItem(
              label: 'Last post',
              value:
                  '${account.lastStatusAt!.day}/${account.lastStatusAt!.month}/${account.lastStatusAt!.year}',
            ),
          InfoItem(label: 'Posts', value: account.statusesCount.toString()),
          InfoItem(label: 'Following', value: account.followingCount.toString()),
          InfoItem(label: 'Followers', value: account.followersCount.toString()),
          if (account.bot) const InfoItem(label: 'Bot account', value: 'Yes'),
          if (account.locked) const InfoItem(label: 'Private account', value: 'Yes'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
