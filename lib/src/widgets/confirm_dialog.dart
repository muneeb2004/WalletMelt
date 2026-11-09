import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';
import 'wm_sheet.dart';

/// Shows a confirmation as a compact [WMSheet] (ADR-0018) and returns `true`
/// when the user confirms, `false` when they cancel, or `null` if dismissed.
///
/// When [isDestructive] is `true` the confirm button and icon use the error
/// colours so users recognise the irreversibility of the action.
Future<bool?> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool isDestructive = false,
  bool useRootNavigator = true,
  IconData? icon,
}) {
  // Heavy haptic for destructive actions; showAppBottomSheet adds a light one.
  if (isDestructive) WMHaptics.heavy();

  return showAppBottomSheet<bool>(
    context,
    useRootNavigator: useRootNavigator,
    builder: (sheetContext) => WMSheet(
      title: title,
      subtitle: body,
      icon: icon ??
          (isDestructive
              ? Icons.delete_outline_rounded
              : Icons.help_outline_rounded),
      destructive: isDestructive,
      actions: [
        WMSheetButton(
          label: 'Cancel',
          kind: WMSheetButtonKind.secondary,
          onPressed: () => Navigator.pop(sheetContext, false),
        ),
        WMSheetButton(
          label: confirmLabel,
          kind: isDestructive
              ? WMSheetButtonKind.destructive
              : WMSheetButtonKind.primary,
          onPressed: () => Navigator.pop(sheetContext, true),
        ),
      ],
    ),
  );
}
