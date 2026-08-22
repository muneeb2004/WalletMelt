import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/category.dart';
import '../../types/expense.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';

class ExpenseListTile extends StatelessWidget {
  const ExpenseListTile({
    required this.expense,
    required this.category,
    required this.onTap,
    super.key,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final color = category == null
        ? WalletMeltColors.textMuted
        : colorFromHex(category!.color);

    final displayTitle = expense.title.isNotEmpty ? expense.title : (category?.name ?? 'Expense');
    final categoryName = category?.name ?? 'Uncategorized';
    final dateStr = readableDate(parseIsoDate(expense.date));
    final hasVendor = expense.vendor != null && expense.vendor!.trim().isNotEmpty;
    final subtitleText = hasVendor
        ? '${expense.vendor!.trim()} • $categoryName'
        : '$categoryName • $dateStr';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            WMHaptics.light();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Category Icon Container
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withValues(alpha: 0.14)
                        : color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    _iconFor(category?.icon),
                    color: color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 14),
                // Title and Subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitleText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Amount
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '-${formatMoney(expense.amount, expense.currency)}',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                      ),
                    ),
                    if (expense.taxAmount != null && expense.taxAmount! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+${expense.taxAmount!.toStringAsFixed(expense.taxAmount! % 1 == 0 ? 0 : 2)} tax',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: WalletMeltColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String readableDate(DateTime date) {
  final now = DateTime.now();
  if (date.year == now.year && date.month == now.month && date.day == now.day) {
    return 'Today';
  }
  return '${date.day}/${date.month}/${date.year}';
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
