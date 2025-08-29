import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/widgets/common/app_page_scaffold.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';
import 'package:pixelodon/providers/settings_provider.dart';
import 'package:pixelodon/widgets/common/platform_app_bar_wrapper.dart';

/// Settings screen with logout functionality
class SettingsScreen extends ConsumerWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final instances = ref.watch(instancesProvider);

    return AppPageScaffold(
      appBar: PlatformAppBarWrapper(
        platformAppBar: PlatformAppBar(
          title: const Text('Settings'),
        ),
      ),
      usesSlivers: false, // ListView is not a sliver-based widget
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Accounts Section
          const Text(
            'Accounts',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // List of accounts
          if (instances.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  for (int i = 0; i < instances.length; i++) ...[
                    _buildAccountListTile(context, ref, instances[i], activeInstance),
                    if (i < instances.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Add Account Button
          SizedBox(
            width: double.infinity,
            child: PlatformTextButton(
              onPressed: () => _addAccount(context),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add),
                  const SizedBox(width: 8),
                  const Text('Add Account'),
                ],
              ),
              material: (_, __) => MaterialTextButtonData(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Theme.of(context).colorScheme.outline),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // App Settings Section
          const Text(
            'App Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                PlatformListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  subtitle: Text(ref.read(themeModeProvider.notifier).themeModeDisplayName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showThemeSelection(context, ref),
                ),
                const Divider(height: 1),
                PlatformListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showNotificationSettings(context, ref),
                ),
                const Divider(height: 1),
                PlatformListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  subtitle: Text(ref.read(languageProvider.notifier).languageDisplayName),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showLanguageSelection(context, ref),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // About Section
          const Text(
            'About',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                PlatformListTile(
                  leading: const Icon(Icons.info_outlined),
                  title: const Text('About Pixelodon'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1),
                PlatformListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showPrivacyPolicy(context),
                ),
                const Divider(height: 1),
                PlatformListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () => _showTermsOfService(context),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button (only show if there are accounts)
          if (instances.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: PlatformElevatedButton(
                onPressed: activeInstance != null 
                    ? () => _showLogoutDialog(context, ref, activeInstance.domain)
                    : null,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.logout),
                    const SizedBox(width: 8),
                    const Text('Log Out Current Account'),
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
        ],
      ),
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
        ScaffoldMessenger.of(context).showSnackBar(
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
      
      // Navigate to login screen
      if (context.mounted) {
        context.go('/auth/login');
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to log out: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
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
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('@${account?.acct ?? 'unknown'}'),
          Text(
            instance.domain,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
          const SizedBox(width: 8),
          PlatformIconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showAccountActions(context, ref, instance, isActive),
          ),
        ],
      ),
      onTap: !isActive ? () => _switchAccount(context, ref, instance.domain) : null,
    );
  }
  
  
  /// Switches to the specified account
  void _switchAccount(BuildContext context, WidgetRef ref, String domain) {
    final authRepository = ref.read(authRepositoryProvider);
    authRepository.setActiveInstance(domain);
    
    // Navigate to home and update bottom navigation state
    ref.read(currentIndexProvider.notifier).state = 0; // Set to Home tab
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
  
  /// Shows account actions using platform-appropriate action sheet
  void _showAccountActions(BuildContext context, WidgetRef ref, Instance instance, bool isActive) {
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
                'Account Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            if (!isActive)
              PlatformListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('Switch to this account'),
                onTap: () {
                  Navigator.of(context).pop();
                  _switchAccount(context, ref, instance.domain);
                },
              ),
            PlatformListTile(
              leading: Icon(Icons.remove_circle_outline, color: Colors.red),
              title: const Text('Remove account', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.of(context).pop();
                _showRemoveAccountDialog(context, ref, instance);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
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
      
      // Perform logout through the auth repository
      final authRepository = ref.read(authRepositoryProvider);
      await authRepository.logout(domain);
      
      // Show success message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Account removed from $domain'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
        
        // If no accounts left, navigate to login
        final instances = ref.read(instancesProvider);
        if (instances.isEmpty) {
          context.go('/auth/login');
        }
      }
    } catch (e) {
      // Show error message
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to remove account: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  /// Shows theme selection dialog
  void _showThemeSelection(BuildContext context, WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    final availableThemes = settingsService.getAvailableThemeModes();
    final currentTheme = ref.read(themeModeProvider);

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
                await ref.read(themeModeProvider.notifier).setThemeMode(theme);
                if (context.mounted) Navigator.of(context).pop();
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Shows language selection dialog
  void _showLanguageSelection(BuildContext context, WidgetRef ref) {
    final settingsService = ref.read(settingsServiceProvider);
    final availableLanguages = settingsService.getAvailableLanguages();
    final currentLanguage = ref.read(languageProvider);

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
                'Select Language',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ...availableLanguages.map((language) => PlatformListTile(
              title: Text(settingsService.getLanguageDisplayName(language)),
              trailing: currentLanguage == language
                  ? const Icon(Icons.check)
                  : null,
              onTap: () async {
                await ref.read(languageProvider.notifier).setLanguage(language);
                if (context.mounted) Navigator.of(context).pop();
              },
            )),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Shows notification settings
  void _showNotificationSettings(BuildContext context, WidgetRef ref) {
    showPlatformModalSheet(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          final notificationSettings = ref.watch(notificationSettingsProvider);
          
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
                      await ref.read(notificationSettingsProvider.notifier)
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
            Icon(
              Icons.photo_camera,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
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
