import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  const ClassModel({
    required this.id,
    required this.schoolId,
    required this.name,
    required this.stream,
    required this.classTeacher,
    this.createdAt,
  });

  final String id;
  final String schoolId;
  final String name;
  final String stream;
  final String classTeacher;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'schoolId': schoolId,
      'name': name,
      'stream': stream,
      'classTeacher': classTeacher,
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    };
  }

  factory ClassModel.fromMap(String id, Map<String, dynamic> map) {
    return ClassModel(
      id: id,
      schoolId: map['schoolId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      stream: map['stream'] as String? ?? '',
      classTeacher: map['classTeacher'] as String? ?? '',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
