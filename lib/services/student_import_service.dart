import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';

class StudentImportService {
  static const List<String> templateHeaders = <String>[
    'admissionNumber',
    'studentName',
    'className',
    'streamName',
    'parentPhone',
    'termFee',
    'previousBalance',
    'totalExpectedFee',
  ];

  Future<void> downloadTemplate() async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel['Students'];

    sheet.appendRow(
      templateHeaders
          .map<CellValue>((header) => TextCellValue(header))
          .toList(),
    );
    sheet.appendRow(<CellValue>[
      TextCellValue('ADM001'),
      TextCellValue('Amina Noor'),
      TextCellValue('Form Three'),
      TextCellValue('East'),
      TextCellValue('0712345678'),
      DoubleCellValue(25000),
      DoubleCellValue(5000),
      DoubleCellValue(30000),
    ]);

    final List<int>? bytes = excel.save(
      fileName: 'student_import_template.xlsx',
    );
    if (bytes == null) {
      throw Exception('Unable to generate the Excel template.');
    }

    await FileSaver.instance.saveFile(
      name: 'student_import_template',
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
