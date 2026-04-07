import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_models.dart';

class LeadTimeLineChart extends StatelessWidget {
  final List<LeadTimeWeek> data;
  final bool isLoading;

  const LeadTimeLineChart({super.key, required this.data, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty) {
      return const Center(
        child: Text('No data for selected range', style: TextStyle(color: Colors.grey)),
      );
    }

    final double maxY = data.map((d) => d.avgDays).reduce((a, b) => a > b ? a : b).toDouble();

    final spots = data.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.avgDays);
    }).toList();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY + 2.0,
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${data[spot.x.toInt()].week}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: '${spot.y.toStringAsFixed(1)} days',
                      style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.normal),
                    ),
                  ],
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
          getDrawingVerticalLine: (value) => FlLine(color: Colors.grey.withOpacity(0.1), strokeWidth: 1),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade300, width: 1),
            left: BorderSide(color: Colors.grey.shade300, width: 1),
            top: BorderSide.none,
            right: BorderSide.none,
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final int index = value.toInt();
                if (index < 0 || index >= data.length || value != index.toDouble()) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    data[index].week,
                    style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                  textAlign: TextAlign.right,
                );
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: 1.0,
              color: Colors.red.shade400,
              strokeWidth: 2,
              dashArray: [5, 5],
              label: HorizontalLineLabel(
                show: true,
                alignment: Alignment.topRight,
                padding: const EdgeInsets.only(bottom: 4, right: 4),
                style: TextStyle(fontSize: 10, color: Colors.red.shade400, fontWeight: FontWeight.bold),
                labelResolver: (line) => 'High risk threshold',
              ),
            ),
          ],
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple.shade500,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isRed = spot.y < 1.0;
                return FlDotCirclePainter(
                  radius: 4,
                  color: isRed ? Colors.red : Colors.purple.shade500,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.shade500.withOpacity(0.1),
            ),
          ),
        ],
      ),
      duration: const Duration(milliseconds: 400),
    );
  }
}
