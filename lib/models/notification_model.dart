import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.recipientRole,
    required this.schoolId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final String recipientRole;
  final String schoolId;
  final bool isRead;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'title': title,
      'message': message,
      'type': type,
      'recipientRole': recipientRole,
      'schoolId': schoolId,
      'isRead': isRead,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }
}
