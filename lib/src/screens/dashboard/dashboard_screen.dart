import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/charts/category_breakdown_chart.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final insights = state.monthlyInsights;
    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: state.refresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WalletMelt',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Where did your money go this month?',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: state.previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: state.nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),

              // ── Hero spend card ─────────────────────────────────────────
              LiquidGlass(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WalletMeltColors.brandSoft
                              .withValues(alpha: 0.32),
                          boxShadow: [
                            BoxShadow(
                                color: WalletMeltColors.brand
                                    .withValues(alpha: 0.22),
                                blurRadius: 48)
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(readableMonth(state.selectedMonth),
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                            formatMoney(
                                insights.total, state.settings.currency),
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          insights.highestCategory == null
                              ? 'Add your first expense to reveal where the month melted.'
                              : 'Highest melt: ${insights.highestCategory!.category.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Budget summary card ─────────────────────────────────────
              if (state.getMonthlyBudgetAmount() != null) ...[
                _DashboardBudgetCard(state: state),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Content: empty or charts + recent ──────────────────────
              if (state.expenses.isEmpty)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses yet',
                  subtitle: 'Tap + to add your first expense.',
                )
              else ...[
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Category melt',
                        icon: Icons.donut_small_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RepaintBoundary(
                        child: CategoryBreakdownChart(
                            items: insights.categorySpend),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Grocery vs utilities',
                        icon: Icons.compare_arrows_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ComparisonBar(
                        leftLabel: 'Grocery',
                        leftValue: insights.groceryTotal,
                        rightLabel: 'Utilities',
                        rightValue: insights.utilitiesTotal,
                        currency: state.settings.currency,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Recent expenses',
                        icon: Icons.history_rounded,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final expense in insights.recentExpenses)
                        ExpenseListTile(
                          expense: expense,
                          category: state.categoryById(expense.categoryId),
                          onTap: () => context.push('/expense/${expense.id}'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.currency,
  });

  final String leftLabel;
  final double leftValue;
  final String rightLabel;
  final double rightValue;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final total = leftValue + rightValue;
    final leftPercent = total == 0 ? 0.5 : leftValue / total;
    final leftFlex = (leftPercent * 100).round().clamp(1, 99).toInt();
    final rightFlex = (100 - leftFlex).clamp(1, 99).toInt();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 16,
            child: Row(
              children: [
                Expanded(
                    flex: leftFlex,
                    child: const ColoredBox(color: WalletMeltColors.positive)),
                Expanded(
                    flex: rightFlex,
                    child: const ColoredBox(color: WalletMeltColors.brand)),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
                child: Text('$leftLabel\n${formatMoney(leftValue, currency)}')),
            Expanded(
                child: Text('$rightLabel\n${formatMoney(rightValue, currency)}',
                    textAlign: TextAlign.end)),
          ],
        ),
      ],
    );
  }
}

class _DashboardBudgetCard extends StatelessWidget {
  const _DashboardBudgetCard({required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = state.getMonthlyBudgetAmount() ?? 0.0;
    final totalSpent = state.getCurrentMonthTotalSpent();
    final remaining = monthlyBudget - totalSpent;
    final isOverBudget = remaining < 0;
    final ratio = monthlyBudget > 0 ? totalSpent / monthlyBudget : 0.0;
    final Color budgetColor = budgetProgressColor(ratio);

    return LiquidGlass(
      onTap: () => context.push('/budget'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Month's Budget",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              InkWell(
                onTap: () => context.push('/budget'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
                  child: Text(
                    'Details →',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(fraction: ratio, color: budgetColor),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${formatMoney(totalSpent, state.settings.currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                isOverBudget
                    ? 'Over by ${formatMoney(-remaining, state.settings.currency)}'
                    : 'Remaining: ${formatMoney(remaining, state.settings.currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? WalletMeltColors.danger : null,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
