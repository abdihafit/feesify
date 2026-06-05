import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  const SchoolModel({
    required this.id,
    required this.name,
    required this.county,
    required this.principalName,
    required this.email,
    required this.phone,
    required this.status,
    required this.paymentStatus,
    this.principalUserId,
    this.createdAt,
  });

  final String id;
  final String name;
  final String county;
  final String principalName;
  final String email;
  final String phone;
  final String status;
  final String paymentStatus;
  final String? principalUserId;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'county': county,
      'principalName': principalName,
      'email': email,
      'phone': phone,
      'status': status,
      'paymentStatus': paymentStatus,
      'principalUserId': principalUserId,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory SchoolModel.fromMap(String id, Map<String, dynamic> map) {
    return SchoolModel(
      id: id,
      name: map['name'] as String? ?? '',
      county: map['county'] as String? ?? '',
      principalName: map['principalName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      status: map['status'] as String? ?? 'pending approval',
      paymentStatus: map['paymentStatus'] as String? ?? 'pending',
      principalUserId: map['principalUserId'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
