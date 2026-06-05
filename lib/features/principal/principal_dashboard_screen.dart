import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/app_shell.dart';
import '../../widgets/dashboard_card.dart';
import '../classes/class_setup_screen.dart';
import '../payments/payment_workspace_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../students/student_import_screen.dart';
import '../students/students_screen.dart';
import 'manage_bursar_screen.dart';
import 'principal_overview_screen.dart';

class PrincipalDashboardScreen extends StatelessWidget {
  const PrincipalDashboardScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Principal Dashboard',
      subtitle:
          'Track balances, enrollment, collections, and school-wide bursary activity.',
      user: user,
      tabs: <AppTab>[
        AppTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          child: PrincipalOverviewScreen(schoolId: user.schoolId),
        ),
        AppTab(
          label: 'Students',
          icon: Icons.school_outlined,
          child: StudentsScreen(schoolId: user.schoolId),
        ),
        AppTab(
          label: 'Import Students',
          icon: Icons.upload_file_outlined,
          child: StudentImportScreen(schoolId: user.schoolId),
        ),
        AppTab(
          label: 'Payments',
          icon: Icons.receipt_long_outlined,
          child: PaymentWorkspaceScreen(schoolId: user.schoolId, user: user),
        ),
        AppTab(
          label: 'Reports',
          icon: Icons.insights_outlined,
          child: ReportsScreen(schoolId: user.schoolId),
        ),
        AppTab(
          label: 'Classes & Streams',
          icon: Icons.class_outlined,
          child: ClassSetupScreen(schoolId: user.schoolId),
        ),
        AppTab(
          label: 'Settings',
          icon: Icons.settings_outlined,
          child: SettingsScreen(
            user: user,
            extraSection: DashboardCard(
              title: 'Manage Bursar',
              subtitle:
                  'Create bursar accounts for this school from a simple guided page.',
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder:
                          (_) => Scaffold(
                            appBar: AppBar(title: const Text('Manage Bursar')),
                            body: ManageBursarScreen(principal: user),
                          ),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts_outlined),
                label: const Text('Open Manage Bursar'),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
