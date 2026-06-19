import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';
import 'app_card.dart';

/// Unified empty-state display. Used on History, Insights, and Budget screens
/// to surface a consistent icon + heading + subtitle when there is no data.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 56,
            color: colorScheme.onSurface.withValues(alpha: 0.30),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: tt.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            style: tt.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
