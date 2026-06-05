import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/app_shell.dart';
import 'school_approvals_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, this.user});

  final UserModel? user;

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Admin Dashboard',
      subtitle: 'Monitor registrations, approvals, and school account status.',
      user: user,
      tabs: const <AppTab>[
        AppTab(
          label: 'Dashboard',
          icon: Icons.dashboard_outlined,
          child: SchoolApprovalsScreen(),
        ),
      ],
    );
  }
}
