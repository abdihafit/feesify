import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/utils/currency_formatter.dart';
import '../../models/class_model.dart';
import '../../models/payment_model.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class PrincipalOverviewScreen extends StatefulWidget {
  const PrincipalOverviewScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  State<PrincipalOverviewScreen> createState() =>
      _PrincipalOverviewScreenState();
}

class _PrincipalOverviewScreenState extends State<PrincipalOverviewScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _selectedTerm = 'All Terms';
  int _selectedYear = DateTime.now().year;
  String _selectedClass = 'All Classes';
  String _selectedStream = 'All Streams';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<StudentModel>>(
      stream: _firestoreService.streamStudents(widget.schoolId),
      builder: (context, studentSnapshot) {
        return StreamBuilder<List<PaymentModel>>(
          stream: _firestoreService.streamPayments(widget.schoolId),
          builder: (context, paymentSnapshot) {
            return StreamBuilder<List<ClassModel>>(
              stream: _firestoreService.streamClasses(widget.schoolId),
              builder: (context, classSnapshot) {
                if (studentSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    paymentSnapshot.connectionState ==
                        ConnectionState.waiting ||
                    classSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final List<StudentModel> students =
                    studentSnapshot.data ?? <StudentModel>[];
                final List<PaymentModel> payments =
                    paymentSnapshot.data ?? <PaymentModel>[];
                final List<ClassModel> classes =
                    classSnapshot.data ?? <ClassModel>[];

                if (students.isEmpty) {
                  return const EmptyState(
                    icon: Icons.insights_outlined,
                    title: 'No student data yet',
                    message:
                        'Once students and payments are added, the principal dashboard summary will appear here.',
                  );
                }

                final List<String> classOptions = <String>[
                  'All Classes',
                  ...{
                    ...students.map((student) => student.className),
                    ...classes.map((classModel) => classModel.name),
                  }.where((value) => value.trim().isNotEmpty),
                ];
                final List<String> streamOptions = <String>[
                  'All Streams',
                  ...{
                    ...students.map((student) => student.streamName),
                    ...classes.map((classModel) => classModel.stream),
                  }.where((value) => value.trim().isNotEmpty),
                ];

                final List<StudentModel> filteredStudents =
                    students.where((student) {
                      final bool classMatches =
                          _selectedClass == 'All Classes' ||
                          student.className == _selectedClass;
                      final bool streamMatches =
                          _selectedStream == 'All Streams' ||
                          student.streamName == _selectedStream;
                      return classMatches && streamMatches;
                    }).toList();

                final Set<String> filteredStudentIds =
                    filteredStudents.map((student) => student.id).toSet();
                final List<PaymentModel> filteredPayments =
                    payments.where((payment) {
                      if (!filteredStudentIds.contains(payment.studentId)) {
                        return false;
                      }

                      final DateTime paymentDate =
                          payment.paymentDate ??
                          payment.receivedAt ??
                          DateTime(1970);
                      return paymentDate.year == _selectedYear;
                    }).toList();

                final List<PaymentModel> termPayments =
                    filteredPayments.where((payment) {
                      if (_selectedTerm == 'All Terms') {
                        return true;
                      }
                      return _termForDate(
                            payment.paymentDate ??
                                payment.receivedAt ??
                                DateTime(1970),
                          ) ==
                          _selectedTerm;
                    }).toList();

                final DateTime now = DateTime.now();
                final double totalExpectedFees = filteredStudents.fold<double>(
                  0,
                  (sum, student) => sum + student.totalExpectedFee,
                );
                final double totalOutstandingBalance = filteredStudents
                    .fold<double>(0, (sum, student) => sum + student.balance);
                final int studentsWithBalances =
                    filteredStudents
                        .where((student) => student.balance > 0)
                        .length;
                final int fullyPaidStudents =
                    filteredStudents
                        .where((student) => student.balance <= 0)
                        .length;
                final double totalCollectedThisTerm = termPayments.fold<double>(
                  0,
                  (sum, payment) => sum + payment.amount,
                );
                final double totalCollectedThisMonth = filteredPayments
                    .where((payment) {
                      final DateTime paymentDate =
                          payment.paymentDate ??
                          payment.receivedAt ??
                          DateTime(1970);
                      return paymentDate.month == now.month &&
                          paymentDate.year == now.year;
                    })
                    .fold<double>(0, (sum, payment) => sum + payment.amount);
                final double totalCollectedThisYear = filteredPayments
                    .fold<double>(0, (sum, payment) => sum + payment.amount);

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    DashboardCard(
                      title: 'Principal Overview',
                      subtitle:
                          'Monitor enrollment, collection progress, and outstanding balances with school-wide filters.',
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _FilterDropdown<String>(
                            label: 'Term',
                            value: _selectedTerm,
                            options: const <String>[
                              'All Terms',
                              'Term 1',
                              'Term 2',
                              'Term 3',
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedTerm = value);
                              }
                            },
                          ),
                          _FilterDropdown<int>(
                            label: 'Year',
                            value: _selectedYear,
                            options: _availableYears(payments),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedYear = value);
                              }
                            },
                          ),
                          _FilterDropdown<String>(
                            label: 'Class',
                            value: _selectedClass,
                            options: classOptions,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedClass = value);
                              }
                            },
                          ),
                          _FilterDropdown<String>(
                            label: 'Stream',
                            value: _selectedStream,
                            options: streamOptions,
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedStream = value);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.count(
                      crossAxisCount:
                          MediaQuery.of(context).size.width >= 1200 ? 4 : 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.35,
                      children: <Widget>[
                        _MetricCard(
                          title: 'Total students',
                          value: filteredStudents.length.toString(),
                        ),
                        _MetricCard(
                          title: 'Total expected fees',
                          value: CurrencyFormatter.formatAmount(
                            totalExpectedFees,
                          ),
                        ),
                        _MetricCard(
                          title: 'Collected this term',
                          value: CurrencyFormatter.formatAmount(
                            totalCollectedThisTerm,
                          ),
                        ),
                        _MetricCard(
                          title: 'Collected this month',
                          value: CurrencyFormatter.formatAmount(
                            totalCollectedThisMonth,
                          ),
                        ),
                        _MetricCard(
                          title: 'Collected this year',
                          value: CurrencyFormatter.formatAmount(
                            totalCollectedThisYear,
                          ),
                        ),
                        _MetricCard(
                          title: 'Outstanding balance',
                          value: CurrencyFormatter.formatAmount(
                            totalOutstandingBalance,
                          ),
                        ),
                        _MetricCard(
                          title: 'Students with balances',
                          value: studentsWithBalances.toString(),
                        ),
                        _MetricCard(
                          title: 'Fully paid students',
                          value: fullyPaidStudents.toString(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    DashboardCard(
                      title: 'Active Filters',
                      subtitle:
                          'Current summary based on selected year, term, class, and stream.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text('Term: $_selectedTerm'),
                          Text('Year: $_selectedYear'),
                          Text('Class: $_selectedClass'),
                          Text('Stream: $_selectedStream'),
                          const SizedBox(height: 8),
                          Text(
                            'Updated ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  String _termForDate(DateTime date) {
    if (date.month >= 1 && date.month <= 4) {
      return 'Term 1';
    }
    if (date.month >= 5 && date.month <= 8) {
      return 'Term 2';
    }
    return 'Term 3';
  }

  List<int> _availableYears(List<PaymentModel> payments) {
    final Set<int> years =
        payments
            .map((payment) => (payment.paymentDate ?? payment.receivedAt)?.year)
            .whereType<int>()
            .toSet();
    years.add(DateTime.now().year);
    final List<int> sortedYears =
        years.toList()..sort((a, b) => b.compareTo(a));
    return sortedYears;
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
          ],
        ),
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> options;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 220,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        items:
            options
                .map(
                  (option) => DropdownMenuItem<T>(
                    value: option,
                    child: Text(option.toString()),
                  ),
                )
                .toList(),
        onChanged: onChanged,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
