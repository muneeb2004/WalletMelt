import 'package:flutter/material.dart';

import '../utils/haptics.dart';
import 'app_spacing.dart';

/// Visual weight of a [WMCard]. Depth is tonal, never a shadow.
enum WMCardTone {
  /// Default in-flow card (surfaceContainer).
  surface,

  /// Raised tile / icon well (surfaceContainerHigh).
  raised,

  /// Hero emphasis (primaryContainer).
  brand,

  /// Transparent with a hairline outline.
  outlined,
}

/// The one card primitive (ADR-0010). No shadows, no blur, no gradients.
class WMCard extends StatelessWidget {
  const WMCard({
    required this.child,
    super.key,
    this.tone = WMCardTone.surface,
    this.padding = const EdgeInsets.all(AppSpacing.md),
    this.radius = AppSpacing.radiusLg,
    this.onTap,
  });

  final Widget child;
  final WMCardTone tone;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (tone) {
      WMCardTone.surface => scheme.surfaceContainer,
      WMCardTone.raised => scheme.surfaceContainerHigh,
      WMCardTone.brand => scheme.primaryContainer,
      WMCardTone.outlined => Colors.transparent,
    };
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: tone == WMCardTone.outlined
          ? BorderSide(color: scheme.outlineVariant)
          : BorderSide.none,
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null
          ? Padding(padding: padding, child: child)
          : InkWell(
              onTap: () {
                WMHaptics.light();
                onTap!();
              },
              child: Padding(padding: padding, child: child),
            ),
    );
  }
}
