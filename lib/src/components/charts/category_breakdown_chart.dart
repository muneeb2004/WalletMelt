import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart';
import '../../utils/insights.dart';
import '../../utils/currency_format.dart';

class CategoryBreakdownChart extends StatelessWidget {
  const CategoryBreakdownChart({required this.items, super.key});

  final List<CategorySpend> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppState>();
    final currency = state.settings.currency;

    if (items.isEmpty) {
      return Text(
        'Add expenses to see where the month melted.',
        style: theme.textTheme.bodyMedium,
      );
    }

    final totalSpent = items.fold<double>(0.0, (sum, item) => sum + item.total);

    // Process categories: collapse those < 2% into "Other"
    final List<CategorySpend> displayItems = [];
    double collapsedTotal = 0.0;

    for (final item in items) {
      if (item.percentOfTotal >= 0.02) {
        displayItems.add(item);
      } else {
        collapsedTotal += item.total;
      }
    }

    if (collapsedTotal > 0.0) {
      final collapsedPercent = totalSpent > 0 ? collapsedTotal / totalSpent : 0.0;
      final otherCategory = Category(
        id: 'other_collapsed',
        name: 'Other',
        icon: 'more_horiz',
        color: '#9A958B',
        isDefault: true,
        createdAt: '',
        updatedAt: '',
      );
      displayItems.add(CategorySpend(
        category: otherCategory,
        total: collapsedTotal,
        percentOfTotal: collapsedPercent,
      ));
    }

    // Sort descending by total spend
    displayItems.sort((a, b) => b.total.compareTo(a.total));

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in displayItems) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  onTap: () {
                    WMHaptics.light();
                    if (item.category.id == 'other_collapsed') {
                      // Navigate to all transactions
                      context.go('/history');
                    } else {
                      // Navigate to category transactions
                      context.go('/history?categoryId=${item.category.id}');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
                    child: Row(
                      children: [
                        // Category Icon container with color background
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: colorFromHex(item.category.color).withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colorFromHex(item.category.color).withValues(alpha: 0.28),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              _iconFor(item.category.icon),
                              color: colorFromHex(item.category.color),
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item.category.name,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'PlusJakartaSans',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    formatMoney(item.total, currency),
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontFamily: 'PlusJakartaSans',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: TweenAnimationBuilder<double>(
                                        tween: Tween<double>(begin: 0.0, end: item.percentOfTotal),
                                        duration: const Duration(milliseconds: 700),
                                        curve: Curves.easeOutCubic,
                                        builder: (context, value, child) {
                                          return LinearProgressIndicator(
                                            value: value,
                                            backgroundColor: isDark ? Colors.white12 : Colors.black12,
                                            valueColor: AlwaysStoppedAnimation<Color>(
                                              colorFromHex(item.category.color),
                                            ),
                                            minHeight: 8,
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '${(item.percentOfTotal * 100).toStringAsFixed(0)}%',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontFamily: 'PlusJakartaSans',
                                      color: WalletMeltColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _iconFor(String? name) {
    return switch (name) {
      'bolt' => Icons.bolt_rounded,
      'local_fire_department' => Icons.local_fire_department_rounded,
      'shopping_basket' => Icons.shopping_basket_rounded,
      'wifi' => Icons.wifi_rounded,
      'water_drop' => Icons.water_drop_rounded,
      'home' => Icons.home_rounded,
      'build' => Icons.build_rounded,
      'local_gas_station' => Icons.local_gas_station_rounded,
      _ => Icons.more_horiz_rounded,
    };
  }
}
