import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';

class PendingApprovalScreen extends StatefulWidget {
  const PendingApprovalScreen({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  State<PendingApprovalScreen> createState() => _PendingApprovalScreenState();
}

class _PendingApprovalScreenState extends State<PendingApprovalScreen> {
  bool _isBusy = false;

  AuthService get _authService => AuthService();

  bool get _hasFirebaseApp => Firebase.apps.isNotEmpty;

  User? get _currentUser => _authService.currentUser;

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _isBusy = true);

    try {
      await action();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    const Icon(Icons.hourglass_top_rounded, size: 56),
                    const SizedBox(height: 16),
                    Text(
                      widget.title,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 12),
                    Text(widget.message, textAlign: TextAlign.center),
                    if (_hasFirebaseApp && _currentUser?.email != null) ...<Widget>[
                      const SizedBox(height: 20),
                      Text(
                        _currentUser!.emailVerified
                            ? 'Email status: Verified'
                            : 'Email status: Not verified (optional)',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          FilledButton.tonal(
                            onPressed: _isBusy || _currentUser!.emailVerified
                                ? null
                                : () => _runAction(
                                    () => _authService.sendEmailVerification(),
                                    'Verification email sent.',
                                  ),
                            child: const Text('Send Verification Email'),
                          ),
                          OutlinedButton(
                            onPressed: _isBusy
                                ? null
                                : () => _runAction(
                                    () => _authService.reloadCurrentUser(),
                                    'Verification status refreshed.',
                                  ),
                            child: const Text('Refresh Status'),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton.tonal(
                      onPressed: _isBusy ? null : () => _authService.signOut(),
                      child: const Text('Sign out'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
