import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/charts/category_breakdown_chart.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/section_header.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final selectedMonth = context.select((AppState s) => s.selectedMonth);
    final insights = context.select((AppState s) => s.monthlyInsights);
    final currency = context.select((AppState s) => s.settings.currency);
    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
            Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded,
                    size: 14, color: WalletMeltColors.textMuted),
                const SizedBox(width: AppSpacing.xs + 2),
                Text(readableMonth(selectedMonth),
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
            const SizedBox(height: AppSpacing.md + 2),
            if (insights.total == 0) ...[
              EmptyState(
                icon: Icons.insights_rounded,
                title: 'No data yet',
                subtitle:
                    'Add expenses to see your monthly trend, category breakdown, and spending insights.',
              ),
            ] else ...[
              WMGlassSurface.tier2(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Monthly trend',
                      icon: Icons.trending_up_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(formatMoney(insights.total, currency),
                        style: Theme.of(context).textTheme.displaySmall),
                    if (insights.monthOverMonthDelta != null) ...[
                      const SizedBox(height: AppSpacing.sm + 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: insights.monthOverMonthDelta! <= 0
                              ? WalletMeltColors.positive.withValues(alpha: 0.16)
                              : WalletMeltColors.danger.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: insights.monthOverMonthDelta! <= 0
                                ? WalletMeltColors.positive.withValues(alpha: 0.28)
                                : WalletMeltColors.danger.withValues(alpha: 0.28),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              insights.monthOverMonthDelta! <= 0
                                  ? Icons.trending_down_rounded
                                  : Icons.trending_up_rounded,
                              color: insights.monthOverMonthDelta! <= 0
                                  ? (Theme.of(context).brightness == Brightness.dark
                                      ? WalletMeltColors.positive
                                      : const Color(0xFF1E7E52))
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? WalletMeltColors.danger
                                      : const Color(0xFFC0392B)),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${insights.monthOverMonthDelta! >= 0 ? '+' : ''}${insights.monthOverMonthDelta!.toStringAsFixed(1)}% vs previous month',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: insights.monthOverMonthDelta! <= 0
                                        ? (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF1E7E52))
                                        : (Theme.of(context).brightness == Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFFC0392B)),
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Add another month of expenses to compare trends.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              WMGlassSurface.tier2(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Where it melted',
                      icon: Icons.pie_chart_outline_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    RepaintBoundary(
                      child:
                          CategoryBreakdownChart(items: insights.categorySpend),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              WMGlassSurface.tier2(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Budgets',
                      icon: Icons.account_balance_wallet_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Track your monthly spend ceiling and optional category limits.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    OutlinedButton.icon(
                      onPressed: () => context.go('/budget'),
                      icon: const Icon(Icons.account_balance_wallet_rounded),
                      label: const Text('Manage Budgets'),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
