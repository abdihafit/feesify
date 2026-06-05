import 'dart:math';

import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../models/class_model.dart';
import '../../models/student_import_result.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../services/student_import_service.dart';
import '../../widgets/dashboard_card.dart';
import '../../widgets/empty_state.dart';

class StudentImportScreen extends StatefulWidget {
  const StudentImportScreen({
    super.key,
    required this.schoolId,
    this.readOnly = false,
  });

  final String schoolId;
  final bool readOnly;

  @override
  State<StudentImportScreen> createState() => _StudentImportScreenState();
}

class _StudentImportScreenState extends State<StudentImportScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final StudentImportService _studentImportService = StudentImportService();

  bool _isDownloadingTemplate = false;
  bool _isUploading = false;
  StudentImportResult? _lastResult;
  String? _errorMessage;

  Future<void> _downloadTemplate() async {
    setState(() {
      _isDownloadingTemplate = true;
      _errorMessage = null;
    });

    try {
      await _studentImportService.downloadTemplate();
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Excel template downloaded successfully.'),
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isDownloadingTemplate = false);
      }
    }
  }

  Future<void> _uploadExcel() async {
    setState(() {
      _isUploading = true;
      _errorMessage = null;
      _lastResult = null;
    });

    try {
      final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: <String>['xlsx'],
        withData: true,
      );

      if (pickedFile == null || pickedFile.files.single.bytes == null) {
        setState(() => _isUploading = false);
        return;
      }

      final StudentImportResult result = await _processExcel(
        pickedFile.files.single.bytes!,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _lastResult = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Student import completed. Uploaded ${result.totalUploaded} students.',
          ),
        ),
      );
    } catch (error) {
      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<StudentImportResult> _processExcel(List<int> bytes) async {
    final Excel excel = Excel.decodeBytes(bytes);
    final String sheetName = excel.tables.keys.first;
    final Sheet? sheet = excel.tables[sheetName];

    if (sheet == null || sheet.rows.isEmpty) {
      throw Exception('The uploaded Excel file is empty.');
    }

    final List<String> headers =
        sheet.rows.first
            .map((cell) => _cellToString(cell?.value).trim())
            .toList();
    final Map<String, int> headerIndex = <String, int>{};
    for (int index = 0; index < headers.length; index++) {
      if (headers[index].isNotEmpty) {
        headerIndex[headers[index]] = index;
      }
    }

    const List<String> requiredHeaders = <String>[
      'admissionNumber',
      'studentName',
      'className',
      'streamName',
      'parentPhone',
      'termFee',
      'previousBalance',
      'totalExpectedFee',
    ];

    final List<String> missingHeaders =
        requiredHeaders
            .where((header) => !headerIndex.containsKey(header))
            .toList();
    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing required columns: ${missingHeaders.join(', ')}.',
      );
    }

    final List<ClassModel> classes = await _firestoreService.getClasses(
      widget.schoolId,
    );
    final Map<String, ClassModel> classLookup = <String, ClassModel>{
      for (final ClassModel classModel in classes)
        _classLookupKey(classModel.name, classModel.stream): classModel,
    };

    final Set<String> existingAdmissionNumbers = await _firestoreService
        .getAdmissionNumbers(widget.schoolId);
    final Set<String> seenInFile = <String>{};
    final List<StudentModel> studentsToUpload = <StudentModel>[];
    final List<StudentImportFailure> failedRows = <StudentImportFailure>[];
    int skippedDuplicates = 0;

    for (int rowIndex = 1; rowIndex < sheet.rows.length; rowIndex++) {
      final List<Data?> row = sheet.rows[rowIndex];
      final int excelRowNumber = rowIndex + 1;

      final String admissionNumber =
          _readCell(row, headerIndex['admissionNumber']!).trim();
      if (admissionNumber.isEmpty) {
        failedRows.add(
          StudentImportFailure(
            rowNumber: excelRowNumber,
            reason: 'Missing admission number',
          ),
        );
        continue;
      }

      if (existingAdmissionNumbers.contains(admissionNumber) ||
          seenInFile.contains(admissionNumber)) {
        skippedDuplicates++;
        continue;
      }

      final String studentName =
          _readCell(row, headerIndex['studentName']!).trim();
      final String className = _readCell(row, headerIndex['className']!).trim();
      final String streamName =
          _readCell(row, headerIndex['streamName']!).trim();
      final String parentPhone =
          _readCell(row, headerIndex['parentPhone']!).trim();

      final double? termFee = _parseDouble(
        _readCell(row, headerIndex['termFee']!),
      );
      final double? previousBalance = _parseDouble(
        _readCell(row, headerIndex['previousBalance']!),
      );
      final double? totalExpectedFee = _parseDouble(
        _readCell(row, headerIndex['totalExpectedFee']!),
      );
      final double totalPaid =
          headerIndex.containsKey('totalPaid')
              ? (_parseDouble(_readCell(row, headerIndex['totalPaid']!)) ?? 0)
              : 0;

      if (studentName.isEmpty ||
          className.isEmpty ||
          streamName.isEmpty ||
          termFee == null ||
          previousBalance == null ||
          totalExpectedFee == null) {
        failedRows.add(
          StudentImportFailure(
            rowNumber: excelRowNumber,
            admissionNumber: admissionNumber,
            reason: 'Missing or invalid required values in the row',
          ),
        );
        continue;
      }

      final ClassModel? matchedClass =
          classLookup[_classLookupKey(className, streamName)];
      final double balance = max(0, totalExpectedFee - totalPaid);

      studentsToUpload.add(
        StudentModel(
          id: '${widget.schoolId}_$admissionNumber',
          admissionNumber: admissionNumber,
          fullName: studentName,
          schoolId: widget.schoolId,
          classId: matchedClass?.id ?? '',
          className: className,
          streamName: streamName,
          guardianName: '',
          guardianPhone: parentPhone,
          termFee: termFee,
          previousBalance: previousBalance,
          totalPaid: totalPaid,
          totalExpectedFee: totalExpectedFee,
          totalFees: totalExpectedFee,
          balance: balance,
          createdAt: DateTime.now(),
        ),
      );
      seenInFile.add(admissionNumber);
    }

    return _firestoreService.importStudents(
      schoolId: widget.schoolId,
      students: studentsToUpload,
      skippedDuplicates: skippedDuplicates,
      failedRows: failedRows,
    );
  }

  String _readCell(List<Data?> row, int index) {
    if (index >= row.length) {
      return '';
    }

    return _cellToString(row[index]?.value);
  }

  String _cellToString(CellValue? value) {
    if (value == null) {
      return '';
    }

    return value.toString();
  }

  double? _parseDouble(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.trim());
  }

  String _classLookupKey(String className, String streamName) {
    return '${className.trim().toLowerCase()}::${streamName.trim().toLowerCase()}';
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        DashboardCard(
          title: 'Student Import',
          subtitle:
              widget.readOnly
                  ? 'Review the student import template and latest upload summary for this school.'
                  : 'Upload an Excel file to add students to this school in bulk.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: <Widget>[
                  FilledButton.icon(
                    onPressed:
                        widget.readOnly || _isDownloadingTemplate
                            ? null
                            : _downloadTemplate,
                    icon: const Icon(Icons.download_outlined),
                    label: Text(
                      _isDownloadingTemplate
                          ? 'Preparing template...'
                          : 'Download Excel Template',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed:
                        widget.readOnly || _isUploading ? null : _uploadExcel,
                    icon: const Icon(Icons.upload_file_outlined),
                    label: Text(
                      _isUploading ? 'Uploading...' : 'Upload Excel File',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (widget.readOnly)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Read-only mode: review the import workflow here.',
                  ),
                ),
              Text(
                'Expected columns: admissionNumber, studentName, className, streamName, parentPhone, termFee, previousBalance, totalExpectedFee.',
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Upload Summary',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 12),
        if (_lastResult == null)
          const EmptyState(
            icon: Icons.summarize_outlined,
            title: 'No upload summary yet',
            message:
                'Download the template, fill it in, then upload the Excel file to see the import summary.',
          )
        else
          DashboardCard(
            title: 'Latest Import Result',
            subtitle: 'Summary of the last Excel upload for this school.',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _SummaryRow(
                  label: 'Total uploaded',
                  value: _lastResult!.totalUploaded.toString(),
                ),
                _SummaryRow(
                  label: 'Skipped duplicates',
                  value: _lastResult!.skippedDuplicates.toString(),
                ),
                _SummaryRow(
                  label: 'Failed rows',
                  value: _lastResult!.failedRows.length.toString(),
                ),
                if (_lastResult!.failedRows.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 16),
                  Text(
                    'Failed Rows',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ..._lastResult!.failedRows.map(
                    (failure) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Row ${failure.rowNumber}: ${failure.reason}${failure.admissionNumber == null ? '' : ' (${failure.admissionNumber})'}',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label)),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
