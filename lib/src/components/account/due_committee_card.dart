import 'package:flutter/material.dart';

import '../../analytics/committee_planner.dart';
import '../../screens/committees/committees_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../theme/wm_card.dart';
import '../../types/committee.dart';
import '../../utils/currency_format.dart';
import 'compact_button_style.dart';

/// Dashboard prompt for the oldest due committee item (ADR-0016). Nothing is
/// posted automatically: the user confirms, or taps Later to hide it for now.
class DueCommitteeCard extends StatefulWidget {
  const DueCommitteeCard({required this.state, super.key});

  final AppState state;

  @override
  State<DueCommitteeCard> createState() => _DueCommitteeCardState();
}

class _DueCommitteeCardState extends State<DueCommitteeCard> {
  final Set<String> _later = {};

  String _key(CommitteeDueItem i) =>
      '${i.committeeId}-${i.kind.name}-${i.monthIndex}';

  @override
  Widget build(BuildContext context) {
    // Rebuild on any AppState change so a confirmed item disappears at once,
    // wherever the card is placed.
    return ListenableBuilder(
      listenable: widget.state,
      builder: (context, _) => _buildCard(context),
    );
  }

  Widget _buildCard(BuildContext context) {
    final state = widget.state;
    if (!state.committeesAvailable) return const SizedBox.shrink();
    final items =
        state.dueCommitteeItems.where((i) => !_later.contains(_key(i))).toList();
    if (items.isEmpty) return const SizedBox.shrink();
    final item = items.first;
    final progress = state.committeeProgress
        .where((p) => p.committee.id == item.committeeId)
        .firstOrNull;
    if (progress == null) return const SizedBox.shrink();
    final c = progress.committee;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isPayout = item.kind == CommitteeEventKind.payout;
    final d = item.dueDate;
    final dateText =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final more = items.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: WMCard(
        key: const Key('dashboard_due_committee'),
        tone: WMCardTone.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isPayout
                  ? 'Did you receive your ${c.name} payout?'
                  : 'Did you pay your ${c.name} installment?',
              style: textTheme.titleMedium
                  ?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Month ${item.monthIndex} · ${formatMoneyMinorUnits(item.amountMinorUnits, c.currency)} · $dateText'
              '${more > 0 ? ' · $more more waiting' : ''}',
              style: textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.smMd),
            Row(
              children: [
                FilledButton(
                  style: compactButtonStyle,
                  onPressed: () => isPayout
                      ? showConfirmPayoutSheet(context, c)
                      : showConfirmInstallmentSheet(context, c, item.monthIndex),
                  child: Text(isPayout ? 'Received' : 'Paid'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  style: compactButtonStyle,
                  onPressed: () => setState(() => _later.add(_key(item))),
                  child: const Text('Later'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
