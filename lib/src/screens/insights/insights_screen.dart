import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/charts/category_breakdown_chart.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final insights = state.monthlyInsights;
    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Text('Insights', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 4),
            Text(readableMonth(state.selectedMonth),
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly trend',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Text(formatMoney(insights.total, state.settings.currency),
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    insights.monthOverMonthDelta == null
                        ? 'Add another month of expenses to compare trends.'
                        : '${insights.monthOverMonthDelta! >= 0 ? '+' : ''}${insights.monthOverMonthDelta!.toStringAsFixed(1)}% vs previous month',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            LiquidGlass(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Where it melted',
                      style: Theme.of(context).textTheme.titleLarge),
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
                  Text('Budgets',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Track your monthly spend ceiling and optional category limits.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/budget'),
                    icon: const Icon(Icons.account_balance_wallet_rounded),
                    label: const Text('Manage Budgets'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
