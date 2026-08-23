import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';

/// A key-value display tile used in hero cards on the Dashboard and Budget
/// screens to show summary statistics (e.g. Spent, Remaining, Days Left).
class StatTile extends StatelessWidget {
  const StatTile({
    required this.label,
    required this.value,
    super.key,
    this.valueColor,
    this.icon,
  });

  final String label;
  final String value;

  /// Optional override for the value text color (e.g. danger color when over
  /// budget).
  final Color? valueColor;

  /// Optional leading icon displayed above the label.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tt = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(
          vertical: AppSpacing.sm + 4, horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark
            ? const Color.fromRGBO(255, 255, 255, 0.08)
            : const Color.fromRGBO(0, 0, 0, 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius - 8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: valueColor),
            const SizedBox(height: AppSpacing.xs),
          ],
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: tt.titleMedium?.copyWith(
                color: valueColor,
                fontSize: 14,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: tt.labelMedium?.copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
