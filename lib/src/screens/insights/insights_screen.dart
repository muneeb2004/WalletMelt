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
import '../../types/debt.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../widgets/triple_metric_row.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final currency = state.settings.currency;
    final selectedMonth = state.selectedMonth;
    final insights = state.monthlyInsights;
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    // Calculate Lending and Debt metrics
    double receivables = 0.0;
    double liabilities = 0.0;
    double overdueAmount = 0.0;

    final nowStr = DateTime.now().toIso8601String().substring(0, 10);

    final debtorAmounts = <String, double>{};
    final creditorAmounts = <String, double>{};

    // Calculate Tax Metrics
    double monthlyTax = 0.0;
    double yearlyTax = 0.0;
    double taxableSpend = 0.0;
    double nonTaxableSpend = 0.0;
    final taxByCategory = <String, double>{};

    final selectedYear = selectedMonth.year;
    final selectedMonthInt = selectedMonth.month;

    for (final exp in state.expenses) {
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

    // Calculate Subscription Metrics
    double monthlySubSpend = 0.0;
    double annualSubSpend = 0.0;
    wm_sub.Subscription? mostExpensiveSub;
    double highestSubPrice = 0.0;

    final activeSubs = state.subscriptions
        .where((s) => s.status == wm_sub.SubscriptionStatus.active)
        .toList();
    final subSpendByCategory = <String, double>{};

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

    for (final debt in state.debts) {
      if (debt.isSettled) continue;

      final isReceivable =
          debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven;
      if (isReceivable) {
        receivables += debt.remainingAmount;
        debtorAmounts[debt.personName] =
            (debtorAmounts[debt.personName] ?? 0.0) + debt.remainingAmount;
      } else {
        liabilities += debt.remainingAmount;
        creditorAmounts[debt.personName] =
            (creditorAmounts[debt.personName] ?? 0.0) + debt.remainingAmount;
      }

      if (debt.dueDate != null && debt.dueDate!.compareTo(nowStr) < 0) {
        overdueAmount += debt.remainingAmount;
      }
    }

    final netDebtPosition = receivables - liabilities;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    String? largestDebtorName;
    double largestDebtorAmount = 0.0;
    debtorAmounts.forEach((name, amount) {
      if (amount > largestDebtorAmount) {
        largestDebtorAmount = amount;
        largestDebtorName = name;
      }
    });

    String? largestCreditorName;
    double largestCreditorAmount = 0.0;
    creditorAmounts.forEach((name, amount) {
      if (amount > largestCreditorAmount) {
        largestCreditorAmount = amount;
        largestCreditorName = name;
      }
    });

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
          children: [
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
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
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
            if (insights.total == 0) ...[
              const EmptyState(
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: insights.monthOverMonthDelta! <= 0
                              ? WalletMeltColors.positive
                                  .withValues(alpha: 0.16)
                              : WalletMeltColors.danger.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: insights.monthOverMonthDelta! <= 0
                                ? WalletMeltColors.positive
                                    .withValues(alpha: 0.28)
                                : WalletMeltColors.danger
                                    .withValues(alpha: 0.28),
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
                                  ? (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? WalletMeltColors.positive
                                      : const Color(0xFF1E7E52))
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? WalletMeltColors.danger
                                      : const Color(0xFFC0392B)),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${insights.monthOverMonthDelta! >= 0 ? '+' : ''}${insights.monthOverMonthDelta!.toStringAsFixed(1)}% vs previous month',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: insights.monthOverMonthDelta! <= 0
                                        ? (Theme.of(context).brightness ==
                                                Brightness.dark
                                            ? Colors.white
                                            : const Color(0xFF1E7E52))
                                        : (Theme.of(context).brightness ==
                                                Brightness.dark
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
                      onPressed: () => context.go('/planning'),
                      icon: const Icon(Icons.account_balance_wallet_rounded),
                      label: const Text('Manage Budgets'),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
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
                    value1: '${receivables.toStringAsFixed(receivables % 1 == 0 ? 0 : 2)} $currency',
                    color1: WalletMeltColors.positive,
                    label2: 'LIABILITIES',
                    value2: '${liabilities.toStringAsFixed(liabilities % 1 == 0 ? 0 : 2)} $currency',
                    color2: theme.colorScheme.error,
                    label3: 'OVERDUE',
                    value3: '${overdueAmount.toStringAsFixed(overdueAmount % 1 == 0 ? 0 : 2)} $currency',
                    color3: overdueAmount > 0 ? theme.colorScheme.error : WalletMeltColors.textMuted,
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
                    mostExpensiveSub != null
                        ? '${mostExpensiveSub.name} (${(mostExpensiveSub.amount + (mostExpensiveSub.taxAmount ?? 0.0)).toStringAsFixed(0)} $currency/${mostExpensiveSub.billingCycle})'
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
    );
  }
}
