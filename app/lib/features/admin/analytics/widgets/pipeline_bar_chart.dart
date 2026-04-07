import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_models.dart';

class PipelineBarChart extends StatelessWidget {
  final List<PipelineWeek> data;
  final bool isLoading;

  const PipelineBarChart({super.key, required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return const Center(
        child: Text('No scheduled content in this period', style: TextStyle(color: Colors.white70)),
      );
    }

    final double maxY = data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();

    return SizedBox(height: 140, child: BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxY + (maxY * 0.2), // Add 20% headroom
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // Use tooltipBgColor instead of getTooltipColor due to version compat (depends on 0.68 api)
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${data[group.x.toInt()].label}\n',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                children: <TextSpan>[
                  TextSpan(
                    text: '${(rod.toY - 1).toInt()}', // -1 if we render from 1 so min height is visible, but normally rod.toY
                    style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.w500),
                  ),
                ],
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (double value, TitleMeta meta) {
                final int index = value.toInt();
                if (index < 0 || index >= data.length || value != value.toInt()) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].week,
                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (double value, TitleMeta meta) {
                if (value == 0 || value % 1 != 0) return const SizedBox.shrink();
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.white.withOpacity(0.3), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: data.asMap().entries.map((entry) {
          final int index = entry.key;
          final PipelineWeek weekData = entry.value;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: weekData.count.toDouble(),
                color: Colors.white,
                width: 16,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
      ),
      swapAnimationDuration: const Duration(milliseconds: 400),
    ));
  }
}
