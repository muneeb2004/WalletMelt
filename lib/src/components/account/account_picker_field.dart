import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import '../../types/account.dart';

/// Optional account selector for the expense form (ADR-0011).
///
/// Only accounts in [currency] are offered, so a derived balance never mixes
/// currencies. `null` means "No account" (the expense stays unassigned).
class AccountPickerField extends StatelessWidget {
  const AccountPickerField({
    required this.accounts,
    required this.currency,
    required this.value,
    required this.onChanged,
    this.label = 'Paid from',
    this.helperText,
    super.key,
  });

  final List<Account> accounts;
  final String currency;
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final eligible = [
      for (final a in accounts)
        if (a.currency == currency && (!a.isArchived || a.id == value)) a,
    ];
    if (eligible.isEmpty) return const SizedBox.shrink();
    final selected = eligible.any((a) => a.id == value) ? value : null;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: DropdownButtonFormField<String?>(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        dropdownColor: Theme.of(context).colorScheme.surfaceContainerHigh,
        menuMaxHeight: 320,
        key: const ValueKey('expense-account-picker'),
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          helperMaxLines: 2,
          prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
        ),
        style: textTheme.bodyLarge,
        items: [
          const DropdownMenuItem<String?>(
            value: null,
            child: Text('No account'),
          ),
          for (final a in eligible)
            DropdownMenuItem<String?>(
              value: a.id,
              child: Text(a.name, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}
