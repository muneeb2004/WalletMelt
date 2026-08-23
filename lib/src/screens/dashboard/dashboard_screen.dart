import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../screens/budget/budget_screen.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../types/debt.dart';
import '../../widgets/section_header.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../widgets/state_views.dart';
import '../../widgets/triple_metric_row.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AppState, bool>((s) => s.isLoading);
    final insights = context.select((AppState s) => s.monthlyInsights);
    final selectedMonth =
        context.select<AppState, DateTime>((s) => s.selectedMonth);
    final monthlyBudget = context
        .select<AppState, double?>((s) => s.getMonthlyBudgetAmount());
    final hasExpenses =
        context.select<AppState, bool>((s) => s.expenses.isNotEmpty);
    final currency =
        context.select<AppState, String>((s) => s.settings.currency);
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
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

    if (isLoading) {
      return Scaffold(
        body: AppBackground(
          child: Skeletonizer(
            enabled: true,
            child: Stack(
              children: [
                ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            'Good Morning',
                            style: textTheme.headlineMedium?.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const WMDarkHeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('MONTHLY SPEND'),
                          SizedBox(height: 12),
                          Text('0.00', style: TextStyle(fontSize: 38)),
                          SizedBox(height: 14),
                          Text('Loading financial metrics...'),
                        ],
                      ),
                    ),
                  ],
                ),
                const Center(
                  child: CircularProgressIndicator(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final totalSpent = state.getCurrentMonthTotalSpent();
    final hasBudget = monthlyBudget != null && monthlyBudget > 0;
    final budgetLimit = monthlyBudget ?? 0.0;
    final remaining = budgetLimit - totalSpent;
    final isOverBudget = hasBudget && remaining < 0;
    final ratio = hasBudget ? (totalSpent / budgetLimit).clamp(0.0, 1.5) : 0.0;
    final Color budgetColor = budgetProgressColor(ratio);
    final now = DateTime.now();
    final isCurrentMonth = selectedMonth.year == now.year && selectedMonth.month == now.month;
    final lastDayOfMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final daysRemaining = isCurrentMonth ? (lastDayOfMonth - now.day + 1).clamp(1, 31) : 1;

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: context.read<AppState>().refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              // ── Header row: Greeting, Month Selector Pill & Shortcuts ─────
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _greeting(),
                        maxLines: 1,
                        style: textTheme.headlineMedium?.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Month Switcher Controls
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark
                          ? WalletMeltColors.darkSurface
                          : Colors.white,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: isDark
                            ? WalletMeltColors.darkBorder
                            : WalletMeltColors.lightBorder,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 38),
                          tooltip: 'Previous month',
                          onPressed: context.read<AppState>().previousMonth,
                          icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        ),
                        Text(
                          readableMonth(selectedMonth),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 38),
                          tooltip: 'Next month',
                          onPressed: context.read<AppState>().nextMonth,
                          icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Settings Shortcut (with 48dp minimum accessible touch target)
                  SizedBox(
                    width: 44,
                    height: 44,
                    child: Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: isDark
                              ? WalletMeltColors.darkSurface
                              : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? WalletMeltColors.darkBorder
                                : WalletMeltColors.lightBorder,
                            width: 1.0,
                          ),
                        ),
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                          tooltip: 'Settings',
                          onPressed: () => context.push('/settings'),
                          icon: const Icon(Icons.settings_outlined, size: 18),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // ── Primary FinSight-Style Dark Financial Hero Card ──────────
              WMDarkHeroCard(
                onTap: () {
                  BudgetScreen.showSetBudgetSheet(
                    context,
                    state,
                    monthlyBudget,
                    totalSpent,
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Top Meta Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
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
                              Expanded(
                                child: Text(
                                  '${readableMonth(selectedMonth).toUpperCase()} SPEND',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (insights.monthOverMonthDelta != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: insights.monthOverMonthDelta! <= 0
                                  ? WalletMeltColors.positive.withValues(alpha: 0.18)
                                  : WalletMeltColors.danger.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  insights.monthOverMonthDelta! <= 0
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  size: 11,
                                  color: insights.monthOverMonthDelta! <= 0
                                      ? WalletMeltColors.positive
                                      : WalletMeltColors.danger,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  '${insights.monthOverMonthDelta!.abs().toStringAsFixed(1)}%',
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

                    // Big Confident Spend Typography
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(totalSpent, currency),
                        style: const TextStyle(
                          fontSize: 38,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Budget Progress & Remaining Amount Context
                    if (hasBudget) ...[
                      // Progress Bar
                      LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isOverBudget
                                    ? 'Over budget by ${formatMoney(-remaining, currency)}'
                                    : '${formatMoney(remaining, currency)} remaining',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isOverBudget
                                      ? WalletMeltColors.danger
                                      : Colors.white.withValues(alpha: 0.85),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Budget: ${formatMoney(budgetLimit, currency)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      // Daily Spend Allowance (Feature)
                      if (isCurrentMonth) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'DAILY ALLOWANCE',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                  color: Colors.white.withValues(alpha: 0.6),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    isOverBudget
                                        ? 'Over budget — no daily allowance'
                                        : '${formatMoney(remaining / daysRemaining, currency)} / day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isOverBudget
                                          ? WalletMeltColors.danger
                                          : Colors.white.withValues(alpha: 0.9),
                                      fontFeatures: const [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              insights.highestCategory == null
                                  ? 'No budget set for this month'
                                  : 'Highest: ${insights.highestCategory!.category.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Set Budget',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: WalletMeltColors.brand,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: WalletMeltColors.brand,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ── Quick Action Controls Row (FinSight Action Buttons) ──────
              Row(
                children: [
                  WMQuickActionButton(
                    icon: Icons.add_rounded,
                    label: 'Add Expense',
                    isPrimary: true,
                    onTap: () => context.push('/expense/new'),
                  ),
                  const SizedBox(width: 10),
                  WMQuickActionButton(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Fuel Refill',
                    onTap: () => context.push('/expense/new?categoryId=fuel'),
                  ),
                  const SizedBox(width: 10),
                  WMQuickActionButton(
                    icon: Icons.shopping_basket_rounded,
                    label: 'Groceries',
                    onTap: () => context.push('/expense/new?categoryId=grocery'),
                  ),
                  const SizedBox(width: 10),
                  WMQuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Insights',
                    onTap: () => context.push('/insights'),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Recent Activity / Transaction Timeline ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Recent Activity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                  ),
                  if (hasExpenses)
                    GestureDetector(
                      onTap: () => context.go('/history'),
                      child: Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? WalletMeltColors.brand : WalletMeltColors.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              if (!hasExpenses) ...[
                WMGlassSurface.tier1(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: WalletMeltColors.textMuted.withValues(alpha: 0.6),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          'No expenses recorded yet',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap + Add Expense above to log your first purchase.',
                          style: TextStyle(fontSize: 12, color: WalletMeltColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                WMGlassSurface.tier1(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  child: Column(
                    children: [
                      for (int i = 0; i < insights.recentExpenses.length; i++) ...[
                        ExpenseListTile(
                          expense: insights.recentExpenses[i],
                          category: context
                              .read<AppState>()
                              .categoryById(insights.recentExpenses[i].categoryId),
                          onTap: () => context.push('/expense/${insights.recentExpenses[i].id}'),
                        ),
                        if (i < insights.recentExpenses.length - 1)
                          Divider(
                            height: 1,
                            indent: 64,
                            color: isDark
                                ? WalletMeltColors.darkBorder
                                : WalletMeltColors.lightBorder,
                          ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 28),

              // ── Upcoming Commitments & Obligations ───────────────────────
              if (state.subscriptions.any((s) => s.status == wm_sub.SubscriptionStatus.active)) ...[
                _DashboardUpcomingRenewalsCard(state: state, currency: currency),
                const SizedBox(height: 16),
              ],

              if (state.debts.any((d) => !d.isSettled)) ...[
                _DashboardObligationsCard(state: state, currency: currency),
                const SizedBox(height: 16),
              ],

              if (state.currentMonthExpenses.any((e) => e.taxAmount != null && e.taxAmount! > 0)) ...[
                _DashboardTaxCard(state: state, currency: currency),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private Sub-Components ───────────────────────────────────────────────────

class _DashboardObligationsCard extends StatelessWidget {
  const _DashboardObligationsCard({
    required this.state,
    required this.currency,
  });

  final AppState state;
  final String currency;

  @override
  Widget build(BuildContext context) {
    double owedToMe = 0.0;
    double iOwe = 0.0;

    for (final debt in state.debts) {
      if (debt.isSettled) continue;
      if (debt.type == DebtType.owedToMe || debt.type == DebtType.loanGiven) {
        owedToMe += debt.remainingAmount;
      } else {
        iOwe += debt.remainingAmount;
      }
    }

    final netPosition = owedToMe - iOwe;
    final isNegative = netPosition < 0;

    if (owedToMe == 0 && iOwe == 0) {
      return const SizedBox.shrink();
    }

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/debt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Financial obligations',
            icon: Icons.handshake_rounded,
            padding: EdgeInsets.zero,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          TripleMetricRow(
            label1: 'OWED TO ME',
            value1: '${owedToMe.toStringAsFixed(owedToMe % 1 == 0 ? 0 : 2)} $currency',
            color1: WalletMeltColors.positive,
            label2: 'I OWE',
            value2: '${iOwe.toStringAsFixed(iOwe % 1 == 0 ? 0 : 2)} $currency',
            color2: Theme.of(context).colorScheme.error,
            label3: 'NET POSITION',
            value3: '${netPosition >= 0 ? "+" : ""}${netPosition.toStringAsFixed(netPosition % 1 == 0 ? 0 : 2)} $currency',
            color3: isNegative ? Theme.of(context).colorScheme.error : WalletMeltColors.positive,
          ),
        ],
      ),
    );
  }
}

class _DashboardTaxCard extends StatelessWidget {
  const _DashboardTaxCard({required this.state, required this.currency});

  final AppState state;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final taxThisMonth = state.currentMonthExpenses
        .fold<double>(0, (sum, e) => sum + (e.taxAmount ?? 0.0));
    if (taxThisMonth == 0) return const SizedBox.shrink();

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/insights'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Tax paid this month',
            icon: Icons.account_balance_rounded,
            padding: EdgeInsets.zero,
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.color
                  ?.withValues(alpha: 0.54),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatMoney(taxThisMonth, currency),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardUpcomingRenewalsCard extends StatelessWidget {
  const _DashboardUpcomingRenewalsCard(
      {required this.state, required this.currency});

  final AppState state;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final activeSubs = state.subscriptions
        .where((s) => s.status == wm_sub.SubscriptionStatus.active)
        .toList();
    if (activeSubs.isEmpty) return const SizedBox.shrink();

    final sortedSubs = List<wm_sub.Subscription>.from(activeSubs);
    sortedSubs
        .sort((a, b) => a.nextOccurrenceDate.compareTo(b.nextOccurrenceDate));

    final nextRenewals = sortedSubs.take(3).toList();

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/planning'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Upcoming renewals',
            icon: Icons.repeat_rounded,
            padding: EdgeInsets.zero,
            trailing: Text(
              'View all →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WalletMeltColors.brand
                    : WalletMeltColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nextRenewals.length,
            separatorBuilder: (context, index) => Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? WalletMeltColors.darkBorder
                    : WalletMeltColors.lightBorder),
            itemBuilder: (context, index) {
              final sub = nextRenewals[index];
              final totalAmount = sub.amount + (sub.taxAmount ?? 0.0);

              final nextDate = DateTime.tryParse(sub.nextOccurrenceDate);
              String daysText = '';
              if (nextDate != null) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final renewal =
                    DateTime(nextDate.year, nextDate.month, nextDate.day);
                final days = renewal.difference(today).inDays;
                if (days < 0) {
                  daysText = 'overdue';
                } else if (days == 0) {
                  daysText = 'today';
                } else if (days == 1) {
                  daysText = 'tomorrow';
                } else {
                  daysText = 'in $days days';
                }
              } else {
                daysText = 'unknown';
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sub.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          daysText,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: daysText == 'today' || daysText == 'overdue'
                                ? WalletMeltColors.danger
                                : WalletMeltColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatMoney(totalAmount, currency),
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
