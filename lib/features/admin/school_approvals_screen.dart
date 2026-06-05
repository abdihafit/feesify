import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/payment_model.dart';
import '../../models/school_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class SchoolApprovalsScreen extends StatelessWidget {
  const SchoolApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return StreamBuilder<List<SchoolModel>>(
      stream: firestoreService.streamSchools(),
      builder: (context, schoolSnapshot) {
        if (schoolSnapshot.hasError) {
          return EmptyState(
            icon: Icons.error_outline,
            title: 'Unable to load schools',
            message: schoolSnapshot.error.toString(),
          );
        }

        if (schoolSnapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<SchoolModel> schools =
            schoolSnapshot.data ?? <SchoolModel>[];
        final List<SchoolModel> pendingSchools =
            schools
                .where((school) => school.status == 'pending approval')
                .toList();
        final int approvedCount =
            schools.where((school) => school.status == 'approved').length;
        final int inactiveCount =
            schools.where((school) => school.status == 'inactive').length;

        return StreamBuilder<List<PaymentModel>>(
          stream: firestoreService.streamPaymentsForAllSchools(),
          builder: (context, paymentSnapshot) {
            if (paymentSnapshot.hasError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: 'Unable to load school payments',
                message: paymentSnapshot.error.toString(),
              );
            }

            if (paymentSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final List<PaymentModel> payments =
                paymentSnapshot.data ?? <PaymentModel>[];
            final Map<String, double> paymentsBySchool = <String, double>{};

            for (final PaymentModel payment in payments) {
              paymentsBySchool.update(
                payment.schoolId,
                (current) => current + payment.amount,
                ifAbsent: () => payment.amount,
              );
            }

            if (schools.isEmpty) {
              return const EmptyState(
                icon: Icons.apartment_outlined,
                title: 'No schools registered',
                message:
                    'Once principals register schools, they will appear here for review.',
              );
            }

            return ListView(
              padding: const EdgeInsets.all(16),
              children: <Widget>[
                GridView.count(
                  crossAxisCount:
                      MediaQuery.of(context).size.width >= 1000 ? 4 : 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  children: <Widget>[
                    _SummaryCard(
                      label: 'Total registered schools',
                      value: schools.length.toString(),
                      icon: Icons.apartment_outlined,
                    ),
                    _SummaryCard(
                      label: 'Pending schools',
                      value: pendingSchools.length.toString(),
                      icon: Icons.hourglass_top_outlined,
                    ),
                    _SummaryCard(
                      label: 'Approved schools',
                      value: approvedCount.toString(),
                      icon: Icons.verified_outlined,
                    ),
                    _SummaryCard(
                      label: 'Inactive schools',
                      value: inactiveCount.toString(),
                      icon: Icons.block_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  'Pending School Registrations',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 12),
                if (pendingSchools.isEmpty)
                  const EmptyState(
                    icon: Icons.verified_user_outlined,
                    title: 'No pending approvals',
                    message:
                        'New school registrations will appear here for admin action.',
                  )
                else
                  ...pendingSchools.map(
                    (school) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DashboardCard(
                        title: school.name,
                        subtitle: '${school.county} | ${school.principalName}',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            _InfoRow(
                              label: 'Principal name',
                              value: school.principalName,
                            ),
                            _InfoRow(label: 'Phone', value: school.phone),
                            _InfoRow(label: 'Email', value: school.email),
                            _InfoRow(
                              label: 'Registration date',
                              value: _formatDate(school.createdAt),
                            ),
                            _InfoRow(
                              label: 'Payment status',
                              value: _resolvePaymentStatus(
                                school: school,
                                paidAmount: paymentsBySchool[school.id] ?? 0,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                FilledButton(
                                  onPressed:
                                      school.principalUserId == null
                                          ? null
                                          : () => _runAction(
                                            context: context,
                                            actionLabel: 'approved',
                                            action:
                                                () => firestoreService
                                                    .approveSchool(
                                                      schoolId: school.id,
                                                      principalUserId:
                                                          school
                                                              .principalUserId!,
                                                    ),
                                          ),
                                  child: const Text('Approve School'),
                                ),
                                OutlinedButton(
                                  onPressed:
                                      school.principalUserId == null
                                          ? null
                                          : () => _runAction(
                                            context: context,
                                            actionLabel: 'rejected',
                                            action:
                                                () => firestoreService
                                                    .rejectSchool(
                                                      schoolId: school.id,
                                                      principalUserId:
                                                          school
                                                              .principalUserId!,
                                                    ),
                                          ),
                                  child: const Text('Reject School'),
                                ),
                                TextButton(
                                  onPressed:
                                      school.principalUserId == null
                                          ? null
                                          : () => _runAction(
                                            context: context,
                                            actionLabel: 'deactivated',
                                            action:
                                                () => firestoreService
                                                    .deactivateSchool(
                                                      schoolId: school.id,
                                                      principalUserId:
                                                          school
                                                              .principalUserId!,
                                                    ),
                                          ),
                                  child: const Text('Deactivate School'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _runAction({
    required BuildContext context,
    required Future<void> Function() action,
    required String actionLabel,
  }) async {
    await action();

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('School has been $actionLabel successfully.')),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }

    final String month = date.month.toString().padLeft(2, '0');
    final String day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _resolvePaymentStatus({
    required SchoolModel school,
    required double paidAmount,
  }) {
    if (school.paymentStatus != 'pending') {
      return school.paymentStatus;
    }

    if (paidAmount > 0) {
      return '${school.paymentStatus} (${CurrencyFormatter.formatAmount(paidAmount)})';
    }

    return school.paymentStatus;
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon),
            const SizedBox(height: 16),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: RichText(
        text: TextSpan(
          style: DefaultTextStyle.of(context).style,
          children: <InlineSpan>[
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}
