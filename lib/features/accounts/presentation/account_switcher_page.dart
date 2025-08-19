import 'package:flutter/material.dart';

class AccountSwitcherPage extends StatelessWidget {
  const AccountSwitcherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Accounts')),
      body: ListView(
        children: const [
          ListTile(title: Text('Example Account 1'), subtitle: Text('mastodon.social')),
          ListTile(title: Text('Example Account 2'), subtitle: Text('pixelfed.social')),
        ],
      ),
    );
  }
}

