import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/spending_summaries.dart';
import '../../utils/currency_format.dart';
import '../section_header.dart';

/// Dedicated UI section presenting Top Categories, Top Merchants, and Largest Expenses.
class SpendingSummarySection extends StatelessWidget {
  const SpendingSummarySection({
    required this.summaries,
    required this.currency,
    super.key,
    this.onCategoryTap,
    this.onMerchantTap,
    this.onTransactionTap,
  });

  final SpendingSummaries summaries;
  final String currency;
  final ValueChanged<String>? onCategoryTap;
  final ValueChanged<String>? onMerchantTap;
  final ValueChanged<String>? onTransactionTap;

  @override
  Widget build(BuildContext context) {
    final hasCategories = summaries.topCategories.isNotEmpty;
    final hasMerchants = summaries.topMerchants.isNotEmpty;
    final hasTransactions = summaries.largestExpenses.isNotEmpty;

    if (!hasCategories && !hasMerchants && !hasTransactions) {
      return const SizedBox.shrink();
    }


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.lg),
        const SectionHeader(title: 'Spending Summaries'),
        const SizedBox(height: AppSpacing.sm),

        // 1. Top Categories Summary
        if (hasCategories) ...[
          WMGlassSurface.tier2(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Top Categories',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: context.scheme.onSurface,
                      ),
                    ),
                    Text(
                      'By net spend',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                ...summaries.topCategories.map((item) {
                  return InkWell(
                    onTap: () => onCategoryTap?.call(item.categoryId),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                item.categoryName,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: context.scheme.onSurface,
                                ),
                              ),
                              Text(
                                '${formatMoney(item.netAmount, currency)} (${item.percentOfTotal.toStringAsFixed(0)}%)',
                                style: withTabularFigures(
                                  TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: context.scheme.onSurface,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: (item.percentOfTotal / 100.0).clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: (context.scheme.onSurface).withValues(alpha: 0.06),
                              valueColor: AlwaysStoppedAnimation<Color>(context.scheme.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 2. Top Merchants Summary
        if (hasMerchants) ...[
          WMGlassSurface.tier2(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Top Merchants',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...summaries.topMerchants.map((merchant) {
                  return InkWell(
                    onTap: () => onMerchantTap?.call(merchant.merchantKey),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchant.displayName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${merchant.positiveTransactionCount} purchases${merchant.refundCount > 0 ? ', ${merchant.refundCount} refunds' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatMoney(merchant.netAmount, currency),
                            style: withTabularFigures(
                              TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // 3. Largest Expenses Summary
        if (hasTransactions) ...[
          WMGlassSurface.tier2(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Largest Transactions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: context.scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                ...summaries.largestExpenses.map((expense) {
                  return InkWell(
                    onTap: () => onTransactionTap?.call(expense.id),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  expense.title,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: context.scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  '${expense.categoryName}${expense.vendor != null && expense.vendor!.isNotEmpty ? ' · ${expense.vendor}' : ''}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: context.scheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            formatMoney(expense.amount, currency),
                            style: withTabularFigures(
                              TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.scheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
