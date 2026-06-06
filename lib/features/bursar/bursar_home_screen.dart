import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';
import '../payments/payment_entry_screen.dart';
import '../students/student_import_screen.dart';
import '../students/student_search_screen.dart';

class BursarHomeScreen extends StatelessWidget {
  const BursarHomeScreen({
    super.key,
    required this.user,
  });

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'Finance Dashboard',
          subtitle:
              'Open the bursar tools directly from here to import students, search learners, and record payments.',
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: <Widget>[
              _ActionButton(
                icon: Icons.add_card_outlined,
                title: 'Record Payment',
                description: 'Post new collections with automatic receipts.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Payment Entry')),
                        body: PaymentEntryScreen(
                          schoolId: user.schoolId,
                          bursar: user,
                        ),
                      ),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.upload_file_outlined,
                title: 'Import Students',
                description: 'Upload learners in bulk from Excel.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Import Students')),
                        body: StudentImportScreen(schoolId: user.schoolId),
                      ),
                    ),
                  );
                },
              ),
              _ActionButton(
                icon: Icons.person_search_outlined,
                title: 'Search Student',
                description: 'Find balances and payment history quickly.',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Student Search')),
                        body: StudentSearchScreen(schoolId: user.schoolId),
                      ),
                    ),
                  );
                },
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

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 230,
      child: FilledButton.tonal(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.all(18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
