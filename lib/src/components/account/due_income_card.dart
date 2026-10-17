import 'package:flutter/material.dart';

import '../../screens/income/income_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_spacing.dart';
import '../../theme/wm_card.dart';
import '../../utils/currency_format.dart';
import 'compact_button_style.dart';

/// Dashboard prompt for the oldest due income schedule (ADR-0012). Income is
/// never posted automatically: the user confirms or skips each occurrence.
class DueIncomeCard extends StatelessWidget {
  const DueIncomeCard({required this.state, super.key});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    if (!state.incomeAvailable) return const SizedBox.shrink();
    final due = state.dueIncomeSchedules;
    if (due.isEmpty) return const SizedBox.shrink();
    final schedule = due.first;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final more = due.length - 1;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: WMCard(
        key: const Key('dashboard_due_income'),
        tone: WMCardTone.brand,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Did ${schedule.title} arrive?',
                style: textTheme.titleMedium
                    ?.copyWith(color: scheme.onPrimaryContainer)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              '${formatMoneyMinorUnits(schedule.amountMinorUnits, schedule.currency)} expected on ${schedule.nextDueDate.substring(0, 10)}'
              '${more > 0 ? ' · $more more waiting' : ''}',
              style: textTheme.bodySmall?.copyWith(color: scheme.onPrimaryContainer),
            ),
            const SizedBox(height: AppSpacing.smMd),
            Row(
              children: [
                FilledButton(
                  style: compactButtonStyle,
                  onPressed: () => showConfirmIncomeSheet(context, schedule),
                  child: const Text('Received'),
                ),
                const SizedBox(width: AppSpacing.sm),
                TextButton(
                  style: compactButtonStyle,
                  onPressed: () => state.skipIncomeOccurrence(schedule.id),
                  child: const Text('Skip'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
