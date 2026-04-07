import 'package:flutter/material.dart';
import '../data/analytics_models.dart';

class TrendIndicator extends StatelessWidget {
  final TrendData? data;

  const TrendIndicator({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const SizedBox.shrink();
    }

    IconData icon;
    Color color;
    String label;

    switch (data!.trend) {
      case 'up':
        icon = Icons.trending_up;
        color = Colors.green;
        label = 'Trending up';
        break;
      case 'down':
        icon = Icons.trending_down;
        color = Colors.red;
        label = 'Trending down';
        break;
      case 'flat':
      default:
        icon = Icons.trending_flat;
        color = Colors.grey;
        label = 'No change';
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          'current: ${data!.current} vs previous: ${data!.previous}',
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
