import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// A section label row used above list sections across all screens.
///
/// Renders an optional leading [icon], a [title] in [titleMedium], and an
/// optional [trailing] widget (e.g. an action button).
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.icon,
    this.trailing,
    this.padding = const EdgeInsets.symmetric(vertical: AppSpacing.sm),
  });

  final String title;
  final IconData? icon;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.titleMedium;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(child: Text(title, style: style)),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
