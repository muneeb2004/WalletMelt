import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../components/charts/category_breakdown_chart.dart';
import '../../components/expense/expense_list_tile.dart';
import '../../components/glass/app_background.dart';
import '../../state/app_state.dart';
import '../../theme/wallet_melt_theme.dart';
import '../../utils/currency_format.dart';
import '../../utils/date_utils.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/progress_bar.dart';
import '../../types/debt.dart';
import '../../widgets/section_header.dart';
import '../../types/subscription.dart' as wm_sub;

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isLoading = context.select<AppState, bool>((s) => s.isLoading);
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final insights = context.select((AppState s) => s.monthlyInsights);
    final selectedMonth = context.select<AppState, DateTime>((s) => s.selectedMonth);
    final hasBudget = context.select<AppState, bool>((s) => s.getMonthlyBudgetAmount() != null);
    final hasExpenses = context.select<AppState, bool>((s) => s.expenses.isNotEmpty);
    final currency = context.select<AppState, String>((s) => s.settings.currency);
    final state = context.watch<AppState>();

    return Scaffold(
      body: AppBackground(
        child: RefreshIndicator(
          onRefresh: context.read<AppState>().refresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              // ── Header row ──────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('WalletMelt',
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text('Where did your money go this month?',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Previous month',
                    onPressed: context.read<AppState>().previousMonth,
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  IconButton(
                    tooltip: 'Next month',
                    onPressed: context.read<AppState>().nextMonth,
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md + 2),

              // ── Hero spend card ─────────────────────────────────────────
              LiquidGlass(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: WalletMeltColors.brandSoft
                              .withValues(alpha: 0.32),
                          boxShadow: [
                            BoxShadow(
                                color: WalletMeltColors.brand
                                    .withValues(alpha: 0.22),
                                blurRadius: 48)
                          ],
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(readableMonth(selectedMonth),
                            style: Theme.of(context).textTheme.labelLarge),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                            formatMoney(
                                insights.total, currency),
                            style: Theme.of(context).textTheme.displaySmall),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          insights.highestCategory == null
                              ? 'Add your first expense to reveal where the month melted.'
                              : 'Highest melt: ${insights.highestCategory!.category.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // ── Budget summary card ─────────────────────────────────────
              if (hasBudget) ...[
                const _DashboardBudgetCard(),
                const SizedBox(height: AppSpacing.md),
              ],

              // ── Financial Obligations Card ──────────────────────────────
              _DashboardObligationsCard(state: state, currency: currency),
              const SizedBox(height: AppSpacing.md),

              // ── Tax Paid Card ──────────────────────────────────────────
              _DashboardTaxCard(state: state, currency: currency),
              const SizedBox(height: AppSpacing.md),

              // ── Upcoming Renewals Card ──────────────────────────────────
              _DashboardUpcomingRenewalsCard(state: state, currency: currency),
              const SizedBox(height: AppSpacing.md),

              // ── Content: empty or charts + recent ──────────────────────
              if (!hasExpenses)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No expenses yet',
                  subtitle: 'Tap + to add your first expense.',
                )
              else ...[
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Category melt',
                        icon: Icons.donut_small_rounded,
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      RepaintBoundary(
                        child: CategoryBreakdownChart(
                            items: insights.categorySpend),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Grocery vs utilities',
                        icon: Icons.compare_arrows_rounded,
                        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _ComparisonBar(
                        leftLabel: 'Grocery',
                        leftValue: insights.groceryTotal,
                        rightLabel: 'Utilities',
                        rightValue: insights.utilitiesTotal,
                        currency: currency,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                LiquidGlass(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SectionHeader(
                        title: 'Recent expenses',
                        icon: Icons.history_rounded,
                        padding: EdgeInsets.only(bottom: AppSpacing.xs),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      for (final expense in insights.recentExpenses)
                        ExpenseListTile(
                          expense: expense,
                          category: context.read<AppState>().categoryById(expense.categoryId),
                          onTap: () => context.push('/expense/${expense.id}'),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Private widgets ──────────────────────────────────────────────────────────

class _ComparisonBar extends StatelessWidget {
  const _ComparisonBar({
    required this.leftLabel,
    required this.leftValue,
    required this.rightLabel,
    required this.rightValue,
    required this.currency,
  });

  final String leftLabel;
  final double leftValue;
  final String rightLabel;
  final double rightValue;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final total = leftValue + rightValue;
    final leftPercent = total == 0 ? 0.5 : leftValue / total;
    final leftFlex = (leftPercent * 100).round().clamp(1, 99).toInt();
    final rightFlex = (100 - leftFlex).clamp(1, 99).toInt();
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                  flex: leftFlex,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF8FD6B5),
                          Color(0xFF5AB693),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 2,
                  color: isDark ? const Color(0xFF1E1E24) : Colors.white,
                ),
                Expanded(
                  flex: rightFlex,
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFD98A),
                          Color(0xFFF4B740),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm + 2),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    leftLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(leftValue, currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: WalletMeltColors.positive,
                          fontSize: 15,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    rightLabel,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(rightValue, currency),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: WalletMeltColors.brand,
                          fontSize: 15,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DashboardBudgetCard extends StatelessWidget {
  const _DashboardBudgetCard();

  @override
  Widget build(BuildContext context) {
    final monthlyBudget = context.select<AppState, double>((s) => s.getMonthlyBudgetAmount() ?? 0.0);
    final totalSpent = context.select<AppState, double>((s) => s.getCurrentMonthTotalSpent());
    final currency = context.select<AppState, String>((s) => s.settings.currency);
    final remaining = monthlyBudget - totalSpent;
    final isOverBudget = remaining < 0;
    final ratio = monthlyBudget > 0 ? totalSpent / monthlyBudget : 0.0;
    final Color budgetColor = budgetProgressColor(ratio);

    return LiquidGlass(
      onTap: () => context.go('/budget'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "This Month's Budget",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xs, horizontal: AppSpacing.sm),
                child: Text(
                  'Details →',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ProgressBar(fraction: ratio, color: budgetColor),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spent: ${formatMoney(totalSpent, currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Text(
                isOverBudget
                    ? 'Over by ${formatMoney(-remaining, currency)}'
                    : 'Remaining: ${formatMoney(remaining, currency)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isOverBudget ? WalletMeltColors.danger : null,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

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

    // Show obligations only if there are active outstanding debts/loans.
    if (owedToMe == 0 && iOwe == 0) {
      return const SizedBox.shrink();
    }

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/debt'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Financial obligations',
                icon: Icons.handshake_rounded,
                padding: EdgeInsets.zero,
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OWED TO ME',
                      style: TextStyle(
                        fontSize: 9,
                        color: WalletMeltColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${owedToMe.toStringAsFixed(owedToMe % 1 == 0 ? 0 : 2)} $currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: WalletMeltColors.positive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: const Color(0x1Fffffff)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'I OWE',
                      style: TextStyle(
                        fontSize: 9,
                        color: WalletMeltColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${iOwe.toStringAsFixed(iOwe % 1 == 0 ? 0 : 2)} $currency',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: WalletMeltColors.danger,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(width: 1, height: 24, color: const Color(0x1Fffffff)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'NET POSITION',
                      style: TextStyle(
                        fontSize: 9,
                        color: WalletMeltColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${netPosition >= 0 ? "+" : ""}${netPosition.toStringAsFixed(netPosition % 1 == 0 ? 0 : 2)} $currency',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: isNegative ? WalletMeltColors.danger : WalletMeltColors.positive,
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
    final taxThisMonth = state.currentMonthExpenses.fold<double>(0, (sum, e) => sum + (e.taxAmount ?? 0.0));
    if (taxThisMonth == 0) return const SizedBox.shrink();

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.go('/insights'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Tax paid this month',
                icon: Icons.account_balance_rounded,
                padding: EdgeInsets.zero,
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.54),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formatMoney(taxThisMonth, currency),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: WalletMeltColors.danger,
                ),
          ),
        ],
      ),
    );
  }
}

class _DashboardUpcomingRenewalsCard extends StatelessWidget {
  const _DashboardUpcomingRenewalsCard({required this.state, required this.currency});

  final AppState state;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final activeSubs = state.subscriptions.where((s) => s.status == wm_sub.SubscriptionStatus.active).toList();
    if (activeSubs.isEmpty) return const SizedBox.shrink();

    final sortedSubs = List<wm_sub.Subscription>.from(activeSubs);
    sortedSubs.sort((a, b) => a.nextOccurrenceDate.compareTo(b.nextOccurrenceDate));

    final nextRenewals = sortedSubs.take(3).toList();

    return WMGlassSurface.tier2(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () => context.push('/subscriptions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(
                title: 'Upcoming renewals',
                icon: Icons.repeat_rounded,
                padding: EdgeInsets.zero,
              ),
              Text(
                'View all →',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm + 2),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: nextRenewals.length,
            separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0x1Fffffff)),
            itemBuilder: (context, index) {
              final sub = nextRenewals[index];
              final totalAmount = sub.amount + (sub.taxAmount ?? 0.0);
              
              final nextDate = DateTime.tryParse(sub.nextOccurrenceDate);
              String daysText = '';
              if (nextDate != null) {
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final renewal = DateTime(nextDate.year, nextDate.month, nextDate.day);
                final days = renewal.difference(today).inDays;
                if (days < 0) {
                  daysText = 'overdue';
                } else if (days == 0) {
                  daysText = 'today';
                } else if (days == 1) {
                  daysText = 'tomorrow';
                } else {
                  daysText = '$days days';
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
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
                        ),
                        Text(
                          daysText,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: daysText == 'today' || daysText == 'overdue'
                                ? WalletMeltColors.warning
                                : WalletMeltColors.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      formatMoney(totalAmount, currency),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 14),
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

