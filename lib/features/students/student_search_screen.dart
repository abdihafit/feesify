import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/payment_model.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class StudentSearchScreen extends StatefulWidget {
  const StudentSearchScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  State<StudentSearchScreen> createState() => _StudentSearchScreenState();
}

class _StudentSearchScreenState extends State<StudentSearchScreen> {
  final TextEditingController _admissionNumberController =
      TextEditingController();

  String _query = '';

  @override
  void dispose() {
    _admissionNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'Student Search',
          subtitle:
              'Enter an admission number to automatically fetch student and payment details.',
          child: TextField(
            controller: _admissionNumberController,
            onChanged: (value) {
              setState(() => _query = value.trim());
            },
            decoration: InputDecoration(
              labelText: 'Admission number',
              hintText: 'Enter admission number',
              suffixIcon:
                  _query.isEmpty
                      ? null
                      : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _admissionNumberController.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        if (_query.isEmpty)
          const EmptyState(
            icon: Icons.search_outlined,
            title: 'Search for a student',
            message:
                'Type an admission number above to load the student profile and payment history.',
          )
        else
          StreamBuilder<StudentModel?>(
            stream: firestoreService.streamStudentByAdmissionNumber(
              schoolId: widget.schoolId,
              admissionNumber: _query,
            ),
            builder: (context, studentSnapshot) {
              if (studentSnapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              final StudentModel? student = studentSnapshot.data;
              if (student == null) {
                return const EmptyState(
                  icon: Icons.person_search_outlined,
                  title: 'Student not found',
                  message:
                      'No student was found for that admission number in this school.',
                );
              }

              return Column(
                children: <Widget>[
                  DashboardCard(
                    title: student.fullName,
                    subtitle:
                        '${student.admissionNumber} | ${student.className} ${student.streamName}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        _InfoRow(
                          label: 'Student name',
                          value: student.fullName,
                        ),
                        _InfoRow(label: 'Class', value: student.className),
                        _InfoRow(label: 'Stream', value: student.streamName),
                        _InfoRow(
                          label: 'Total expected fee',
                          value: CurrencyFormatter.formatAmount(
                            student.totalExpectedFee,
                          ),
                        ),
                        _InfoRow(
                          label: 'Total paid',
                          value: CurrencyFormatter.formatAmount(
                            student.totalPaid,
                          ),
                        ),
                        _InfoRow(
                          label: 'Current balance',
                          value: CurrencyFormatter.formatAmount(
                            student.balance,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Payment History',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder<List<PaymentModel>>(
                    stream: firestoreService.streamStudentPayments(
                      schoolId: widget.schoolId,
                      studentId: student.id,
                    ),
                    builder: (context, paymentSnapshot) {
                      if (paymentSnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }

                      final List<PaymentModel> payments =
                          paymentSnapshot.data ?? <PaymentModel>[];
                      if (payments.isEmpty) {
                        return const EmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No payment history',
                          message:
                              'This student does not have any recorded payments yet.',
                        );
                      }

                      return Column(
                        children:
                            payments
                                .map(
                                  (payment) => Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: DashboardCard(
                                      title: payment.reference,
                                      subtitle:
                                          '${payment.method} | ${payment.status.toUpperCase()}',
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          _InfoRow(
                                            label: 'Amount',
                                            value:
                                                CurrencyFormatter.formatAmount(
                                                  payment.amount,
                                                ),
                                          ),
                                          _InfoRow(
                                            label: 'Date',
                                            value:
                                                payment.receivedAt == null
                                                    ? 'N/A'
                                                    : DateFormat(
                                                      'yyyy-MM-dd',
                                                    ).format(
                                                      payment.receivedAt!,
                                                    ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                      );
                    },
                  ),
                ],
              );
            },
          ),
      ],
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
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
