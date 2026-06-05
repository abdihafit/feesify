import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import '../../models/user_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../admin/admin_dashboard_screen.dart';
import '../bursar/bursar_dashboard_screen.dart';
import '../principal/principal_dashboard_screen.dart';
import 'login_screen.dart';
import 'pending_approval_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    late final AuthService authService;
    late final FirestoreService firestoreService;

    try {
      authService = AuthService();
      firestoreService = FirestoreService();
    } catch (_) {
      return const LoginScreen();
    }

    return StreamBuilder<User?>(
      stream: authService.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final User? firebaseUser = authSnapshot.data;
        if (firebaseUser == null) {
          return const LoginScreen();
        }

        final String email = firebaseUser.email?.trim().toLowerCase() ?? '';
        final bool isAdmin = AppConstants.adminEmails.contains(email);

        if (isAdmin) {
          return FutureBuilder<void>(
            future: firestoreService.ensureAdminUser(
              userId: firebaseUser.uid,
              email: email,
            ),
            builder: (context, adminSetupSnapshot) {
              if (adminSetupSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              return StreamBuilder<UserModel?>(
                stream: firestoreService.streamUser(firebaseUser.uid),
                builder: (context, adminSnapshot) {
                  if (adminSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }

                  return AdminDashboardScreen(
                    user:
                        adminSnapshot.data ??
                        UserModel(
                          id: firebaseUser.uid,
                          email: email,
                          name: 'System Administrator',
                          role: 'admin',
                          schoolId: '',
                          status: 'active',
                        ),
                  );
                },
              );
            },
          );
        }

        return StreamBuilder<UserModel?>(
          stream: firestoreService.streamUser(firebaseUser.uid),
          builder: (context, userSnapshot) {
            if (userSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final UserModel? user = userSnapshot.data;
            if (user == null) {
              return const PendingApprovalScreen(
                title: 'Account setup incomplete',
                message:
                    'Your login exists, but your user profile is not ready yet. Please contact the administrator.',
              );
            }

            if (user.status != 'active') {
              return PendingApprovalScreen(
                title: 'Approval pending',
                message:
                    'Your school registration is awaiting admin approval before dashboard access is granted.',
              );
            }

            switch (user.role) {
              case 'principal':
                return PrincipalDashboardScreen(user: user);
              case 'bursar':
                return BursarDashboardScreen(user: user);
              default:
                return const PendingApprovalScreen(
                  title: 'Role not recognized',
                  message:
                      'Your account does not have an approved application role yet. Please contact the administrator.',
                );
            }
          },
        );
      },
    );
  }
}
