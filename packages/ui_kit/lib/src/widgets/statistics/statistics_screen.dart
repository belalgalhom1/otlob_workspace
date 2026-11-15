import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../dialogs/app_dialog.dart';
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
      builder: AppDialogStyles.adaptivePickerTheme,
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
    final textColor = theme.colorScheme.onSurface;
    final accentTextColor = isDark ? AppColors.primary : const Color(0xFF92400E);
    final config = widget.config;
    final backgroundColor =
        config.backgroundColor ?? theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _isArabic ? config.titleAr : config.titleEn,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontWeight: FontWeight.bold, color: textColor),
        ),
        actions: [
          IconButton(
            tooltip: _isArabic ? 'تصدير' : 'Export',
            icon: Icon(LucideIcons.download, color: textColor),
            onPressed: () => _export(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
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
            child: SizedBox(
              width: double.infinity,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
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
                  if (_customRange != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(
                          alpha: isDark ? 0.14 : 0.16,
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                '${DateFormat('yyyy-MM-dd').format(_customRange!.start)}'
                                ' - '
                                '${DateFormat('yyyy-MM-dd').format(_customRange!.end)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: accentTextColor,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => setState(() {
                                _customRange = null;
                                _future = _startFetch();
                              }),
                              child: Padding(
                                padding: const EdgeInsets.all(2),
                                child: Icon(
                                  Icons.close,
                                  size: 16,
                                  color: accentTextColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
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
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.alertTriangle,
                            color: AppColors.error,
                            size: 44,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.error),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(LucideIcons.refreshCw, size: 16),
                            label: Text(_isArabic ? 'إعادة المحاولة' : 'Retry'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                final rows = _filterRows(snapshot.data ?? const []);
                if (rows.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.chartNoAxesCombined,
                            size: 52,
                            color: textColor.withValues(alpha: 0.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isArabic
                                ? 'لا توجد بيانات في هذه الفترة'
                                : 'No data for this period',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: textColor.withValues(alpha: 0.55),
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final fallbackEpoch = DateTime.fromMillisecondsSinceEpoch(0);
                final chartRows = [...rows]..sort((a, b) =>
                    (_startDate(a) ?? fallbackEpoch)
                        .compareTo(_startDate(b) ?? fallbackEpoch));
                final dateFormat = DateFormat('MMM d');
                final chartValues = [
                  for (final r in chartRows) config.amount(r)
                ];
                final chartLabels = [
                  for (final r in chartRows)
                    _startDate(r) != null
                        ? dateFormat.format(_startDate(r)!)
                        : ''
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
      ),
    );
  }

  Future<void> _export(BuildContext context) async {
    final isArabic = _isArabic;
    final config = widget.config;
    final List<dynamic> rawRows;
    try {
      rawRows = await _future;
    } catch (_) {
      return;
    }
    final rows = _filterRows(rawRows);
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

    List<ExportSection>? sections;
    if (config.exportSections != null && config.exportSections!.isNotEmpty) {
      sections = config.exportSections!.map((sec) {
        final secTitle = isArabic ? sec.titleAr : sec.titleEn;
        final secHeaders = [
          isArabic ? 'الفترة' : 'Period',
          isArabic ? 'يبدأ' : 'Start',
          isArabic ? 'ينتهي' : 'End',
          for (final col in sec.columns) isArabic ? col.labelAr : col.labelEn,
        ];
        final secData = [
          for (final row in rows)
            [
              row['period']?.toString() ?? '',
              _startDate(row) != null ? dateFormat.format(_startDate(row)!) : '',
              _endDate(row) != null ? dateFormat.format(_endDate(row)!) : '',
              for (final col in sec.columns) col.value(row),
            ],
        ];
        return ExportSection(
          title: secTitle,
          headers: secHeaders,
          rows: secData,
        );
      }).toList();
    }

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
      entityName: config.entityName,
      sections: sections,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary
                : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? AppColors.primary
                  : (isDark ? AppColors.borderDark : AppColors.borderLight),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected
                    ? AppColors.onPrimary
                    : theme.colorScheme.onSurface,
              ),
            ),
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
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    isArabic ? 'إجماليات الفترة' : 'Period Totals',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    isArabic ? 'ملخص إحصائي' : 'Executive Summary',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 10.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final item in items)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(item.icon, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isArabic ? item.labelAr : item.labelEn,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFCBD5E1),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: constraints.maxWidth * 0.52,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: AlignmentDirectional.centerEnd,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            item.value(rows),
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
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
    final textColor = theme.colorScheme.onSurface;
    final dateFormat = DateFormat('MMM dd, yyyy');

    final start = config.amount(row);
    final details = config.rowDetails(row);
    final amountColor = start < 0
        ? (isDark ? AppColors.error : const Color(0xFFB91C1C))
        : (isDark ? AppColors.success : const Color(0xFF047857));
    final amountText =
        '${NumberFormat('#,##0.00', 'en_US').format(start)}'
        '${config.tooltipSuffix.isEmpty ? '' : ' ${config.tooltipSuffix}'}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_fmt(_parse(row['startDate']), dateFormat)}'
                        ' - ${_fmt(_parse(row['endDate']), dateFormat)}',
                        maxLines: 2,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: textColor.withValues(alpha: 0.72),
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: constraints.maxWidth * 0.45,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerEnd,
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        amountText,
                        maxLines: 1,
                        style: TextStyle(
                          color: amountColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (details.length > 1) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final detail in details) _statChip(context, detail),
                ],
              ),
            ],
          ],
        ),
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

  Widget _statChip(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final chipTextColor = isDark ? AppColors.primary : const Color(0xFF92400E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: isDark ? 0.14 : 0.16),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: isDark ? 0.28 : 0.35),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: chipTextColor,
          fontWeight: FontWeight.w600,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}