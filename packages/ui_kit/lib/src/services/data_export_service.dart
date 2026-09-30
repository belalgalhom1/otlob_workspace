import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_colors.dart';

enum ExportFormat { excel, pdf }

class DataExportService {
  static String buildCsvContent(
    List<String> headers,
    List<List<String>> rows,
  ) {
    final buffer = StringBuffer('\uFEFF');
    buffer.writeln(headers.map(_csvEscape).join(','));

    for (final row in rows) {
      final cells = List<String>.from(row);
      while (cells.length < headers.length) {
        cells.add('');
      }
      buffer.writeln(
        cells.take(headers.length).map(_csvEscape).join(','),
      );
    }

    return buffer.toString();
  }

  static Future<void> showExportOptions(
    BuildContext context, {
    required String title,
    String? subtitle,
    required List<String> headers,
    required List<List<String>> rows,
    String? filename,
  }) async {
    final format = await showModalBottomSheet<ExportFormat>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => _ExportFormatSheet(
        title: title,
        subtitle: subtitle,
      ),
    );
    if (format == null || !context.mounted) return;

    final safeName =
        (filename ?? title).replaceAll(RegExp(r'[^\w]+'), '_');

    try {
      switch (format) {
        case ExportFormat.excel:
          await exportCsv(
            context: context,
            title: title,
            headers: headers,
            rows: rows,
            filename: safeName,
          );
        case ExportFormat.pdf:
          await exportPdf(
            context: context,
            title: title,
            headers: headers,
            rows: rows,
            filename: safeName,
          );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  static String _csvEscape(String value) {
    if (value.contains(',') ||
        value.contains('"') ||
        value.contains('\n') ||
        value.contains('\r')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static Future<void> exportCsv({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required String filename,
  }) async {
    final content = buildCsvContent(headers, rows);

    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${filename}_$stamp.csv');
    await file.writeAsString(content);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        title: title,
        subject: title,
      ),
    );
  }

  static Future<void> exportPdf({
    required BuildContext context,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required String filename,
  }) async {
    final doc = pw.Document();

    final font = await PdfGoogleFonts.cairoRegular();
    final boldFont = await PdfGoogleFonts.cairoBold();

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          textDirection: pw.TextDirection.rtl,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 22,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    DateFormat('yyyy-MM-dd').format(DateTime.now()),
                    style: const pw.TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              '${headers.length} ${headers.length == 1 ? 'column' : 'columns'} - ${rows.length} ${rows.length == 1 ? 'row' : 'rows'}',
              style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
            ),
            pw.SizedBox(height: 24),
            pw.TableHelper.fromTextArray(
              headers: headers,
              data: _toPdfRows(rows, headers.length),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 1),
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
              ),
              headerDecoration:
                  const pw.BoxDecoration(color: PdfColors.blueGrey800),
              cellHeight: 30,
              cellAlignments: {
                for (var i = 0; i < headers.length; i++)
                  i: pw.Alignment.centerRight,
              },
            ),
          ];
        },
      ),
    );

    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${filename}_$stamp.pdf',
    );
  }

  static List<List<String>> _toPdfRows(
    List<List<String>> rows,
    int columnCount,
  ) {
    return rows.map((row) {
      final cells = List<String>.from(row);
      while (cells.length < columnCount) {
        cells.add('');
      }
      return cells.take(columnCount).toList();
    }).toList();
  }
}

class _ExportFormatSheet extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _ExportFormatSheet({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : Colors.black54,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FormatOption(
                    label: 'Excel (CSV)',
                    icon: LucideIcons.fileSpreadsheet,
                    color: Colors.green,
                    onTap: () =>
                        Navigator.pop(context, ExportFormat.excel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _FormatOption(
                    label: 'PDF',
                    icon: LucideIcons.fileText,
                    color: AppColors.error,
                    onTap: () => Navigator.pop(context, ExportFormat.pdf),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FormatOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FormatOption({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}