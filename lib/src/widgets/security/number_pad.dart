import 'package:flutter/material.dart';
import '../../theme/wallet_melt_theme.dart';

/// Numeric keypad for digit entry with responsive layout, semantic labels, and optional biometric action.
class NumberPad extends StatelessWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onDelete;
  final VoidCallback? onBiometricPressed;
  final String? biometricLabel;
  final IconData? biometricIcon;
  final bool disabled;

  const NumberPad({
    required this.onKeyPress,
    required this.onDelete,
    this.onBiometricPressed,
    this.biometricLabel,
    this.biometricIcon,
    this.disabled = false,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Responsive key size calculation
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        // Key button size adapts to available screen width (e.g. 320px to 430px+)
        final buttonSize = (availableWidth / 3.8).clamp(56.0, 72.0);
        final horizontalPadding = ((availableWidth - (buttonSize * 3)) / 6).clamp(4.0, 16.0);
        final verticalMargin = (buttonSize * 0.12).clamp(4.0, 10.0);

        Widget buildKey(String digit) {
          return Semantics(
            label: 'Digit $digit',
            button: true,
            enabled: !disabled,
            child: SizedBox(
              width: buttonSize + (horizontalPadding * 2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalMargin,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () {
                            WMHaptics.light();
                            onKeyPress(digit);
                          },
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    splashColor: isDark
                        ? WalletMeltColors.brand.withValues(alpha: 0.12)
                        : Colors.black.withValues(alpha: 0.08),
                    highlightColor: isDark
                        ? WalletMeltColors.brand.withValues(alpha: 0.06)
                        : Colors.black.withValues(alpha: 0.04),
                    child: Container(
                      height: buttonSize,
                      width: buttonSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? WalletMeltColors.darkSurface.withValues(alpha: disabled ? 0.3 : 0.7)
                            : Colors.white.withValues(alpha: disabled ? 0.4 : 0.85),
                        border: Border.all(
                          color: isDark
                              ? WalletMeltColors.darkBorder
                              : WalletMeltColors.lightBorder,
                          width: 1.0,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        digit,
                        style: TextStyle(
                          fontSize: buttonSize * 0.38,
                          fontWeight: FontWeight.w700,
                          color: disabled
                              ? (isDark
                                  ? WalletMeltColors.darkTextSecondary.withValues(alpha: 0.4)
                                  : WalletMeltColors.textSecondary.withValues(alpha: 0.4))
                              : (isDark
                                  ? WalletMeltColors.darkTextPrimary
                                  : WalletMeltColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Widget buildDeleteKey() {
          return Semantics(
            label: 'Delete last digit',
            button: true,
            enabled: !disabled,
            child: SizedBox(
              width: buttonSize + (horizontalPadding * 2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalMargin,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () {
                            WMHaptics.selection();
                            onDelete();
                          },
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    splashColor: theme.colorScheme.error.withValues(alpha: 0.12),
                    highlightColor: theme.colorScheme.error.withValues(alpha: 0.06),
                    child: Container(
                      height: buttonSize,
                      width: buttonSize,
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.backspace_outlined,
                        size: buttonSize * 0.34,
                        color: disabled
                            ? (isDark
                                ? WalletMeltColors.darkTextSecondary.withValues(alpha: 0.3)
                                : WalletMeltColors.textSecondary.withValues(alpha: 0.3))
                            : (isDark
                                ? WalletMeltColors.darkTextPrimary
                                : WalletMeltColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        Widget buildBiometricKey() {
          if (onBiometricPressed == null) {
            return SizedBox(
              width: buttonSize + (horizontalPadding * 2),
              height: buttonSize + (verticalMargin * 2),
            );
          }

          final label = biometricLabel ?? 'Biometrics';
          return Semantics(
            label: 'Unlock with $label',
            button: true,
            enabled: !disabled,
            child: SizedBox(
              width: buttonSize + (horizontalPadding * 2),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding,
                  vertical: verticalMargin,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: disabled
                        ? null
                        : () {
                            WMHaptics.medium();
                            onBiometricPressed!();
                          },
                    borderRadius: BorderRadius.circular(buttonSize / 2),
                    splashColor: isDark
                        ? WalletMeltColors.brand.withValues(alpha: 0.15)
                        : Colors.black.withValues(alpha: 0.08),
                    highlightColor: isDark
                        ? WalletMeltColors.brand.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.04),
                    child: Container(
                      height: buttonSize,
                      width: buttonSize,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark
                            ? WalletMeltColors.darkSurface.withValues(alpha: 0.5)
                            : Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: isDark
                              ? WalletMeltColors.darkBorder
                              : WalletMeltColors.lightBorder,
                          width: 1.0,
                        ),
                      ),
                      child: Icon(
                        biometricIcon ?? Icons.fingerprint_rounded,
                        size: buttonSize * 0.42,
                        color: isDark
                            ? WalletMeltColors.brand
                            : WalletMeltColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }

        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildKey('1'),
                  buildKey('2'),
                  buildKey('3'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildKey('4'),
                  buildKey('5'),
                  buildKey('6'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildKey('7'),
                  buildKey('8'),
                  buildKey('9'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  buildBiometricKey(),
                  buildKey('0'),
                  buildDeleteKey(),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Convenience alias adhering to WalletMelt design token naming.
typedef WMPinKeypad = NumberPad;
