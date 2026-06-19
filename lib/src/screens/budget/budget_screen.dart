import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../types/budget.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Check if the navigated month is the current calendar month
    final isCurrentMonth = state.selectedMonth.year == now.year &&
        state.selectedMonth.month == now.month;

    final monthlyBudget = state.getMonthlyBudgetAmount();
    final totalSpent = state.getCurrentMonthTotalSpent();
    final remaining = monthlyBudget != null ? monthlyBudget - totalSpent : null;
    final daysLeft = _getDaysLeftInMonth(state.selectedMonth);

    // Calculate ratio
    final ratio = monthlyBudget != null && monthlyBudget > 0
        ? totalSpent / monthlyBudget
        : 0.0;

    // Get color based on threshold ratio
    final budgetColor = _getBudgetColor(ratio);

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Budgeting',
                          style: Theme.of(context).textTheme.headlineMedium),
                      const SizedBox(height: 4),
                      Text('Keep your spending under control.',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
                // Month Navigation
                IconButton(
                  tooltip: 'Previous month',
                  onPressed: state.previousMonth,
                  icon: const Icon(Icons.chevron_left_rounded),
                ),
                Text(
                  readableMonth(state.selectedMonth),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  tooltip: 'Next month',
                  onPressed: isCurrentMonth ? null : state.nextMonth,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // SECTION 1: TOTAL MONTHLY BUDGET (HERO)
            if (monthlyBudget == null)
              _buildEmptyHeroCard(context, state)
            else
              _buildActiveHeroCard(
                context,
                state,
                monthlyBudget,
                totalSpent,
                remaining!,
                daysLeft,
                ratio,
                budgetColor,
                isDark,
              ),

            const SizedBox(height: 24),

            // SECTION 2: CATEGORY BUDGETS (SECONDARY)
            _buildCategoryBudgetsSection(context, state),
            const SizedBox(height: 84), // Bottom padding for navigation shell
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHeroCard(BuildContext context, AppState state) {
    return LiquidGlass(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 48,
            color: WalletMeltColors.brand,
          ),
          const SizedBox(height: 12),
          Text(
            'No monthly budget set',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Set a monthly limit to track your total spending.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              minimumSize: const Size(180, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
            ),
            onPressed: () => _showSetBudgetSheet(context, state, null),
            icon: const Icon(Icons.add_rounded),
            label: const Text('Set Budget'),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveHeroCard(
    BuildContext context,
    AppState state,
    double monthlyBudget,
    double totalSpent,
    double remaining,
    int daysLeft,
    double ratio,
    Color budgetColor,
    bool isDark,
  ) {
    final isOverBudget = remaining < 0;

    return LiquidGlass(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                readableMonth(state.selectedMonth),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') {
                    _showSetBudgetSheet(context, state, monthlyBudget);
                  } else if (value == 'clear') {
                    _confirmClearBudget(context, state);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Edit Budget'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'clear',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 18, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Clear Budget',
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ratio percentage text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                isOverBudget
                    ? 'Over Budget'
                    : '${(ratio * 100).toStringAsFixed(0)}% Used',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: budgetColor,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(
                '${formatMoney(totalSpent, state.settings.currency)} of ${formatMoney(monthlyBudget, state.settings.currency)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Linear Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: LinearProgressIndicator(
                value: ratio.clamp(0.0, 1.0),
                backgroundColor: isDark
                    ? const Color.fromRGBO(255, 255, 255, 0.08)
                    : const Color.fromRGBO(0, 0, 0, 0.06),
                valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
              ),
            ),
          ),
          if (isOverBudget) ...[
            const SizedBox(height: 8),
            Text(
              'You exceeded your budget this month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: WalletMeltColors.danger,
                      ) ??
                  const TextStyle(color: WalletMeltColors.danger, fontSize: 12),
            ),
          ],
          const SizedBox(height: 20),

          // Stats Chips Row
          Row(
            children: [
              Expanded(
                child: _buildStatTile(
                  'Spent',
                  formatMoney(totalSpent, state.settings.currency),
                  context,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  isOverBudget ? 'Over by' : 'Remaining',
                  isOverBudget
                      ? formatMoney(-remaining, state.settings.currency)
                      : formatMoney(remaining, state.settings.currency),
                  context,
                  valueColor: isOverBudget ? WalletMeltColors.danger : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildStatTile(
                  'Days Left',
                  '$daysLeft',
                  context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile(String label, String value, BuildContext context,
      {Color? valueColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromRGBO(255, 255, 255, 0.04)
            : const Color.fromRGBO(0, 0, 0, 0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            label,
            style:
                Theme.of(context).textTheme.labelMedium?.copyWith(fontSize: 11),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: valueColor,
                  fontSize: 14,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection(BuildContext context, AppState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Category Budgets',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 2),
                Text(
                  'Optional — track spending limits by category',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            IconButton.filledTonal(
              onPressed: () => _showCategoryBudgetSheet(context, state, null),
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (state.currentBudgets.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No category budgets for this month. Tap + to add one.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          Column(
            children: [
              for (final budget in state.currentBudgets)
                _buildCategoryBudgetRow(context, state, budget),
            ],
          ),
      ],
    );
  }

  Widget _buildCategoryBudgetRow(
      BuildContext context, AppState state, CategoryBudget budget) {
    final category = state.categoryById(budget.categoryId);
    final categoryName = category?.name ?? 'Unknown';
    final categoryColor = category != null
        ? colorFromHex(category.color)
        : WalletMeltColors.brand;

    final spent = _getCategorySpent(budget.categoryId, state);
    final remaining = budget.amount - spent;
    final isOverBudget = remaining < 0;

    final ratio = budget.amount > 0 ? spent / budget.amount : 0.0;
    final progressColor = _getBudgetColor(ratio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: LiquidGlass(
        onTap: () => _showCategoryBudgetSheet(context, state, budget),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Color indicator dot
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: categoryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    categoryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  isOverBudget
                      ? 'Over by ${formatMoney(-remaining, state.settings.currency)}'
                      : '${formatMoney(remaining, state.settings.currency)} left',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: isOverBudget ? WalletMeltColors.danger : null,
                        fontSize: 12,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Spent: ${formatMoney(spent, state.settings.currency)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Limit: ${formatMoney(budget.amount, state.settings.currency)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Linear Progress Indicator
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: LinearProgressIndicator(
                  value: ratio.clamp(0.0, 1.0),
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                          ? const Color.fromRGBO(255, 255, 255, 0.06)
                          : const Color.fromRGBO(0, 0, 0, 0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _getCategorySpent(String categoryId, AppState state) {
    var spent = 0.0;
    for (final exp in state.expenses) {
      if (exp.deletedAt == null && exp.categoryId == categoryId) {
        try {
          final date = parseIsoDate(exp.date);
          if (isSameMonth(date, state.selectedMonth)) {
            spent += exp.amount;
          }
        } catch (_) {}
      }
    }
    return spent;
  }

  Color _getBudgetColor(double ratio) {
    if (ratio < 0.70) {
      return WalletMeltColors.positive;
    } else if (ratio < 0.90) {
      return WalletMeltColors.brand;
    } else if (ratio <= 1.0) {
      return WalletMeltColors.warning;
    } else {
      return WalletMeltColors.danger;
    }
  }

  int _getDaysLeftInMonth(DateTime month) {
    final now = DateTime.now();
    if (month.year < now.year ||
        (month.year == now.year && month.month < now.month)) {
      return 0; // Past month
    }
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    if (month.year == now.year && month.month == now.month) {
      return lastDay - now.day;
    }
    return lastDay;
  }

  // Set/Edit total budget bottom sheet
  Future<void> _showSetBudgetSheet(
      BuildContext context, AppState state, double? currentAmount) async {
    final controller = TextEditingController(
      text: currentAmount != null ? currentAmount.toStringAsFixed(0) : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentAmount != null
                      ? 'Edit Monthly Budget'
                      : 'Set Monthly Budget',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Budget Amount (${state.settings.currency})',
                    hintText: 'e.g. 50000',
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18)),
                        ),
                        onPressed: () async {
                          final parsed =
                              double.tryParse(controller.text.trim());
                          if (parsed == null || parsed <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Please enter a valid amount greater than 0.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          await state.setMonthlyBudgetAmount(parsed);
                          if (context.mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  // Clear total budget confirmation
  Future<void> _confirmClearBudget(BuildContext context, AppState state) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Clear Monthly Budget?'),
          content: const Text(
              'This will clear the monthly spend ceiling. Your expenses and category budgets will remain intact.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Clear'),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      await state.clearMonthlyBudgetAmount();
    }
  }

  // Add/Edit category budget bottom sheet
  Future<void> _showCategoryBudgetSheet(BuildContext context, AppState state,
      CategoryBudget? existingBudget) async {
    final amountController = TextEditingController(
      text: existingBudget != null
          ? existingBudget.amount.toStringAsFixed(0)
          : '',
    );
    var categoryId =
        existingBudget?.categoryId ?? state.categories.firstOrNull?.id;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final isEdit = existingBudget != null;
            return SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                    20, 8, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          isEdit
                              ? 'Edit Category Budget'
                              : 'Add Category Budget',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        if (isEdit)
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red),
                            onPressed: () => _confirmDeleteCategoryBudget(
                                context, state, existingBudget),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Category selector dropdown
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: [
                        for (final cat in state.categories)
                          DropdownMenuItem(
                            value: cat.id,
                            child: Text(cat.name),
                          ),
                      ],
                      onChanged: isEdit
                          ? null // Category is read-only during edit
                          : (val) => setSheetState(() => categoryId = val),
                    ),
                    const SizedBox(height: 12),

                    // Amount textfield
                    TextField(
                      controller: amountController,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Limit Amount (${state.settings.currency})',
                        hintText: 'e.g. 5000',
                      ),
                    ),
                    const SizedBox(height: 20),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            onPressed: () async {
                              final parsed =
                                  double.tryParse(amountController.text.trim());
                              if (categoryId == null ||
                                  parsed == null ||
                                  parsed <= 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Please select a category and enter an amount > 0.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Duplicate validation (only for new budgets)
                              if (!isEdit) {
                                final duplicate = state.currentBudgets
                                    .any((b) => b.categoryId == categoryId);
                                if (duplicate) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Budget already exists for this category this month. Edit it instead.'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }
                              }

                              final month = monthKey(state.selectedMonth);
                              await state.setCategoryBudget(
                                categoryId: categoryId!,
                                amount: parsed,
                                month: month,
                              );

                              if (context.mounted) {
                                Navigator.pop(context);
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    amountController.dispose();
  }

  // Delete category budget confirmation
  Future<void> _confirmDeleteCategoryBudget(
      BuildContext context, AppState state, CategoryBudget budget) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete Category Budget?'),
          content: const Text(
              'Are you sure you want to remove the spend limit for this category? This will not affect your expenses.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirm == true && context.mounted) {
      Navigator.pop(context); // Close the bottom sheet
      await state.clearCategoryBudget(
        categoryId: budget.categoryId,
        month: budget.month,
      );
    }
  }
}
