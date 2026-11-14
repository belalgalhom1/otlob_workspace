import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;

class TrendBarChart extends StatelessWidget {
  final List<double> values;
  final List<String> labels;
  final String tooltipSuffix;
  final Color barColor;
  final double height;

  const TrendBarChart({
    super.key,
    required this.values,
    required this.labels,
    this.tooltipSuffix = '',
    required this.barColor,
    this.height = 210,
  });

  double _niceInterval(double maxValue) {
    if (maxValue <= 1) return 1;
    final exponent = (math.log(maxValue) / math.ln10).floor();
    final base = math.pow(10, exponent).toDouble();
    final ratio = maxValue / base;
    if (ratio < 2) return (base / 5).clamp(0.01, double.infinity).toDouble();
    if (ratio < 5) return (base / 2).clamp(0.01, double.infinity).toDouble();
    return base;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor =
        isDark ? Colors.white.withValues(alpha: 0.65) : Colors.black54;
    final gridColor =
        isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black12;

    if (values.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            '--',
            style: TextStyle(
              color: labelColor,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    final minRaw = values.reduce(math.min);
    final maxRaw = values.reduce(math.max);
    final minY = minRaw < 0 ? minRaw * 1.15 : 0.0;
    final maxY = (maxRaw == 0 && minRaw == 0)
        ? 1.0
        : (maxRaw <= 0 ? 0.0 : maxRaw * 1.15);
    final span = math.max(maxRaw.abs(), minRaw.abs());
    final labelStep =
        ((labels.length / 7).ceil()).clamp(1, labels.length).toInt();
    final barWidth = values.length > 20 ? 6.0 : (values.length > 10 ? 10.0 : 16.0);
    final compactFmt = NumberFormat.compact();
    final tooltipFmt = NumberFormat('#,##0.##', 'en_US');

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: minY,
          maxY: maxY,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(span),
            getDrawingHorizontalLine: (value) =>
                FlLine(color: gridColor, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min && minRaw >= 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 46),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            compactFmt.format(value),
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 10,
                              color: labelColor,
                              fontFeatures: const [
                                FontFeature.tabularFigures(),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: labelStep.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.round();
                  if ((value - index).abs() > 0.01 ||
                      index < 0 ||
                      index >= labels.length ||
                      index % labelStep != 0) {
                    return const SizedBox.shrink();
                  }
                  return SideTitleWidget(
                    meta: meta,
                    fitInside: SideTitleFitInsideData.fromTitleMeta(meta),
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9.5, color: labelColor),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF1E293B) : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = groupIndex >= 0 && groupIndex < labels.length
                    ? labels[groupIndex]
                    : '';
                return BarTooltipItem(
                  '$label\n${tooltipFmt.format(rod.toY)}'
                  '${tooltipSuffix.isEmpty ? '' : ' $tooltipSuffix'}',
                  TextStyle(
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                );
              },
            ),
          ),
          barGroups: [
            for (var i = 0; i < values.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: values[i],
                    width: barWidth,
                    color: barColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}