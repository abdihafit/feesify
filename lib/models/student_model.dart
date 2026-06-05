import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  const StudentModel({
    required this.id,
    required this.admissionNumber,
    required this.fullName,
    required this.schoolId,
    required this.classId,
    required this.className,
    required this.streamName,
    required this.guardianName,
    required this.guardianPhone,
    required this.termFee,
    required this.previousBalance,
    required this.totalPaid,
    required this.totalExpectedFee,
    required this.totalFees,
    required this.balance,
    this.createdAt,
  });

  final String id;
  final String admissionNumber;
  final String fullName;
  final String schoolId;
  final String classId;
  final String className;
  final String streamName;
  final String guardianName;
  final String guardianPhone;
  final double termFee;
  final double previousBalance;
  final double totalPaid;
  final double totalExpectedFee;
  final double totalFees;
  final double balance;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'admissionNumber': admissionNumber,
      'fullName': fullName,
      'schoolId': schoolId,
      'classId': classId,
      'className': className,
      'streamName': streamName,
      'guardianName': guardianName,
      'guardianPhone': guardianPhone,
      'termFee': termFee,
      'previousBalance': previousBalance,
      'totalPaid': totalPaid,
      'totalExpectedFee': totalExpectedFee,
      'totalFees': totalFees,
      'balance': balance,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory StudentModel.fromMap(String id, Map<String, dynamic> map) {
    return StudentModel(
      id: id,
      admissionNumber: map['admissionNumber'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      schoolId: map['schoolId'] as String? ?? '',
      classId: map['classId'] as String? ?? '',
      className: map['className'] as String? ?? '',
      streamName: map['streamName'] as String? ?? '',
      guardianName: map['guardianName'] as String? ?? '',
      guardianPhone: map['guardianPhone'] as String? ?? '',
      termFee: (map['termFee'] as num?)?.toDouble() ?? 0,
      previousBalance: (map['previousBalance'] as num?)?.toDouble() ?? 0,
      totalPaid: (map['totalPaid'] as num?)?.toDouble() ?? 0,
      totalExpectedFee: (map['totalExpectedFee'] as num?)?.toDouble() ?? 0,
      totalFees: (map['totalFees'] as num?)?.toDouble() ?? 0,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
