import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Shows a confirmation [AlertDialog] and returns `true` when the user
/// confirms, `false` when they cancel, or `null` if dismissed via back.
///
/// When [isDestructive] is `true` the confirm button is rendered using
/// [colorScheme.error] so users recognise the irreversibility of the action.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool isDestructive = false,
}) {
  return showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        if (isDestructive)
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          )
        else
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.buttonRadius),
              ),
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(confirmLabel),
          ),
      ],
    ),
  );
}
