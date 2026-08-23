import 'package:flutter/material.dart';

import '../theme/wallet_melt_theme.dart';
import 'app_card.dart';

/// Standard error state widget across WalletMelt screens.
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    required this.message,
    super.key,
    this.title = 'Something went wrong',
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: WalletMeltColors.danger.withValues(alpha: isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: WalletMeltColors.danger.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 38,
                color: WalletMeltColors.danger,
              ),
            ),
            const SizedBox(height: AppSpacing.md + 4),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WalletMeltColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md + 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  backgroundColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
                  foregroundColor: isDark ? Colors.white : WalletMeltColors.textPrimary,
                  side: BorderSide(
                    color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                onPressed: () {
                  WMHaptics.light();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: Text(
                  retryLabel,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard offline state widget across WalletMelt screens.
class AppOfflineState extends StatelessWidget {
  const AppOfflineState({
    super.key,
    this.title = 'Offline Mode',
    this.message = 'You are offline. Local data is securely cached and will sync when reconnected.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: WalletMeltColors.warning.withValues(alpha: isDark ? 0.18 : 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: WalletMeltColors.warning.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 38,
                color: WalletMeltColors.warning,
              ),
            ),
            const SizedBox(height: AppSpacing.md + 4),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: WalletMeltColors.textMuted,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.md + 4),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(160, 44),
                  backgroundColor: isDark ? WalletMeltColors.darkSurface : Colors.white,
                  foregroundColor: isDark ? Colors.white : WalletMeltColors.textPrimary,
                  side: BorderSide(
                    color: isDark ? WalletMeltColors.darkBorder : WalletMeltColors.lightBorder,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
                  ),
                ),
                onPressed: () {
                  WMHaptics.light();
                  onRetry!();
                },
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text(
                  'Check Connection',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
