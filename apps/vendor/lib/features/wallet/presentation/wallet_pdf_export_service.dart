import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class WalletPdfExportService {
  static Future<void> exportTransactionsPdf({
    required BuildContext context,
    required double balance,
    required List<dynamic> transactions,
  }) async {
    final pdf = pw.Document();

    // Load an Arabic compatible font.
    // Cairo is excellent for numbers and Arabic text.
    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    final dateFormat = DateFormat('yyyy-MM-dd hh:mm a');

    // Filter or map transactions
    final tableData = transactions.map((tx) {
      final id = tx['id']?.toString() ?? '';
      final idShort = id.length >= 8 ? id.substring(0, 8) : id;
      final type = tx['type']?.toString() ?? 'N/A';
      final amount = double.tryParse(tx['amount']?.toString() ?? '0') ?? 0.0;
      final createdAt = tx['createdAt'] != null
          ? dateFormat.format(DateTime.parse(tx['createdAt']).toLocal())
          : 'Unknown';
      final desc = tx['description'] ?? '';

      return [
        createdAt,
        idShort,
        type,
        desc,
        '${amount.toStringAsFixed(2)} EGP',
      ];
    }).toList();

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(
            base: font,
            bold: boldFont,
          ),
          textDirection: pw.TextDirection.rtl, // Set RTL for Arabic
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (pw.Context context) {
          return [
            // Header
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'كشف حساب المعاملات المالية', // Financial Transactions Statement
                    style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 14),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            
            // Balance Info
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('الرصيد المتاح:', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                  pw.Text('${balance.toStringAsFixed(2)} EGP', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.green700)),
                ],
              ),
            ),
            pw.SizedBox(height: 30),

            // Transactions Table
            pw.TableHelper.fromTextArray(
              headers: ['التاريخ', 'رقم المعاملة', 'النوع', 'الوصف', 'المبلغ'],
              data: tableData,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 30,
              cellAlignments: {
                0: pw.Alignment.centerRight,
                1: pw.Alignment.centerRight,
                2: pw.Alignment.centerRight,
                3: pw.Alignment.centerRight,
                4: pw.Alignment.centerLeft, // amount aligned left
              },
            ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'financial_transactions_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }
}
