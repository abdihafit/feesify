import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  const PaymentModel({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.studentName,
    required this.admissionNumber,
    required this.amount,
    required this.method,
    required this.status,
    required this.reference,
    required this.receiptNumber,
    required this.receivedBy,
    required this.previousBalance,
    required this.newBalance,
    this.paymentDate,
    this.receivedAt,
  });

  final String id;
  final String studentId;
  final String schoolId;
  final String studentName;
  final String admissionNumber;
  final double amount;
  final String method;
  final String status;
  final String reference;
  final String receiptNumber;
  final String receivedBy;
  final double previousBalance;
  final double newBalance;
  final DateTime? paymentDate;
  final DateTime? receivedAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'studentId': studentId,
      'schoolId': schoolId,
      'studentName': studentName,
      'admissionNumber': admissionNumber,
      'amount': amount,
      'method': method,
      'status': status,
      'reference': reference,
      'receiptNumber': receiptNumber,
      'receivedBy': receivedBy,
      'previousBalance': previousBalance,
      'newBalance': newBalance,
      'paymentDate':
          paymentDate == null ? null : Timestamp.fromDate(paymentDate!),
      'receivedAt': receivedAt == null ? null : Timestamp.fromDate(receivedAt!),
    };
  }

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      id: id,
      studentId: map['studentId'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      studentName: map['studentName'] as String? ?? '',
      admissionNumber: map['admissionNumber'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      method: map['method'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      reference: map['reference'] as String? ?? '',
      receiptNumber: map['receiptNumber'] as String? ?? '',
      receivedBy: map['receivedBy'] as String? ?? '',
      previousBalance: (map['previousBalance'] as num?)?.toDouble() ?? 0,
      newBalance: (map['newBalance'] as num?)?.toDouble() ?? 0,
      paymentDate: (map['paymentDate'] as Timestamp?)?.toDate(),
      receivedAt: (map['receivedAt'] as Timestamp?)?.toDate(),
    );
  }
}
