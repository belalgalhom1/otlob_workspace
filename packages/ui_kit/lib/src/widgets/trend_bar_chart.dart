import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
        isDark ? Colors.white.withValues(alpha: 0.6) : Colors.black54;
    final gridColor =
        isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black12;

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

    final maxValue = values.reduce((a, b) => math.max(a, b));
    final labelStep =
        ((labels.length / 8).ceil()).clamp(1, labels.length).toInt();
    final barWidth = values.length > 20 ? 6.0 : (values.length > 10 ? 10.0 : 16.0);

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          minY: 0,
          maxY: maxValue == 0 ? 1 : maxValue * 1.15,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _niceInterval(maxValue),
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
                reservedSize: 42,
                getTitlesWidget: (value, meta) {
                  if (value == meta.min) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      NumberFormat.compact().format(value),
                      style: TextStyle(fontSize: 10, color: labelColor),
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: labelStep.toDouble(),
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= labels.length) {
                    return const SizedBox.shrink();
                  }
                  if (index % labelStep != 0) return const SizedBox.shrink();
                  return SideTitleWidget(
                    meta: meta,
                    child: Text(
                      labels[index],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 9, color: labelColor),
                    ),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) =>
                  isDark ? const Color(0xFF383838) : Colors.white,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final label = groupIndex >= 0 && groupIndex < labels.length
                    ? labels[groupIndex]
                    : '';
                return BarTooltipItem(
                  '$label\n${NumberFormat('#,##0').format(rod.toY)}'
                  '${tooltipSuffix.isEmpty ? '' : ' $tooltipSuffix'}',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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