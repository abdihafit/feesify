import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/dashboard_card.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.user, this.extraSection});

  final UserModel user;
  final Widget? extraSection;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isBusy = false;

  AuthService get _authService => AuthService();

  bool get _hasFirebaseApp => Firebase.apps.isNotEmpty;

  bool get _isCurrentEmailVerified =>
      _hasFirebaseApp && (_authService.currentUser?.emailVerified ?? false);

  Future<void> _runVerificationAction(
    Future<void> Function() action,
    String message,
  ) async {
    setState(() => _isBusy = true);

    try {
      await action();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() {});
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) {
        setState(() => _isBusy = false);
      }
    }
  }

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
              Text('Name: ${widget.user.name}'),
              const SizedBox(height: 8),
              Text('Email: ${widget.user.email}'),
              const SizedBox(height: 8),
              Text('Role: ${widget.user.role.toUpperCase()}'),
              const SizedBox(height: 8),
              Text('School ID: ${widget.user.schoolId}'),
              const SizedBox(height: 8),
              Text('Status: ${widget.user.status}'),
              if (widget.user.phoneNumber != null &&
                  widget.user.phoneNumber!.isNotEmpty) ...<Widget>[
                const SizedBox(height: 8),
                Text('Phone: ${widget.user.phoneNumber}'),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_hasFirebaseApp) ...<Widget>[
          DashboardCard(
            title: 'Email Verification',
            subtitle:
                'Verification is optional for principals and bursars. Use it only if you want an extra confirmation on this email address.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _isCurrentEmailVerified
                      ? 'Current status: Verified'
                      : 'Current status: Not verified',
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: <Widget>[
                    FilledButton.tonal(
                      onPressed: _isBusy || _isCurrentEmailVerified
                          ? null
                          : () => _runVerificationAction(
                              () => _authService.sendEmailVerification(),
                              'Verification email sent.',
                            ),
                      child: const Text('Send Verification Email'),
                    ),
                    OutlinedButton(
                      onPressed: _isBusy
                          ? null
                          : () => _runVerificationAction(
                              () => _authService.reloadCurrentUser(),
                              'Verification status refreshed.',
                            ),
                      child: const Text('Refresh Status'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
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
        if (widget.extraSection != null) ...<Widget>[
          const SizedBox(height: 12),
          widget.extraSection!,
        ],
      ],
    );
  }
}
