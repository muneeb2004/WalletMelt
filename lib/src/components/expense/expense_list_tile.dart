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
    final color = category == null
        ? WalletMeltColors.textMuted
        : colorFromHex(category!.color);
    return Material(
      type: MaterialType.transparency,
      child: ListTile(
        onTap: onTap,
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(16)),
          child: Icon(_iconFor(category?.icon), color: color),
        ),
        title:
            Text(expense.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${category?.name ?? 'Unknown'} • ${readableDate(parseIsoDate(expense.date))}'),
        trailing: Text(
          formatMoney(expense.amount, expense.currency),
          style: Theme.of(context).textTheme.titleMedium,
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
