import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../types/debt.dart';
import '../../types/expense.dart';
import '../../types/insight_action.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/insights/insight_card_shell.dart';
import '../../widgets/insights/insight_content.dart';
import '../../widgets/insights/spending_summary_section.dart';
import '../../widgets/section_header.dart';
import '../../widgets/state_views.dart';
import '../../widgets/triple_metric_row.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  // Metric cache tracking
  List<Expense>? _lastExpenses;
  List<wm_sub.Subscription>? _lastSubscriptions;
  List<DebtRecord>? _lastDebts;
  DateTime? _lastSelectedMonth;

  // Cached obligation metrics
  late double receivables;
  late double liabilities;
  late double overdueAmount;
  late double monthlyTax;
  late double yearlyTax;
  late double taxableSpend;
  late double nonTaxableSpend;
  late Map<String, double> taxByCategory;
  late double monthlySubSpend;
  late double annualSubSpend;
  late wm_sub.Subscription? mostExpensiveSub;
  late double highestSubPrice;
  late Map<String, double> subSpendByCategory;
  late String? largestDebtorName;
  late double largestDebtorAmount;
  late String? largestCreditorName;
  late double largestCreditorAmount;
  late double netDebtPosition;

  @override
  void initState() {
    super.initState();
    taxByCategory = {};
    subSpendByCategory = {};
  }

  void _calculateMetrics(AppState state) {
    final expenses = state.expenses;
    final subscriptions = state.subscriptions;
    final debts = state.debts;
    final selectedMonth = state.selectedMonth;

    if (_lastExpenses == expenses &&
        _lastSubscriptions == subscriptions &&
        _lastDebts == debts &&
        _lastSelectedMonth == selectedMonth) {
      return;
    }

    _lastExpenses = expenses;
    _lastSubscriptions = subscriptions;
    _lastDebts = debts;
    _lastSelectedMonth = selectedMonth;

    receivables = 0.0;
    liabilities = 0.0;
    overdueAmount = 0.0;

    final nowStr = DateTime.now().toIso8601String().substring(0, 10);
    final debtorAmounts = <String, double>{};
    final creditorAmounts = <String, double>{};

    monthlyTax = 0.0;
    yearlyTax = 0.0;
    taxableSpend = 0.0;
    nonTaxableSpend = 0.0;
    taxByCategory.clear();

    final selectedYear = selectedMonth.year;
    final selectedMonthInt = selectedMonth.month;

    for (final exp in expenses) {
      if (exp.deletedAt != null) continue;

      DateTime expDate;
      try {
        expDate = DateTime.parse(exp.date);
      } catch (_) {
        continue;
      }

      final isSameYear = expDate.year == selectedYear;
      final isSameMonth = isSameYear && expDate.month == selectedMonthInt;

      if (isSameMonth) {
        if (exp.taxAmount != null && exp.taxAmount! > 0) {
          monthlyTax += exp.taxAmount!;
          taxableSpend += exp.subtotalAmount ?? (exp.amount - exp.taxAmount!);
          final category = state.categoryById(exp.categoryId);
          final catName = category?.name ?? 'Uncategorized';
          taxByCategory[catName] =
              (taxByCategory[catName] ?? 0.0) + exp.taxAmount!;
        } else {
          nonTaxableSpend += exp.amount;
        }
      }

      if (isSameYear) {
        if (exp.taxAmount != null && exp.taxAmount! > 0) {
          yearlyTax += exp.taxAmount!;
        }
      }
    }

    monthlySubSpend = 0.0;
    annualSubSpend = 0.0;
    mostExpensiveSub = null;
    highestSubPrice = 0.0;
    subSpendByCategory.clear();

    final activeSubs = subscriptions
        .where((s) => s.status == wm_sub.SubscriptionStatus.active && !s.isDeleted)
        .toList();

    for (final sub in activeSubs) {
      final subTotalCost = sub.amount + (sub.taxAmount ?? 0.0);
      double monthlyEquivalent = 0.0;
      final cycle = sub.billingCycle.toLowerCase().trim();

      if (cycle == 'monthly') {
        monthlyEquivalent = subTotalCost;
      } else if (cycle == 'quarterly') {
        monthlyEquivalent = subTotalCost / 3.0;
      } else if (cycle == 'semi-annual' || cycle == 'semi_annual') {
        monthlyEquivalent = subTotalCost / 6.0;
      } else if (cycle == 'annual' || cycle == 'yearly') {
        monthlyEquivalent = subTotalCost / 12.0;
      } else if (cycle.startsWith('custom_')) {
        final parts = cycle.split('_');
        if (parts.length == 2) {
          final days = int.tryParse(parts[1]) ?? 30;
          monthlyEquivalent = subTotalCost * (30.0 / days);
        } else {
          monthlyEquivalent = subTotalCost;
        }
      } else {
        monthlyEquivalent = subTotalCost;
      }

      monthlySubSpend += monthlyEquivalent;

      final category = state.categoryById(sub.categoryId);
      final catName = category?.name ?? 'Uncategorized';
      subSpendByCategory[catName] =
          (subSpendByCategory[catName] ?? 0.0) + monthlyEquivalent;

      if (subTotalCost > highestSubPrice) {
        highestSubPrice = subTotalCost;
        mostExpensiveSub = sub;
      }
    }

    annualSubSpend = monthlySubSpend * 12.0;

    for (final debt in debts) {
      if (debt.isSettled) continue;

      final isReceivable =
          debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;
      final resolvedName = state.payeeNameFor(debt);
      if (isReceivable) {
        receivables += debt.remainingAmount;
        debtorAmounts[resolvedName] =
            (debtorAmounts[resolvedName] ?? 0.0) + debt.remainingAmount;
      } else {
        liabilities += debt.remainingAmount;
        creditorAmounts[resolvedName] =
            (creditorAmounts[resolvedName] ?? 0.0) + debt.remainingAmount;
      }

      if (debt.dueDate != null && debt.dueDate!.compareTo(nowStr) < 0) {
        overdueAmount += debt.remainingAmount;
      }
    }

    netDebtPosition = receivables - liabilities;

    largestDebtorName = null;
    largestDebtorAmount = 0.0;
    debtorAmounts.forEach((name, amount) {
      if (amount > largestDebtorAmount) {
        largestDebtorAmount = amount;
        largestDebtorName = name;
      }
    });

    largestCreditorName = null;
    largestCreditorAmount = 0.0;
    creditorAmounts.forEach((name, amount) {
      if (amount > largestCreditorAmount) {
        largestCreditorAmount = amount;
        largestCreditorName = name;
      }
    });
  }

  void _handleInsightAction(BuildContext context, InsightAction action) {
    switch (action.type) {
      case InsightActionType.viewCategory:
        if (action.targetId != null) {
          context.go('/history?categoryId=${action.targetId}');
        } else {
          context.go('/history');
        }
      case InsightActionType.viewExpense:
        if (action.targetId != null) {
          context.push('/expense/${action.targetId}');
        }
      case InsightActionType.viewBudgets:
        context.go('/planning');
      case InsightActionType.viewHistory:
        context.go('/history');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final selectedMonth = state.selectedMonth;
    final insights = state.monthlyInsights;
    final cards = state.insightCards;
    final summaries = state.spendingSummaries;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    _calculateMetrics(state);
    final expensiveSub = mostExpensiveSub;
    final isDark = theme.brightness == Brightness.dark;

    if (state.errorMessage != null) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppErrorState(
                message: state.errorMessage!,
                onRetry: () => context.read<AppState>().refresh(),
              ),
            ),
          ),
        ),
      );
    }

    if (state.isOffline) {
      return Scaffold(
        body: AppBackground(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppOfflineState(
                onRetry: () => context.read<AppState>().refresh(),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: AppBackground(
        child: Skeletonizer(
          enabled: state.isLoading,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // Header with Month Navigation
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Insights',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 13, color: WalletMeltColors.textMuted),
                            const SizedBox(width: 6),
                            Text(
                              readableMonth(selectedMonth),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: WalletMeltColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),

              if (insights.total == 0 && cards.isEmpty) ...[
                const EmptyState(
                  icon: Icons.bar_chart_rounded,
                  title: 'No data yet',
                  subtitle:
                      'Add expenses to see your monthly trend, category breakdown, and actionable spending insights.',
                ),
              ] else ...[
                // Monthly Spend Trend Hero Banner
                WMDarkHeroCard(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: WalletMeltColors.brand,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'MONTHLY SPEND TREND',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: isDark
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                          if (insights.monthOverMonthDelta != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: insights.monthOverMonthDelta! <= 0
                                    ? WalletMeltColors.positive
                                        .withValues(alpha: 0.18)
                                    : WalletMeltColors.danger
                                        .withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    insights.monthOverMonthDelta! <= 0
                                        ? Icons.trending_down_rounded
                                        : Icons.trending_up_rounded,
                                    color: insights.monthOverMonthDelta! <= 0
                                        ? WalletMeltColors.positive
                                        : WalletMeltColors.danger,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${insights.monthOverMonthDelta! >= 0 ? '+' : ''}${insights.monthOverMonthDelta!.toStringAsFixed(1)}%',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: insights.monthOverMonthDelta! <= 0
                                          ? WalletMeltColors.positive
                                          : WalletMeltColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        formatMoney(insights.total, currency),
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : WalletMeltColors.textPrimary,
                          letterSpacing: -0.6,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        insights.highestCategory == null
                            ? 'Add another month of expenses to compare trends.'
                            : 'Highest category: ${insights.highestCategory!.category.name} (${formatMoney(insights.highestCategory!.total, currency)})',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Actionable Insights Feed
                if (cards.isNotEmpty) ...[
                  const SectionHeader(title: 'Actionable Insights'),
                  const SizedBox(height: AppSpacing.sm),
                  for (final card in cards)
                    InsightCardShell(
                      card: card,
                      content: InsightContent(
                        data: card.data,
                        currency: currency,
                      ),
                      onAction: (action) => _handleInsightAction(context, action),
                    ),
                ],

                // Spending Summaries
                SpendingSummarySection(
                  summaries: summaries,
                  currency: currency,
                  onCategoryTap: (catId) =>
                      context.go('/history?categoryId=$catId'),
                  onMerchantTap: (_) => context.go('/history'),
                  onTransactionTap: (expId) => context.push('/expense/$expId'),
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
                        style: theme.textTheme.bodyMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      OutlinedButton.icon(
                        onPressed: () => context.go('/planning'),
                        icon: const Icon(Icons.account_balance_wallet_rounded),
                        label: const Text('Manage Budgets'),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Obligations: Lending & Debt
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Lending & Debt Insights',
                      icon: Icons.handshake_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Position:',
                          style: textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${netDebtPosition >= 0 ? "+" : ""}${netDebtPosition.toStringAsFixed(netDebtPosition % 1 == 0 ? 0 : 2)} $currency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: netDebtPosition >= 0
                                ? WalletMeltColors.positive
                                : theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Divider(
                        height: 1,
                        color: isDark
                            ? WalletMeltColors.darkBorder
                            : WalletMeltColors.lightBorder),
                    AppSpacing.gapSm,
                    TripleMetricRow(
                      label1: 'RECEIVABLES',
                      value1:
                          '${receivables.toStringAsFixed(receivables % 1 == 0 ? 0 : 2)} $currency',
                      color1: WalletMeltColors.positive,
                      label2: 'LIABILITIES',
                      value2:
                          '${liabilities.toStringAsFixed(liabilities % 1 == 0 ? 0 : 2)} $currency',
                      color2: theme.colorScheme.error,
                      label3: 'OVERDUE',
                      value3:
                          '${overdueAmount.toStringAsFixed(overdueAmount % 1 == 0 ? 0 : 2)} $currency',
                      color3: overdueAmount > 0
                          ? theme.colorScheme.error
                          : WalletMeltColors.textMuted,
                    ),
                    AppSpacing.gapSm,
                    Divider(
                        height: 1,
                        color: isDark
                            ? WalletMeltColors.darkBorder
                            : WalletMeltColors.lightBorder),
                    AppSpacing.gapSm,
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LARGEST DEBTOR',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: WalletMeltColors.textMuted,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                largestDebtorName != null
                                    ? '$largestDebtorName (${largestDebtorAmount.toStringAsFixed(largestDebtorAmount % 1 == 0 ? 0 : 2)} $currency)'
                                    : 'None',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'LARGEST CREDITOR',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: WalletMeltColors.textMuted,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                largestCreditorName != null
                                    ? '$largestCreditorName (${largestCreditorAmount.toStringAsFixed(largestCreditorAmount % 1 == 0 ? 0 : 2)} $currency)'
                                    : 'None',
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w700),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Tax Insights
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Tax Insights',
                      icon: Icons.account_balance_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax Paid This Month:',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          '${monthlyTax.toStringAsFixed(monthlyTax % 1 == 0 ? 0 : 2)} $currency',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: WalletMeltColors.danger),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Tax Paid This Year:',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          '${yearlyTax.toStringAsFixed(yearlyTax % 1 == 0 ? 0 : 2)} $currency',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: WalletMeltColors.danger),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Divider(
                        height: 1,
                        color: isDark
                            ? WalletMeltColors.darkBorder
                            : WalletMeltColors.lightBorder),
                    AppSpacing.gapSm,
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TAXABLE SPEND',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: WalletMeltColors.textMuted,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${taxableSpend.toStringAsFixed(taxableSpend % 1 == 0 ? 0 : 2)} $currency',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        AppSpacing.gapSm,
                        Container(
                            width: 1,
                            height: 28,
                            color: isDark
                                ? WalletMeltColors.darkBorder
                                : WalletMeltColors.lightBorder),
                        AppSpacing.gapSm,
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'TAX-FREE SPEND',
                                style: TextStyle(
                                    fontSize: 9,
                                    color: WalletMeltColors.textMuted,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${nonTaxableSpend.toStringAsFixed(nonTaxableSpend % 1 == 0 ? 0 : 2)} $currency',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (taxByCategory.isNotEmpty) ...[
                      AppSpacing.gapSm,
                      Divider(
                          height: 1,
                          color: isDark
                              ? WalletMeltColors.darkBorder
                              : WalletMeltColors.lightBorder),
                      AppSpacing.gapSm,
                      const Text(
                        'TAX BY CATEGORY (THIS MONTH)',
                        style: TextStyle(
                            fontSize: 9,
                            color: WalletMeltColors.textMuted,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      for (final entry in taxByCategory.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                '${entry.value.toStringAsFixed(entry.value % 1 == 0 ? 0 : 2)} $currency',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Subscription Insights
              WMGlassSurface.tier2(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(
                      title: 'Subscription Insights',
                      icon: Icons.repeat_rounded,
                      padding: EdgeInsets.only(bottom: AppSpacing.xs),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Est. Spend:',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          '${monthlySubSpend.toStringAsFixed(monthlySubSpend % 1 == 0 ? 0 : 2)} $currency',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: WalletMeltColors.brandDeep),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Annual Est. Spend:',
                            style: TextStyle(fontSize: 13)),
                        Text(
                          '${annualSubSpend.toStringAsFixed(annualSubSpend % 1 == 0 ? 0 : 2)} $currency',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: WalletMeltColors.brandDeep),
                        ),
                      ],
                    ),
                    AppSpacing.gapSm,
                    Divider(
                        height: 1,
                        color: isDark
                            ? WalletMeltColors.darkBorder
                            : WalletMeltColors.lightBorder),
                    AppSpacing.gapSm,
                    const Text(
                      'MOST EXPENSIVE',
                      style: TextStyle(
                          fontSize: 9,
                          color: WalletMeltColors.textMuted,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      expensiveSub != null
                          ? '${expensiveSub.name} (${(expensiveSub.amount + (expensiveSub.taxAmount ?? 0.0)).toStringAsFixed(0)} $currency/${expensiveSub.billingCycle})'
                          : 'None active',
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    if (subSpendByCategory.isNotEmpty) ...[
                      AppSpacing.gapSm,
                      Divider(
                          height: 1,
                          color: isDark
                              ? WalletMeltColors.darkBorder
                              : WalletMeltColors.lightBorder),
                      AppSpacing.gapSm,
                      const Text(
                        'SUBSCRIPTIONS BY CATEGORY',
                        style: TextStyle(
                            fontSize: 9,
                            color: WalletMeltColors.textMuted,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      for (final entry in subSpendByCategory.entries) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key,
                                  style: const TextStyle(fontSize: 12)),
                              Text(
                                '${entry.value.toStringAsFixed(entry.value % 1 == 0 ? 0 : 2)} $currency/mo',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
