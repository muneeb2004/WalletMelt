import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../utils/insights.dart';

class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({required this.items, super.key});

  final List<CategorySpend> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (items.isEmpty) {
      return Text('Add expenses to see where the month melted.',
          style: theme.textTheme.bodyMedium);
    }
    return SizedBox(
      height: 210,
      child: Row(
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: PieChart(
              PieChartData(
                sectionsSpace: 3,
                centerSpaceRadius: 44,
                startDegreeOffset: -90,
                sections: items.take(6).map((item) {
                  final color = colorFromHex(item.category.color);
                  return PieChartSectionData(
                    value: item.total,
                    color: color,
                    radius: 22 + (item.percentOfTotal * 22),
                    title: '',
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items.take(5))
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                                color: colorFromHex(item.category.color),
                                shape: BoxShape.circle)),
                        const SizedBox(width: 8),
                        Expanded(
                            child: Text(item.category.name,
                                maxLines: 1, overflow: TextOverflow.ellipsis)),
                        Text('${(item.percentOfTotal * 100).round()}%',
                            style: theme.textTheme.labelMedium),
                      ],
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
