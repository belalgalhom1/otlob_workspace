import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../trend_bar_chart.dart';
import '../../services/data_export_service.dart';
import 'statistics_config.dart';

class StatisticsScreen extends StatefulWidget {
  final StatisticsConfig config;

  const StatisticsScreen({super.key, required this.config});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  static const _periods = ['DAILY', 'WEEKLY', 'MONTHLY'];

  String _period = 'DAILY';
  DateTimeRange? _customRange;
  late Future<List<dynamic>> _future;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode == 'ar';

  String get _effectiveFetchPeriod =>
      _customRange == null ? _period : StatisticsDateUtils.periodForRange(_customRange!);

  Future<List<dynamic>> _startFetch() {
    return widget.config.fetch(
      _effectiveFetchPeriod,
      from: _customRange?.start,
      to: _customRange?.end,
    );
  }

  @override
  void initState() {
    super.initState();
    _future = _startFetch();
  }

  String _labelFor(String period) {
    switch (period) {
      case 'WEEKLY':
        return _isArabic ? 'أسبوعي' : 'Weekly';
      case 'MONTHLY':
        return _isArabic ? 'شهري' : 'Monthly';
      default:
        return _isArabic ? 'يومي' : 'Daily';
    }
  }

  List<dynamic> _filterRows(List<dynamic> rows) {
    return StatisticsDateUtils.filterByRange(rows, _customRange);
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      helpText: _isArabic ? 'اختر الفترة الزمنية' : 'Select date range',
      saveText: _isArabic ? 'حفظ' : 'Save',
      initialDateRange:
          _customRange ?? DateTimeRange(start: DateTime(now.year), end: now),
    );
    if (picked != null) {
      setState(() => _customRange = picked);
      _reload();
    }
  }

  void _reload() {
    setState(() {
      _future = _startFetch();
    });
  }

  DateTime? _startDate(dynamic row) {
    final raw = row['startDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  DateTime? _endDate(dynamic row) {
    final raw = row['endDate'];
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final config = widget.config;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        title: Text(
          _isArabic ? config.titleAr : config.titleEn,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          IconButton(
            tooltip: 'Export',
            icon: Icon(LucideIcons.download, color: textColor),
            onPressed: () => _export(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                for (final period in _periods) ...[
                  Expanded(
                    child: _PeriodChip(
                      label: _labelFor(period),
                      selected: _customRange == null && _period == period,
                      onTap: () => setState(() {
                        _customRange = null;
                        _period = period;
                        _future = _startFetch();
                      }),
                    ),
                  ),
                  if (period != _periods.last) const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _pickRange,
                  icon: const Icon(LucideIcons.calendar, size: 16),
                  label: Text(
                    _isArabic ? 'فترة مخصصة' : 'Custom range',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
                if (_customRange != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${DateFormat('yyyy-MM-dd').format(_customRange!.start)}'
                              ' - '
                              '${DateFormat('yyyy-MM-dd').format(_customRange!.end)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => setState(() {
                              _customRange = null;
                              _future = _startFetch();
                            }),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _future,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      '${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                final rows = _filterRows(snapshot.data ?? const []);
                if (rows.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.chartNoAxesCombined,
                          size: 52,
                          color: textColor.withValues(alpha: 0.15),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isArabic
                              ? 'لا توجد بيانات في هذه الفترة'
                              : 'No data for this period',
                          style: TextStyle(
                            color: textColor.withValues(alpha: 0.4),
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final chartRows = [...rows]..sort((a, b) =>
                    DateTime.parse(a['startDate'].toString())
                        .compareTo(DateTime.parse(b['startDate'].toString())));
                final dateFormat = DateFormat('MMM d');
                final chartValues = [
                  for (final r in chartRows) config.amount(r)
                ];
                final chartLabels = [
                  for (final r in chartRows)
                    dateFormat.format(
                      DateTime.parse(r['startDate'].toString()).toLocal(),
                    )
                ];

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _SummaryCard(
                      isArabic: _isArabic,
                      items: config.summary,
                      rows: rows,
                    ),
                    const SizedBox(height: 16),
                    _TrendCard(
                      isArabic: _isArabic,
                      title:
                          _isArabic ? config.chartTitleAr : config.chartTitleEn,
                      tooltipSuffix: config.tooltipSuffix,
                      values: chartValues,
                      labels: chartLabels,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    for (final row in rows)
                      _StatRow(
                        config: config,
                        row: row,
                        isArabic: _isArabic,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final isArabic = _isArabic;
    final config = widget.config;
    final rows = _filterRows(await _future);
    if (!context.mounted) return;

    final headers = [
      isArabic ? 'الفترة' : 'Period',
      isArabic ? 'يبدأ' : 'Start',
      isArabic ? 'ينتهي' : 'End',
      for (final column in config.exportColumns)
        isArabic ? column.labelAr : column.labelEn,
    ];

    final dateFormat = DateFormat('yyyy-MM-dd');
    final data = [
      for (final row in rows)
        [
          row['period']?.toString() ?? '',
          _startDate(row) != null
              ? dateFormat.format(_startDate(row)!)
              : '',
          _endDate(row) != null ? dateFormat.format(_endDate(row)!) : '',
          for (final column in config.exportColumns) column.value(row),
        ],
    ];

    final subtitle = _customRange != null
        ? '${DateFormat('yyyy-MM-dd').format(_customRange!.start)} - '
            '${DateFormat('yyyy-MM-dd').format(_customRange!.end)}'
        : isArabic
            ? 'بيانات ${_labelFor(_period)}'
            : '${_labelFor(_period)} report';

    await DataExportService.showExportOptions(
      context,
      title: isArabic ? config.titleAr : config.titleEn,
      subtitle: subtitle,
      headers: headers,
      rows: data,
      filename:
          '${config.filenamePrefix}_${_customRange != null ? 'custom' : _period.toLowerCase()}',
    );
  }
}

class _TrendCard extends StatelessWidget {
  final bool isArabic;
  final String title;
  final String tooltipSuffix;
  final List<double> values;
  final List<String> labels;
  final Color color;

  const _TrendCard({
    required this.isArabic,
    required this.title,
    required this.tooltipSuffix,
    required this.values,
    required this.labels,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: textColor,
            ),
          ),
          const SizedBox(height: 14),
          TrendBarChart(
            values: values,
            labels: labels,
            tooltipSuffix: tooltipSuffix,
            barColor: color,
          ),
        ],
      ),
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : (isDark
                  ? Colors.white.withValues(alpha: 0.06)
                  : Colors.black.withValues(alpha: 0.04)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final bool isArabic;
  final List<StatisticSummaryItem> items;
  final List<dynamic> rows;

  const _SummaryCard({
    required this.isArabic,
    required this.items,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isArabic ? 'إجماليات الفترة' : 'Period Totals',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 12),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(item.icon, color: Colors.white70, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isArabic ? item.labelAr : item.labelEn,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13),
                    ),
                  ),
                  Text(
                    item.value(rows),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final StatisticsConfig config;
  final dynamic row;
  final bool isArabic;

  const _StatRow({
    required this.config,
    required this.row,
    required this.isArabic,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final start = config.amount(row);
    final details = config.rowDetails(row);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF252525) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fmt(_parse(row['startDate']), dateFormat)}'
                      ' - ${_fmt(_parse(row['endDate']), dateFormat)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: textColor,
                      ),
                    ),
                    if (details.length == 1) ...[
                      const SizedBox(height: 6),
                      Text(
                        details.first,
                        style: TextStyle(fontSize: 12, color: textColor),
                      ),
                    ],
                  ],
                ),
              ),
              Text(
                '${start.toStringAsFixed(2)} ${config.tooltipSuffix}',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          if (details.length > 1) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [for (final detail in details) _statChip(detail)],
            ),
          ],
        ],
      ),
    );
  }

  DateTime? _parse(dynamic raw) {
    if (raw == null) return null;
    return DateTime.tryParse(raw.toString())?.toLocal();
  }

  String _fmt(DateTime? dt, DateFormat format) {
    return dt != null ? format.format(dt) : '';
  }

  Widget _statChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}