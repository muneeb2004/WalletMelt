import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/account.dart';

/// Bottom sheet that lets the user pick (or clear) the account linked to an
/// existing debt or subscription. Returns `chosen` via [onSelected]; the sheet
/// closes itself. Only same-currency, non-archived accounts are offered, plus
/// the currently linked one so it can be seen and cleared.
Future<void> showChooseAccountSheet(
  BuildContext context, {
  required List<Account> accounts,
  required String currency,
  required String? currentAccountId,
  required String title,
  required String explanation,
  required Future<void> Function(String? accountId) onSelected,
}) {
  final eligible = [
    for (final a in accounts)
      if (a.currency == currency &&
          (!a.isArchived || a.id == currentAccountId))
        a,
  ];
  return showAppBottomSheet<void>(
    context,
    builder: (sheetContext) {
      final textTheme = Theme.of(sheetContext).textTheme;
      Future<void> choose(String? id) async {
        final navigator = Navigator.of(sheetContext);
        await onSelected(id);
        navigator.pop();
      }

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.smMd, AppSpacing.lg, AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(explanation, style: textTheme.bodyMedium),
            const SizedBox(height: AppSpacing.md),
            if (eligible.isEmpty)
              Text(
                'No $currency accounts yet. Add one from Settings, then come back.',
                style: textTheme.bodyMedium,
              ),
            RadioGroup<String?>(
              groupValue: currentAccountId,
              onChanged: (id) => choose(id),
              child: Column(
                children: [
                  const RadioListTile<String?>(
                    value: null,
                    contentPadding: EdgeInsets.zero,
                    title: Text('No account'),
                  ),
                  for (final a in eligible)
                    RadioListTile<String?>(
                      value: a.id,
                      contentPadding: EdgeInsets.zero,
                      title: Text(a.name),
                      subtitle: a.isArchived ? const Text('Archived') : null,
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
