import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/currency_formatter.dart';
import '../../models/class_model.dart';
import '../../models/payment_model.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../services/report_export_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key, required this.schoolId});

  final String schoolId;

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final ReportExportService _reportExportService = ReportExportService();
  final TextEditingController _admissionController = TextEditingController();

  String _selectedReport = _reportTypes.first;
  String _selectedTerm = 'Term 1';
  int _selectedYear = DateTime.now().year;
  String _selectedClass = 'All Classes';
  String _selectedStream = 'All Streams';
  bool _isExportingPdf = false;
  bool _isExportingExcel = false;

  static const List<String> _reportTypes = <String>[
    'Individual Student Statement',
    'Class Fee Report',
    'Term Collection Report',
    'Whole School Balance Report',
  ];

  @override
  void dispose() {
    _admissionController.dispose();
    super.dispose();
  }

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

                final List<String> classOptions = <String>[
                  'All Classes',
                  ...{
                    ...AppConstants.schoolClassLevels,
                    ...classes.map((classModel) => classModel.name),
                    ...students.map((student) => student.className),
                  }.where((value) => value.trim().isNotEmpty),
                ];
                final List<String> streamOptions = <String>[
                  'All Streams',
                  ...{
                    ...classes.map((classModel) => classModel.stream),
                    ...students.map((student) => student.streamName),
                  }.where((value) => value.trim().isNotEmpty),
                ];
                final List<int> yearOptions = _availableYears(payments);

                final StudentModel? selectedStudent = students
                    .where((student) {
                      return student.admissionNumber.trim().toLowerCase() ==
                          _admissionController.text.trim().toLowerCase();
                    })
                    .cast<StudentModel?>()
                    .firstWhere(
                      (student) => student != null,
                      orElse: () => null,
                    );

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    DashboardCard(
                      title: 'Reports',
                      subtitle:
                          'Review school finance reports and export them as PDF or Excel.',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          DropdownButtonFormField<String>(
                            initialValue: _selectedReport,
                            items:
                                _reportTypes
                                    .map(
                                      (report) => DropdownMenuItem<String>(
                                        value: report,
                                        child: Text(report),
                                      ),
                                    )
                                    .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedReport = value);
                              }
                            },
                            decoration: const InputDecoration(
                              labelText: 'Report type',
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_selectedReport == 'Individual Student Statement')
                            TextField(
                              controller: _admissionController,
                              onChanged: (_) => setState(() {}),
                              decoration: const InputDecoration(
                                labelText: 'Admission number',
                              ),
                            ),
                          if (_selectedReport == 'Class Fee Report' ||
                              _selectedReport == 'Whole School Balance Report')
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
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
                          if (_selectedReport == 'Term Collection Report')
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: <Widget>[
                                _FilterDropdown<String>(
                                  label: 'Term',
                                  value: _selectedTerm,
                                  options: const <String>[
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
                                  options: yearOptions,
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() => _selectedYear = value);
                                    }
                                  },
                                ),
                              ],
                            ),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: <Widget>[
                              FilledButton.icon(
                                onPressed:
                                    _isExportingPdf
                                        ? null
                                        : () => _exportCurrentReport(
                                          students: students,
                                          payments: payments,
                                          selectedStudent: selectedStudent,
                                          exportType: _ReportExportType.pdf,
                                        ),
                                icon: const Icon(Icons.picture_as_pdf_outlined),
                                label: Text(
                                  _isExportingPdf
                                      ? 'Exporting PDF...'
                                      : 'Export PDF',
                                ),
                              ),
                              OutlinedButton.icon(
                                onPressed:
                                    _isExportingExcel
                                        ? null
                                        : () => _exportCurrentReport(
                                          students: students,
                                          payments: payments,
                                          selectedStudent: selectedStudent,
                                          exportType: _ReportExportType.excel,
                                        ),
                                icon: const Icon(Icons.table_chart_outlined),
                                label: Text(
                                  _isExportingExcel
                                      ? 'Exporting Excel...'
                                      : 'Export Excel',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildReportBody(
                      students: students,
                      payments: payments,
                      selectedStudent: selectedStudent,
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

  Widget _buildReportBody({
    required List<StudentModel> students,
    required List<PaymentModel> payments,
    required StudentModel? selectedStudent,
  }) {
    switch (_selectedReport) {
      case 'Individual Student Statement':
        return _buildStudentStatement(
          student: selectedStudent,
          payments: payments,
        );
      case 'Class Fee Report':
        return _buildClassFeeReport(students);
      case 'Term Collection Report':
        return _buildTermCollectionReport(payments);
      case 'Whole School Balance Report':
      default:
        return _buildWholeSchoolBalanceReport(students);
    }
  }

  Widget _buildStudentStatement({
    required StudentModel? student,
    required List<PaymentModel> payments,
  }) {
    if (_admissionController.text.trim().isEmpty) {
      return const EmptyState(
        icon: Icons.person_search_outlined,
        title: 'Select a student',
        message:
            'Enter an admission number to generate the individual student statement.',
      );
    }

    if (student == null) {
      return const EmptyState(
        icon: Icons.error_outline,
        title: 'Student not found',
        message: 'No student matches that admission number in this school.',
      );
    }

    final List<PaymentModel> studentPayments =
        payments.where((payment) => payment.studentId == student.id).toList()
          ..sort((a, b) {
            final DateTime aDate =
                a.paymentDate ?? a.receivedAt ?? DateTime(1970);
            final DateTime bDate =
                b.paymentDate ?? b.receivedAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

    return Column(
      children: <Widget>[
        DashboardCard(
          title: student.fullName,
          subtitle:
              '${student.admissionNumber} | ${student.className} ${student.streamName}',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Total expected fee: ${CurrencyFormatter.formatAmount(student.totalExpectedFee)}',
              ),
              Text(
                'Total paid: ${CurrencyFormatter.formatAmount(student.totalPaid)}',
              ),
              Text(
                'Balance: ${CurrencyFormatter.formatAmount(student.balance)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (studentPayments.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No payments recorded',
            message: 'This student has no payment history yet.',
          )
        else
          ...studentPayments.map(
            (payment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DashboardCard(
                title: payment.receiptNumber,
                subtitle:
                    '${_formatDate(payment.paymentDate ?? payment.receivedAt)} | ${payment.method}',
                trailing: Text(
                  CurrencyFormatter.formatAmount(payment.amount),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildClassFeeReport(List<StudentModel> students) {
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

    if (filteredStudents.isEmpty) {
      return const EmptyState(
        icon: Icons.class_outlined,
        title: 'No students for this filter',
        message:
            'Adjust the class or stream filter to view the class fee report.',
      );
    }

    return Column(
      children:
          filteredStudents
              .map(
                (student) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardCard(
                    title: '${student.admissionNumber} - ${student.fullName}',
                    subtitle: '${student.className} ${student.streamName}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Total expected: ${CurrencyFormatter.formatAmount(student.totalExpectedFee)}',
                        ),
                        Text(
                          'Total paid: ${CurrencyFormatter.formatAmount(student.totalPaid)}',
                        ),
                        Text(
                          'Balance: ${CurrencyFormatter.formatAmount(student.balance)}',
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildTermCollectionReport(List<PaymentModel> payments) {
    final List<PaymentModel> filteredPayments =
        payments.where((payment) {
            final DateTime paymentDate =
                payment.paymentDate ?? payment.receivedAt ?? DateTime(1970);
            return paymentDate.year == _selectedYear &&
                _termForDate(paymentDate) == _selectedTerm;
          }).toList()
          ..sort((a, b) {
            final DateTime aDate =
                a.paymentDate ?? a.receivedAt ?? DateTime(1970);
            final DateTime bDate =
                b.paymentDate ?? b.receivedAt ?? DateTime(1970);
            return bDate.compareTo(aDate);
          });

    if (filteredPayments.isEmpty) {
      return const EmptyState(
        icon: Icons.payments_outlined,
        title: 'No term collections found',
        message: 'No payment records match the selected term and year.',
      );
    }

    return Column(
      children:
          filteredPayments
              .map(
                (payment) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DashboardCard(
                    title: payment.receiptNumber,
                    subtitle:
                        '${_formatDate(payment.paymentDate ?? payment.receivedAt)} | ${payment.studentName}',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Amount: ${CurrencyFormatter.formatAmount(payment.amount)}',
                        ),
                        Text('Payment method: ${payment.method}'),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
    );
  }

  Widget _buildWholeSchoolBalanceReport(List<StudentModel> students) {
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

    if (filteredStudents.isEmpty) {
      return const EmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No balance records found',
        message: 'Adjust the filters to view the whole school balance report.',
      );
    }

    final double totalOutstanding = filteredStudents.fold<double>(
      0,
      (sum, student) => sum + student.balance,
    );

    return Column(
      children: <Widget>[
        DashboardCard(
          title: 'Whole School Balance Report',
          subtitle: '${filteredStudents.length} students in current filter',
          trailing: Text(
            CurrencyFormatter.formatAmount(totalOutstanding),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 12),
        ...filteredStudents.map(
          (student) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: DashboardCard(
              title: '${student.admissionNumber} - ${student.fullName}',
              subtitle: '${student.className} ${student.streamName}',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Total expected: ${CurrencyFormatter.formatAmount(student.totalExpectedFee)}',
                  ),
                  Text(
                    'Total paid: ${CurrencyFormatter.formatAmount(student.totalPaid)}',
                  ),
                  Text(
                    'Balance: ${CurrencyFormatter.formatAmount(student.balance)}',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _exportCurrentReport({
    required List<StudentModel> students,
    required List<PaymentModel> payments,
    required StudentModel? selectedStudent,
    required _ReportExportType exportType,
  }) async {
    setState(() {
      if (exportType == _ReportExportType.pdf) {
        _isExportingPdf = true;
      } else {
        _isExportingExcel = true;
      }
    });

    try {
      final _ReportPayload payload = _buildExportPayload(
        students: students,
        payments: payments,
        selectedStudent: selectedStudent,
      );

      if (exportType == _ReportExportType.pdf) {
        await _reportExportService.exportPdf(
          fileName: payload.fileName,
          title: payload.title,
          headers: payload.headers,
          rows: payload.rows,
          notes: payload.notes,
        );
      } else {
        await _reportExportService.exportExcel(
          fileName: payload.fileName,
          sheetName: payload.sheetName,
          headers: payload.headers,
          rows: payload.rows,
        );
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${payload.title} exported as ${exportType == _ReportExportType.pdf ? 'PDF' : 'Excel'}.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Export failed: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isExportingPdf = false;
          _isExportingExcel = false;
        });
      }
    }
  }

  _ReportPayload _buildExportPayload({
    required List<StudentModel> students,
    required List<PaymentModel> payments,
    required StudentModel? selectedStudent,
  }) {
    switch (_selectedReport) {
      case 'Individual Student Statement':
        if (selectedStudent == null) {
          throw Exception('Select a valid student before exporting.');
        }
        final List<PaymentModel> studentPayments =
            payments
                .where((payment) => payment.studentId == selectedStudent.id)
                .toList()
              ..sort((a, b) {
                final DateTime aDate =
                    a.paymentDate ?? a.receivedAt ?? DateTime(1970);
                final DateTime bDate =
                    b.paymentDate ?? b.receivedAt ?? DateTime(1970);
                return aDate.compareTo(bDate);
              });
        return _ReportPayload(
          fileName:
              'student_statement_${selectedStudent.admissionNumber.toLowerCase()}',
          sheetName: 'StudentStatement',
          title: 'Individual Student Statement',
          headers: const <String>[
            'Date',
            'Receipt Number',
            'Reference',
            'Payment Method',
            'Amount',
          ],
          rows:
              studentPayments
                  .map(
                    (payment) => <String>[
                      _formatDate(payment.paymentDate ?? payment.receivedAt),
                      payment.receiptNumber,
                      payment.reference,
                      payment.method,
                      CurrencyFormatter.formatAmount(payment.amount),
                    ],
                  )
                  .toList(),
          notes: <String>[
            'Student: ${selectedStudent.fullName}',
            'Admission Number: ${selectedStudent.admissionNumber}',
            'Class: ${selectedStudent.className} ${selectedStudent.streamName}',
            'Total Expected Fee: ${CurrencyFormatter.formatAmount(selectedStudent.totalExpectedFee)}',
            'Total Paid: ${CurrencyFormatter.formatAmount(selectedStudent.totalPaid)}',
            'Balance: ${CurrencyFormatter.formatAmount(selectedStudent.balance)}',
          ],
        );
      case 'Class Fee Report':
        final List<StudentModel> classStudents =
            students.where((student) {
              final bool classMatches =
                  _selectedClass == 'All Classes' ||
                  student.className == _selectedClass;
              final bool streamMatches =
                  _selectedStream == 'All Streams' ||
                  student.streamName == _selectedStream;
              return classMatches && streamMatches;
            }).toList();
        return _ReportPayload(
          fileName: 'class_fee_report',
          sheetName: 'ClassFeeReport',
          title: 'Class Fee Report',
          headers: const <String>[
            'Admission Number',
            'Student Name',
            'Class',
            'Stream',
            'Total Expected',
            'Total Paid',
            'Balance',
          ],
          rows:
              classStudents
                  .map(
                    (student) => <String>[
                      student.admissionNumber,
                      student.fullName,
                      student.className,
                      student.streamName,
                      CurrencyFormatter.formatAmount(student.totalExpectedFee),
                      CurrencyFormatter.formatAmount(student.totalPaid),
                      CurrencyFormatter.formatAmount(student.balance),
                    ],
                  )
                  .toList(),
          notes: <String>[
            'Class Filter: $_selectedClass',
            'Stream Filter: $_selectedStream',
          ],
        );
      case 'Term Collection Report':
        final List<PaymentModel> termPayments =
            payments.where((payment) {
                final DateTime paymentDate =
                    payment.paymentDate ?? payment.receivedAt ?? DateTime(1970);
                return paymentDate.year == _selectedYear &&
                    _termForDate(paymentDate) == _selectedTerm;
              }).toList()
              ..sort((a, b) {
                final DateTime aDate =
                    a.paymentDate ?? a.receivedAt ?? DateTime(1970);
                final DateTime bDate =
                    b.paymentDate ?? b.receivedAt ?? DateTime(1970);
                return aDate.compareTo(bDate);
              });
        return _ReportPayload(
          fileName: 'term_collection_report',
          sheetName: 'TermCollections',
          title: 'Term Collection Report',
          headers: const <String>[
            'Date',
            'Receipt Number',
            'Student',
            'Amount',
            'Payment Method',
          ],
          rows:
              termPayments
                  .map(
                    (payment) => <String>[
                      _formatDate(payment.paymentDate ?? payment.receivedAt),
                      payment.receiptNumber,
                      payment.studentName,
                      CurrencyFormatter.formatAmount(payment.amount),
                      payment.method,
                    ],
                  )
                  .toList(),
          notes: <String>['Term: $_selectedTerm', 'Year: $_selectedYear'],
        );
      case 'Whole School Balance Report':
      default:
        final List<StudentModel> balanceStudents =
            students.where((student) {
              final bool classMatches =
                  _selectedClass == 'All Classes' ||
                  student.className == _selectedClass;
              final bool streamMatches =
                  _selectedStream == 'All Streams' ||
                  student.streamName == _selectedStream;
              return classMatches && streamMatches;
            }).toList();
        return _ReportPayload(
          fileName: 'whole_school_balance_report',
          sheetName: 'SchoolBalance',
          title: 'Whole School Balance Report',
          headers: const <String>[
            'Admission Number',
            'Student Name',
            'Class',
            'Stream',
            'Total Expected',
            'Total Paid',
            'Balance',
          ],
          rows:
              balanceStudents
                  .map(
                    (student) => <String>[
                      student.admissionNumber,
                      student.fullName,
                      student.className,
                      student.streamName,
                      CurrencyFormatter.formatAmount(student.totalExpectedFee),
                      CurrencyFormatter.formatAmount(student.totalPaid),
                      CurrencyFormatter.formatAmount(student.balance),
                    ],
                  )
                  .toList(),
          notes: <String>[
            'Class Filter: $_selectedClass',
            'Stream Filter: $_selectedStream',
            'Total Outstanding: ${CurrencyFormatter.formatAmount(balanceStudents.fold<double>(0, (sum, student) => sum + student.balance))}',
          ],
        );
    }
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

  String _termForDate(DateTime date) {
    if (date.month >= 1 && date.month <= 4) {
      return 'Term 1';
    }
    if (date.month >= 5 && date.month <= 8) {
      return 'Term 2';
    }
    return 'Term 3';
  }

  String _formatDate(DateTime? date) {
    if (date == null) {
      return 'N/A';
    }
    return DateFormat('yyyy-MM-dd').format(date);
  }
}

enum _ReportExportType { pdf, excel }

class _ReportPayload {
  const _ReportPayload({
    required this.fileName,
    required this.sheetName,
    required this.title,
    required this.headers,
    required this.rows,
    this.notes = const <String>[],
  });

  final String fileName;
  final String sheetName;
  final String title;
  final List<String> headers;
  final List<List<String>> rows;
  final List<String> notes;
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
