import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/firestore_paths.dart';
import '../models/class_model.dart';
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../models/school_model.dart';
import '../models/student_import_result.dart';
import '../models/student_model.dart';
import '../models/user_model.dart';
import '../core/utils/phone_number_utils.dart';

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection(FirestorePaths.users);

  CollectionReference<Map<String, dynamic>> get _schoolsCollection =>
      _firestore.collection(FirestorePaths.schools);

  CollectionReference<Map<String, dynamic>> get _classesCollection =>
      _firestore.collection(FirestorePaths.classes);

  CollectionReference<Map<String, dynamic>> get _studentsCollection =>
      _firestore.collection(FirestorePaths.students);

  CollectionReference<Map<String, dynamic>> get _paymentsCollection =>
      _firestore.collection(FirestorePaths.payments);

  CollectionReference<Map<String, dynamic>> get _notificationsCollection =>
      _firestore.collection(FirestorePaths.notifications);

  CollectionReference<Map<String, dynamic>> get _loginIdentifiersCollection =>
      _firestore.collection(FirestorePaths.loginIdentifiers);

  Future<void> saveUser(UserModel user) {
    return _usersCollection
        .doc(user.id)
        .set(user.toMap(), SetOptions(merge: true));
  }

  Future<void> saveSchool(SchoolModel school) {
    return _schoolsCollection
        .doc(school.id)
        .set(school.toMap(), SetOptions(merge: true));
  }

  Future<void> createPrincipalRegistration({
    required String userId,
    required String schoolName,
    required String county,
    required String principalName,
    required String phoneNumber,
    required String email,
  }) async {
    final DocumentReference<Map<String, dynamic>> schoolRef =
        _schoolsCollection.doc();
    final DateTime now = DateTime.now();

    final String normalizedPhone = PhoneNumberUtils.normalize(phoneNumber);

    final SchoolModel school = SchoolModel(
      id: schoolRef.id,
      name: schoolName,
      county: county,
      principalName: principalName,
      email: email,
      phone: normalizedPhone,
      status: 'pending approval',
      paymentStatus: 'pending',
      principalUserId: userId,
      createdAt: now,
    );

    final UserModel principal = UserModel(
      id: userId,
      email: email,
      name: principalName,
      role: 'principal',
      schoolId: schoolRef.id,
      status: 'pending approval',
      phoneNumber: normalizedPhone,
      createdAt: now,
    );

    final DocumentReference<Map<String, dynamic>> notificationRef =
        _notificationsCollection.doc();
    final NotificationModel notification = NotificationModel(
      id: notificationRef.id,
      title: 'New school registration',
      message:
          '$schoolName registered under $principalName and is awaiting approval.',
      type: 'school_registration',
      recipientRole: 'admin',
      schoolId: schoolRef.id,
      createdAt: now,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(schoolRef, school.toMap());
      transaction.set(_usersCollection.doc(userId), principal.toMap());
      transaction.set(notificationRef, notification.toMap());
      transaction.set(_loginIdentifiersCollection.doc(normalizedPhone), <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'phoneNumber': normalizedPhone,
        'userId': userId,
        'schoolId': schoolRef.id,
        'role': 'principal',
        'status': 'pending approval',
        'createdAt': Timestamp.fromDate(now),
      });
    });
  }

  Future<void> ensureAdminUser({
    required String userId,
    required String email,
  }) {
    final UserModel admin = UserModel(
      id: userId,
      email: email,
      name: 'System Administrator',
      role: 'admin',
      schoolId: '',
      status: 'active',
      createdAt: DateTime.now(),
    );

    return _usersCollection
        .doc(userId)
        .set(admin.toMap(), SetOptions(merge: true));
  }

  Stream<UserModel?> streamUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      final Map<String, dynamic>? data = snapshot.data();
      if (!snapshot.exists || data == null) {
        return null;
      }
      return UserModel.fromMap(snapshot.id, data);
    });
  }

  Stream<List<SchoolModel>> streamSchools() {
    return _schoolsCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SchoolModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<SchoolModel>> streamPendingSchools() {
    return _schoolsCollection
        .where('status', isEqualTo: 'pending approval')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SchoolModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<ClassModel>> streamClasses(String schoolId) {
    return _classesCollection
        .where('schoolId', isEqualTo: schoolId)
        .orderBy('name')
        .orderBy('stream')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<StudentModel>> streamStudents(String schoolId) {
    return _studentsCollection
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
          final List<StudentModel> students = snapshot.docs
              .map((doc) => StudentModel.fromMap(doc.id, doc.data()))
              .toList();

          students.sort(
            (a, b) => a.admissionNumber.toLowerCase().compareTo(
              b.admissionNumber.toLowerCase(),
            ),
          );

          return students;
        });
  }

  Stream<StudentModel?> streamStudentByAdmissionNumber({
    required String schoolId,
    required String admissionNumber,
  }) {
    return _studentsCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('admissionNumber', isEqualTo: admissionNumber.trim())
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) {
            return null;
          }

          final QueryDocumentSnapshot<Map<String, dynamic>> doc =
              snapshot.docs.first;
          return StudentModel.fromMap(doc.id, doc.data());
        });
  }

  Future<List<ClassModel>> getClasses(String schoolId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _classesCollection.where('schoolId', isEqualTo: schoolId).get();

    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<Set<String>> getAdmissionNumbers(String schoolId) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot =
        await _studentsCollection.where('schoolId', isEqualTo: schoolId).get();

    return snapshot.docs
        .map((doc) => (doc.data()['admissionNumber'] as String? ?? '').trim())
        .where((admissionNumber) => admissionNumber.isNotEmpty)
        .toSet();
  }

  Stream<List<PaymentModel>> streamPayments(String schoolId) {
    return _paymentsCollection
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<PaymentModel>> streamStudentPayments({
    required String schoolId,
    required String studentId,
  }) {
    return _paymentsCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .orderBy('receivedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Stream<List<PaymentModel>> streamPaymentsForAllSchools() {
    return _paymentsCollection.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.id, doc.data()))
          .toList();
    });
  }

  Stream<List<UserModel>> streamSchoolUsersByRole({
    required String schoolId,
    required String role,
  }) {
    return _usersCollection
        .where('schoolId', isEqualTo: schoolId)
        .where('role', isEqualTo: role)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => UserModel.fromMap(doc.id, doc.data()))
              .toList();
        });
  }

  Future<void> saveStudent(StudentModel student) {
    return _studentsCollection
        .doc(student.id)
        .set(student.toMap(), SetOptions(merge: true));
  }

  Future<StudentImportResult> importStudents({
    required String schoolId,
    required List<StudentModel> students,
    required int skippedDuplicates,
    required List<StudentImportFailure> failedRows,
  }) async {
    final WriteBatch batch = _firestore.batch();

    for (final StudentModel student in students) {
      batch.set(_studentsCollection.doc(student.id), student.toMap());
    }

    if (students.isNotEmpty) {
      await batch.commit();
    }

    return StudentImportResult(
      totalUploaded: students.length,
      skippedDuplicates: skippedDuplicates,
      failedRows: failedRows,
    );
  }

  Future<void> savePayment(PaymentModel payment) {
    return _paymentsCollection
        .doc(payment.id)
        .set(payment.toMap(), SetOptions(merge: true));
  }

  Future<PaymentModel> recordPayment({
    required StudentModel student,
    required String schoolId,
    required DateTime paymentDate,
    required String method,
    required double amountPaid,
    required String referenceNumber,
    required String receivedBy,
  }) async {
    final DocumentReference<Map<String, dynamic>> paymentRef =
        _paymentsCollection.doc();
    final double previousBalance = student.balance;
    final double newTotalPaid = student.totalPaid + amountPaid;
    final double newBalance = (student.totalExpectedFee - newTotalPaid).clamp(
      0,
      double.infinity,
    );
    final String receiptNumber =
        'RCT-${DateTime.now().millisecondsSinceEpoch}-${paymentRef.id.substring(0, 4).toUpperCase()}';

    final PaymentModel payment = PaymentModel(
      id: paymentRef.id,
      studentId: student.id,
      schoolId: schoolId,
      studentName: student.fullName,
      admissionNumber: student.admissionNumber,
      amount: amountPaid,
      method: method,
      status: newBalance <= 0 ? 'paid' : 'partial',
      reference: referenceNumber,
      receiptNumber: receiptNumber,
      receivedBy: receivedBy,
      previousBalance: previousBalance,
      newBalance: newBalance.toDouble(),
      paymentDate: paymentDate,
      receivedAt: DateTime.now(),
    );

    final StudentModel updatedStudent = StudentModel(
      id: student.id,
      admissionNumber: student.admissionNumber,
      fullName: student.fullName,
      schoolId: student.schoolId,
      classId: student.classId,
      className: student.className,
      streamName: student.streamName,
      guardianName: student.guardianName,
      guardianPhone: student.guardianPhone,
      termFee: student.termFee,
      previousBalance: student.previousBalance,
      totalPaid: newTotalPaid,
      totalExpectedFee: student.totalExpectedFee,
      totalFees: student.totalFees,
      balance: newBalance.toDouble(),
      createdAt: student.createdAt,
    );

    await _firestore.runTransaction((transaction) async {
      transaction.set(paymentRef, payment.toMap());
      transaction.set(
        _studentsCollection.doc(student.id),
        updatedStudent.toMap(),
        SetOptions(merge: true),
      );
    });

    return payment;
  }

  Future<void> saveClassroom(ClassModel classroom) {
    return _classesCollection
        .doc(classroom.id)
        .set(classroom.toMap(), SetOptions(merge: true));
  }

  Future<void> createClassStream({
    required String schoolId,
    required String name,
    required String stream,
  }) {
    final DocumentReference<Map<String, dynamic>> classRef =
        _classesCollection.doc();

    final ClassModel classroom = ClassModel(
      id: classRef.id,
      schoolId: schoolId,
      name: name,
      stream: stream,
      classTeacher: '',
      createdAt: DateTime.now(),
    );

    return saveClassroom(classroom);
  }

  Future<void> updateClassStream({
    required String classId,
    required String schoolId,
    required String name,
    required String stream,
  }) {
    final ClassModel classroom = ClassModel(
      id: classId,
      schoolId: schoolId,
      name: name,
      stream: stream,
      classTeacher: '',
      createdAt: DateTime.now(),
    );

    return saveClassroom(classroom);
  }

  Future<void> deleteClassStream(String classId) {
    return _classesCollection.doc(classId).delete();
  }

  Future<void> saveBursarUser({
    required String userId,
    required String name,
    required String phoneNumber,
    required String email,
    required String schoolId,
  }) {
    final String normalizedPhone = PhoneNumberUtils.normalize(phoneNumber);
    final String normalizedEmail = email.trim().toLowerCase();

    final UserModel bursar = UserModel(
      id: userId,
      email: normalizedEmail,
      name: name,
      role: 'bursar',
      schoolId: schoolId,
      status: 'active',
      phoneNumber: normalizedPhone,
      createdAt: DateTime.now(),
    );

    return _firestore.runTransaction((transaction) async {
      transaction.set(_usersCollection.doc(userId), bursar.toMap(), SetOptions(merge: true));
      transaction.set(_loginIdentifiersCollection.doc(normalizedPhone), <String, dynamic>{
        'email': normalizedEmail,
        'phoneNumber': normalizedPhone,
        'userId': userId,
        'schoolId': schoolId,
        'role': 'bursar',
        'status': 'active',
        'createdAt': Timestamp.fromDate(DateTime.now()),
      }, SetOptions(merge: true));
    });
  }

  Future<String?> resolveEmailFromIdentifier(String identifier) async {
    final String trimmedIdentifier = identifier.trim().toLowerCase();
    if (trimmedIdentifier.contains('@')) {
      return trimmedIdentifier;
    }

    final String normalizedPhone = PhoneNumberUtils.normalize(identifier);
    final DocumentSnapshot<Map<String, dynamic>> snapshot =
        await _loginIdentifiersCollection.doc(normalizedPhone).get();

    if (!snapshot.exists) {
      return null;
    }

    final String? email = snapshot.data()?['email'] as String?;
    return email?.trim().toLowerCase();
  }

  Future<void> approveSchool({
    required String schoolId,
    required String principalUserId,
  }) async {
    await _firestore.runTransaction((transaction) async {
      transaction.update(_schoolsCollection.doc(schoolId), <String, dynamic>{
        'status': 'approved',
      });
      transaction.set(_usersCollection.doc(principalUserId), <String, dynamic>{
        'status': 'active',
      }, SetOptions(merge: true));
    });
  }

  Future<void> rejectSchool({
    required String schoolId,
    required String principalUserId,
  }) async {
    await _updateSchoolAndPrincipalStatus(
      schoolId: schoolId,
      principalUserId: principalUserId,
      schoolStatus: 'rejected',
      userStatus: 'suspended',
    );
  }

  Future<void> deactivateSchool({
    required String schoolId,
    required String principalUserId,
  }) async {
    await _updateSchoolAndPrincipalStatus(
      schoolId: schoolId,
      principalUserId: principalUserId,
      schoolStatus: 'inactive',
      userStatus: 'suspended',
    );
  }

  Future<void> _updateSchoolAndPrincipalStatus({
    required String schoolId,
    required String principalUserId,
    required String schoolStatus,
    required String userStatus,
  }) async {
    await _firestore.runTransaction((transaction) async {
      transaction.update(_schoolsCollection.doc(schoolId), <String, dynamic>{
        'status': schoolStatus,
      });
      transaction.set(_usersCollection.doc(principalUserId), <String, dynamic>{
        'status': userStatus,
      }, SetOptions(merge: true));
    });
  }
}
