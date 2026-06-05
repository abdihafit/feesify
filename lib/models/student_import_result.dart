class StudentImportFailure {
  const StudentImportFailure({
    required this.rowNumber,
    required this.reason,
    this.admissionNumber,
  });

  final int rowNumber;
  final String reason;
  final String? admissionNumber;
}

class StudentImportResult {
  const StudentImportResult({
    required this.totalUploaded,
    required this.skippedDuplicates,
    required this.failedRows,
  });

  final int totalUploaded;
  final int skippedDuplicates;
  final List<StudentImportFailure> failedRows;
}
