import 'package:flutter/material.dart';

import '../../models/user_model.dart';
import '../../widgets/dashboard_card.dart';
import '../students/student_search_screen.dart';
import 'payment_entry_screen.dart';
import 'payments_screen.dart';

class PaymentWorkspaceScreen extends StatelessWidget {
  const PaymentWorkspaceScreen({
    super.key,
    required this.schoolId,
    required this.user,
    this.readOnly = false,
  });

  final String schoolId;
  final UserModel user;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16),
          child: DashboardCard(
            title: 'Payments Workspace',
            subtitle:
                readOnly
                    ? 'Review payment records and preview payment actions in read-only mode.'
                    : 'Record payments, search students, and review recent collections from one place.',
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Payment Entry'),
                              ),
                              body: PaymentEntryScreen(
                                schoolId: schoolId,
                                bursar: user,
                                readOnly: readOnly,
                              ),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_card_outlined),
                  label: Text(
                    readOnly ? 'Preview Payment Entry' : 'Record Payment',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder:
                            (_) => Scaffold(
                              appBar: AppBar(
                                title: const Text('Student Search'),
                              ),
                              body: StudentSearchScreen(schoolId: schoolId),
                            ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_search_outlined),
                  label: const Text('Search Student'),
                ),
              ],
            ),
          ),
        ),
        Expanded(child: PaymentsScreen(schoolId: schoolId)),
      ],
    );
  }
}
