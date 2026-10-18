import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

import '../../components/account/dashboard_balance_card.dart';
import '../../components/account/due_committee_card.dart';
import '../../components/account/due_income_card.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../screens/budget/budget_screen.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../analytics/financial_metrics_calculator.dart';
import '../../types/debt.dart';
import '../../widgets/section_header.dart';
import '../../types/subscription.dart' as wm_sub;
import '../../widgets/state_views.dart';
import '../../widgets/triple_metric_row.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  String _timeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AppState, bool>((s) => s.isLoading);
    final insights = context.select((AppState s) => s.monthlyInsights);
    final selectedMonth =
        context.select<AppState, DateTime>((s) => s.selectedMonth);
    final monthlyBudget =
        context.select<AppState, double?>((s) => s.getMonthlyBudgetAmount());
    final hasExpenses =
        context.select<AppState, bool>((s) => s.expenses.isNotEmpty);
    final currency =
        context.select<AppState, String>((s) => s.settings.currency);
    final state = context.watch<AppState>();
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final scheme = theme.colorScheme;
    final money = context.money;

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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Good',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Morning',
                                style: textTheme.headlineMedium?.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.5,
                                  height: 1.15,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const WMDarkHeroCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('TOTAL SPEND'),
                          SizedBox(height: 16),
                          Text('0.00', style: TextStyle(fontSize: 38)),
                          SizedBox(height: 16),
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
    final allowanceResult =
        FinancialMetricsCalculator.calculateDailySpendAllowance(
      monthlyBudget: monthlyBudget,
      totalSpent: totalSpent,
      month: selectedMonth,
      period: state.budgetPeriod,
    );
    final hasBudget = allowanceResult.hasBudget;
    final budgetLimit = allowanceResult.totalBudget;
    final remaining = allowanceResult.remainingBudget ?? 0.0;
    final isOverBudget = allowanceResult.isOverBudget;
    final ratio = hasBudget ? (totalSpent / budgetLimit).clamp(0.0, 1.5) : 0.0;
    final Color budgetColor = money.budget(ratio);
    final isCurrentMonth = allowanceResult.isCurrentMonth;

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: context.read<AppState>().refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.sm, AppSpacing.md, 96),
            children: [
              // ── Header: greeting, month switcher, settings ──────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Good ${_timeOfDay().toLowerCase()}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Settings',
                    onPressed: () => context.push('/settings'),
                    icon: const Icon(Icons.settings_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: Alignment.centerLeft,
                child: _MonthSwitcher(
                  label: state.budgetPeriod.label(selectedMonth),
                  onPrevious: context.read<AppState>().previousMonth,
                  onNext: context.read<AppState>().nextMonth,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Hero: total spend, budget bar, daily allowance ──────────
              WMCard(
                key: const Key('dashboard_hero'),
                tone: WMCardTone.brand,
                padding: const EdgeInsets.all(AppSpacing.md),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Total spend',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.labelMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                        ),
                        if (insights.monthOverMonthDelta != null)
                          _DeltaChip(delta: insights.monthOverMonthDelta!),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatMoney(totalSpent, currency),
                        style: textTheme.displaySmall
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (hasBudget) ...[
                      LinearProgressIndicator(
                        value: ratio.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: scheme.surface,
                        valueColor: AlwaysStoppedAnimation<Color>(budgetColor),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusPill),
                      ),
                      const SizedBox(height: AppSpacing.smMd),
                      Row(
                        children: [
                          Expanded(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                isOverBudget
                                    ? 'Over budget by ${formatMoney(-remaining, currency)}'
                                    : '${formatMoney(remaining, currency)} remaining',
                                style: textTheme.titleSmall?.copyWith(
                                  color: isOverBudget
                                      ? money.overText
                                      : scheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                'Budget: ${formatMoney(budgetLimit, currency)}',
                                style: textTheme.bodySmall
                                    ?.copyWith(color: scheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (isCurrentMonth) ...[
                        const SizedBox(height: AppSpacing.smMd),
                        Material(
                          color: scheme.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.radiusMd),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => context.push('/settings/metrics'),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.smMd,
                                vertical: AppSpacing.sm + 2,
                              ),
                              child: Row(
                                children: [
                                  Text(
                                    'Daily allowance',
                                    style: textTheme.labelMedium,
                                  ),
                                  const SizedBox(width: AppSpacing.xs),
                                  Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                    color: scheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        isOverBudget
                                            ? 'Over budget — no daily allowance'
                                            : '${formatMoney(allowanceResult.dailyAllowance, currency)} / day',
                                        style: textTheme.titleSmall?.copyWith(
                                          color: isOverBudget
                                              ? money.overText
                                              : scheme.onSurface,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ] else
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              insights.highestCategory == null
                                  ? 'No budget set for this month'
                                  : 'Highest: ${insights.highestCategory!.category.name}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.bodySmall
                                  ?.copyWith(color: scheme.primary),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Set budget',
                            style: textTheme.labelMedium
                                ?.copyWith(color: scheme.primary),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Icon(Icons.arrow_forward_rounded,
                              size: 16, color: scheme.primary),
                        ],
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Quick actions ────────────────────────────────────────────
              Row(
                children: [
                  WMQuickActionButton(
                    icon: Icons.add_rounded,
                    label: 'Add expense',
                    isPrimary: true,
                    onTap: () => context.push('/expense/new'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  WMQuickActionButton(
                    icon: Icons.local_gas_station_rounded,
                    label: 'Fuel refill',
                    onTap: () => context.push('/expense/new?categoryId=fuel'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  WMQuickActionButton(
                    icon: Icons.shopping_basket_rounded,
                    label: 'Groceries',
                    onTap: () =>
                        context.push('/expense/new?categoryId=grocery'),
                  ),
                  const SizedBox(width: AppSpacing.smMd),
                  WMQuickActionButton(
                    icon: Icons.bar_chart_rounded,
                    label: 'Insights',
                    onTap: () => context.push('/insights'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),

              // ── Account balance (opt-in, ADR-0011) ───────────────────────
              DueIncomeCard(state: state),
              DueCommitteeCard(state: state),
              DashboardBalanceCard(state: state),

              // ── Recent activity ──────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Recent activity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleLarge,
                    ),
                  ),
                  if (hasExpenses)
                    TextButton(
                      onPressed: () => context.go('/history'),
                      child: const Text('View all'),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              if (!hasExpenses)
                WMCard(
                  tone: WMCardTone.outlined,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.lg,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 40,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'No expenses recorded yet',
                          style: textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'Tap Add expense above to log your first purchase.',
                          textAlign: TextAlign.center,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                )
              else
                WMCard(
                  padding: const EdgeInsets.all(AppSpacing.xs + 2),
                  child: Column(
                    children: [
                      for (int i = 0;
                          i < insights.recentExpenses.length;
                          i++) ...[
                        ExpenseListTile(
                          expense: insights.recentExpenses[i],
                          category: context.read<AppState>().categoryById(
                              insights.recentExpenses[i].categoryId),
                          onTap: () => context.push(
                              '/expense/${insights.recentExpenses[i].id}'),
                        ),
                        if (i < insights.recentExpenses.length - 1)
                          const Divider(height: 1, indent: 64),
                      ],
                    ],
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),

              // ── Upcoming Commitments & Obligations ───────────────────────
              if (state.subscriptions.any(
                  (s) => s.status == wm_sub.SubscriptionStatus.active)) ...[
                _DashboardUpcomingRenewalsCard(
                    state: state, currency: currency),
                const SizedBox(height: 16),
              ],

              if (state.debts.any((d) => !d.isSettled)) ...[
                _DashboardObligationsCard(state: state, currency: currency),
                const SizedBox(height: 16),
              ],

              if (state.currentMonthExpenses
                  .any((e) => e.taxAmount != null && e.taxAmount! > 0)) ...[
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

    return WMCard(
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          TripleMetricRow(
            label1: 'OWED TO ME',
            value1:
                '${owedToMe.toStringAsFixed(owedToMe % 1 == 0 ? 0 : 2)} $currency',
            color1: context.money.incomeText,
            label2: 'I OWE',
            value2: '${iOwe.toStringAsFixed(iOwe % 1 == 0 ? 0 : 2)} $currency',
            color2: Theme.of(context).colorScheme.error,
            label3: 'NET POSITION',
            value3:
                '${netPosition >= 0 ? "+" : ""}${netPosition.toStringAsFixed(netPosition % 1 == 0 ? 0 : 2)} $currency',
            color3: isNegative
                ? Theme.of(context).colorScheme.error
                : context.money.incomeText,
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

    return WMCard(
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
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatMoney(taxThisMonth, currency),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Theme.of(context).colorScheme.error,
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

    return WMCard(
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
              'View all',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nextRenewals.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
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
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          daysText,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(
                                color:
                                    daysText == 'today' || daysText == 'overdue'
                                        ? context.money.overText
                                        : Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    Text(
                      formatMoney(totalAmount, currency),
                      style: Theme.of(context).textTheme.titleMedium,
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

class _MonthSwitcher extends StatelessWidget {
  const _MonthSwitcher({
    required this.label,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainer,
      shape: const StadiumBorder(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Previous month',
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
          ),
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Next month',
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.delta});

  /// Month-over-month change in percent. Negative means spending fell.
  final double delta;

  @override
  Widget build(BuildContext context) {
    final money = context.money;
    final down = delta <= 0;
    final color = down ? money.incomeText : money.overText;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
      ),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              down ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              size: 14,
              color: color,
            ),
            const SizedBox(width: 2),
            Text(
              '${delta.abs().toStringAsFixed(1)}%',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
