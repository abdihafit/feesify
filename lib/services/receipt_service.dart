import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../core/constants/app_constants.dart';
import '../core/utils/currency_formatter.dart';
import '../models/payment_model.dart';
import '../models/student_model.dart';

class ReceiptService {
  Future<Uint8List> buildReceiptPdf({
    required PaymentModel payment,
    required StudentModel student,
  }) async {
    final pw.Document document = pw.Document();
    final String paymentDate =
        payment.paymentDate == null
            ? 'N/A'
            : DateFormat('yyyy-MM-dd').format(payment.paymentDate!);

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: <pw.Widget>[
              pw.Text(
                AppConstants.appName,
                style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text('Payment Receipt'),
              pw.SizedBox(height: 24),
              _receiptRow('Receipt Number', payment.receiptNumber),
              _receiptRow('Date', paymentDate),
              _receiptRow('Admission Number', payment.admissionNumber),
              _receiptRow('Student Name', payment.studentName),
              _receiptRow(
                'Class',
                '${student.className} ${student.streamName}'.trim(),
              ),
              _receiptRow('Payment Method', payment.method),
              _receiptRow('Reference Number', payment.reference),
              _receiptRow('Received By', payment.receivedBy),
              pw.SizedBox(height: 16),
              _receiptRow(
                'Previous Balance',
                CurrencyFormatter.formatAmount(payment.previousBalance),
              ),
              _receiptRow(
                'Amount Paid',
                CurrencyFormatter.formatAmount(payment.amount),
              ),
              _receiptRow(
                'New Balance',
                CurrencyFormatter.formatAmount(payment.newBalance),
              ),
            ],
          );
        },
      ),
    );

    return document.save();
  }

  Future<void> printReceipt({
    required PaymentModel payment,
    required StudentModel student,
  }) async {
    final Uint8List bytes = await buildReceiptPdf(
      payment: payment,
      student: student,
    );
    await Printing.layoutPdf(onLayout: (_) async => bytes);
  }

  Future<void> downloadReceipt({
    required PaymentModel payment,
    required StudentModel student,
  }) async {
    final Uint8List bytes = await buildReceiptPdf(
      payment: payment,
      student: student,
    );

    await FileSaver.instance.saveFile(
      name: 'receipt_${payment.receiptNumber}',
      bytes: bytes,
      ext: 'pdf',
      mimeType: MimeType.pdf,
    );
  }

  pw.Widget _receiptRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Row(
        children: <pw.Widget>[
          pw.Expanded(
            child: pw.Text(
              label,
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(child: pw.Text(value)),
        ],
      ),
    );
  }
}
