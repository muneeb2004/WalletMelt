import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../types/budget.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/sheet_handle.dart';
import '../../widgets/stat_tile.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  static Future<void> showSetBudgetSheet(
      BuildContext context, AppState state, double? currentAmount) async {
    final controller = TextEditingController(
      text: currentAmount != null ? currentAmount.toStringAsFixed(0) : '',
    );

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.sm,
                    AppSpacing.lg,
                    AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SheetHandle(),
                    Text(
                      currentAmount != null
                          ? 'Edit Monthly Budget'
                          : 'Set Monthly Budget',
                      style: Theme.of(sheetContext).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.md + 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius)),
                            ),
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius)),
                            ),
                            onPressed: () async {
                              final parsed =
                                  double.tryParse(controller.text.trim());
                              if (parsed == null || parsed <= 0) {
                                showErrorSnackbar(sheetContext,
                                    'Please enter a valid amount greater than 0.');
                                return;
                              }
                              await state.setMonthlyBudgetAmount(parsed);
                              if (sheetContext.mounted) Navigator.pop(sheetContext);
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    controller.dispose();
  }

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.read<AppState>();
    final selectedMonth = context.select((AppState s) => s.selectedMonth);
    final monthlyBudget = context.select((AppState s) => s.getMonthlyBudgetAmount());
    final totalSpent = context.select((AppState s) => s.getCurrentMonthTotalSpent());
    final currency = context.select((AppState s) => s.settings.currency);
    final currentBudgets = context.select((AppState s) => s.currentBudgets);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();

    // Check if the navigated month is the current calendar month
    final isCurrentMonth = selectedMonth.year == now.year &&
        selectedMonth.month == now.month;

    final remaining = monthlyBudget != null ? monthlyBudget - totalSpent : null;
    final daysLeft = _getDaysLeftInMonth(selectedMonth);

    // Calculate ratio
    final ratio = monthlyBudget != null && monthlyBudget > 0
        ? totalSpent / monthlyBudget
        : 0.0;

    // Get color based on threshold ratio
    final budgetColor = budgetProgressColor(ratio);

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
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
                  readableMonth(selectedMonth),
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
                selectedMonth,
                monthlyBudget,
                totalSpent,
                remaining!,
                daysLeft,
                ratio,
                budgetColor,
                isDark,
                currency,
              ),

            const SizedBox(height: AppSpacing.lg),

            // SECTION 2: CATEGORY BUDGETS (SECONDARY)
            _buildCategoryBudgetsSection(context, state, selectedMonth, currentBudgets, currency),
            const SizedBox(height: 84), // Bottom padding for navigation shell
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHeroCard(BuildContext context, AppState state) {
    return EmptyState(
      icon: Icons.savings_outlined,
      title: 'No monthly budget set',
      subtitle: 'Set a monthly limit to track your total spending.',
      actionLabel: 'Set Budget',
      onActionPressed: () => BudgetScreen.showSetBudgetSheet(context, state, null),
    );
  }

  Widget _buildActiveHeroCard(
    BuildContext context,
    AppState state,
    DateTime selectedMonth,
    double monthlyBudget,
    double totalSpent,
    double remaining,
    int daysLeft,
    double ratio,
    Color budgetColor,
    bool isDark,
    String currency,
  ) {
    final isOverBudget = remaining < 0;

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                readableMonth(selectedMonth),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (value) {
                  if (value == 'edit') {
                    BudgetScreen.showSetBudgetSheet(context, state, monthlyBudget);
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
                            size: 18, color: WalletMeltColors.danger),
                        SizedBox(width: 8),
                        Text('Clear Budget',
                            style: TextStyle(color: WalletMeltColors.danger)),
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
                '${formatMoney(totalSpent, currency)} of ${formatMoney(monthlyBudget, currency)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),

          ProgressBar(fraction: ratio, color: budgetColor, height: 12),
          if (isOverBudget) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You exceeded your budget this month.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: WalletMeltColors.danger,
                  ),
            ),
          ],
          const SizedBox(height: AppSpacing.md + 4),

          Row(
            children: [
              Expanded(
                child: StatTile(
                  label: 'Spent',
                  value: formatMoney(totalSpent, currency),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: isOverBudget ? 'Over by' : 'Remaining',
                  value: isOverBudget
                      ? formatMoney(-remaining, currency)
                      : formatMoney(remaining, currency),
                  valueColor: isOverBudget ? WalletMeltColors.danger : null,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Days Left',
                  value: '$daysLeft',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBudgetsSection(
    BuildContext context,
    AppState state,
    DateTime selectedMonth,
    List<CategoryBudget> currentBudgets,
    String currency,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Category Budgets',
          icon: Icons.pie_chart_outline_rounded,
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          trailing: IconButton.filledTonal(
            onPressed: () => _showCategoryBudgetSheet(context, state, null),
            icon: const Icon(Icons.add_rounded),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        if (currentBudgets.isEmpty)
          const EmptyState(
            icon: Icons.pie_chart_outline_rounded,
            title: 'No category budgets set',
            subtitle: 'Add a budget for a specific spending category.',
          )
        else ...[
          // Pre-aggregate spent amounts in O(E) to avoid nested O(B * E) lookup loops
          () {
            final expenses = context.select((AppState s) => s.expenses);
            final categorySpentMap = <String, double>{};
            for (final exp in expenses) {
              if (exp.deletedAt == null) {
                try {
                  final date = parseIsoDate(exp.date);
                  if (isSameMonth(date, selectedMonth)) {
                    categorySpentMap[exp.categoryId] =
                        (categorySpentMap[exp.categoryId] ?? 0) + exp.amount;
                  }
                } catch (_) {}
              }
            }
            return Column(
              children: [
                for (final budget in currentBudgets)
                  _buildCategoryBudgetRow(
                    context: context,
                    state: state,
                    budget: budget,
                    spent: categorySpentMap[budget.categoryId] ?? 0.0,
                    currency: currency,
                  ),
              ],
            );
          }(),
        ],
      ],
    );
  }

  Widget _buildCategoryBudgetRow({
    required BuildContext context,
    required AppState state,
    required CategoryBudget budget,
    required double spent,
    required String currency,
  }) {
    final category = state.categoryById(budget.categoryId);
    final categoryName = category?.name ?? 'Unknown';
    final categoryColor = category != null
        ? colorFromHex(category.color)
        : WalletMeltColors.brand;

    final remaining = budget.amount - spent;
    final isOverBudget = remaining < 0;

    final ratio = budget.amount > 0 ? spent / budget.amount : 0.0;
    final progressColor = budgetProgressColor(ratio);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: WMGlassSurface.tier1(
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
                      ? 'Over by ${formatMoney(-remaining, currency)}'
                      : '${formatMoney(remaining, currency)} left',
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
                  'Spent: ${formatMoney(spent, currency)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                Text(
                  'Limit: ${formatMoney(budget.amount, currency)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(fraction: ratio, color: progressColor),
          ],
        ),
      ),
    );
  }

  // _getBudgetColor removed — use top-level budgetProgressColor() from wallet_melt_theme.dart

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



  // Clear total budget confirmation
  Future<void> _confirmClearBudget(BuildContext context, AppState state) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Clear Monthly Budget?',
      body:
          'This will clear the monthly spend ceiling. Your expenses and category budgets will remain intact.',
      confirmLabel: 'Clear',
      isDestructive: true,
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
      useRootNavigator: true,
      constraints: const BoxConstraints(maxWidth: 600),
      builder: (sheetContext) {
        return SafeArea(
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
            ),
            child: StatefulBuilder(
              builder: (context, setSheetState) {
                final isEdit = existingBudget != null;
                return SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.sm,
                        AppSpacing.lg,
                        AppSpacing.lg),
                    child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SheetHandle(),
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
                                color: WalletMeltColors.danger),
                            onPressed: () => _confirmDeleteCategoryBudget(
                                context, state, existingBudget),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm + 2),

                    // Category selector dropdown
                    DropdownButtonFormField<String>(
                      initialValue: categoryId,
                      decoration: const InputDecoration(labelText: 'Category'),
                      dropdownColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF1E1E24)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                    const SizedBox(height: AppSpacing.sm),

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
                    const SizedBox(height: AppSpacing.md + 4),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius)),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(50),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.buttonRadius)),
                            ),
                            onPressed: () async {
                              final parsed =
                                  double.tryParse(amountController.text.trim());
                              if (categoryId == null ||
                                  parsed == null ||
                                  parsed <= 0) {
                                showErrorSnackbar(context,
                                    'Please select a category and enter an amount > 0.');
                                return;
                              }
                              if (!isEdit) {
                                final duplicate = state.currentBudgets
                                    .any((b) => b.categoryId == categoryId);
                                if (duplicate) {
                                  showErrorSnackbar(context,
                                      'Budget already exists for this category this month. Edit it instead.');
                                  return;
                                }
                              }
                              final month = monthKey(state.selectedMonth);
                              await state.setCategoryBudget(
                                categoryId: categoryId!,
                                amount: parsed,
                                month: month,
                              );
                              if (context.mounted) Navigator.pop(context);
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
        ),
      ),
    );
      },
    );
    amountController.dispose();
  }

  // Delete category budget confirmation
  Future<void> _confirmDeleteCategoryBudget(
      BuildContext context, AppState state, CategoryBudget budget) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Category Budget?',
      body:
          'Are you sure you want to remove the spend limit for this category? This will not affect your expenses.',
      confirmLabel: 'Delete',
      isDestructive: true,
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
