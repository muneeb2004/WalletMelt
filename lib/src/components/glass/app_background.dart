import 'package:flutter/material.dart';

/// Flat screen canvas (ADR-0010): scheme surface, centred, max 600dp wide.
class AppBackground extends StatelessWidget {
  const AppBackground({
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
