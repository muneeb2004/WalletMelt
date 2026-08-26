import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/insight_data.dart';
import '../../utils/currency_format.dart';

/// Exhaustive sealed dispatcher rendering custom visual elements for each [InsightData] subtype.
class InsightContent extends StatelessWidget {
  const InsightContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final InsightData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return switch (data) {
      WhyChangedData d => WhyChangedContent(data: d, currency: currency),
      BudgetRiskData d => BudgetRiskContent(data: d, currency: currency),
      VelocityData d => VelocityContent(data: d, currency: currency),
      CategoryChangesData d => CategoryChangesContent(data: d, currency: currency),
      FrequencyData d => FrequencyContent(data: d, currency: currency),
      MerchantInconsistencyData d => MerchantInconsistencyContent(data: d),
      EssentialSplitData d => EssentialSplitContent(data: d, currency: currency),
    };
  }
}

class WhyChangedContent extends StatelessWidget {
  const WhyChangedContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final WhyChangedData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final deltaSign = data.totalDelta > 0 ? '+' : '';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Top Driver',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                data.topContributorName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$deltaSign${formatMoney(data.totalDelta, currency)}',
                style: withTabularFigures(
                  TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: data.isIncrease ? WalletMeltColors.warning : WalletMeltColors.positive,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${data.directionalContributionPercent.toStringAsFixed(0)}% contribution',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BudgetRiskContent extends StatelessWidget {
  const BudgetRiskContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final BudgetRiskData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highest = data.highestRiskItem;
    final usagePct = highest.usagePercent.clamp(0.0, 100.0) / 100.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                '${formatMoney(highest.spent, currency)} spent',
                style: withTabularFigures(
                  TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                  ),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                'Limit: ${formatMoney(highest.budgetAmount, currency)}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: usagePct,
            minHeight: 6,
            backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
            valueColor: AlwaysStoppedAnimation<Color>(
              highest.usagePercent >= 95
                  ? WalletMeltColors.danger
                  : (highest.usagePercent >= 80 ? WalletMeltColors.warning : WalletMeltColors.brand),
            ),
          ),
        ),
        if (highest.projectedTotal != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Projected month-end: ${formatMoney(highest.projectedTotal!, currency)}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class VelocityContent extends StatelessWidget {
  const VelocityContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final VelocityData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final changeSign = data.projectedChangePercent > 0 ? '+' : '';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Projected Total',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatMoney(data.projectedTotal, currency),
              style: withTabularFigures(
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: (data.projectedChangePercent > 0 ? WalletMeltColors.warning : WalletMeltColors.positive)
                .withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            '$changeSign${data.projectedChangePercent.toStringAsFixed(0)}% vs last month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: data.projectedChangePercent > 0 ? WalletMeltColors.warning : WalletMeltColors.positive,
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryChangesContent extends StatelessWidget {
  const CategoryChangesContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final CategoryChangesData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: data.changes.take(3).map((change) {
        final isIncrease = change.absoluteChange > 0;
        final sign = isIncrease ? '+' : '';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                change.categoryName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                ),
              ),
              Text(
                '$sign${formatMoney(change.absoluteChange, currency)} (${change.percentChange?.toStringAsFixed(0) ?? '100'}%)',
                style: withTabularFigures(
                  TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isIncrease ? WalletMeltColors.warning : WalletMeltColors.positive,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class FrequencyContent extends StatelessWidget {
  const FrequencyContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final FrequencyData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Text(
              '${data.currentCount}',
              style: withTabularFigures(
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'vs ${data.previousCount} last mo',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
              ),
            ),
          ],
        ),
        Container(
          width: 1,
          height: 28,
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.1),
        ),
        Column(
          children: [
            Text(
              formatMoney(data.currentAvgValue, currency),
              style: withTabularFigures(
                TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'avg / purchase',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class MerchantInconsistencyContent extends StatelessWidget {
  const MerchantInconsistencyContent({
    required this.data,
    super.key,
  });

  final MerchantInconsistencyData data;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: data.inconsistencies.take(2).map((item) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
          ),
          child: Text(
            '${item.displayName}: ${item.categoryNames.join(', ')}',
            style: TextStyle(
              fontSize: 11,
              color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
            ),
          ),
        );
      }).toList(),
    );
  }
}

class EssentialSplitContent extends StatelessWidget {
  const EssentialSplitContent({
    required this.data,
    required this.currency,
    super.key,
  });

  final EssentialSplitData data;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final essentialPct = (data.essentialPercent / 100.0).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Essential: ${formatMoney(data.essentialTotal, currency)} (${data.essentialPercent.toStringAsFixed(0)}%)',
                  style: withTabularFigures(
                    const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: WalletMeltColors.brand,
                    ),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  'Other: ${formatMoney(data.otherTotal, currency)}',
                  style: withTabularFigures(
                    TextStyle(
                      fontSize: 12,
                      color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                    ),
                  ),
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: essentialPct,
              minHeight: 6,
              backgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(WalletMeltColors.brand),
            ),
          ),
        ],
      ),
    );
  }
}
