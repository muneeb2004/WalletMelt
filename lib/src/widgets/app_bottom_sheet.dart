import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Shows a standardized bottom sheet with unified constraints, safe area padding,
/// keyboard avoidance, and custom animations. Automatically plays haptic feedback on launch.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool showDragHandle = true,
  double maxWidth = 600,
  Color? backgroundColor,
}) async {
  // Trigger tactile haptic feedback when the sheet starts opening
  await WMHaptics.light();

  if (!context.mounted) return null;

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    constraints: BoxConstraints(maxWidth: maxWidth),
    builder: (sheetContext) {
      return SafeArea(
        child: AnimatedPadding(
          duration: AppMotion.fast,
          curve: AppMotion.standard,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: builder(sheetContext),
        ),
      );
    },
  );
}
