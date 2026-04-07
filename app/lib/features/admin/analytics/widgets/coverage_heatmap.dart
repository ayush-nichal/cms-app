import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/analytics_models.dart';

class CoverageHeatmap extends StatelessWidget {
  final HeatmapData? data;
  final bool isLoading;
  final DateTime monthDate;

  const CoverageHeatmap({super.key, this.data, this.isLoading = false, required this.monthDate});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data == null || data!.dateToCount.isEmpty) {
      return const Center(child: Text('No heatmap data', style: TextStyle(color: Colors.grey)));
    }

    final daysInMonth = DateTime(monthDate.year, monthDate.month + 1, 0).day;
    final firstDayOfMonth = DateTime(monthDate.year, monthDate.month, 1);
    
    // 1 = Mon, 7 = Sun
    final int emptyLeadingCells = firstDayOfMonth.weekday - 1;
    final int totalCells = emptyLeadingCells + daysInMonth; 
    
    final List<Widget> dayHeaders = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
      return Center(child: Text(d, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
    }).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: dayHeaders,
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
            childAspectRatio: 1.0,
          ),
          itemCount: totalCells,
          itemBuilder: (context, index) {
            if (index < emptyLeadingCells) {
              return const SizedBox.shrink(); // Empty slot before the 1st
            }
            
            final dayNumber = index - emptyLeadingCells + 1;
            final cellDate = DateTime(monthDate.year, monthDate.month, dayNumber);
            final dateKey = DateFormat('yyyy-MM-dd').format(cellDate);
            
            int count = 0;
            if (data!.dateToCount.containsKey(dateKey)) {
              count = data!.dateToCount[dateKey]!;
            }

            Color bgColor = Colors.grey.shade100;
            Color textColor = Colors.grey.shade600;

            if (count == 1) {
              bgColor = Colors.green.shade300;
              textColor = Colors.white;
            } else if (count >= 2) {
              bgColor = Colors.green.shade700;
              textColor = Colors.white;
            } else {
              bgColor = Colors.grey.shade200;
            }

            final cell = Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(4),
              ),
              alignment: Alignment.center,
              child: Text(
                '$dayNumber',
                style: TextStyle(fontSize: 10, color: textColor, fontWeight: FontWeight.w600),
              ),
            );

            return Tooltip(
              message: '$count posts on ${DateFormat('MMM d').format(cellDate)}',
              child: cell,
            );
          },
        ),
      ],
    );
  }
}
