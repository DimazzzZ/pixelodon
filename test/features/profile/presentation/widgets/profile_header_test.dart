import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cached_network_image/cached_network_image.dart';

import 'package:pixelodon/features/profile/presentation/widgets/profile_header.dart';
import 'package:pixelodon/features/profile/data/profile_models.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/models/instance.dart';
import '../../../../test_support/app_pump.dart';

void main() {
  group('ProfileHeader Widget Tests', () {
    late UserProfile testProfile;

    setUp(() {
      testProfile = const UserProfile(
        id: '123',
        username: 'testuser',
        acct: 'testuser@pixelfed.de',
        displayName: 'Test User',
        avatarUrl: 'https://example.com/avatar.jpg',
        coverUrl: 'https://example.com/cover.jpg',
        bio: 'Test bio content',
        interests: ['photography', 'art'],
        posts: 42,
        followers: 100,
        following: 50,
        followState: FollowState.notFollowing,
        isCurrentUser: false,
      );
    });

    group('Avatar Positioning and Elevation', () {
      testWidgets('avatar should be positioned in foreground with proper elevation', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that avatar Material widget exists with proper elevation
        final avatarMaterialFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byWidgetPredicate((widget) =>
              widget is Material &&
              widget.elevation == 16 &&
              widget.shape is CircleBorder &&
              widget.clipBehavior == Clip.antiAlias &&
              widget.color == Colors.transparent),
        );

        expect(avatarMaterialFinder, findsOneWidget, 
            reason: 'Avatar should be wrapped in Material with elevation 16 for proper layering');

        // Assert - Check that avatar container has correct dimensions
        final avatarContainerFinder = find.descendant(
          of: avatarMaterialFinder,
          matching: find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.constraints?.maxWidth == 136 &&
              widget.constraints?.maxHeight == 136),
        );

        expect(avatarContainerFinder, findsOneWidget,
            reason: 'Avatar container should have 136x136 dimensions');

        // Assert - Check that avatar has white border
        final avatarContainer = tester.widget<Container>(avatarContainerFinder);
        final decoration = avatarContainer.decoration as BoxDecoration;
        
        expect(decoration.shape, BoxShape.circle,
            reason: 'Avatar should be circular');
        expect(decoration.border?.top.color, Colors.white,
            reason: 'Avatar should have white border');
        expect(decoration.border?.top.width, 4,
            reason: 'Avatar border should be 4px wide');

        // Assert - Check that avatar has proper shadow
        expect(decoration.boxShadow, isNotNull,
            reason: 'Avatar should have shadow for depth');
        expect(decoration.boxShadow!.length, 1,
            reason: 'Avatar should have exactly one shadow');
        
        final shadow = decoration.boxShadow!.first;
        expect(shadow.color, Colors.black.withOpacity(0.12),
            reason: 'Shadow should be black with 12% opacity');
        expect(shadow.blurRadius, 20,
            reason: 'Shadow blur radius should be 20');
        expect(shadow.offset, const Offset(0, 8),
            reason: 'Shadow should have y-offset of 8');
      });

      testWidgets('avatar should be positioned correctly relative to content', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that avatar is positioned using Positioned widget
        final positionedFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byWidgetPredicate((widget) =>
              widget is Positioned &&
              widget.top == 0), // Avatar should be at top of stack
        );

        expect(positionedFinder, findsOneWidget,
            reason: 'Avatar should be positioned at top of stack using Positioned widget');

        // Get screen width to verify horizontal centering
        final screenWidth = tester.getSize(find.byType(CustomScrollView)).width;
        final expectedLeft = screenWidth / 2 - 68; // Center horizontally (136px avatar / 2)

        final positionedWidget = tester.widget<Positioned>(positionedFinder);
        expect(positionedWidget.left, expectedLeft,
            reason: 'Avatar should be horizontally centered');
      });

      testWidgets('avatar should contain CachedNetworkImage with correct URL', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that CachedNetworkImage exists with correct URL
        final cachedImageFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byWidgetPredicate((widget) =>
              widget is CachedNetworkImage &&
              widget.imageUrl == testProfile.avatarUrl),
        );

        expect(cachedImageFinder, findsOneWidget,
            reason: 'Avatar should contain CachedNetworkImage with correct URL');

        // Assert - Check that image has correct fit
        final cachedImage = tester.widget<CachedNetworkImage>(cachedImageFinder);
        expect(cachedImage.fit, BoxFit.cover,
            reason: 'Avatar image should use BoxFit.cover');
      });

      testWidgets('avatar should show placeholder when image fails to load', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        final profileWithBadUrl = testProfile.copyWith(
          avatarUrl: 'https://invalid-url.com/nonexistent.jpg',
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: profileWithBadUrl,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that placeholder icon exists
        final placeholderIconFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byIcon(Icons.person),
        );

        expect(placeholderIconFinder, findsOneWidget,
            reason: 'Avatar should show person icon as placeholder when image fails');

        // Assert - Check placeholder icon size
        final iconWidget = tester.widget<Icon>(placeholderIconFinder);
        expect(iconWidget.size, 48,
            reason: 'Placeholder icon should be 48px for 136px avatar');
      });

      testWidgets('avatar should be clipped to oval shape', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that ClipOval exists
        final clipOvalFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byType(ClipOval),
        );

        expect(clipOvalFinder, findsOneWidget,
            reason: 'Avatar image should be clipped to oval shape');

        // Assert - Check that CachedNetworkImage is inside ClipOval
        final imageInClipFinder = find.descendant(
          of: clipOvalFinder,
          matching: find.byType(CachedNetworkImage),
        );

        expect(imageInClipFinder, findsOneWidget,
            reason: 'CachedNetworkImage should be inside ClipOval');
      });
    });

    group('Profile Content Layout', () {
      testWidgets('profile content should have proper padding to accommodate avatar', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that main content container has correct top margin and padding
        final contentContainerFinder = find.descendant(
          of: find.byType(SliverProfileContent),
          matching: find.byWidgetPredicate((widget) =>
              widget is Container &&
              widget.margin == const EdgeInsets.only(top: 68) &&
              widget.padding == const EdgeInsets.fromLTRB(16.0, 76.0, 16.0, 16.0)),
        );

        expect(contentContainerFinder, findsOneWidget,
            reason: 'Content container should have 68px top margin and 76px top padding to accommodate avatar');
      });

      testWidgets('username should be displayed correctly', (WidgetTester tester) async {
        // Arrange
        const testInstance = Instance(
          domain: 'pixelfed.de',
          name: 'Pixelfed Test',
          isPixelfed: true,
        );

        // Act
        await AppPump.pumpAuthenticatedApp(
          tester,
          CustomScrollView(
            slivers: [
              SliverProfileContent(
                profile: testProfile,
                isLoading: false,
                onFollowToggle: () {},
                onEditProfile: () {},
              ),
            ],
          ),
          instance: testInstance,
        );

        await tester.pumpAndSettle();

        // Assert - Check that display name is shown
        expect(find.text(testProfile.displayName!), findsOneWidget,
            reason: 'Display name should be visible');

        // Assert - Check that handle is shown
        expect(find.textContaining('@testuser'), findsOneWidget,
            reason: 'User handle should be visible');
      });
    });
  });
}
