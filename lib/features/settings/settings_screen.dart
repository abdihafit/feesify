import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.user, this.extraSection});

  final UserModel user;
  final Widget? extraSection;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'Account Settings',
          subtitle:
              'Review your school access details and basic account information.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Name: ${user.name}'),
              const SizedBox(height: 8),
              Text('Email: ${user.email}'),
              const SizedBox(height: 8),
              Text('Role: ${user.role.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('School ID: ${user.schoolId}'),
              const SizedBox(height: 8),
              Text('Status: ${user.status}'),
              if (user.phoneNumber != null &&
                  user.phoneNumber!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text('Phone: ${user.phoneNumber}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DashboardCard(
          title: 'System Help',
          subtitle: 'Simple reminders for everyday school finance work.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Use Students to review learner balances and details.'),
              SizedBox(height: 8),
              Text('Use Import Students to add records in bulk from Excel.'),
              SizedBox(height: 8),
              Text('Use Payments to review collections and record receipts.'),
              SizedBox(height: 8),
              Text('Use Reports to export PDF and Excel summaries.'),
            ],
          ),
        ),
        if (extraSection != null) ...<Widget>[
          const SizedBox(height: 12),
          extraSection!,
        ],
      ],
    );
  }
}
