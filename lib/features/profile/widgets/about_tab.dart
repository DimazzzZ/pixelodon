import 'package:flutter/material.dart';
import 'package:pixelodon/models/account.dart';
import 'package:pixelodon/features/profile/widgets/info_item.dart';
import 'package:pixelodon/features/profile/widgets/profile_field_item.dart';

class AboutTab extends StatelessWidget {
  final Account account;
  const AboutTab({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
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
      ],
    );
  }
}
