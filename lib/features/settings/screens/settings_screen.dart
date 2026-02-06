import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/providers/service_providers.dart';
import 'package:pixelodon/repositories/auth_repository.dart';

/// Settings screen with platform-specific design following established patterns
class SettingsScreen extends ConsumerWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (Platform.isIOS) {
      return _buildIOSScaffold(context, ref);
    } else {
      return _buildMaterialScaffold(context, ref);
    }
  }

  /// Build iOS-style scaffold with CupertinoNavigationBar
  Widget _buildIOSScaffold(BuildContext context, WidgetRef ref) {
    return CupertinoPageScaffold(
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          children: [
            // Navigation bar
            CupertinoNavigationBar(
              middle: const Text('Settings'),
              backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
            ),
            // Content
            Expanded(
              child: _buildIOSContent(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  /// Build Material-style scaffold with NestedScrollView
  Widget _buildMaterialScaffold(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar.medium(
            title: const Text('Settings'),
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
            forceElevated: innerBoxIsScrolled,
          ),
        ],
        body: _buildMaterialContent(context, ref),
      ),
    );
  }

  /// Build iOS-style content with grouped lists
  Widget _buildIOSContent(BuildContext context, WidgetRef ref) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final instances = ref.watch(instancesProvider);
    return CupertinoScrollbar(
      child: ListView(
        padding: const EdgeInsets.only(top: 20),
        children: [
          // Accounts Section
          if (instances.isNotEmpty) ...[
            _buildIOSSection(
              title: 'Accounts',
              children: [
                for (int i = 0; i < instances.length; i++)
                  _buildAccountListTile(context, ref, instances[i], activeInstance),
              ],
            ),
          ],

          // Add Account Button
          _buildIOSSection(
            children: [
              CupertinoListTile(
                title: const Text('Add Account'),
                leading: const Icon(CupertinoIcons.add),
                trailing: const CupertinoListTileChevron(),
                onTap: () => _addAccount(context),
              ),
            ],
          ),

          // App Settings Section
          _buildIOSSection(
            title: 'App Settings',
            children: [
              _buildThemeListTile(context, ref),
              _buildNotificationListTile(context, ref),
              _buildLanguageListTile(context, ref),
            ],
          ),

          // About Section
          _buildIOSSection(
            title: 'About',
            children: [
              _buildAboutListTile(context),
              _buildPrivacyListTile(context),
              _buildTermsListTile(context),
            ],
          ),
        ],
      ),
    );
  }

  /// Build Material-style content with proper sections
  Widget _buildMaterialContent(BuildContext context, WidgetRef ref) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final instances = ref.watch(instancesProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Accounts Section
        if (instances.isNotEmpty) ...[
          Text(
            'Accounts',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.surfaceContainerLow,
            ),
            child: Column(
              children: [
                for (int i = 0; i < instances.length; i++) ...[
                  _buildAccountListTile(context, ref, instances[i], activeInstance),
                  if (i < instances.length - 1)
                    Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Add Account Button
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: ListTile(
            leading: Icon(
              Icons.add,
              color: Theme.of(context).colorScheme.primary,
            ),
            title: Text(
              'Add Account',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            onTap: () => _addAccount(context),
          ),
        ),

        const SizedBox(height: 32),

        // App Settings Section
        Text(
          'App Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Column(
            children: [
              _buildThemeListTile(context, ref),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _buildNotificationListTile(context, ref),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _buildLanguageListTile(context, ref),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // About Section
        Text(
          'About',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Theme.of(context).colorScheme.surfaceContainerLow,
          ),
          child: Column(
            children: [
              _buildAboutListTile(context),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _buildPrivacyListTile(context),
              Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant),
              _buildTermsListTile(context),
            ],
          ),
        ),

        // Logout Button (only show if there are accounts)
        if (instances.isNotEmpty)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.1),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                'Log Out Current Account',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              onTap: activeInstance != null
                  ? () => _showLogoutDialog(context, ref, activeInstance.domain)
                  : null,
            ),
          ),

        const SizedBox(height: 32),
      ],
    );
  }

  /// Build iOS-style section with optional title
  Widget _buildIOSSection({String? title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Text(
                title.toUpperCase(),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: CupertinoColors.secondaryLabel,
                ),
              ),
            ),
          ],
          CupertinoListSection.insetGrouped(
            margin: EdgeInsets.zero,
            children: children,
          ),
        ],
      ),
    );
  }

  /// Build theme list tile
  Widget _buildThemeListTile(BuildContext context, WidgetRef ref) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.palette_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.paintbrush),
      ),
      title: const Text('Theme'),
      subtitle: Text(ref.read(themeModeNotifierProvider.notifier).themeModeDisplayName),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showThemeSelection(context, ref),
    );
  }

  /// Build notification list tile
  Widget _buildNotificationListTile(BuildContext context, WidgetRef ref) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.notifications_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.bell),
      ),
      title: const Text('Notifications'),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showNotificationSettings(context, ref),
    );
  }

  /// Build language list tile
  Widget _buildLanguageListTile(BuildContext context, WidgetRef ref) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.language_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.globe),
      ),
      title: const Text('Language'),
      subtitle: Text(ref.read(languageNotifierProvider.notifier).languageDisplayName),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showLanguageSelection(context, ref),
    );
  }

  /// Build about list tile
  Widget _buildAboutListTile(BuildContext context) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.info_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.info_circle),
      ),
      title: const Text('About Pixelodon'),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showAboutDialog(context),
    );
  }

  /// Build privacy list tile
  Widget _buildPrivacyListTile(BuildContext context) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.privacy_tip_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.shield),
      ),
      title: const Text('Privacy Policy'),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showPrivacyPolicy(context),
    );
  }

  /// Build terms list tile
  Widget _buildTermsListTile(BuildContext context) {
    return PlatformListTile(
      leading: PlatformWidget(
        material: (_, __) => const Icon(Icons.description_outlined),
        cupertino: (_, __) => const Icon(CupertinoIcons.doc_text),
      ),
      title: const Text('Terms of Service'),
      trailing: PlatformWidget(
        material: (_, __) => const Icon(Icons.arrow_forward_ios, size: 16),
        cupertino: (_, __) => const CupertinoListTileChevron(),
      ),
      onTap: () => _showTermsOfService(context),
    );
  }
  
  /// Shows logout confirmation dialog
  void _showLogoutDialog(BuildContext context, WidgetRef ref, String domain) {
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return PlatformAlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out? You will need to log in again to access your account.'),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            PlatformDialogAction(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performLogout(context, ref, domain);
              },
              material: (_, __) => MaterialDialogActionData(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );
  }
  
  /// Performs the logout operation
  Future<void> _performLogout(BuildContext context, WidgetRef ref, String domain) async {
    try {
      // Show loading indicator
      if (context.mounted) {
        _showSnackBar(context, const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 16),
              Text('Logging out...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ));
      }
      
      // Perform logout through the auth repository
      final authRepository = ref.read(authRepositoryProvider.notifier);
      await authRepository.logout(domain);
      
      // Navigate to login screen
      if (context.mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        _showSnackBar(context, SnackBar(
          content: Text('Failed to log out: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }
  
  /// Builds a list tile for an account
  Widget _buildAccountListTile(BuildContext context, WidgetRef ref, Instance instance, Instance? activeInstance) {
    final account = ref.watch(accountInfoProvider(instance.domain));
    final isActive = activeInstance?.domain == instance.domain;
    
    return PlatformListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isActive ? Colors.blue.withOpacity(0.2) : Colors.blue.withOpacity(0.1),
          image: account?.avatar != null 
              ? DecorationImage(
                  image: NetworkImage(account!.avatar!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: account?.avatar == null 
            ? Icon(
                instance.isPixelfed ? Icons.photo_camera : Icons.chat_bubble,
                color: Colors.blue,
              )
            : null,
      ),
      title: Text(
        account?.displayName ?? account?.username ?? 'Unknown User',
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Text('@${account?.acct ?? 'unknown'}@${instance.domain}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            PlatformWidget(
              material: (_, __) => Icon(
                Icons.check_circle,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              cupertino: (_, __) => Icon(
                CupertinoIcons.checkmark_circle_fill,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          const SizedBox(width: 8),
          PlatformIconButton(
            icon: PlatformWidget(
              material: (_, __) => const Icon(Icons.more_vert),
              cupertino: (_, __) => const Icon(CupertinoIcons.ellipsis_vertical),
            ),
            onPressed: () => _showAccountActions(context, ref, instance, isActive),
          ),
        ],
      ),
      onTap: !isActive ? () => _switchAccount(context, ref, instance.domain) : null,
    );
  }
  
  
  /// Switches to the specified account
  void _switchAccount(BuildContext context, WidgetRef ref, String domain) {
    final authRepository = ref.read(authRepositoryProvider.notifier);
    authRepository.setActiveInstance(domain);
    
    // Navigate to home and update bottom navigation state
    ref.read(currentIndexProvider.notifier).setIndex(0); // Set to Home tab
    context.go('/home');
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Switched to account on $domain'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
  
  /// Shows the add account dialog/navigation
  void _addAccount(BuildContext context) {
    // Navigate to the login screen to add a new account
    context.go('/auth/login');
  }
  
  /// Shows account actions using platform-appropriate UI
  void _showAccountActions(BuildContext context, WidgetRef ref, Instance instance, bool isActive) {
    if (Platform.isIOS) {
      showCupertinoModalPopup(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: const Text('Account Actions'),
          actions: [
            if (!isActive)
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.of(context).pop();
                  _switchAccount(context, ref, instance.domain);
                },
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.arrow_2_squarepath, size: 20),
                    SizedBox(width: 8),
                    Text('Switch to this account'),
                  ],
                ),
              ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.of(context).pop();
                _showRemoveAccountDialog(context, ref, instance);
              },
              isDestructiveAction: true,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.minus_circle, size: 20),
                  SizedBox(width: 8),
                  Text('Remove account'),
                ],
              ),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ),
      );
    } else {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Account Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (!isActive)
                ListTile(
                  leading: const Icon(Icons.swap_horiz),
                  title: const Text('Switch to this account'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _switchAccount(context, ref, instance.domain);
                  },
                ),
              ListTile(
                leading: Icon(
                  Icons.remove_circle_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                title: Text(
                  'Remove account',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showRemoveAccountDialog(context, ref, instance);
                },
              ),
            ],
          ),
        ),
      );
    }
  }
  
  /// Shows the remove account confirmation dialog
  void _showRemoveAccountDialog(BuildContext context, WidgetRef ref, Instance instance) {
    final account = ref.read(accountInfoProvider(instance.domain));
    
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return PlatformAlertDialog(
          title: const Text('Remove Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Are you sure you want to remove this account?'),
              const SizedBox(height: 16),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    backgroundImage: account?.avatar != null ? NetworkImage(account!.avatar!) : null,
                    child: account?.avatar == null 
                        ? Icon(
                            instance.isPixelfed ? Icons.photo_camera : Icons.chat_bubble,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          )
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          account?.displayName ?? account?.username ?? 'Unknown User',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text('@${account?.acct ?? 'unknown'}'),
                        Text(
                          instance.domain,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text('This will log you out from this account and remove it from the app.'),
            ],
          ),
          actions: [
            PlatformDialogAction(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            PlatformDialogAction(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeAccount(context, ref, instance.domain);
              },
              material: (_, __) => MaterialDialogActionData(
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              ),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }
  
  /// Removes an account from the app
  Future<void> _removeAccount(BuildContext context, WidgetRef ref, String domain) async {
    try {
      // Show loading indicator
      _showSnackBar(context, const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Removing account...'),
          ],
        ),
        duration: Duration(seconds: 3),
      ));
      
      // Perform logout through the auth repository
      final authRepository = ref.read(authRepositoryProvider.notifier);
      await authRepository.logout(domain);

      // Show success message
      if (context.mounted) {
        _showSnackBar(context, SnackBar(
          content: Text('Account removed from $domain'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ));

        // If no accounts left, navigate to login
        // Check the instances provider directly
        final instances = ref.read(instancesProvider);
        if (instances.isEmpty) {
          context.go('/auth/login');
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        _showSnackBar(context, SnackBar(
          content: Text('Failed to remove account: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ));
      }
    }
  }

  /// Safely shows a SnackBar, handling cases where ScaffoldMessenger is not available
  void _showSnackBar(BuildContext context, SnackBar snackBar) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    } catch (e) {
      // If ScaffoldMessenger is not available, print to debug console
      debugPrint('Could not show SnackBar: ${snackBar.content}');
    }
  }

  /// Shows theme selection dialog
  void _showThemeSelection(BuildContext context, WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    final availableThemes = settingsService.getAvailableThemeModes();
    final currentTheme = ref.read(themeModeNotifierProvider);

    showPlatformModalSheet(
      context: context,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Theme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...availableThemes.map((theme) => PlatformListTile(
              title: Text(settingsService.getThemeModeDisplayName(theme)),
              trailing: currentTheme == theme
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await ref.read(themeModeNotifierProvider.notifier).setThemeMode(theme);
                if (context.mounted) Navigator.of(context).pop();
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Shows language selection dialog - coming soon alert
  void _showLanguageSelection(BuildContext context, WidgetRef ref) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('Language Settings'),
        content: const Text('Language settings will be added soon but are not yet available.'),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows notification settings
  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    showPlatformModalSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final notificationSettings = ref.watch(notificationSettingsNotifierProvider);
          
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Notification Settings',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                ...notificationSettings.entries.map((entry) => PlatformListTile(
                  title: Text(_getNotificationDisplayName(entry.key)),
                  trailing: PlatformSwitch(
                    value: entry.value,
                    onChanged: (value) async {
                      await ref.read(notificationSettingsNotifierProvider.notifier)
                          .updateSetting(entry.key, value);
                    },
                  ),
                )),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Gets display name for notification type
  String _getNotificationDisplayName(String key) {
    switch (key) {
      case 'mentions':
        return 'Mentions';
      case 'follows':
        return 'New Followers';
      case 'likes':
        return 'Likes';
      case 'reposts':
        return 'Reposts';
      case 'posts':
        return 'New Posts';
      default:
        return key;
    }
  }

  /// Shows about dialog
  void _showAboutDialog(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('About Pixelodon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              width: 64,
              height: 64,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 16),
            const Text('Version 1.0.0'),
            const SizedBox(height: 8),
            const Text(
              'A modern, privacy-respecting Fediverse client for Mastodon and Pixelfed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows privacy policy
  void _showPrivacyPolicy(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('Privacy Policy'),
        content: const Text('Privacy policy implementation coming soon.'),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Shows terms of service
  void _showTermsOfService(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: const Text('Terms of Service'),
        content: const Text('Terms of service implementation coming soon.'),
        actions: [
          PlatformDialogAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
