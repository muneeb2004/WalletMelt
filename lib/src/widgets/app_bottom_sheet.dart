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
  bool useRootNavigator = true,
  AnimationStyle? sheetAnimationStyle,
}) async {
  // Trigger tactile haptic feedback when the sheet starts opening
  WMHaptics.light();

  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: useRootNavigator,
    isScrollControlled: isScrollControlled,
    showDragHandle: showDragHandle,
    backgroundColor: backgroundColor,
    constraints: BoxConstraints(maxWidth: maxWidth),
    sheetAnimationStyle: sheetAnimationStyle ??
        const AnimationStyle(
          duration: AppMotion.medium,
          reverseDuration: AppMotion.fast,
          curve: AppMotion.entrance,
          reverseCurve: AppMotion.exit,
        ),
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
