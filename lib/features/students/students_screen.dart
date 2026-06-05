import 'package:flutter/material.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class StudentsScreen extends StatelessWidget {
  StudentsScreen({super.key, required this.schoolId});

  final String schoolId;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentModel>>(
      stream: _firestoreService.streamStudents(schoolId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final List<StudentModel> students = snapshot.data ?? <StudentModel>[];
        if (students.isEmpty) {
          return const EmptyState(
            icon: Icons.school_outlined,
            title: 'No students yet',
            message: 'Add student records in Firestore to see enrollment here.',
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final StudentModel student = students[index];
            return DashboardCard(
              title: student.fullName,
              subtitle:
                  'Adm: ${student.admissionNumber} • ${student.guardianName}',
              trailing: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    CurrencyFormatter.formatAmount(student.balance),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('Outstanding balance'),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
