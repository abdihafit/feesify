import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/payment_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class PaymentsScreen extends StatelessWidget {
  PaymentsScreen({super.key, required this.schoolId});

  final String schoolId;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PaymentModel>>(
      stream: _firestoreService.streamPayments(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<PaymentModel> payments = snapshot.data ?? <PaymentModel>[];
        if (payments.isEmpty) {
          return const EmptyState(
            icon: Icons.payments_outlined,
            title: 'No payments recorded',
            message:
                'Once payments are added to Firestore, they will appear here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: payments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final PaymentModel payment = payments[index];
            return DashboardCard(
              title:
                  payment.receiptNumber.isEmpty
                      ? payment.reference
                      : payment.receiptNumber,
              subtitle:
                  '${payment.studentName} | ${payment.method} | ${payment.status.toUpperCase()}',
              trailing: Text(
                CurrencyFormatter.formatAmount(payment.amount),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Reference: ${payment.reference}'),
                  Text('Received by: ${payment.receivedBy}'),
                  Text(
                    'Date: ${payment.paymentDate == null ? 'N/A' : DateFormat('yyyy-MM-dd').format(payment.paymentDate!)}',
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
