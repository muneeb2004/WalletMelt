import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../analytics/financial_metrics_calculator.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';

class MetricCalculationsScreen extends StatelessWidget {
  const MetricCalculationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final state = context.watch<AppState>();

    final currency = state.settings.currency;
    final selectedMonth = state.selectedMonth;
    final monthlyBudget = state.getMonthlyBudgetAmount();
    final totalSpent = state.getCurrentMonthTotalSpent();

    final allowanceResult =
        FinancialMetricsCalculator.calculateDailySpendAllowance(
      monthlyBudget: monthlyBudget,
      totalSpent: totalSpent,
      month: selectedMonth,
    );

    final budgetUtil = FinancialMetricsCalculator.calculateBudgetUtilization(
      monthlyBudget: monthlyBudget,
      totalSpent: totalSpent,
    );

    final debtSummary =
        FinancialMetricsCalculator.calculateDebtSummary(state.debts);

    final now = DateTime.now();
    final lastDayOfMonth =
        DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    return Scaffold(
      body: AppBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
          children: [
            // Top Bar
            Row(
              children: [
                IconButton(
                  tooltip: 'Back',
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Metric Calculations',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Intro Header Card
            WMGlassSurface.tier1(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: context.scheme.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.functions_rounded,
                      size: 22,
                      color: context.scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mathematical Transparency',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Every metric in WalletMelt is calculated deterministically with zero hidden estimates. Here is the exact mathematical breakdown of how your figures are derived.',
                          style: TextStyle(
                            fontSize: 11,
                            color: context.scheme.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ══════════════════════════════════════════════════════════════════
            // FEATURED SECTION: PER DAY ALLOWANCE
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'FEATURED: PER DAY ALLOWANCE',
              icon: Icons.today_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: context.scheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'PRIMARY METRIC',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: context.scheme.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        readableMonth(selectedMonth),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: context.scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    'Daily Spend Allowance Formula',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Formula Display Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.scheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: context.scheme.outlineVariant,
                        width: 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'Daily Allowance = (Remaining Budget) / (Days Remaining in Month)',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: context.scheme.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Center(
                          child: Text(
                            'where Remaining Budget = Total Monthly Budget – Total Spent This Month\n'
                            'and Days Remaining = (Last Day of Month) – (Today) + 1',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: context.scheme.onSurfaceVariant,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Live calculation breakdown with user's current values
                  Text(
                    'YOUR REAL-TIME CURRENT MONTH BREAKDOWN:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),

                  _buildFormulaStepRow(context, 
                    label: 'Monthly Budget Limit (B)',
                    value: allowanceResult.hasBudget
                        ? formatMoney(allowanceResult.totalBudget, currency)
                        : 'No Budget Set',
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Total Spent So Far (S)',
                    value: formatMoney(allowanceResult.totalSpent, currency),
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Remaining Budget (R = B – S)',
                    value: allowanceResult.hasBudget
                        ? (allowanceResult.isOverBudget
                            ? '-${formatMoney(-(allowanceResult.remainingBudget ?? 0), currency)} (Over budget)'
                            : formatMoney(
                                allowanceResult.remainingBudget ?? 0, currency))
                        : 'N/A',
                    valueColor: allowanceResult.isOverBudget
                        ? context.scheme.error
                        : context.money.incomeText,
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Current Calendar Day',
                    value: 'Day ${now.day} of $lastDayOfMonth days',
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Active Days Remaining ($lastDayOfMonth – ${now.day} + 1)',
                    value: '${allowanceResult.daysRemaining} days (including today)',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 10),
                  const Divider(height: 1),
                  const SizedBox(height: 10),

                  // Result Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Expanded(
                        child: Text(
                          'RESULTING DAILY ALLOWANCE:',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        allowanceResult.isOverBudget
                            ? 'Over budget (0.00 / day)'
                            : (allowanceResult.hasBudget
                                ? '${formatMoney(allowanceResult.dailyAllowance, currency)} / day'
                                : 'Set a budget to activate'),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: allowanceResult.isOverBudget
                              ? context.scheme.error
                              : context.scheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Boundary Rules & Explanations
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.scheme.onSurface.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: context.scheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Key Allowance Rules & Boundary Conditions:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBulletPoint(context, 
                          title: 'Why is "+ 1" added to remaining days?',
                          detail:
                              'Today has not finished. Your remaining budget is available to spend today plus the remaining calendar days through end-of-month. Excluding today would cause an artificial compression of daily allowances.',
                          isDark: isDark,
                        ),
                        _buildBulletPoint(context, 
                          title: 'What happens when over budget?',
                          detail:
                              'When total spending exceeds the monthly budget (Remaining Budget ≤ 0), the daily allowance automatically drops to 0.00 and is highlighted in red to signal that no further discretionary allowance remains.',
                          isDark: isDark,
                        ),
                        _buildBulletPoint(context, 
                          title: 'What happens on the final day of the month?',
                          detail:
                              'On the last calendar day, Days Remaining evaluates to 1. The entire remaining budget is allocated as today\'s allowance.',
                          isDark: isDark,
                        ),
                        _buildBulletPoint(context, 
                          title: 'What about past or future months?',
                          detail:
                              'Past months are permanently closed and historical total spending is displayed. Future months show the full monthly allocation divided by that month\'s total day count.',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 2: MONTHLY BUDGET UTILIZATION & HEALTH
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'BUDGET PROGRESS & UTILIZATION',
              icon: Icons.pie_chart_outline_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulaBox(context, 
                    formula: 'Utilization Ratio = Total Spent / Monthly Budget Limit\n'
                        'Utilization % = Utilization Ratio × 100%',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFormulaStepRow(context, 
                    label: 'Current Status',
                    value: budgetUtil.hasBudget
                        ? '${budgetUtil.percentage.toStringAsFixed(1)}% Used'
                        : 'No Budget Set',
                    valueColor: budgetUtil.progressColor,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Color Threshold Rules:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  _buildColorRuleItem(context, 
                    color: context.money.incomeText,
                    label: '≤ 70% Spent (Healthy)',
                    description: 'Pacing well within monthly ceiling.',
                    isDark: isDark,
                  ),
                  _buildColorRuleItem(context, 
                    color: context.money.cautionText,
                    label: '70% – 90% Spent (Caution)',
                    description: 'Approaching budget ceiling.',
                    isDark: isDark,
                  ),
                  _buildColorRuleItem(context, 
                    color: context.scheme.error,
                    label: '> 90% Spent or Over Budget (Critical)',
                    description: 'Near depletion or exceeded limit.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 3: SPENDING VELOCITY & PACE
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'SPENDING VELOCITY & PROJECTED TOTAL',
              icon: Icons.speed_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulaBox(context, 
                    formula: 'Daily Pace = Total Positive Spend / Days Elapsed\n'
                        'Projected Month Spend = Daily Pace × Total Days in Month\n'
                        'Projected Change % = ((Projected – Last Month) / Last Month) × 100',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Velocity evaluates whether your current daily run-rate is accelerating or decelerating compared to the previous month. Requires at least 3 active days and 5 transactions.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.scheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 4: FINANCIAL OBLIGATIONS & DEBT
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'FINANCIAL OBLIGATIONS (DEBT)',
              icon: Icons.handshake_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulaBox(context, 
                    formula: 'Receivables (Owed to Me) = ∑ Unsettled lent amounts\n'
                        'Liabilities (I Owe) = ∑ Unsettled borrowed amounts\n'
                        'Net Position = Receivables – Liabilities\n'
                        'Overdue Amount = ∑ Unsettled obligations where Due Date < Today',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildFormulaStepRow(context, 
                    label: 'Current Receivables',
                    value: formatMoney(debtSummary.receivables, currency),
                    valueColor: context.money.incomeText,
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Current Liabilities',
                    value: formatMoney(debtSummary.liabilities, currency),
                    valueColor: context.scheme.error,
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Current Net Position',
                    value: '${debtSummary.netPosition >= 0 ? "+" : ""}${formatMoney(debtSummary.netPosition, currency)}',
                    valueColor: debtSummary.netPosition >= 0
                        ? context.money.incomeText
                        : context.scheme.error,
                    isDark: isDark,
                  ),
                  _buildFormulaStepRow(context, 
                    label: 'Overdue Outstanding',
                    value: formatMoney(debtSummary.overdueAmount, currency),
                    valueColor: debtSummary.overdueAmount > 0
                        ? context.scheme.error
                        : null,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 5: SUBSCRIPTION NORMALIZATION
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'SUBSCRIPTION BILLING NORMALIZATION',
              icon: Icons.autorenew_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulaBox(context, 
                    formula: 'Monthly Equivalent (Monthly) = Cost\n'
                        'Monthly Equivalent (Quarterly) = Cost / 3\n'
                        'Monthly Equivalent (Semi-Annual) = Cost / 6\n'
                        'Monthly Equivalent (Annual) = Cost / 12\n'
                        'Monthly Equivalent (Weekly) = Cost × (52 / 12)\n'
                        'Annual Equivalent = Monthly Equivalent × 12',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Standardizes varied recurring payment intervals to comparable monthly and annual cost metrics.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 6: TAX & EFFECTIVE RATE
            // ══════════════════════════════════════════════════════════════════
            _buildSectionHeader(context, 
              title: 'TAX CALCULATIONS',
              icon: Icons.account_balance_rounded,
              isDark: isDark,
            ),
            const SizedBox(height: 8),

            WMGlassSurface.tier2(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFormulaBox(context, 
                    formula: 'Taxable Spend = ∑ (Subtotal Amount)\n'
                        'Monthly Tax = ∑ (Tax Amount in Month)\n'
                        'Effective Tax Rate = (Monthly Tax / Taxable Spend) × 100%',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Separates gross amount into underlying net subtotal and tax paid. Only expenses with explicit tax entries are included in the effective tax rate calculation.',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, {
    required String title,
    required IconData icon,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: context.scheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: context.scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFormulaBox(BuildContext context, {required String formula, required bool isDark}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: context.scheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Text(
        formula,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: context.scheme.onSurface,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _buildFormulaStepRow(BuildContext context, {
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: context.scheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: valueColor ?? (context.scheme.onSurface),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, {
    required String title,
    required String detail,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5),
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: context.scheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  fontSize: 11,
                  color: context.scheme.onSurfaceVariant,
                  height: 1.35,
                ),
                children: [
                  TextSpan(
                    text: '$title ',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  TextSpan(text: detail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorRuleItem(BuildContext context, {
    required Color color,
    required String label,
    required String description,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  TextSpan(
                    text: ' – $description',
                    style: TextStyle(
                      fontSize: 11,
                      color: context.scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
