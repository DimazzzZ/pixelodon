import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pixelodon/features/app_shell/app_shell.dart';
import 'package:pixelodon/models/instance.dart';
import 'package:pixelodon/providers/auth_provider.dart';

/// Settings screen with logout functionality
class SettingsScreen extends ConsumerWidget {
  /// Constructor
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeInstance = ref.watch(activeInstanceProvider);
    final instances = ref.watch(instancesProvider);
    final authRepository = ref.watch(authRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
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
            Card(
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
            child: OutlinedButton.icon(
              onPressed: () => _addAccount(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Account'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('Theme'),
                  subtitle: const Text('Light'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement theme selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Theme selection coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: const Text('Notifications'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement notification settings
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Notification settings coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.language_outlined),
                  title: const Text('Language'),
                  subtitle: const Text('English'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement language selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Language selection coming soon')),
                    );
                  },
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
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outlined),
                  title: const Text('About Pixelodon'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Pixelodon',
                      applicationVersion: '1.0.0',
                      applicationIcon: const Icon(Icons.photo_camera, size: 48),
                      children: [
                        const Text('A modern, privacy-respecting Fediverse client for Mastodon and Pixelfed.'),
                      ],
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement privacy policy
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Privacy policy coming soon')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.description_outlined),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    // TODO: Implement terms of service
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Terms of service coming soon')),
                    );
                  },
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Logout Button (only show if there are accounts)
          if (instances.isNotEmpty)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: activeInstance != null 
                    ? () => _showLogoutDialog(context, ref, activeInstance.domain)
                    : null,
                icon: const Icon(Icons.logout),
                label: const Text('Log Out Current Account'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.error,
                  foregroundColor: Theme.of(context).colorScheme.onError,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  /// Shows logout confirmation dialog
  void _showLogoutDialog(BuildContext context, WidgetRef ref, String domain) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text('Are you sure you want to log out? You will need to log in again to access your account.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _performLogout(context, ref, domain);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
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
    
    return ListTile(
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
          PopupMenuButton<String>(
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
        ],
      ),
      onTap: !isActive ? () => _switchAccount(context, ref, instance.domain) : null,
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
  
  /// Shows the remove account confirmation dialog
  void _showRemoveAccountDialog(BuildContext context, WidgetRef ref, Instance instance) {
    final account = ref.read(accountInfoProvider(instance.domain));
    
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
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
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await _removeAccount(context, ref, instance.domain);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
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
}
