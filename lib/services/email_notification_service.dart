import '../models/payment_model.dart';
import '../models/student_model.dart';

class EmailNotificationService {
  const EmailNotificationService();

  Future<void> sendPaymentReceipt({
    required StudentModel student,
    required PaymentModel payment,
  }) async {
    // Connect this service to a backend provider such as Firebase Functions,
    // SendGrid, or Resend when transactional email is ready.
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  Future<void> sendBalanceReminder(StudentModel student) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }
}
