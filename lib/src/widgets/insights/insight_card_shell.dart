import 'package:flutter/material.dart';

import '../../theme/wallet_melt_theme.dart';
import '../../types/insight_action.dart';
import '../../types/insight_card.dart';

/// Standard container shell for rendered insight cards with severity accenting
/// and clean typography.
class InsightCardShell extends StatelessWidget {
  const InsightCardShell({
    required this.card,
    required this.content,
    super.key,
    this.onAction,
    this.margin = const EdgeInsets.only(bottom: AppSpacing.md),
  });

  final InsightCard card;
  final Widget content;
  final ValueChanged<InsightAction>? onAction;
  final EdgeInsetsGeometry margin;

  Color _severityColor(BuildContext context) {
    return switch (card.severity) {
      InsightSeverity.alert => WalletMeltColors.danger,
      InsightSeverity.warning => WalletMeltColors.warning,
      InsightSeverity.positive => WalletMeltColors.positive,
      InsightSeverity.info => WalletMeltColors.brand,
    };
  }

  String _headerPillText() {
    final sevText = card.severity.name.toUpperCase();
    final taxText = card.taxonomy.name.toUpperCase();
    return '$sevText · $taxText';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final sevColor = _severityColor(context);

    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: sevColor.withValues(alpha: card.severity == InsightSeverity.alert ? 0.6 : 0.25),
          width: card.severity == InsightSeverity.alert ? 1.5 : 1.0,
        ),
      ),
      child: WMGlassSurface.tier2(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Header (Subtle metadata tag + Title)
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Text(
                    _headerPillText(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: sevColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (card.period != null)
                  Text(
                    card.period!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              card.title,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? WalletMeltColors.darkTextPrimary : WalletMeltColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              card.description,
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? WalletMeltColors.darkTextSecondary : WalletMeltColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // 2. Custom Detector Content
            content,

            // 3. Action CTA Button
            if (card.action != null) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onAction?.call(card.action!),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    visualDensity: VisualDensity.compact,
                    foregroundColor: sevColor,
                  ),
                  child: Text(
                    card.action!.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.xs),
            ],
          ],
        ),
      ),
    );
  }
}
