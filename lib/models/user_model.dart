import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.schoolId,
    required this.status,
    this.phoneNumber,
    this.createdAt,
  });

  final String id;
  final String email;
  final String name;
  final String role;
  final String schoolId;
  final String status;
  final String? phoneNumber;
  final DateTime? createdAt;

  String get fullName => name;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'email': email,
      'name': name,
      'role': role,
      'schoolId': schoolId,
      'status': status,
      'phoneNumber': phoneNumber,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    final Timestamp? createdTimestamp = map['createdAt'] as Timestamp?;

    return UserModel(
      id: id,
      email: map['email'] as String? ?? '',
      name: map['name'] as String? ?? map['fullName'] as String? ?? '',
      role: map['role'] as String? ?? 'bursar',
      schoolId: map['schoolId'] as String? ?? '',
      status: map['status'] as String? ?? 'pending approval',
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: createdTimestamp?.toDate(),
    );
  }
}
