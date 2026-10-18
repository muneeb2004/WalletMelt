import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Shared list rhythm so every screen scrolls and spaces the same way.
abstract final class FluidList {
  FluidList._();

  /// Standard list padding. [bottom] clears the shell's extended FAB.
  static const EdgeInsets padding = EdgeInsets.fromLTRB(
    AppSpacing.md,
    AppSpacing.sm,
    AppSpacing.md,
    120,
  );

  /// Gap between consecutive cards.
  static const double gap = AppSpacing.smMd;

  /// Soft, springy scroll physics used by every list.
  static const ScrollPhysics physics = BouncingScrollPhysics(
    parent: AlwaysScrollableScrollPhysics(),
  );
}

/// Fades and slides a list row in once, staggered by [index].
///
/// Only the first few rows stagger; later rows (scrolled into view) animate
/// with no delay so scrolling never feels laggy.
class FluidItem extends StatelessWidget {
  const FluidItem({required this.index, required this.child, super.key});

  final int index;
  final Widget child;

  static const int _maxStagger = 8;
  static const Duration _step = Duration(milliseconds: 40);
  static const Duration _duration = Duration(milliseconds: 320);

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).disableAnimations) return child;
    final delay = _step * (index < _maxStagger ? index : 0);
    final total = _duration + delay;
    final start = delay.inMilliseconds / total.inMilliseconds;
    final curve = Interval(start, 1, curve: Curves.easeOutCubic);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: curve,
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, (1 - t) * 18),
          child: child,
        ),
      ),
    );
  }
}

/// A uniform animated column of cards for screens built from a children list.
class FluidColumnList extends StatelessWidget {
  const FluidColumnList({
    required this.children,
    super.key,
    this.padding = FluidList.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: padding,
      physics: FluidList.physics,
      itemCount: children.length,
      separatorBuilder: (_, __) => const SizedBox(height: FluidList.gap),
      itemBuilder: (_, i) => FluidItem(index: i, child: children[i]),
    );
  }
}
