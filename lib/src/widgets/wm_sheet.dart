import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// Shared anatomy for every modal in the app (ADR-0018).
///
/// Header (optional icon tile, title, optional subtitle, close button),
/// scrollable body, and a sticky footer with equal-width actions. Show it
/// through `showAppBottomSheet`, which supplies the drag handle, safe area and
/// keyboard avoidance.
class WMSheet extends StatelessWidget {
  const WMSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.destructive = false,
    this.showClose = true,
    this.child,
    this.actions = const [],
  });

  final String title;
  final String? subtitle;

  /// Optional leading icon tile, used by confirmations.
  final IconData? icon;

  /// Tints the icon tile with the error colours.
  final bool destructive;
  final bool showClose;
  final Widget? child;

  /// Footer buttons, laid out as equal-width columns. Use [WMSheetButton].
  final List<WMSheetButton> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: destructive
                    ? scheme.errorContainer
                    : scheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                icon,
                color: destructive
                    ? scheme.onErrorContainer
                    : scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: AppSpacing.smMd),
          ],
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: text.titleLarge),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          subtitle!,
                          style: text.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (showClose && icon == null)
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: AppSpacing.md),
            Flexible(child: SingleChildScrollView(child: child)),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            _WMSheetFooter(actions: actions),
          ],
        ],
      ),
    );
  }
}

/// Lays the buttons side by side, or stacked (primary first) when any label
/// would not fit on one line at the current width and text scale.
class _WMSheetFooter extends StatelessWidget {
  const _WMSheetFooter({required this.actions});

  final List<WMSheetButton> actions;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.smMd;
        final each =
            (constraints.maxWidth - gap * (actions.length - 1)) / actions.length;
        final available = each - WMSheetButton.horizontalPadding * 2;
        final style = Theme.of(context).textTheme.labelLarge ??
            const TextStyle(fontSize: 14, fontWeight: FontWeight.w600);
        final scaler = MediaQuery.textScalerOf(context);
        final fits = actions.every((a) {
          final painter = TextPainter(
            text: TextSpan(text: a.label, style: style),
            textDirection: Directionality.of(context),
            textScaler: scaler,
            maxLines: 1,
          )..layout();
          final width = painter.width;
          painter.dispose();
          return width <= available;
        });

        if (fits) {
          return Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) SizedBox(width: gap),
                Expanded(child: actions[i]),
              ],
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = actions.length - 1; i >= 0; i--) ...[
              if (i < actions.length - 1) const SizedBox(height: AppSpacing.sm),
              actions[i],
            ],
          ],
        );
      },
    );
  }
}

enum WMSheetButtonKind { primary, secondary, destructive }

/// Footer button with a fixed height and shape so every sheet matches.
class WMSheetButton extends StatelessWidget {
  const WMSheetButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = WMSheetButtonKind.primary,
  });

  final String label;
  final VoidCallback? onPressed;
  final WMSheetButtonKind kind;

  /// Horizontal padding inside the button, shared with the footer's fit check.
  static const double horizontalPadding = 16;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
    );
    const size = Size.fromHeight(48);
    final child = Text(label);

    switch (kind) {
      case WMSheetButtonKind.secondary:
        return FilledButton.tonal(
          style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding)),
          onPressed: onPressed,
          child: child,
        );
      case WMSheetButtonKind.destructive:
        return FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: size,
            shape: shape,
            padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
            backgroundColor: scheme.error,
            foregroundColor: scheme.onError,
          ),
          onPressed: onPressed,
          child: child,
        );
      case WMSheetButtonKind.primary:
        return FilledButton(
          style: FilledButton.styleFrom(
              minimumSize: size,
              shape: shape,
              padding: const EdgeInsets.symmetric(horizontal: horizontalPadding)),
          onPressed: onPressed,
          child: child,
        );
    }
  }
}
