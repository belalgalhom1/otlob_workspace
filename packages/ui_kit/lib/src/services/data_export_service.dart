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

/// One table section inside a multi-section export (e.g. one analytics tab).
class ExportSection {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const ExportSection({
    required this.title,
    required this.headers,
    required this.rows,
  });
}

class DriverSettlementOrderExportData {
  final String orderNumber;
  final DateTime settledAt;
  final double subtotal;
  final double reimbursedAmount;
  final double collectedCash;
  final double deliveryFee;
  final double netAmount;

  const DriverSettlementOrderExportData({
    required this.orderNumber,
    required this.settledAt,
    required this.subtotal,
    required this.reimbursedAmount,
    required this.collectedCash,
    required this.deliveryFee,
    required this.netAmount,
  });
}

class VendorSettlementOrderExportData {
  final String orderNumber;
  final DateTime settledAt;
  final double subtotal;
  final double commissionAmount;
  final double netVendorEarnings;

  const VendorSettlementOrderExportData({
    required this.orderNumber,
    required this.settledAt,
    required this.subtotal,
    required this.commissionAmount,
    required this.netVendorEarnings,
  });
}

class DriverShiftOrderExportData {
  final String orderNumber;
  final DateTime? pickedUpAt;
  final DateTime? actualDeliveryTime;
  final double deliveryFee;
  final double driverManagerCommission;
  final double platformProfit;
  final double driverEarnings;

  const DriverShiftOrderExportData({
    required this.orderNumber,
    this.pickedUpAt,
    this.actualDeliveryTime,
    required this.deliveryFee,
    required this.driverManagerCommission,
    required this.platformProfit,
    required this.driverEarnings,
  });
}

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
    String? entityName,
    List<ExportSection>? sections,
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
    final isRtl = Localizations.localeOf(context).languageCode == 'ar';

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
          if (sections != null && sections.isNotEmpty) {
            await exportSectionsPdf(
              context: context,
              title: title,
              subtitle: subtitle,
              entityName: entityName,
              sections: sections,
              filename: safeName,
              isRtl: isRtl,
            );
          } else {
            await exportPdf(
              context: context,
              title: title,
              subtitle: subtitle,
              entityName: entityName,
              headers: headers,
              rows: rows,
              filename: safeName,
              isRtl: isRtl,
            );
          }
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
    String? subtitle,
    String? entityName,
    required List<String> headers,
    required List<List<String>> rows,
    required String filename,
    bool isRtl = true,
  }) async {
    // If table has more than 7 columns, split into 2 readable pages
    if (headers.length > 8) {
      final fixedCount = headers.length >= 3 ? 3 : 1;
      final fixedHeaders = headers.sublist(0, fixedCount);
      final dynamicHeaders = headers.sublist(fixedCount);
      final half = (dynamicHeaders.length / 2).ceil();

      final s1Headers = [...fixedHeaders, ...dynamicHeaders.sublist(0, half)];
      final s2Headers = [...fixedHeaders, ...dynamicHeaders.sublist(half)];

      final s1Rows = rows.map((r) => [
        ...r.sublist(0, fixedCount),
        ...r.sublist(fixedCount, fixedCount + half),
      ]).toList();

      final s2Rows = rows.map((r) => [
        ...r.sublist(0, fixedCount),
        ...r.sublist(fixedCount + half),
      ]).toList();

      await exportSectionsPdf(
        context: context,
        title: title,
        subtitle: subtitle,
        entityName: entityName,
        sections: [
          ExportSection(
            title: isRtl ? 'القسم الأول - البيانات الأساسية والمالية' : 'Section 1 - Financial Overview',
            headers: s1Headers,
            rows: s1Rows,
          ),
          ExportSection(
            title: isRtl ? 'القسم الثاني - مؤشرات الأداء والتشغيل' : 'Section 2 - Operational Breakdown',
            headers: s2Headers,
            rows: s2Rows,
          ),
        ],
        filename: filename,
        isRtl: isRtl,
      );
    } else {
      await exportSectionsPdf(
        context: context,
        title: title,
        subtitle: subtitle,
        entityName: entityName,
        sections: [ExportSection(title: title, headers: headers, rows: rows)],
        filename: filename,
        isRtl: isRtl,
      );
    }
  }

  /// Multi-section PDF: every section starts on its own page, so a full
  /// analytics report lands in one file with one page per tab/section.
  static Future<void> exportSectionsPdf({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? entityName,
    required List<ExportSection> sections,
    required String filename,
    bool isRtl = true,
  }) async {
    // Resolve entity/driver name if not explicitly passed
    String? resolvedEntity = entityName?.trim();
    if ((resolvedEntity == null || resolvedEntity.isEmpty) && title.contains(':')) {
      resolvedEntity = title.split(':').sublist(1).join(':').trim();
    }
    final doc = pw.Document();

    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      boldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }

    final direction = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());

    final brandPrimary = PdfColor.fromInt(0xFF0F172A); // Slate 900
    final brandAccent = PdfColor.fromInt(0xFFE5A93C);  // Otlob Gold
    final bgZebra = PdfColor.fromInt(0xFFF8FAFC);      // Slate 50
    final borderColor = PdfColor.fromInt(0xFFE2E8F0);  // Slate 200
    final cardBg = PdfColor.fromInt(0xFFF1F5F9);       // Slate 100

    // Prevent crushed/broken text: if any section has > 7 columns, split into parts
    final normalizedSections = <ExportSection>[];
    for (final sec in sections) {
      // In A4 landscape, up to 9-10 columns fit with ample room without line breaks.
      if (sec.headers.length > 8) {
        final fixedCount = sec.headers.length >= 3 ? 3 : 1;
        final fixedHeaders = sec.headers.sublist(0, fixedCount);
        final dynamicHeaders = sec.headers.sublist(fixedCount);
        final half = (dynamicHeaders.length / 2).ceil();

        final s1Headers = [...fixedHeaders, ...dynamicHeaders.sublist(0, half)];
        final s2Headers = [...fixedHeaders, ...dynamicHeaders.sublist(half)];

        final s1Rows = sec.rows.map((r) => [
          ...r.sublist(0, fixedCount),
          ...r.sublist(fixedCount, fixedCount + half),
        ]).toList();

        final s2Rows = sec.rows.map((r) => [
          ...r.sublist(0, fixedCount),
          ...r.sublist(fixedCount + half),
        ]).toList();

        normalizedSections.add(ExportSection(
          title: '${sec.title} (${isRtl ? 'الجزء 1' : 'Part 1'})',
          headers: s1Headers,
          rows: s1Rows,
        ));
        normalizedSections.add(ExportSection(
          title: '${sec.title} (${isRtl ? 'الجزء 2' : 'Part 2'})',
          headers: s2Headers,
          rows: s2Rows,
        ));
      } else {
        normalizedSections.add(sec);
      }
    }

    for (var s = 0; s < normalizedSections.length; s++) {
      final section = normalizedSections[s];
      final sectionSubtitle = normalizedSections.length > 1 ? section.title : subtitle;

      doc.addPage(
        pw.MultiPage(
          pageTheme: pw.PageTheme(
            pageFormat: PdfPageFormat.a4.landscape,
            theme: pw.ThemeData.withFont(base: font, bold: boldFont),
            textDirection: direction,
            margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          ),
          footer: (pw.Context ctx) => pw.Container(
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isRtl ? 'منصة اطلب - تقرير بيانات إحصائية رسمي معتمد' : 'Otlob Platform - Official Operations & Analytics Report',
                  style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
                pw.Text(
                  '${isRtl ? 'صفحة' : 'Page'} ${ctx.pageNumber} / ${ctx.pagesCount}',
                  style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
                ),
              ],
            ),
          ),
          build: (pw.Context context) {
            return [
              // 1. Executive Top Banner with Otlob Branding
              pw.Container(
                decoration: pw.BoxDecoration(
                  color: brandPrimary,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          title,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        if (sectionSubtitle != null && sectionSubtitle.isNotEmpty) ...[
                          pw.SizedBox(height: 2),
                          pw.Text(
                            sectionSubtitle,
                            style: pw.TextStyle(
                              fontSize: 11,
                              fontWeight: pw.FontWeight.bold,
                              color: brandAccent,
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 2),
                        if (resolvedEntity != null && resolvedEntity.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: brandAccent,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '${isRtl ? 'السائق' : 'Driver'}: $resolvedEntity',
                              style: pw.TextStyle(
                                fontSize: 9.5,
                                fontWeight: pw.FontWeight.bold,
                                color: brandPrimary,
                              ),
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 2),
                        pw.Text(
                          isRtl
                              ? 'تقرير إحصائي معتمد من لوحة تحكم منصة اطلب'
                              : 'Official certified operational export from Otlob Platform',
                          style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey400),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                      children: [
                        pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text('OTLOB', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandAccent)),
                            pw.Text('  |  ', style: pw.TextStyle(fontSize: 11, color: PdfColors.white)),
                            pw.Text('اطلب', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: brandAccent)),
                          ],
                        ),
                        pw.Text(
                          dateStr,
                          style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey300),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 2. Summary KPI bar
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: pw.BoxDecoration(
                  color: cardBg,
                  borderRadius: pw.BorderRadius.circular(6),
                  border: pw.Border.all(color: borderColor, width: 0.8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (resolvedEntity != null && resolvedEntity.isNotEmpty)
                      pw.Text(
                        '${isRtl ? 'السائق' : 'Driver'}: $resolvedEntity',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                    pw.Text(
                      '${isRtl ? 'إجمالي السجلات' : 'Total Records'}: ${section.rows.length}',
                      style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                    ),
                    pw.Text(
                      '${isRtl ? 'عدد الأعمدة' : 'Columns'}: ${section.headers.length}',
                      style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                    ),
                    pw.Text(
                      '${isRtl ? 'حالة التقرير' : 'Status'}: ${isRtl ? 'مكتمل ومعتمد' : 'Certified Complete'}',
                      style: pw.TextStyle(fontSize: 9.5, color: PdfColors.green800, fontWeight: pw.FontWeight.bold),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),

              // 3. High-Quality Data Table
              if (section.rows.isEmpty)
                pw.Container(
                  padding: const pw.EdgeInsets.all(24),
                  alignment: pw.Alignment.center,
                  decoration: pw.BoxDecoration(
                    color: bgZebra,
                    borderRadius: pw.BorderRadius.circular(8),
                    border: pw.Border.all(color: borderColor, width: 0.5),
                  ),
                  child: pw.Text(
                    isRtl ? 'لا توجد بيانات متاحة في هذا القسم' : 'No data records available in this section',
                    style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                  ),
                )
              else
                pw.TableHelper.fromTextArray(
                  headers: section.headers,
                  data: _toPdfRows(section.rows, section.headers.length),
                  border: pw.TableBorder.all(color: borderColor, width: 0.5),
                  headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: section.headers.length > 8 ? 7.5 : 8.5,
                  ),
                  headerDecoration: pw.BoxDecoration(color: brandPrimary),
                  headerHeight: 28,
                  cellHeight: 24,
                  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  cellStyle: pw.TextStyle(fontSize: section.headers.length > 8 ? 7.5 : 8.0),
                  rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                  oddRowDecoration: pw.BoxDecoration(color: bgZebra),
                  cellAlignments: {
                    for (var i = 0; i < section.headers.length; i++)
                      i: pw.Alignment.center,
                  },
                ),
            ];
          },
        ),
      );
    }

    final stamp = DateFormat('yyyyMMdd').format(DateTime.now());
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: '${filename}_$stamp.pdf',
    );
  }

  /// Combined single-file CSV for multiple sections (blank line + titled
  /// header row per section) so "everything" also ships as one file.
  /// Specialized Executive PDF report for a Driver Shift with all individual
  /// orders, driver manager commission, delivery fee, platform profit,
  /// pickup/delivery times, and executive KPI summary cards.
  static Future<void> exportDriverShiftPdfReport({
    required BuildContext context,
    required String driverName,
    String? driverPhone,
    String? zoneName,
    required String shiftTitle,
    required DateTime shiftDate,
    DateTime? startTime,
    DateTime? endTime,
    required List<DriverShiftOrderExportData> orders,
    bool isRtl = true,
  }) async {
    final doc = pw.Document();

    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      boldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final direction = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final shiftDateStr = DateFormat('yyyy-MM-dd').format(shiftDate);
    final timeFormat = DateFormat('hh:mm a');

    // Totals calculations
    final totalDeliveryFees = orders.fold<double>(0.0, (s, o) => s + o.deliveryFee);
    final totalManagerCommission = orders.fold<double>(0.0, (s, o) => s + o.driverManagerCommission);
    final totalPlatformProfit = orders.fold<double>(0.0, (s, o) => s + o.platformProfit);
    final totalDriverEarnings = orders.fold<double>(0.0, (s, o) => s + o.driverEarnings);
    final orderCount = orders.length;

    final brandPrimary = PdfColor.fromInt(0xFF0F172A); // Dark Slate
    final brandAccent = PdfColor.fromInt(0xFFE5A93C);  // Otlob Gold
    final bgZebra = PdfColor.fromInt(0xFFF8FAFC);
    final borderColor = PdfColor.fromInt(0xFFE2E8F0);
    final cardBg = PdfColor.fromInt(0xFFF1F5F9);

    final currency = isRtl ? 'ج.م' : 'EGP';

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          textDirection: direction,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        footer: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isRtl ? 'منصة اطلب - تقرير أداء الوردية وإحصائيات العمليات' : 'Otlob Platform - Driver Shift Performance Report',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
              pw.Text(
                '${isRtl ? 'صفحة' : 'Page'} ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            // 1. Top Executive Banner
            pw.Container(
              decoration: pw.BoxDecoration(
                color: brandPrimary,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isRtl ? 'تقرير أداء الوردية وحسابات التوصيل' : 'Shift Performance & Delivery Report',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        isRtl ? 'تفاصيل الطلبات، العمولات، وأرباح المنصة ومسؤول السائقين' : 'Order details, commissions, platform profits & driver earnings',
                        style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey400),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'OTLOB | اطلب',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: brandAccent,
                        ),
                      ),
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // 2. Driver & Shift Info Card
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bgZebra,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Driver Info
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${isRtl ? 'السائق' : 'Driver'}: $driverName',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      if (driverPhone != null && driverPhone.isNotEmpty)
                        pw.Text(
                          '${isRtl ? 'الهاتف' : 'Phone'}: $driverPhone',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                      if (zoneName != null && zoneName.isNotEmpty)
                        pw.Text(
                          '${isRtl ? 'النطاق / المنطقة' : 'Zone'}: $zoneName',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  // Shift Info
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${isRtl ? 'الوردية' : 'Shift'}: $shiftTitle',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      pw.Text(
                        '${isRtl ? 'التاريخ' : 'Date'}: $shiftDateStr',
                        style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                      if (startTime != null && endTime != null)
                        pw.Text(
                          '${isRtl ? 'الفترة' : 'Hours'}: ${timeFormat.format(startTime)} - ${timeFormat.format(endTime)}',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // 3. Metric KPI Cards (5 Cards in a Row)
            pw.Row(
              children: [
                _buildKpiCard(
                  title: isRtl ? 'إجمالي الطلبات' : 'Orders',
                  value: '$orderCount',
                  accentColor: PdfColors.blue800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'رسوم التوصيل' : 'Delivery Fees',
                  value: '${totalDeliveryFees.toStringAsFixed(1)} $currency',
                  accentColor: brandPrimary,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'مسؤول السائقين' : 'Manager Cut',
                  value: '${totalManagerCommission.toStringAsFixed(1)} $currency',
                  accentColor: PdfColors.purple800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'أرباح المنصة' : 'Platform Profit',
                  value: '${totalPlatformProfit.toStringAsFixed(1)} $currency',
                  accentColor: PdfColors.green800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'مستحقات السائق' : 'Driver Earnings',
                  value: '${totalDriverEarnings.toStringAsFixed(1)} $currency',
                  accentColor: brandAccent,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            // 4. Section Title
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  isRtl ? 'بيان الطلبات المكتملة أثناء الوردية' : 'Completed Shift Orders Breakdown',
                  style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                ),
                pw.Text(
                  '${orders.length} ${isRtl ? 'طلب مسلّم' : 'Delivered Orders'}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            ),
            pw.SizedBox(height: 8),

            // 5. Orders Breakdown Table
            if (orders.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: bgZebra,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor, width: 0.5),
                ),
                child: pw.Text(
                  isRtl ? 'لم يتم تسليم أي طلبات خلال هذه الوردية' : 'No delivered orders recorded in this shift',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  isRtl ? 'رقم الطلب' : 'Order #',
                  isRtl ? 'الاستلام' : 'Pickup',
                  isRtl ? 'التسليم' : 'Delivered',
                  isRtl ? 'رسوم التوصيل' : 'Delivery Fee',
                  isRtl ? 'مسؤول السائقين' : 'Manager Share',
                  isRtl ? 'أرباح المنصة' : 'Platform',
                  isRtl ? 'أرباح السائق' : 'Driver',
                ],
                data: [
                  for (final o in orders)
                    [
                      o.orderNumber,
                      o.pickedUpAt != null ? timeFormat.format(o.pickedUpAt!) : '-',
                      o.actualDeliveryTime != null ? timeFormat.format(o.actualDeliveryTime!) : '-',
                      '${o.deliveryFee.toStringAsFixed(1)} $currency',
                      '${o.driverManagerCommission.toStringAsFixed(1)} $currency',
                      '${o.platformProfit.toStringAsFixed(1)} $currency',
                      '${o.driverEarnings.toStringAsFixed(1)} $currency',
                    ],
                  // Totals Row
                  [
                    isRtl ? 'الإجمالي العام' : 'Total',
                    '-',
                    '-',
                    '${totalDeliveryFees.toStringAsFixed(1)} $currency',
                    '${totalManagerCommission.toStringAsFixed(1)} $currency',
                    '${totalPlatformProfit.toStringAsFixed(1)} $currency',
                    '${totalDriverEarnings.toStringAsFixed(1)} $currency',
                  ],
                ],
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: brandPrimary),
                headerHeight: 26,
                cellHeight: 22,
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: pw.BoxDecoration(color: bgZebra),
                cellAlignments: {
                  0: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.center,
                },
              ),
          ];
        },
      ),
    );

    final safeDriver = driverName.replaceAll(RegExp(r'[^\w]+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'shift_report_${safeDriver}_$stamp.pdf',
    );
  }

  static pw.Widget _buildKpiCard({
    required String title,
    required String value,
    required PdfColor accentColor,
    required PdfColor bgColor,
    required PdfColor borderColor,
  }) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(6),
          border: pw.Border.all(color: borderColor, width: 0.8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700),
              maxLines: 1,
            ),
            pw.SizedBox(height: 3),
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: accentColor,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }

  static String buildMultiCsvContent(List<ExportSection> sections) {
    final buffer = StringBuffer('\uFEFF');
    for (var s = 0; s < sections.length; s++) {
      if (s > 0) buffer.writeln();
      final section = sections[s];
      buffer.writeln(_csvEscape('== ${section.title} =='));
      buffer.writeln(section.headers.map(_csvEscape).join(','));
      for (final row in section.rows) {
        final cells = List<String>.from(row);
        while (cells.length < section.headers.length) {
          cells.add('');
        }
        buffer.writeln(
          cells.take(section.headers.length).map(_csvEscape).join(','),
        );
      }
    }
    return buffer.toString();
  }

  static Future<void> exportSectionsCsv({
    required BuildContext context,
    required String title,
    required List<ExportSection> sections,
    required String filename,
  }) async {
    final content = buildMultiCsvContent(sections);

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

  /// Specialized Executive PDF report for a Driver Settlement cycle
  static Future<void> exportDriverSettlementPdfReport({
    required BuildContext context,
    required String driverName,
    String? driverPhone,
    String? zoneName,
    required DateTime periodStart,
    required DateTime periodEnd,
    required double totalCollectedCash,
    required double totalReimbursed,
    required double totalDeliveryFees,
    required double netBalance,
    required List<DriverSettlementOrderExportData> orders,
    bool isRtl = true,
  }) async {
    final doc = pw.Document();

    pw.Font font;
    pw.Font boldFont;
    try {
      font = await PdfGoogleFonts.cairoRegular();
      boldFont = await PdfGoogleFonts.cairoBold();
    } catch (_) {
      font = pw.Font.helvetica();
      boldFont = pw.Font.helveticaBold();
    }
    final direction = isRtl ? pw.TextDirection.rtl : pw.TextDirection.ltr;
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now());
    final dateFormat = DateFormat('yyyy-MM-dd');

    final brandPrimary = PdfColor.fromInt(0xFF0F172A);
    final brandAccent = PdfColor.fromInt(0xFFE5A93C);
    final bgZebra = PdfColor.fromInt(0xFFF8FAFC);
    final borderColor = PdfColor.fromInt(0xFFE2E8F0);
    final cardBg = PdfColor.fromInt(0xFFF1F5F9);
    final currency = isRtl ? 'ج.م' : 'EGP';

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          textDirection: direction,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        ),
        footer: (pw.Context ctx) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(top: pw.BorderSide(color: borderColor, width: 0.5)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                isRtl ? 'منصة اطلب - كشف تسوية حساب السائق المعتمد' : 'Otlob Platform - Certified Driver Settlement Statement',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
              pw.Text(
                '${isRtl ? 'صفحة' : 'Page'} ${ctx.pageNumber} / ${ctx.pagesCount}',
                style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey600),
              ),
            ],
          ),
        ),
        build: (pw.Context context) {
          return [
            pw.Container(
              decoration: pw.BoxDecoration(
                color: brandPrimary,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        isRtl ? 'كشف تسوية حساب السائق المالي' : 'Driver Financial Settlement Statement',
                        style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                      pw.SizedBox(height: 2),
                      pw.Text(
                        isRtl ? 'بيان المبالغ المحصلة والمستردة وأجور التوصيل وصافي الحساب' : 'Summary of collections, reimbursements, delivery fees & balance',
                        style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey400),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'OTLOB | اطلب',
                        style: pw.TextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: brandAccent,
                        ),
                      ),
                      pw.Text(
                        dateStr,
                        style: pw.TextStyle(fontSize: 8.5, color: PdfColors.grey300),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: bgZebra,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: borderColor, width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.end : pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        '${isRtl ? 'السائق' : 'Driver'}: $driverName',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      if (driverPhone != null && driverPhone.isNotEmpty)
                        pw.Text(
                          '${isRtl ? 'الهاتف' : 'Phone'}: $driverPhone',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                      if (zoneName != null && zoneName.isNotEmpty)
                        pw.Text(
                          '${isRtl ? 'المنطقة' : 'Zone'}: $zoneName',
                          style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                        ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: isRtl ? pw.CrossAxisAlignment.start : pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        '${isRtl ? 'فترة التسوية' : 'Settlement Period'}:',
                        style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: brandPrimary),
                      ),
                      pw.Text(
                        '${dateFormat.format(periodStart)} - ${dateFormat.format(periodEnd)}',
                        style: pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            pw.Row(
              children: [
                _buildKpiCard(
                  title: isRtl ? 'إجمالي الطلبات' : 'Orders',
                  value: '${orders.length}',
                  accentColor: PdfColors.blue800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'نقدية مستردة للمتجر (+)' : 'Store Reimbursed (+)',
                  value: '${totalReimbursed.toStringAsFixed(1)} $currency',
                  accentColor: PdfColors.green800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'رسوم التوصيل المستحقة (+)' : 'Delivery Fees (+)',
                  value: '${totalDeliveryFees.toStringAsFixed(1)} $currency',
                  accentColor: brandAccent,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? 'نقدية محصلة من العملاء (-)' : 'Cash Collected (-)',
                  value: '${totalCollectedCash.toStringAsFixed(1)} $currency',
                  accentColor: PdfColors.orange800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
                pw.SizedBox(width: 6),
                _buildKpiCard(
                  title: isRtl ? (netBalance <= 0 ? 'مستحق للمنصة' : 'مستحق للسائق') : 'Net Balance',
                  value: '${netBalance.abs().toStringAsFixed(1)} $currency',
                  accentColor: netBalance <= 0 ? PdfColors.red800 : PdfColors.green800,
                  bgColor: cardBg,
                  borderColor: borderColor,
                ),
              ],
            ),
            pw.SizedBox(height: 18),

            pw.Text(
              isRtl ? 'تفاصيل الطلبات المشمولة في دورة التسوية' : 'Settlement Orders Breakdown',
              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: brandPrimary),
            ),
            pw.SizedBox(height: 8),

            if (orders.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(24),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: bgZebra,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: borderColor, width: 0.5),
                ),
                child: pw.Text(
                  isRtl ? 'لا توجد طلبات في هذه الدورة' : 'No orders in this settlement cycle',
                  style: pw.TextStyle(fontSize: 11, color: PdfColors.grey600),
                ),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: [
                  isRtl ? 'رقم الطلب' : 'Order #',
                  isRtl ? 'تاريخ التسوية' : 'Date',
                  isRtl ? 'قيمة الطلب' : 'Subtotal',
                  isRtl ? 'مستردات الشراء (+)' : 'Reimbursed (+)',
                  isRtl ? 'نقدية محصلة (-)' : 'Collected (-)',
                  isRtl ? 'رسوم التوصيل (+)' : 'Delivery (+)',
                  isRtl ? 'الصافي' : 'Net',
                ],
                data: [
                  for (final o in orders)
                    [
                      o.orderNumber,
                      dateFormat.format(o.settledAt),
                      '${o.subtotal.toStringAsFixed(1)} $currency',
                      '${o.reimbursedAmount.toStringAsFixed(1)} $currency',
                      '${o.collectedCash.toStringAsFixed(1)} $currency',
                      '${o.deliveryFee.toStringAsFixed(1)} $currency',
                      '${o.netAmount.toStringAsFixed(1)} $currency',
                    ],
                  [
                    isRtl ? 'الإجمالي العام' : 'Total',
                    '-',
                    '-',
                    '${totalReimbursed.toStringAsFixed(1)} $currency',
                    '${totalCollectedCash.toStringAsFixed(1)} $currency',
                    '${totalDeliveryFees.toStringAsFixed(1)} $currency',
                    '${netBalance.toStringAsFixed(1)} $currency',
                  ],
                ],
                border: pw.TableBorder.all(color: borderColor, width: 0.5),
                headerStyle: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                  fontSize: 9,
                ),
                headerDecoration: pw.BoxDecoration(color: brandPrimary),
                headerHeight: 26,
                cellHeight: 22,
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: pw.BoxDecoration(color: bgZebra),
                cellAlignments: {
                  0: isRtl ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.center,
                  4: pw.Alignment.center,
                  5: pw.Alignment.center,
                  6: pw.Alignment.center,
                },
              ),
          ];
        },
      ),
    );

    final safeDriver = driverName.replaceAll(RegExp(r'[^\w]+'), '_');
    final stamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    await Printing.sharePdf(
      bytes: await doc.save(),
      filename: 'driver_settlement_${safeDriver}_$stamp.pdf',
    );
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