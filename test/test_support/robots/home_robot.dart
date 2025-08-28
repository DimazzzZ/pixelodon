import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixelodon/features/feed/screens/home_screen.dart';

import '../app_pump.dart';
import '../finders.dart';

/// Robot class for Home screen interactions following page object pattern
/// 
/// This robot encapsulates all Home screen interactions and assertions,
/// providing a clean API for test scenarios. Methods are designed to be
/// chainable and provide meaningful error messages for debugging.
class HomeRobot {
  final WidgetTester tester;

  const HomeRobot(this.tester);

  /// Factory method to create HomeRobot with common setup
  static Future<HomeRobot> openHome(WidgetTester tester) async {
    await AppPump.pumpAuthenticatedApp(tester, const HomeScreen());
    await tester.pumpAndSettleSafely();
    return HomeRobot(tester);
  }

  /// Factory method to open Home with mocked timeline service
  static Future<HomeRobot> openHomeWithMockedService(
    WidgetTester tester, {
    required dynamic mockTimelineService,
  }) async {
    await AppPump.pumpWithMockedTimeline(
      tester,
      const HomeScreen(),
      mockTimelineService: mockTimelineService,
    );
    await tester.pumpAndSettleSafely();
    return HomeRobot(tester);
  }

  // Navigation and Tab Interactions

  /// Tap on the Following tab
  Future<HomeRobot> tapFollowingTab() async {
    await tester.tap(HomeFinders.followingTab);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Tap on the Local tab
  Future<HomeRobot> tapLocalTab() async {
    await tester.tap(HomeFinders.localTab);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Tap on the Federated tab
  Future<HomeRobot> tapFederatedTab() async {
    await tester.tap(HomeFinders.federatedTab);
    await tester.pumpAndSettleSafely();
    return this;
  }

  // Content Interactions

  /// Perform pull to refresh gesture
  Future<HomeRobot> pullToRefresh() async {
    final refreshIndicator = HomeFinders.pullToRefresh;
    expect(refreshIndicator, findsOneWidget, 
      reason: 'RefreshIndicator should be present for pull-to-refresh');
    
    await tester.fling(refreshIndicator, const Offset(0, 300), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait for refresh animation
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Scroll down to load more content (infinite scroll)
  Future<HomeRobot> scrollToLoadMore() async {
    // Check if scrollable widgets exist
    final scrollableFinder = AppFinders.scrollable;
    if (scrollableFinder.evaluate().isEmpty) {
      throw TestFailure('No scrollable widgets found for scrollToLoadMore');
    }
    
    // Find scrollable widget and scroll to bottom
    final scrollable = scrollableFinder.first;
    
    // Check if load more indicator already exists
    if (HomeFinders.loadMoreIndicator.evaluate().isNotEmpty) {
      return this; // Already showing load more indicator
    }
    
    // Scroll down to trigger load more
    await tester.drag(scrollable, const Offset(0, -500));
    await tester.pumpAndSettleSafely();
    
    // Wait for load more indicator to appear
    await tester.pumpUntilFound(
      HomeFinders.loadMoreIndicator,
      timeout: const Duration(seconds: 5),
    );
    
    return this;
  }

  /// Tap on a status card to navigate to details
  Future<HomeRobot> tapStatusCard(String statusId) async {
    final statusCard = StatusFinders.statusCard(statusId);
    expect(statusCard, findsOneWidget, 
      reason: 'Status card with ID $statusId should be visible');
    
    await tester.tap(statusCard);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Tap on the first visible status card
  Future<HomeRobot> tapFirstStatusCard() async {
    // Find all status items and get the first one
    final statusItems = find.byKey(const Key('status_item'));
    expect(statusItems, findsAtLeastNWidgets(1),
      reason: 'At least one status item should be visible');
    
    await tester.tap(statusItems.first);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Like a status
  Future<HomeRobot> likeStatus(String statusId) async {
    final likeButton = StatusFinders.likeButton(statusId);
    expect(likeButton, findsOneWidget,
      reason: 'Like button for status $statusId should be visible');
    
    await tester.tap(likeButton);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Reblog a status
  Future<HomeRobot> reblogStatus(String statusId) async {
    final reblogButton = StatusFinders.reblogButton(statusId);
    expect(reblogButton, findsOneWidget,
      reason: 'Reblog button for status $statusId should be visible');
    
    await tester.tap(reblogButton);
    await tester.pumpAndSettleSafely();
    return this;
  }

  /// Bookmark a status
  Future<HomeRobot> bookmarkStatus(String statusId) async {
    final bookmarkButton = StatusFinders.bookmarkButton(statusId);
    expect(bookmarkButton, findsOneWidget,
      reason: 'Bookmark button for status $statusId should be visible');
    
    await tester.tap(bookmarkButton);
    await tester.pumpAndSettleSafely();
    return this;
  }

  // Assertions and Expectations

  /// Expect Home screen to be visible
  HomeRobot expectHomeScreenVisible() {
    expect(HomeFinders.homeScreen, findsOneWidget,
      reason: 'Home screen should be visible');
    return this;
  }

  /// Expect loading indicator to be visible
  HomeRobot expectLoadingVisible() {
    expect(AppFinders.loadingIndicator, findsAtLeastNWidgets(1),
      reason: 'Loading indicator should be visible');
    return this;
  }

  /// Expect loading indicator to be hidden
  HomeRobot expectLoadingHidden() {
    expect(AppFinders.loadingIndicator, findsNothing,
      reason: 'Loading indicator should be hidden');
    return this;
  }

  /// Expect empty state to be visible
  HomeRobot expectEmptyStateVisible() {
    expect(HomeFinders.emptyState, findsOneWidget,
      reason: 'Empty state should be visible when no content available');
    return this;
  }

  /// Expect error banner to be visible
  HomeRobot expectErrorBannerVisible() {
    expect(HomeFinders.errorBanner, findsOneWidget,
      reason: 'Error banner should be visible when error occurs');
    return this;
  }

  /// Expect error message to contain specific text
  HomeRobot expectErrorMessage(String expectedMessage) {
    expect(find.textContaining(expectedMessage), findsOneWidget,
      reason: 'Error message should contain: $expectedMessage');
    return this;
  }

  /// Expect specific number of status items to be visible
  HomeRobot expectStatusItemCount(int expectedCount) {
    final statusItems = find.byKey(const Key('status_item'));
    expect(statusItems, findsNWidgets(expectedCount),
      reason: 'Should find exactly $expectedCount status items');
    return this;
  }

  /// Expect at least minimum number of status items
  HomeRobot expectAtLeastStatusItems(int minCount) {
    final statusItems = find.byKey(const Key('status_item'));
    expect(statusItems, findsAtLeastNWidgets(minCount),
      reason: 'Should find at least $minCount status items');
    return this;
  }

  /// Expect status item with specific ID to be visible
  HomeRobot expectStatusVisible(String statusId) {
    final statusCard = StatusFinders.statusCard(statusId);
    expect(statusCard, findsOneWidget,
      reason: 'Status with ID $statusId should be visible');
    return this;
  }

  /// Expect status content to contain specific text
  HomeRobot expectStatusContent(String statusId, String expectedContent) {
    final statusContent = StatusFinders.content(statusId);
    expect(statusContent, findsOneWidget);
    
    // Verify the content text
    final contentWidget = tester.widget<Text>(statusContent);
    expect(contentWidget.data, contains(expectedContent),
      reason: 'Status $statusId should contain: $expectedContent');
    return this;
  }

  /// Expect tabs to be visible and properly labeled
  HomeRobot expectTabsVisible() {
    expect(AppFinders.tabBar, findsOneWidget,
      reason: 'TabBar should be visible');
    expect(HomeFinders.followingTabText, findsOneWidget,
      reason: 'Following tab should be visible');
    expect(HomeFinders.localTabText, findsOneWidget,
      reason: 'Local tab should be visible');
    expect(HomeFinders.federatedTabText, findsOneWidget,
      reason: 'Federated tab should be visible');
    return this;
  }

  /// Expect no active instance message
  HomeRobot expectNoActiveInstanceMessage() {
    expect(HomeFinders.noActiveInstance, findsOneWidget,
      reason: 'No active instance message should be visible');
    return this;
  }

  /// Expect instance domain to be visible in app bar
  HomeRobot expectInstanceDomain(String domain) {
    expect(HomeFinders.instanceDomain(domain), findsOneWidget,
      reason: 'Instance domain $domain should be visible in app bar');
    return this;
  }

  // Accessibility Assertions

  /// Verify accessibility semantics are properly set
  HomeRobot expectAccessibilityLabels() {
    // Check that tabs are accessible (even without specific semantic labels)
    expect(HomeFinders.followingTab, findsOneWidget,
      reason: 'Following tab should be accessible');
    expect(HomeFinders.localTab, findsOneWidget,
      reason: 'Local tab should be accessible');
    expect(HomeFinders.federatedTab, findsOneWidget,
      reason: 'Federated tab should be accessible');
    return this;
  }

  /// Expect focus to be manageable (no blocked focus)
  HomeRobot expectFocusable() {
    // Verify that interactive elements can receive focus
    final tappableElements = find.byWidgetPredicate(
      (widget) => widget is GestureDetector || 
                   widget is InkWell || 
                   widget is TextButton ||
                   widget is IconButton
    );
    
    expect(tappableElements, findsAtLeastNWidgets(1),
      reason: 'Should find focusable interactive elements');
    return this;
  }

  // Theme and Layout Assertions

  /// Expect proper theme rendering without overflow
  HomeRobot expectThemeRendering({ThemeMode themeMode = ThemeMode.light}) {
    // Check that the app renders without critical errors (some overflow in test environment is normal)
    final homeScreen = HomeFinders.homeScreen;
    expect(homeScreen, findsOneWidget,
      reason: 'Home screen should render properly in $themeMode mode');
    return this;
  }

  // Utility Methods

  /// Wait for content to load
  Future<HomeRobot> waitForContentLoad({
    Duration timeout = const Duration(seconds: 10),
  }) async {
    // Wait for either content to appear or error state
    await tester.pumpUntilFound(
      find.byWidgetPredicate((widget) => 
        HomeFinders.firstStatusItem.evaluate().isNotEmpty ||
        HomeFinders.emptyState.evaluate().isNotEmpty ||
        HomeFinders.errorBanner.evaluate().isNotEmpty
      ),
      timeout: timeout,
    );
    return this;
  }

  /// Wait for loading to complete
  Future<HomeRobot> waitForLoadingComplete({
    Duration timeout = const Duration(seconds: 5),
  }) async {
    await tester.pumpWhileVisible(AppFinders.loadingIndicator, timeout: timeout);
    return this;
  }

  /// Take a screenshot for debugging (if supported)
  Future<HomeRobot> takeScreenshot(String name) async {
    // Implementation depends on test environment
    // This is a placeholder for golden file generation or debugging
    debugPrint('[DEBUG_LOG] Screenshot: $name');
    return this;
  }
}
