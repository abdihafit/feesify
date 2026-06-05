import 'dart:typed_data';

import 'package:excel/excel.dart';
import 'package:file_saver/file_saver.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ReportExportService {
  Future<void> exportPdf({
    required String fileName,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    List<String> notes = const <String>[],
  }) async {
    final pw.Document document = pw.Document();

    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return <pw.Widget>[
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
            ),
            if (notes.isNotEmpty) ...<pw.Widget>[
              pw.SizedBox(height: 12),
              ...notes.map(
                (note) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Text(note),
                ),
              ),
            ],
            pw.SizedBox(height: 16),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              cellAlignment: pw.Alignment.centerLeft,
            ),
          ];
        },
      ),
    );

    final Uint8List bytes = await document.save();
    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  Future<void> exportExcel({
    required String fileName,
    required String sheetName,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final Excel excel = Excel.createExcel();
    final Sheet sheet = excel[sheetName];

    sheet.appendRow(
      headers.map<CellValue>((header) => TextCellValue(header)).toList(),
    );

    for (final List<String> row in rows) {
      sheet.appendRow(
        row.map<CellValue>((value) => TextCellValue(value)).toList(),
      );
    }

    final List<int>? bytes = excel.save(fileName: '$fileName.xlsx');
    if (bytes == null) {
      throw Exception('Unable to generate Excel export.');
    }

    await FileSaver.instance.saveFile(
      name: fileName,
      bytes: Uint8List.fromList(bytes),
      ext: 'xlsx',
      mimeType: MimeType.microsoftExcel,
    );
  }
}
