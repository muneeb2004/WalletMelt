import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

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
    this.onEdit,
    this.onCategorize,
    this.onDelete,
    this.onRestore,
    super.key,
  });

  final Expense expense;
  final Category? category;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onCategorize;
  final VoidCallback? onDelete;
  final VoidCallback? onRestore;

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

    final isDeleted = expense.deletedAt != null;

    final tileContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          onTap: () {
            WMHaptics.light();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Category Icon Container with subtle glow
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isDark
                        ? color.withValues(alpha: 0.16)
                        : color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    border: Border.all(
                      color: isDark
                          ? color.withValues(alpha: 0.25)
                          : color.withValues(alpha: 0.20),
                      width: 1.0,
                    ),
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
                          fontFamily: 'PlusJakartaSans',
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
                          fontFamily: 'PlusJakartaSans',
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
                // Amount with tabular figures and negative indicator
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '-${formatMoney(expense.amount, expense.currency)}',
                          style: TextStyle(
                            fontFamily: 'PlusJakartaSans',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            fontFeatures: const [FontFeature.tabularFigures()],
                            color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    if (expense.taxAmount != null && expense.taxAmount! > 0) ...[
                      const SizedBox(height: 2),
                      Text(
                        '+${expense.taxAmount!.toStringAsFixed(expense.taxAmount! % 1 == 0 ? 0 : 2)} tax',
                        style: const TextStyle(
                          fontFamily: 'PlusJakartaSans',
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          fontFeatures: [FontFeature.tabularFigures()],
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

    // If swipe callbacks are provided, wrap in Slidable with split actions (Directive 7)
    final hasLeadingActions = onCategorize != null || onEdit != null;
    final hasTrailingActions = onDelete != null || onRestore != null;

    if (!hasLeadingActions && !hasTrailingActions) {
      return tileContent;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Slidable(
        key: ValueKey(expense.id),
        startActionPane: hasLeadingActions
            ? ActionPane(
                motion: const BehindMotion(),
                children: [
                  if (onCategorize != null)
                    SlidableAction(
                      onPressed: (_) {
                        WMHaptics.light();
                        onCategorize!();
                      },
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      icon: Icons.category_rounded,
                      label: 'Category',
                    ),
                  if (onEdit != null)
                    SlidableAction(
                      onPressed: (_) {
                        WMHaptics.light();
                        onEdit!();
                      },
                      backgroundColor: WalletMeltColors.brand,
                      foregroundColor: Colors.white,
                      icon: Icons.edit_rounded,
                      label: 'Edit',
                    ),
                ],
              )
            : null,
        endActionPane: hasTrailingActions
            ? ActionPane(
                motion: const BehindMotion(),
                children: [
                  if (isDeleted && onRestore != null)
                    SlidableAction(
                      onPressed: (_) {
                        WMHaptics.medium();
                        onRestore!();
                      },
                      backgroundColor: WalletMeltColors.positive,
                      foregroundColor: Colors.white,
                      icon: Icons.restore_from_trash_rounded,
                      label: 'Restore',
                    )
                  else if (onDelete != null)
                    SlidableAction(
                      onPressed: (_) {
                        WMHaptics.heavy();
                        onDelete!();
                      },
                      backgroundColor: WalletMeltColors.danger,
                      foregroundColor: Colors.white,
                      icon: Icons.delete_outline_rounded,
                      label: 'Delete',
                    ),
                ],
              )
            : null,
        child: tileContent,
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
