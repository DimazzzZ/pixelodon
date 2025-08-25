import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:pixelodon/core/routing/app_router.dart';

/// Settings screen with logout functionality
class SettingsScreen extends ConsumerWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final instances = ref.watch(instancesProvider);

    return PlatformScaffold(
      appBar: PlatformAppBar(
        title: PlatformText('Settings'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Accounts Section
            _buildSectionHeader(context, 'Accounts'),
            const SizedBox(height: 16),

            // List of accounts
            if (instances.isNotEmpty) ...[
              _buildSection(
                context,
                children: [
                  for (int i = 0; i < instances.length; i++) ...[
                    _buildAccountListTile(context, ref, instances[i], activeInstance),
                    if (i < instances.length - 1)
                      PlatformWidget(
                        material: (_, __) => const Divider(height: 1),
                        cupertino: (_, __) => Container(
                          height: 1,
                          color: CupertinoColors.separator.resolveFrom(context),
                          margin: const EdgeInsets.only(left: 16),
                        ),
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Add Account
            PlatformWidget(
              material: (_, __) => SizedBox(
                width: double.infinity,
                child: PlatformElevatedButton(
                  onPressed: () => _addAccount(context),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PlatformIcons(context).add),
                      const SizedBox(width: 8),
                      PlatformText('Add Account'),
                    ],
                  ),
                  material: (_, __) => MaterialElevatedButtonData(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Theme.of(context).colorScheme.outline),
                      backgroundColor: Colors.transparent,
                      foregroundColor: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              cupertino: (_, __) => _buildSection(
                context,
                children: [
                  CupertinoListTile(
                    leading: Icon(CupertinoIcons.add),
                    title: Text('Add Account'),
                    trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
                    onTap: () => _addAccount(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Settings Section
            _buildSectionHeader(context, 'App Settings'),
            const SizedBox(height: 16),
            _buildSection(
              context,
              children: [
                _buildSettingsListTile(
                  context,
                  icon: isCupertino(context) ? CupertinoIcons.paintbrush : Icons.palette,
                  title: 'Theme',
                  subtitle: 'Light',
                  onTap: () => _showComingSoon(context, 'Theme selection'),
                ),
                _buildDivider(context),
                _buildSettingsListTile(
                  context,
                  icon: isCupertino(context) ? CupertinoIcons.bell : Icons.notifications,
                  title: 'Notifications',
                  onTap: () => _showComingSoon(context, 'Notification settings'),
                ),
                _buildDivider(context),
                _buildSettingsListTile(
                  context,
                  icon: isCupertino(context) ? CupertinoIcons.globe : Icons.language,
                  title: 'Language',
                  subtitle: 'English',
                  onTap: () => _showComingSoon(context, 'Language selection'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // About Section
            _buildSectionHeader(context, 'About'),
            const SizedBox(height: 16),
            _buildSection(
              context,
              children: [
                _buildSettingsListTile(
                  context,
                  icon: PlatformIcons(context).info,
                  title: 'About Pixelodon',
                  onTap: () => _showAbout(context),
                ),
                _buildDivider(context),
                _buildSettingsListTile(
                  context,
                  icon: isCupertino(context) ? CupertinoIcons.lock : Icons.privacy_tip,
                  title: 'Privacy Policy',
                  onTap: () => _showComingSoon(context, 'Privacy policy'),
                ),
                _buildDivider(context),
                _buildSettingsListTile(
                  context,
                  icon: isCupertino(context) ? CupertinoIcons.doc_text : Icons.description,
                  title: 'Terms of Service',
                  onTap: () => _showComingSoon(context, 'Terms of service'),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Logout (only show if there are accounts)
            if (instances.isNotEmpty)
              PlatformWidget(
                // Android/Material: keep existing elevated destructive button
                material: (_, __) => SizedBox(
                  width: double.infinity,
                  child: PlatformElevatedButton(
                    onPressed: activeInstance != null
                        ? () => _showLogoutDialog(context, ref, activeInstance.domain)
                        : null,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.logout),
                        SizedBox(width: 8),
                        Text('Log Out Current Account'),
                      ],
                    ),
                    material: (_, __) => MaterialElevatedButtonData(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.error,
                        foregroundColor: Theme.of(context).colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ),
                // iOS/Cupertino: use a white row with centered red text per iOS guidelines
                cupertino: (_, __) => _buildSection(
                  context,
                  children: [
                    CupertinoListTile(
                      title: const Text(
                        'Log Out Current Account',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: CupertinoColors.destructiveRed),
                      ),
                      onTap: activeInstance != null
                          ? () => _showLogoutDialog(context, ref, activeInstance.domain)
                          : null,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header with platform-appropriate styling
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: isCupertino(context)
          ? CupertinoTheme.of(context).textTheme.navTitleTextStyle.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w600,
            )
          : Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
    );
  }

  /// Builds a platform-appropriate section container
  Widget _buildSection(BuildContext context, {required List<Widget> children}) {
    return PlatformWidget(
      material: (_, __) => Card(
        child: Column(children: children),
      ),
      cupertino: (_, __) => Container(
        decoration: BoxDecoration(
          color: CupertinoColors.systemBackground.resolveFrom(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: CupertinoColors.separator.resolveFrom(context),
            width: 0.5,
          ),
        ),
        child: Column(children: children),
      ),
    );
  }

  /// Builds a platform-appropriate divider
  Widget _buildDivider(BuildContext context) {
    return PlatformWidget(
      material: (_, __) => const Divider(height: 1),
      cupertino: (_, __) => Container(
        height: 0.5,
        color: CupertinoColors.separator.resolveFrom(context),
        margin: const EdgeInsets.only(left: 16),
      ),
    );
  }

  /// Builds a settings list tile with platform-appropriate styling
  Widget _buildSettingsListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return PlatformWidget(
      material: (_, __) => ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
      cupertino: (_, __) => CupertinoListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: subtitle != null ? Text(subtitle) : null,
        trailing: const Icon(CupertinoIcons.chevron_right, size: 16),
        onTap: onTap,
      ),
    );
  }

  /// Shows a coming soon message
  void _showComingSoon(BuildContext context, String feature) {
    if (isCupertino(context)) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text('Coming Soon'),
          content: Text('$feature coming soon'),
          actions: [
            CupertinoDialogAction(
              child: Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$feature coming soon'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Shows the about dialog
  void _showAbout(BuildContext context) {
    showPlatformDialog(
      context: context,
      builder: (context) => PlatformAlertDialog(
        title: Text('About Pixelodon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PlatformIcons(context).photoCamera,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text('Version 1.0.0'),
            const SizedBox(height: 8),
            Text(
              'A modern, privacy-respecting Fediverse client for Mastodon and Pixelfed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          PlatformDialogAction(
            child: Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
  
  /// Shows logout confirmation dialog
  void _showLogoutDialog(BuildContext context, WidgetRef ref, String domain) {
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) => PlatformAlertDialog(
        title: Text('Log Out'),
        content: Text('Are you sure you want to log out? You will need to log in again to access your account.'),
        actions: [
          PlatformDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          PlatformDialogAction(
            child: Text('Log Out'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _performLogout(context, ref, domain);
            },
            cupertino: (_, __) => CupertinoDialogActionData(isDestructiveAction: true),
            material: (_, __) => MaterialDialogActionData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Builds a list tile for an account
  Widget _buildAccountListTile(BuildContext context, WidgetRef ref, Instance instance, Instance? activeInstance) {
    final account = ref.watch(accountInfoProvider(instance.domain));
    final isActive = activeInstance?.domain == instance.domain;
    final acct = account?.acct ?? 'unknown';
    final domain = instance.domain;
    final address = acct.contains('@') ? acct : '$acct@$domain';
    
    return PlatformWidget(
      material: (_, __) => ListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
              : Theme.of(context).colorScheme.primary.withOpacity(0.1),
          backgroundImage: account?.avatar != null ? NetworkImage(account!.avatar!) : null,
          child: account?.avatar == null
              ? Icon(
                  instance.isPixelfed ? Icons.photo_camera : Icons.chat_bubble,
                  color: Theme.of(context).colorScheme.primary,
                )
              : null,
        ),
        title: Text(
          account?.displayName ?? account?.username ?? 'Unknown User',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        trailing: _buildAccountActions(context, ref, instance, isActive),
        onTap: !isActive ? () => _switchAccount(context, ref, instance.domain) : null,
      ),
      cupertino: (_, __) => CupertinoListTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? CupertinoColors.activeBlue.withOpacity(0.2)
              : CupertinoColors.systemGrey6.resolveFrom(context),
          backgroundImage: account?.avatar != null ? NetworkImage(account!.avatar!) : null,
          child: account?.avatar == null
              ? Icon(
                  instance.isPixelfed ? CupertinoIcons.camera : CupertinoIcons.chat_bubble,
                  color: isActive
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey.resolveFrom(context),
                )
              : null,
        ),
        title: Text(
          account?.displayName ?? account?.username ?? 'Unknown User',
          style: TextStyle(
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          address,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            color: CupertinoColors.systemGrey.resolveFrom(context),
          ),
        ),
        trailing: _buildAccountActions(context, ref, instance, isActive),
        onTap: !isActive ? () => _switchAccount(context, ref, instance.domain) : null,
      ),
    );
  }

  /// Builds account action buttons
  Widget _buildAccountActions(BuildContext context, WidgetRef ref, Instance instance, bool isActive) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isActive)
          Icon(
            isCupertino(context) ? CupertinoIcons.checkmark_circle_fill : Icons.check_circle,
            color: isCupertino(context)
                ? CupertinoColors.activeBlue
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
        const SizedBox(width: 8),
        PlatformWidget(
          material: (_, __) => PopupMenuButton<String>(
            onSelected: (value) => _handleAccountAction(context, ref, instance, value),
            itemBuilder: (context) => [
              if (!isActive)
                const PopupMenuItem(
                  value: 'switch',
                  child: Row(
                    children: [
                      Icon(Icons.swap_horiz),
                      SizedBox(width: 8),
                      Text('Switch to this account'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Remove account', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
          cupertino: (_, __) => CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showCupertinoAccountActions(context, ref, instance, isActive),
            child: Icon(
              CupertinoIcons.ellipsis,
              color: CupertinoColors.systemGrey.resolveFrom(context),
            ),
          ),
        ),
      ],
    );
  }

  /// Shows Cupertino-style account actions
  void _showCupertinoAccountActions(BuildContext context, WidgetRef ref, Instance instance, bool isActive) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext sheetContext) => CupertinoActionSheet(
        actions: [
          if (!isActive)
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(sheetContext);
                _handleAccountAction(context, ref, instance, 'switch');
              },
              child: const Text('Switch to this account'),
            ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(sheetContext);
              _handleAccountAction(context, ref, instance, 'remove');
            },
            isDestructiveAction: true,
            child: const Text('Remove account'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(sheetContext),
          child: const Text('Cancel'),
        ),
      ),
    );
  }
  
  /// Handles account actions from the popup menu
  void _handleAccountAction(BuildContext context, WidgetRef ref, Instance instance, String action) {
    switch (action) {
      case 'switch':
        _switchAccount(context, ref, instance.domain);
        break;
      case 'remove':
        _showRemoveAccountDialog(context, ref, instance);
        break;
    }
  }
  
  /// Switches to the specified account
  void _switchAccount(BuildContext context, WidgetRef ref, String domain) {
    final authRepository = ref.read(authRepositoryProvider);
    authRepository.setActiveInstance(domain);
    
    // Navigate to home and update bottom navigation state
    ref.read(currentIndexProvider.notifier).state = 0; // Set to Home tab
    context.go('/home');
  }
  
  /// Shows the add account dialog/navigation
  void _addAccount(BuildContext context) {
    // Navigate to the login screen to add a new account
    context.go('/auth/login');
  }
  
  /// Shows the remove account confirmation dialog
  void _showRemoveAccountDialog(BuildContext context, WidgetRef ref, Instance instance) {
    final account = ref.read(accountInfoProvider(instance.domain));
    
    showPlatformDialog(
      context: context,
      builder: (BuildContext dialogContext) => PlatformAlertDialog(
        title: Text('Remove Account'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to remove this account?'),
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: isCupertino(context)
                      ? CupertinoColors.systemGrey6.resolveFrom(context)
                      : Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  backgroundImage: account?.avatar != null ? NetworkImage(account!.avatar!) : null,
                  child: account?.avatar == null 
                      ? Icon(
                          instance.isPixelfed
                            ? (isCupertino(context) ? CupertinoIcons.camera : Icons.photo_camera)
                            : (isCupertino(context) ? CupertinoIcons.chat_bubble : Icons.chat_bubble),
                          color: isCupertino(context)
                              ? CupertinoColors.systemGrey.resolveFrom(context)
                              : Theme.of(context).colorScheme.primary,
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
                        style: isCupertino(context)
                            ? TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey.resolveFrom(context),
                              )
                            : Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                              ) ?? const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text('This will log you out from this account and remove it from the app.'),
          ],
        ),
        actions: [
          PlatformDialogAction(
            child: Text('Cancel'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
          PlatformDialogAction(
            child: Text('Remove'),
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await _removeAccount(context, ref, instance.domain);
            },
            cupertino: (_, __) => CupertinoDialogActionData(isDestructiveAction: true),
            material: (_, __) => MaterialDialogActionData(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Removes an account from the app
  Future<void> _removeAccount(BuildContext context, WidgetRef ref, String domain) async {
    try {
      // Prefer using the root navigator context for any UI shown around navigation
      final rootCtx = rootNavigatorKey.currentContext ?? context;

      // Show loading indicator
      if (isCupertino(rootCtx)) {
        showCupertinoDialog(
          context: rootCtx,
          barrierDismissible: false,
          builder: (ctx) => const CupertinoAlertDialog(
            content: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 16),
                Text('Removing account...'),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(rootCtx).showSnackBar(
          const SnackBar(
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
          ),
        );
      }

      // Perform logout through the auth repository
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout(domain);
      
      // Close loading dialog if showing
      if (isCupertino(rootCtx)) {
        Navigator.of(rootCtx, rootNavigator: true).maybePop();
      }

      // Determine next step based on remaining accounts
      final instances = ref.read(instancesProvider);
      if (instances.isEmpty) {
        // Navigate to login on next frame to avoid using a stale context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final navCtx = rootNavigatorKey.currentContext;
          if (navCtx != null) {
            navCtx.go('/auth/login');
          }
        });
        return;
      }

      // Show success message when staying on the same screen
      if (isCupertino(rootCtx)) {
        showCupertinoDialog(
          context: rootCtx,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Success'),
            content: Text('Account removed from $domain'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(rootCtx).showSnackBar(
          SnackBar(
            content: Text('Account removed from $domain'),
            backgroundColor: Theme.of(rootCtx).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      final rootCtx = rootNavigatorKey.currentContext ?? context;
      // Close loading dialog if showing
      if (isCupertino(rootCtx)) {
        Navigator.of(rootCtx, rootNavigator: true).maybePop();
      }

      // Show error message
      if (isCupertino(rootCtx)) {
        showCupertinoDialog(
          context: rootCtx,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to remove account: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(rootCtx).showSnackBar(
          SnackBar(
            content: Text('Failed to remove account: $e'),
            backgroundColor: Theme.of(rootCtx).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Performs the logout operation
  Future<void> _performLogout(BuildContext context, WidgetRef ref, String domain) async {
    try {
      // Use root navigator context for UI to avoid stale local contexts
      final rootCtx = rootNavigatorKey.currentContext ?? context;

      // Show loading indicator
      if (isCupertino(rootCtx)) {
        showCupertinoDialog(
          context: rootCtx,
          barrierDismissible: false,
          builder: (ctx) => const CupertinoAlertDialog(
            content: Row(
              children: [
                CupertinoActivityIndicator(),
                SizedBox(width: 16),
                Text('Logging out...'),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(rootCtx).showSnackBar(
          const SnackBar(
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
          ),
        );
      }

      // Perform logout through the auth repository
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout(domain);

      // Close loading dialog if showing
      if (isCupertino(rootCtx)) {
        Navigator.of(rootCtx, rootNavigator: true).maybePop();
      }

      // Navigate to login screen on next frame to avoid context issues
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final navCtx = rootNavigatorKey.currentContext;
        if (navCtx != null) {
          navCtx.go('/auth/login');
        }
      });
    } catch (e) {
      final rootCtx = rootNavigatorKey.currentContext ?? context;
      // Close loading dialog if showing
      if (isCupertino(rootCtx)) {
        Navigator.of(rootCtx, rootNavigator: true).maybePop();
      }

      // Show error message
      if (isCupertino(rootCtx)) {
        showCupertinoDialog(
          context: rootCtx,
          builder: (ctx) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Failed to log out: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(rootCtx).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: $e'),
            backgroundColor: Theme.of(rootCtx).colorScheme.error,
          ),
        );
      }
    }
  }
}
