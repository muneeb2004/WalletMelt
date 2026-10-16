import 'package:flutter/material.dart';
import '../../theme/wallet_melt_theme.dart';

/// Clean secondary biometric action button with platform-adaptive icon and label.
class WMBiometricButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final bool disabled;

  const WMBiometricButton({
    required this.onTap,
    required this.label,
    this.icon,
    this.disabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final resolvedIcon = icon ??
        (label.toLowerCase().contains('face')
            ? Icons.face_rounded
            : Icons.fingerprint_rounded);

    return Semantics(
      label: 'Unlock with $label',
      button: true,
      enabled: !disabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: disabled
              ? null
              : () {
                  WMHaptics.light();
                  onTap();
                },
          borderRadius: BorderRadius.circular(100),
          splashColor: isDark
              ? context.scheme.primary.withValues(alpha: 0.12)
              : context.scheme.shadow.withValues(alpha: 0.06),
          highlightColor: isDark
              ? context.scheme.primary.withValues(alpha: 0.06)
              : context.scheme.shadow.withValues(alpha: 0.03),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              color: isDark
                  ? context.scheme.surfaceContainer.withValues(alpha: disabled ? 0.3 : 0.6)
                  : Colors.white.withValues(alpha: disabled ? 0.4 : 0.8),
              border: Border.all(
                color: context.scheme.outlineVariant,
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  resolvedIcon,
                  size: 18,
                  color: context.scheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Unlock with $label',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: context.scheme.onSurface,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
