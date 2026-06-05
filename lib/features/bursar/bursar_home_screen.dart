import 'package:flutter/material.dart';

import '../../widgets/dashboard_card.dart';

class BursarHomeScreen extends StatelessWidget {
  const BursarHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        const DashboardCard(
          title: 'Finance Dashboard',
          subtitle:
              'Use the menu to post payments, import students, review reports, and manage class streams.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ActionHint(
                icon: Icons.add_card_outlined,
                title: 'Record Payment',
                description: 'Post new collections with automatic receipts.',
              ),
              _ActionHint(
                icon: Icons.upload_file_outlined,
                title: 'Import Students',
                description: 'Upload learners in bulk from Excel.',
              ),
              _ActionHint(
                icon: Icons.person_search_outlined,
                title: 'Search Student',
                description: 'Find balances and payment history quickly.',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const DashboardCard(
          title: 'Simple Workflow',
          subtitle: 'A clear routine for daily bursar work.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('1. Import or review students.'),
              SizedBox(height: 8),
              Text('2. Search the student by admission number.'),
              SizedBox(height: 8),
              Text('3. Record the payment and confirm the receipt.'),
              SizedBox(height: 8),
              Text('4. Use Reports for summaries and exports.'),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionHint extends StatelessWidget {
  const _ActionHint({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon),
          const SizedBox(height: 12),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(description),
        ],
      ),
    );
  }
}
