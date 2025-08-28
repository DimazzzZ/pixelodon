import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Typed finders for common UI elements and test keys
class AppFinders {
  // Common UI elements
  static Finder get loadingIndicator => find.byType(CircularProgressIndicator);
  static Finder get refreshIndicator => find.byType(RefreshIndicator);
  static Finder get scaffold => find.byType(Scaffold);
  static Finder get appBar => find.byType(AppBar);
  static Finder get tabBar => find.byType(TabBar);
  static Finder get tabBarView => find.byType(TabBarView);

  // Text finders
  static Finder textContaining(String text) => find.textContaining(text);
  static Finder exactText(String text) => find.text(text);

  // Icon finders
  static Finder icon(IconData iconData) => find.byIcon(iconData);
  static Finder get homeIcon => find.byIcon(Icons.home_outlined);
  static Finder get localIcon => find.byIcon(Icons.apartment_outlined);
  static Finder get publicIcon => find.byIcon(Icons.public);
  static Finder get settingsIcon => find.byIcon(Icons.settings);

  // Widget type finders
  static Finder byType<T extends Widget>() => find.byType(T);
  static Finder byWidgetPredicate(bool Function(Widget) predicate) => 
      find.byWidgetPredicate(predicate);

  // Semantics finders for accessibility
  static Finder bySemanticsLabel(String label) => find.bySemanticsLabel(label);
  static Finder byTooltip(String tooltip) => find.byTooltip(tooltip);

  // List and scroll finders
  static Finder get scrollable => find.byType(Scrollable);
  static Finder get listView => find.byType(ListView);
  static Finder get sliverList => find.byType(SliverList);

  // Error state finders
  static Finder get errorWidget => find.textContaining('error');
  static Finder get retryButton => find.text('Retry');
  static Finder get errorBanner => find.byType(MaterialBanner);
  static Finder get snackBar => find.byType(SnackBar);
}

/// Home screen specific finders
class HomeFinders {
  // Test keys for Home screen elements (to be added to widgets)
  static const String homeScreenKey = 'home_screen';
  static const String followingTabKey = 'following_tab';
  static const String localTabKey = 'local_tab';
  static const String federatedTabKey = 'federated_tab';
  static const String feedListKey = 'feed_list';
  static const String statusItemKey = 'status_item';
  static const String loadMoreButtonKey = 'load_more_button';
  static const String emptyStateKey = 'empty_state';
  static const String errorBannerKey = 'error_banner';

  // Key-based finders
  static Finder get homeScreen => find.byKey(const Key(homeScreenKey));
  static Finder get followingTab => find.byKey(const Key(followingTabKey));
  static Finder get localTab => find.byKey(const Key(localTabKey));
  static Finder get federatedTab => find.byKey(const Key(federatedTabKey));
  static Finder get feedList => find.byKey(const Key(feedListKey));
  static Finder get emptyState => find.byKey(const Key(emptyStateKey));
  static Finder get errorBanner => find.byKey(const Key(errorBannerKey));

  // Tab text finders
  static Finder get followingTabText => find.text('Following');
  static Finder get localTabText => find.text('Local');
  static Finder get federatedTabText => find.text('Federated');

  // Status item finders
  static Finder statusItem(int index) => 
      find.byKey(Key('${statusItemKey}_$index'));
  static Finder get firstStatusItem => statusItem(0);
  static Finder get lastStatusItem => find.byKey(const Key('last_status_item'));

  // Content state finders
  static Finder get noActiveInstance => find.text('No active instance selected');
  static Finder get loadingShimmer => find.byWidgetPredicate((widget) => 
    widget is Container && 
    widget.decoration != null
  );

  // Action finders
  static Finder get pullToRefresh => find.byType(RefreshIndicator);
  static Finder get loadMoreIndicator => find.text('Loading more...');
  
  // Error state specific finders
  static Finder get networkErrorMessage => find.textContaining('Failed to load timeline');
  static Finder get refreshErrorMessage => find.textContaining('Failed to refresh timeline');
  static Finder get loadMoreErrorMessage => find.textContaining('Failed to load more posts');

  // Instance-related finders
  static Finder instanceDomain(String domain) => find.text(domain);
  static Finder get testInstanceDomain => instanceDomain('test.example.com');
}

/// Status card specific finders
class StatusFinders {
  static const String statusCardKey = 'status_card';
  static const String avatarKey = 'status_avatar';
  static const String usernameKey = 'status_username';
  static const String contentKey = 'status_content';
  static const String actionsKey = 'status_actions';
  static const String likeButtonKey = 'like_button';
  static const String reblogButtonKey = 'reblog_button';
  static const String bookmarkButtonKey = 'bookmark_button';

  // Status card components
  static Finder statusCard(String statusId) => 
      find.byKey(Key('${statusCardKey}_$statusId'));
  static Finder avatar(String statusId) => 
      find.byKey(Key('${avatarKey}_$statusId'));
  static Finder username(String statusId) => 
      find.byKey(Key('${usernameKey}_$statusId'));
  static Finder content(String statusId) => 
      find.byKey(Key('${contentKey}_$statusId'));
  
  // Action buttons
  static Finder likeButton(String statusId) => 
      find.byKey(Key('${likeButtonKey}_$statusId'));
  static Finder reblogButton(String statusId) => 
      find.byKey(Key('${reblogButtonKey}_$statusId'));
  static Finder bookmarkButton(String statusId) => 
      find.byKey(Key('${bookmarkButtonKey}_$statusId'));

  // Generic action finders
  static Finder get anyLikeButton => find.byKey(const Key(likeButtonKey));
  static Finder get anyReblogButton => find.byKey(const Key(reblogButtonKey));
  static Finder get anyBookmarkButton => find.byKey(const Key(bookmarkButtonKey));
}

/// Navigation and routing finders
class NavigationFinders {
  // Bottom navigation
  static Finder get bottomNavigation => find.byType(BottomNavigationBar);
  static Finder navItem(String label) => find.text(label);
  
  // App bar navigation
  static Finder get backButton => find.byIcon(Icons.arrow_back);
  static Finder get closeButton => find.byIcon(Icons.close);
  
  // Floating action button
  static Finder get floatingActionButton => find.byType(FloatingActionButton);
}

/// Accessibility-specific finders
class AccessibilityFinders {
  // Semantic finders
  static Finder withSemantics(String label) => find.bySemanticsLabel(label);
  static Finder withTooltip(String tooltip) => find.byTooltip(tooltip);
  
  // Focus-related finders
  static Finder get focusedWidget => find.byWidgetPredicate(
    (widget) => widget is Focus && widget.autofocus
  );
  
  // Screen reader announcements
  static Finder semanticsContaining(String text) => find.byWidgetPredicate(
    (widget) => widget is Semantics && 
                widget.properties.label?.contains(text) == true
  );
}
