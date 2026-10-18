import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../state/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../theme/wm_card.dart';
import '../../utils/security_utils.dart';
import '../../utils/currency_format.dart';

/// Dashboard entry point for accounts (ADR-0011): a setup prompt before any
/// account exists, then the total balance per currency with a hide toggle.
class DashboardBalanceCard extends StatefulWidget {
  const DashboardBalanceCard({required this.state, super.key});

  final AppState state;

  @override
  State<DashboardBalanceCard> createState() => _DashboardBalanceCardState();
}

class _DashboardBalanceCardState extends State<DashboardBalanceCard> {
  bool _hidden = false;

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    if (!state.accountsAvailable) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final hasAccounts =
        state.accountBalances.any((b) => !b.account.isArchived);

    if (!hasAccounts) {
      // Published screenshots predate accounts; keep them unchanged until a demo
      // account is seeded.
      if (SecurityUtils.isScreenshotMode) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: WMCard(
          key: const Key('dashboard_balance_prompt'),
          tone: WMCardTone.outlined,
          onTap: () => context.push('/accounts'),
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined,
                  color: scheme.primary),
              const SizedBox(width: AppSpacing.smMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Track your balance', style: textTheme.titleMedium),
                    Text(
                      'Add an account and log money in or out to see what you have left.',
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      );
    }

    final totals = state.accountTotals;
    final anyReserved = state.reservedByAccount.values.any((v) => v > 0);
    final free = anyReserved ? state.freeToSpendTotals : const [];
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: WMCard(
        key: const Key('dashboard_balance'),
        onTap: () => context.push('/accounts'),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total balance',
                      style: textTheme.labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant)),
                  const SizedBox(height: AppSpacing.xs),
                  if (totals.isEmpty)
                    Text('No accounts in total', style: textTheme.bodyMedium)
                  else
                    for (final t in totals)
                      Text(
                        _hidden
                            ? '••••'
                            : formatMoneyMinorUnits(t.minorUnits, t.currency),
                        style: withTabularFigures(textTheme.titleLarge),
                      ),
                  if (free.isNotEmpty)
                    for (final t in free)
                      Text(
                        _hidden
                            ? 'Free to spend ••••'
                            : 'Free to spend ${formatMoneyMinorUnits(t.minorUnits, t.currency)}',
                        key: const Key('dashboard_free_to_spend'),
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                ],
              ),
            ),
            IconButton(
              tooltip: _hidden ? 'Show balance' : 'Hide balance',
              onPressed: () => setState(() => _hidden = !_hidden),
              icon: Icon(_hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined),
            ),
          ],
        ),
      ),
    );
  }
}
