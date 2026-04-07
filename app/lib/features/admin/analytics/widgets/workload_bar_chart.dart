import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_models.dart';

class WorkloadBarChart extends StatelessWidget {
  final List<WorkloadChannel> data;
  final bool isLoading;

  const WorkloadBarChart({super.key, required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return const Center(
        child: Text('No workload data available', style: TextStyle(color: Colors.white70)),
      );
    }

    final double maxY = data.map((d) => d.count).reduce((a, b) => a > b ? a : b).toDouble();

    // To create a horizontal bar chart, we rotate the whole chart by 90 degrees clockwise (1 quarterTurn).
    // The data that was X becomes Y visually.
    
    return SizedBox(
      height: 140,
      child: Padding(
        padding: const EdgeInsets.only(left: 32.0, bottom: 16.0), // Extra padding for rotated axis labels
        child: RotatedBox(
        quarterTurns: 1,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: maxY + (maxY * 0.1),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${data[group.x.toInt()].name}\n',
                    const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    children: <TextSpan>[
                      TextSpan(
                        text: '${rod.toY.toInt()} posts',
                        style: const TextStyle(color: Colors.yellow),
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
                  reservedSize: 80, // Space for the channel handles
                  getTitlesWidget: (double value, TitleMeta meta) {
                    final int index = value.toInt();
                    if (index < 0 || index >= data.length || value != index.toDouble()) return const SizedBox.shrink();
                    
                    String handle = data[index].handle;
                    if (handle.length > 12) {
                      handle = '${handle.substring(0, 10)}...';
                    }

                    return RotatedBox(
                      quarterTurns: -1, // counter-rotate the text so it's readable
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Text(
                          handle,
                          style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                          textAlign: TextAlign.right,
                        ),
                      ),
                    );
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 24,
                  getTitlesWidget: (double value, TitleMeta meta) {
                    if (value == 0 || value % 1 != 0) return const SizedBox.shrink();
                    return RotatedBox(
                      quarterTurns: -1,
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: Colors.white70),
                        textAlign: TextAlign.center,
                      ),
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
              final WorkloadChannel ch = entry.value;
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: ch.count.toDouble(),
                    gradient: LinearGradient(
                      colors: [Colors.white70, Colors.white],
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                    ),
                    width: 14,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              );
            }).toList(),
          ),
          swapAnimationDuration: const Duration(milliseconds: 400),
        ),
      ),
    ));
  }
}
