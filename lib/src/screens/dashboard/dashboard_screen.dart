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
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WalletMelt', style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 4),
                        Text('Where did your money go this month?', style: Theme.of(context).textTheme.bodyMedium),
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
              const SizedBox(height: 18),
              LiquidGlass(
                padding: const EdgeInsets.all(24),
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
                          color: WalletMeltColors.brandSoft.withValues(alpha: 0.32),
                          boxShadow: [BoxShadow(color: WalletMeltColors.brand.withValues(alpha: 0.22), blurRadius: 48)],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(readableMonth(state.selectedMonth), style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: 12),
                        Text(formatMoney(insights.total, state.settings.currency), style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: 10),
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
              const SizedBox(height: 16),
              if (state.expenses.isEmpty) _EmptyDashboard(onAdd: () => context.push('/expense/new')) else ...[
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Category melt', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      CategoryBreakdownChart(items: insights.categorySpend),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Grocery vs utilities', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 14),
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
                const SizedBox(height: 16),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recent expenses', style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
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

class _EmptyDashboard extends StatelessWidget {
  const _EmptyDashboard({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('No expenses yet', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Start with rent, utilities, groceries, or a bill receipt. WalletMelt will build the month view from local data.', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          ElevatedButton.icon(onPressed: onAdd, icon: const Icon(Icons.add_rounded), label: const Text('Add first expense')),
        ],
      ),
    );
  }
}

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
                Expanded(flex: leftFlex, child: const ColoredBox(color: WalletMeltColors.positive)),
                Expanded(flex: rightFlex, child: const ColoredBox(color: WalletMeltColors.brand)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: Text('$leftLabel\n${formatMoney(leftValue, currency)}')),
            Expanded(child: Text('$rightLabel\n${formatMoney(rightValue, currency)}', textAlign: TextAlign.end)),
          ],
        ),
      ],
    );
  }
}
