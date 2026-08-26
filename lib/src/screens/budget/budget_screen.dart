import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../types/budget.dart';
import '../../widgets/app_snackbar.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/section_header.dart';
import '../../widgets/stat_tile.dart';
import '../../widgets/state_views.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({this.isEmbedded = false, super.key});

  final bool isEmbedded;

  static Future<void> showSetBudgetSheet(
      BuildContext context, AppState state, double? currentAmount, double totalSpent) async {
    final controller = TextEditingController(
      text: currentAmount != null ? currentAmount.toStringAsFixed(0) : '',
    );

    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                      onChanged: (_) => setSheetState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Budget Amount (${state.settings.currency})',
                        hintText: 'e.g. 50000',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Builder(builder: (context) {
                      final parsed = double.tryParse(controller.text.trim()) ?? 0.0;
                      final remaining = parsed - totalSpent;
                      final isOver = remaining < 0;
                      return WMGlassSurface.tier1(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ADJUSTMENT PREVIEW',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                    color: WalletMeltColors.textMuted,
                                  ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Current Budget',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted, fontSize: 11)),
                                    Text(
                                      currentAmount != null
                                          ? formatMoney(currentAmount, state.settings.currency)
                                          : 'None',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('Actual Spent',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted, fontSize: 11)),
                                    Text(
                                      formatMoney(totalSpent, state.settings.currency),
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('New Budget',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted, fontSize: 11)),
                                    Text(
                                      formatMoney(parsed, state.settings.currency),
                                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text('New Remaining',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            color: WalletMeltColors.textMuted, fontSize: 11)),
                                    Text(
                                      isOver
                                          ? 'Over by ${formatMoney(-remaining, state.settings.currency)}'
                                          : formatMoney(remaining, state.settings.currency),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: isOver
                                            ? WalletMeltColors.danger
                                            : (parsed > 0 ? WalletMeltColors.positive : null),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: AppSpacing.md + 4),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        AppSpacing.gapSm,
                        Expanded(
                          child: ElevatedButton(
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
            );
          },
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
    final theme = Theme.of(context);
    final state = context.watch<AppState>();
    final selectedMonth = context.select((AppState s) => s.selectedMonth);
    final monthlyBudget = context.select((AppState s) => s.getMonthlyBudgetAmount());
    final totalSpent = context.select((AppState s) => s.getCurrentMonthTotalSpent());
    final currency = context.select((AppState s) => s.settings.currency);
    final currentBudgets = context.select((AppState s) => s.currentBudgets);

    final isDark = theme.brightness == Brightness.dark;
    final now = DateTime.now();

    if (state.errorMessage != null) {
      final errorWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppErrorState(
            message: state.errorMessage!,
            onRetry: () => context.read<AppState>().refresh(),
          ),
        ),
      );
      return widget.isEmbedded
          ? errorWidget
          : Scaffold(
              body: AppBackground(
                child: errorWidget,
              ),
            );
    }

    if (state.isOffline) {
      final offlineWidget = Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: AppOfflineState(
            onRetry: () => context.read<AppState>().refresh(),
          ),
        ),
      );
      return widget.isEmbedded
          ? offlineWidget
          : Scaffold(
              body: AppBackground(
                child: offlineWidget,
              ),
            );
    }

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

    final content = ListView(
      padding: EdgeInsets.fromLTRB(20, widget.isEmbedded ? 0 : 16, 20, 120),
      children: [
        if (!widget.isEmbedded) ...[
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budgeting',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('Keep your spending under control.',
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              // Month Navigation
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Previous month',
                onPressed: state.previousMonth,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text(
                readableMonth(selectedMonth),
                style: theme.textTheme.titleMedium,
              ),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                tooltip: 'Next month',
                onPressed: isCurrentMonth ? null : state.nextMonth,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          const SizedBox(height: 18),
        ] else ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Month Ceiling',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Previous month',
                    onPressed: state.previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded, size: 20),
                  ),
                  Text(
                    readableMonth(selectedMonth),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    tooltip: 'Next month',
                    onPressed: isCurrentMonth ? null : state.nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded, size: 20),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],

        // SECTION 1: TOTAL MONTHLY BUDGET (HERO)
        if (monthlyBudget == null)
          _buildEmptyHeroCard(context, state, totalSpent)
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
        _buildCategoryBudgetsSection(
          context,
          state,
          selectedMonth,
          currentBudgets,
          currency,
        ),
      ],
    );

    return Skeletonizer(
      enabled: state.isLoading,
      child: widget.isEmbedded
          ? content
          : Scaffold(
              body: AppBackground(
                child: content,
              ),
            ),
    );
  }

  Widget _buildEmptyHeroCard(BuildContext context, AppState state, double totalSpent) {
    return EmptyState(
      icon: Icons.savings_outlined,
      title: 'No monthly budget set',
      subtitle: 'Set a monthly limit to track your total spending.',
      actionLabel: 'Set Budget',
      onActionPressed: () => BudgetScreen.showSetBudgetSheet(context, state, null, totalSpent),
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
                    BudgetScreen.showSetBudgetSheet(context, state, monthlyBudget, totalSpent);
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

          // Ratio percentage text with generous breathing space
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: isOverBudget
                    ? const EdgeInsets.symmetric(horizontal: 10, vertical: 4)
                    : EdgeInsets.zero,
                decoration: isOverBudget
                    ? BoxDecoration(
                        color: WalletMeltColors.danger.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      )
                    : null,
                child: Text(
                  isOverBudget
                      ? 'Over Budget'
                      : '${(ratio * 100).toStringAsFixed(0)}% Used',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: budgetColor,
                        fontWeight: FontWeight.w800,
                        fontSize: isOverBudget ? 13 : null,
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${formatMoney(totalSpent, currency)} of ${formatMoney(monthlyBudget, currency)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            fontFeatures: const [FontFeature.tabularFigures()],
                          ),
                    ),
                  ),
                ),
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

          // ── Row 1: Spent & Remaining / Over by (2 equal columns) ─────────
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
                  valueColor: isOverBudget ? WalletMeltColors.danger : WalletMeltColors.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // ── Row 2: Days Left in Month (Full-width Cohesive Row) ───────────
          _buildFullWidthMetricRow(
            context: context,
            isDark: isDark,
            icon: Icons.calendar_month_rounded,
            label: 'Days Left in Month',
            value: '$daysLeft ${daysLeft == 1 ? 'Day' : 'Days'} Remaining',
          ),

          // ── Row 3: Daily Spend Allowance (Full-width Cohesive Row) ────────
          if (selectedMonth.year == DateTime.now().year &&
              selectedMonth.month == DateTime.now().month) ...[
            const SizedBox(height: AppSpacing.sm),
            _buildFullWidthMetricRow(
              context: context,
              isDark: isDark,
              icon: Icons.today_rounded,
              label: isOverBudget ? 'Daily Allowance' : 'Daily Spend Allowance',
              value: isOverBudget
                  ? 'No allowance remaining'
                  : '${formatMoney(remaining / daysLeft.clamp(1, 999), currency)} / day',
              valueColor: isOverBudget ? WalletMeltColors.danger : WalletMeltColors.positive,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFullWidthMetricRow({
    required BuildContext context,
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    final tt = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromRGBO(255, 255, 255, 0.08)
            : const Color.fromRGBO(0, 0, 0, 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 8),
        border: Border.all(
          color: isDark
              ? const Color.fromRGBO(255, 255, 255, 0.05)
              : const Color.fromRGBO(0, 0, 0, 0.03),
          width: 1.0,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: valueColor ?? (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tt.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
          const SizedBox(width: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              style: tt.titleMedium?.copyWith(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: valueColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
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
              children: [
                Expanded(
                  child: Text(
                    'Spent: ${formatMoney(spent, currency)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Limit: ${formatMoney(budget.amount, currency)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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

    await showAppBottomSheet<void>(
      context,
      builder: (sheetContext) {
        return StatefulBuilder(
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
                          ? WalletMeltColors.darkSurface
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
                    AppSpacing.gapSm,

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
                        AppSpacing.gapSm,
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
