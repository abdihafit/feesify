import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/app_shell.dart';
import '../classes/class_setup_screen.dart';
import '../payments/payment_workspace_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/settings_screen.dart';
import '../students/student_import_screen.dart';
import '../students/student_search_screen.dart';
import 'bursar_home_screen.dart';

class BursarDashboardScreen extends StatelessWidget {
  const BursarDashboardScreen({super.key, required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Bursar Workspace',
      subtitle:
          'Record collections, monitor status, and follow up on balances.',
      user: user,
      tabs: <AppTab>[
        AppTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          child: BursarHomeScreen(user: user),
        ),
        AppTab(
          label: 'Students',
          icon: Icons.school_outlined,
          child: StudentSearchScreen(schoolId: user.schoolId),
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
          icon: Icons.query_stats_outlined,
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
          child: SettingsScreen(user: user),
        ),
      ],
    );
  }
}
