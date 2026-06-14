import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';

import '../../components/charts/category_breakdown_chart.dart';
import '../../components/glass/app_background.dart';
import '../../providers/budget_providers.dart';
import '../../providers/category_providers.dart';
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
                  const SizedBox(height: 12),
                  _BudgetRowsCategoryGate(
                    fallbackHasCategories: state.categories.isNotEmpty,
                    rows: [
                      for (final spend in insights.categorySpend)
                        _BudgetRow(
                          categoryId: spend.category.id,
                          label: spend.category.name,
                          color: colorFromHex(spend.category.color),
                          spent: spend.total,
                          fallbackBudget: spend.budget?.amount,
                          month: state.currentMonthKey,
                          currency: state.settings.currency,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _showBudgetSheet(context),
                    icon: const Icon(Icons.savings_rounded),
                    label: const Text('Set category budget'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBudgetSheet(BuildContext context) async {
    final amountController = TextEditingController();
    final state = context.read<AppState>();
    var categoryId = state.categories.firstOrNull?.id;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Monthly budget',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: categoryId,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final category in state.categories)
                        DropdownMenuItem(
                            value: category.id, child: Text(category.name)),
                    ],
                    onChanged: (value) =>
                        setSheetState(() => categoryId = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(),
                      decoration: InputDecoration(
                          labelText:
                              'Budget amount (${state.settings.currency})')),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    onPressed: () async {
                      final amount =
                          double.tryParse(amountController.text.trim());
                      if (categoryId == null || amount == null || amount <= 0) {
                        return;
                      }
                      await state.setBudget(categoryId!, amount);
                      if (context.mounted) {
                        Navigator.pop(context);
                      }
                    },
                    child: const Text('Save budget'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    amountController.dispose();
  }
}

class _BudgetRowsCategoryGate extends ConsumerWidget {
  const _BudgetRowsCategoryGate({
    required this.fallbackHasCategories,
    required this.rows,
  });

  final bool fallbackHasCategories;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final hasCategories = categories.when(
      data: (categories) => categories.isNotEmpty,
      loading: () => fallbackHasCategories,
      error: (_, __) => fallbackHasCategories,
    );

    if (!hasCategories) {
      return Text('No categories available.',
          style: Theme.of(context).textTheme.bodyMedium);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
  }
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({
    required this.categoryId,
    required this.label,
    required this.color,
    required this.spent,
    required this.fallbackBudget,
    required this.month,
    required this.currency,
  });

  final String categoryId;
  final String label;
  final Color color;
  final double spent;
  final double? fallbackBudget;
  final String month;
  final String currency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetValue = ref.watch(budgetByCategoryProvider(
        BudgetLookup(month: month, categoryId: categoryId)));
    final budget = budgetValue.when(
      data: (budget) => budget?.amount,
      loading: () => fallbackBudget,
      error: (_, __) => fallbackBudget,
    );
    final progress =
        budget == null || budget == 0 ? 0.0 : (spent / budget).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(label,
                      style: Theme.of(context).textTheme.titleMedium)),
              Text(budget == null
                  ? formatMoney(spent, currency)
                  : '${formatMoney(spent, currency)} / ${formatMoney(budget, currency)}'),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: budget == null ? null : progress,
              minHeight: 10,
              backgroundColor: color.withValues(alpha: 0.14),
              valueColor: AlwaysStoppedAnimation<Color>(
                  progress >= 1 ? WalletMeltColors.warning : color),
            ),
          ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
