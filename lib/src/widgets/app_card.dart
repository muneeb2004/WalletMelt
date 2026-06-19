import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Unified card wrapper. Internally delegates to [LiquidGlass] to preserve
/// the glassmorphic aesthetic. All screens should use [AppCard] rather than
/// instantiating [LiquidGlass] directly.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    super.key,
    this.padding,
    this.onTap,
    this.radius = AppSpacing.cardRadius,
    this.blur = true,
  });

  final Widget child;

  /// Override the inner padding. Defaults to [AppSpacing.md] via [LiquidGlass].
  final EdgeInsetsGeometry? padding;

  /// If non-null, the card becomes tappable with a ripple.
  final VoidCallback? onTap;

  /// Corner radius. Defaults to [AppSpacing.cardRadius].
  final double radius;

  /// Whether to apply backdrop-blur glass effect. Disable for opaque surfaces.
  final bool blur;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      padding: padding ?? AppSpacing.paddingMd,
      blur: blur ? 24.0 : 0.0,
      radius: radius,
      child: onTap != null
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(radius),
              child: child,
            )
          : child,
    );
  }
}
