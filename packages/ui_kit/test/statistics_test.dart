import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  group('DataExportService.buildCsvContent', () {
    test('writes headers and rows with BOM', () {
      final csv = DataExportService.buildCsvContent(
        ['A', 'B'],
        [
          ['1', '2'],
          ['3', '4'],
        ],
      );
      expect(csv.startsWith('\uFEFF'), isTrue);
      expect(csv, contains('A,B\n'));
      expect(csv, contains('1,2\n'));
      expect(csv, contains('3,4\n'));
    });

    test('escapes commas, quotes and newlines', () {
      final csv = DataExportService.buildCsvContent(
        ['Name', 'Note'],
        [
          ['Smith, John', 'has "quote"'],
          ['Line\nBreak', 'plain'],
        ],
      );
      expect(csv, contains('"Smith, John"'));
      expect(csv, contains('"has ""quote"""'));
      expect(csv, contains('"Line\nBreak"'));
    });

    test('pads short rows to header length', () {
      final csv = DataExportService.buildCsvContent(
        ['A', 'B', 'C'],
        [
          ['1'],
          ['1', '2', '3', '4'],
        ],
      );
      expect(csv, contains('1,,\n'));
      expect(csv, contains('1,2,3\n'));
    });
  });

  group('StatisticsDateUtils', () {
    test('periodForRange maps width to DAILY/WEEKLY/MONTHLY', () {
      expect(
        StatisticsDateUtils.periodForRange(
          DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 1, 31)),
        ),
        'DAILY',
      );
      expect(
        StatisticsDateUtils.periodForRange(
          DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 3, 1)),
        ),
        'WEEKLY',
      );
      expect(
        StatisticsDateUtils.periodForRange(
          DateTimeRange(start: DateTime(2026, 1, 1), end: DateTime(2026, 12, 31)),
        ),
        'MONTHLY',
      );
    });

    test('filterByRange keeps overlapping rows only', () {
      final rows = [
        {'startDate': '2026-01-01', 'endDate': '2026-01-15'},
        {'startDate': '2026-02-01', 'endDate': '2026-02-15'},
        {'startDate': '2026-01-10', 'endDate': '2026-02-10'},
      ];
      final range = DateTimeRange(
        start: DateTime(2026, 1, 20),
        end: DateTime(2026, 2, 20),
      );
      final filtered = StatisticsDateUtils.filterByRange(rows, range);
      expect(filtered.length, 2);
      expect(filtered.first['startDate'], '2026-02-01');
      expect(filtered[1]['startDate'], '2026-01-10');
    });

    test('filterByRange returns all rows when range is null', () {
      final rows = [
        {'startDate': '2026-01-01', 'endDate': '2026-01-15'},
      ];
      expect(StatisticsDateUtils.filterByRange(rows, null), rows);
    });
  });
}