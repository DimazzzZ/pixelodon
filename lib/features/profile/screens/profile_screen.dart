import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/models/status.dart' as model;
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/widgets/feed/feed_list.dart';
import 'package:pixelodon/widgets/common/safe_html_widget.dart';
import 'package:pixelodon/core/network/api_service.dart';

/// Provider for a user profile
final profileProvider = StateNotifierProvider.family<ProfileNotifier, ProfileState, String>((ref, accountId) {
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
      isFollowRequestPending: isFollowRequestPending ?? this.isFollowRequestPending,
    );
  }
}

/// Notifier for a profile
class ProfileNotifier extends StateNotifier<ProfileState> {
  final accountService;
  final timelineService;
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
        isFollowing: account.following ?? false,
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
  Future<void> loadStatuses({int retryCount = 0}) async {
    if (domain == null) return;
    
    // Only cancel if there's an ongoing request
    if (_cancelToken != null && !_cancelToken!.isCancelled) {
      _cancelToken!.cancel('New status request');
    }
    _cancelToken = CancelToken();
    
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
      // Automatic retry for cancellation errors with exponential backoff
      if (e is CancellationException && retryCount < 3) {
        final delay = Duration(milliseconds: 100 * (retryCount + 1)); // 100ms, 200ms, 300ms
        await Future.delayed(delay);
        return loadStatuses(retryCount: retryCount + 1);
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
        isFollowing: account.following ?? false,
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
        isFollowing: account.following ?? false,
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
        isFollowing: account.following ?? false,
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

class _ProfileScreenState extends ConsumerState<ProfileScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider(widget.accountId));
    final profileNotifier = ref.read(profileProvider(widget.accountId).notifier);
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
                              child: _buildProfileHeader(
                                context,
                                profileState,
                                profileNotifier,
                                isPixelfed,
                              ),
                            ),
                            SliverPersistentHeader(
                              delegate: _SliverAppBarDelegate(
                                TabBar(
                                  controller: _tabController,
                                  tabs: [
                                    Tab(text: isPixelfed ? 'Media' : 'Posts'),
                                    const Tab(text: 'About'),
                                  ],
                                ),
                              ),
                              pinned: true,
                            ),
                          ];
                        },
                        body: TabBarView(
                          controller: _tabController,
                          children: [
                            // Posts / Media tab
                            _buildPostsTab(
                              profileState,
                              profileNotifier,
                              isPixelfed,
                            ),
                            
                            // About tab
                            _buildAboutTab(profileState.account!),
                          ],
                        ),
                      ),
                    ),
    );
  }
  
  /// Build the profile header
  Widget _buildProfileHeader(
    BuildContext context,
    ProfileState state,
    ProfileNotifier notifier,
    bool isPixelfed,
  ) {
    final account = state.account!;
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header image
        Stack(
          children: [
            // Header
            if (account.header != null)
              CachedNetworkImage(
                imageUrl: account.header!,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 150,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 150,
                  color: theme.colorScheme.primary.withOpacity(0.1),
                ),
              )
            else
              Container(
                height: 150,
                color: theme.colorScheme.primary.withOpacity(0.1),
              ),
            
            // Avatar
            Positioned(
              bottom: -40,
              left: 16,
              child: Material(
                elevation: 8,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 40,
                    backgroundImage: account.avatar != null
                        ? CachedNetworkImageProvider(account.avatar!)
                        : null,
                    child: account.avatar == null
                        ? Text(
                            account.displayName[0],
                            style: const TextStyle(fontSize: 32),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            
            // Follow button
            Positioned(
              bottom: 8,
              right: 16,
              child: _buildFollowButton(state, notifier),
            ),
          ],
        ),
        
        const SizedBox(height: 48),
        
        // Profile info
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display name and username
              Text(
                account.displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '@${account.username}${account.domain != null ? '@${account.domain}' : ''}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
              ),
              
              if (account.note != null && account.note!.isNotEmpty) ...[
                const SizedBox(height: 16),
                SafeHtmlWidget(htmlContent: account.note!),
              ],
              
              const SizedBox(height: 16),
              
              // Stats
              Row(
                children: [
                  _buildStatItem(
                    context,
                    account.statusesCount.toString(),
                    isPixelfed ? 'Posts' : 'Toots',
                  ),
                  _buildStatItem(
                    context,
                    account.followingCount.toString(),
                    'Following',
                  ),
                  _buildStatItem(
                    context,
                    account.followersCount.toString(),
                    'Followers',
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
            ],
          ),
        ),
      ],
    );
  }
  
  /// Build a stat item
  Widget _buildStatItem(BuildContext context, String count, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            count,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  /// Build the follow button
  Widget _buildFollowButton(ProfileState state, ProfileNotifier notifier) {
    final isCurrentUser = ref.read(activeAccountProvider)?.id == widget.accountId;
    
    if (isCurrentUser) {
      return ElevatedButton(
        onPressed: () {
          // TODO: Navigate to edit profile
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Edit Profile'),
      );
    }
    
    if (state.isFollowRequestPending) {
      return ElevatedButton(
        onPressed: notifier.unfollowAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Requested'),
      );
    }
    
    if (state.isFollowing) {
      return ElevatedButton(
        onPressed: notifier.unfollowAccount,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey[200],
          foregroundColor: Colors.black,
        ),
        child: const Text('Unfollow'),
      );
    }
    
    return ElevatedButton(
      onPressed: notifier.followAccount,
      child: const Text('Follow'),
    );
  }
  
  /// Build the posts tab
  Widget _buildPostsTab(
    ProfileState state,
    ProfileNotifier notifier,
    bool isPixelfed,
  ) {
    // Set filters based on the platform
    if (isPixelfed && !state.onlyMedia) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier.setFilters(onlyMedia: true);
      });
    }
    
    if (isPixelfed) {
      // Grid view for Pixelfed
      return state.statuses.isEmpty
          ? Center(
              child: state.isLoadingStatuses
                  ? const CircularProgressIndicator()
                  : const Text('No posts yet'),
            )
          : MasonryGridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
              itemCount: state.statuses.length + (state.isLoadingStatuses && state.hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == state.statuses.length) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                
                final status = state.statuses[index];
                
                if (status.mediaAttachments.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                final attachment = status.mediaAttachments.first;
                
                return GestureDetector(
                  onTap: () {
                    // TODO: Navigate to post detail
                  },
                  child: CachedNetworkImage(
                    imageUrl: attachment.previewUrl ?? attachment.url,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            );
    } else {
      // List view for Mastodon
      return FeedList(
        statuses: state.statuses,
        isLoading: state.isLoadingStatuses,
        hasError: state.hasError,
        errorMessage: state.errorMessage,
        hasMore: state.hasMore,
        onLoadMore: notifier.loadMoreStatuses,
        onRefresh: notifier.refreshStatuses,
        onPostLiked: (status, liked) {
          notifier.updateStatus(status);
        },
        onPostReblogged: (status, reblogged) {
          notifier.updateStatus(status);
        },
        onPostBookmarked: (status, bookmarked) {
          notifier.updateStatus(status);
        },
      );
    }
  }
  
  /// Build the about tab
  Widget _buildAboutTab(Account account) {
    return ListView(
      padding: const EdgeInsets.all(16),
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
          ...account.fields!.map((field) => _buildProfileField(field)),
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
        _buildInfoItem('Account created', account.createdAt != null
            ? '${account.createdAt!.day}/${account.createdAt!.month}/${account.createdAt!.year}'
            : 'Unknown'),
        if (account.lastStatusAt != null)
          _buildInfoItem('Last post', '${account.lastStatusAt!.day}/${account.lastStatusAt!.month}/${account.lastStatusAt!.year}'),
        _buildInfoItem('Posts', account.statusesCount.toString()),
        _buildInfoItem('Following', account.followingCount.toString()),
        _buildInfoItem('Followers', account.followersCount.toString()),
        if (account.bot)
          _buildInfoItem('Bot account', 'Yes'),
        if (account.locked)
          _buildInfoItem('Private account', 'Yes'),
      ],
    );
  }
  
  /// Build a profile field
  Widget _buildProfileField(Field field) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  field.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (field.verifiedAt != null) ...[
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.verified,
                    size: 16,
                    color: Colors.blue,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(field.value),
          ],
        ),
      ),
    );
  }
  
  /// Build an info item
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value),
          ),
        ],
      ),
    );
  }
}

/// Delegate for the sliver app bar
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  
  _SliverAppBarDelegate(this._tabBar);
  
  @override
  double get minExtent => _tabBar.preferredSize.height;
  
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }
  
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
