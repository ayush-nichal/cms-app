import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../data/analytics_models.dart';
import '../../../../core/utils/content_type_translator.dart';

class ContentMixDoughnut extends StatelessWidget {
  final List<ContentMixItem> data;
  final bool isLoading;
  final String platformName;
  final Color textColor;

  const ContentMixDoughnut({super.key, required this.data, this.isLoading = false, this.platformName = 'default', this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (data.isEmpty || data.every((d) => d.count == 0)) {
      return Center(
        child: Text('No content data', style: TextStyle(color: textColor.withOpacity(0.7))),
      );
    }

    final totalCount = data.map((e) => e.count).reduce((a, b) => a + b);

    return Column(
      children: [
        SizedBox(
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 35,
                  sections: data.map((item) {
                    final color = ContentTypeTranslator.getColor(item.contentType);
                    final showTitleInside = item.percent > 5;
                    return PieChartSectionData(
                      color: color,
                      value: item.percent,
                      title: showTitleInside ? '${item.percent.toInt()}%' : '',
                      radius: 30,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    );
                  }).toList(),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    totalCount.toString(),
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textColor),
                  ),
                  Text('posts', style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.7))),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: data.map((item) {
            final color = ContentTypeTranslator.getColor(item.contentType);
            final label = ContentTypeTranslator.translate(item.contentType, platformName);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 10, color: textColor)),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
