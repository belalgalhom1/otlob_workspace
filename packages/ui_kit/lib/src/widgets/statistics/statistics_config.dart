import 'package:flutter/material.dart';

class StatisticSummaryItem {
  final String labelAr;
  final String labelEn;
  final IconData icon;
  final String Function(List<dynamic> rows) value;

  const StatisticSummaryItem({
    required this.labelAr,
    required this.labelEn,
    required this.icon,
    required this.value,
  });
}

class StatisticExportColumn {
  final String labelAr;
  final String labelEn;
  final String Function(dynamic row) value;

  const StatisticExportColumn({
    required this.labelAr,
    required this.labelEn,
    required this.value,
  });
}

class StatisticsConfig {
  final String titleAr;
  final String titleEn;
  final String chartTitleAr;
  final String chartTitleEn;
  final String tooltipSuffix;
  final String filenamePrefix;
  final Future<List<dynamic>> Function(
    String period, {
    DateTime? from,
    DateTime? to,
  }) fetch;
  final double Function(dynamic row) amount;
  final List<StatisticSummaryItem> summary;
  final List<StatisticExportColumn> exportColumns;
  final List<String> Function(dynamic row) rowDetails;

  const StatisticsConfig({
    required this.titleAr,
    required this.titleEn,
    required this.chartTitleAr,
    required this.chartTitleEn,
    required this.tooltipSuffix,
    required this.filenamePrefix,
    required this.fetch,
    required this.amount,
    required this.summary,
    required this.exportColumns,
    required this.rowDetails,
  });
}

class StatisticsFormat {
  static double numOf(dynamic v) {
    return double.tryParse((v ?? 0).toString()) ?? 0.0;
  }

  static int intOf(dynamic v) {
    return int.tryParse((v ?? 0).toString().split('.').first) ?? 0;
  }
}

class StatisticsDateUtils {
  static String periodForRange(DateTimeRange range) {
    final days = range.end.difference(range.start).inDays + 1;
    if (days <= 31) return 'DAILY';
    if (days <= 180) return 'WEEKLY';
    return 'MONTHLY';
  }

  static DateTime? parseDay(dynamic raw) {
    if (raw == null) return null;
    final parsed = DateTime.tryParse(raw.toString());
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static bool overlaps(DateTime? start, DateTime? end, DateTime from, DateTime to) {
    if (start == null || end == null) return false;
    return !start.isAfter(to) && !end.isBefore(from);
  }

  static List<dynamic> filterByRange(
    List<dynamic> rows,
    DateTimeRange? range,
  ) {
    if (range == null) return rows;
    final from = DateTime(range.start.year, range.start.month, range.start.day);
    final to = DateTime(range.end.year, range.end.month, range.end.day);
    return rows.where((r) {
      return overlaps(
        parseDay(r['startDate']),
        parseDay(r['endDate']),
        from,
        to,
      );
    }).toList();
  }
}